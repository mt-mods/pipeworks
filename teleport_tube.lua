local S = minetest.get_translator("pipeworks")
local filename=minetest.get_worldpath() .. "/teleport_tubes" -- Only used for backward-compat
local storage=minetest.get_mod_storage()

local tp_tube_db = nil -- nil forces a read
local tp_tube_db_version = 4

-- cached rceiver list: hash(pos) => {receivers}
local cache = {}

local function hash(pos)
	return string.format("%.30g", minetest.hash_node_position(pos))
end

-- New entry format: <can receive (number)> ':' <channel (string)>

local function serialize_tube_db_entry(entry)
	return entry.cr .. ":" .. entry.channel
end

local function deserialize_tube_db_entry(hash, str)
	local sep = str:find(":", 2, true)
	if not sep then return minetest.deserialize(str) end
	local cr = tonumber(str:sub(1, sep - 1))
	if not cr then return minetest.deserialize(str) end
	local channel = str:sub(sep + 1)
	local pos = minetest.get_position_from_hash(tonumber(hash))
	return {x = pos.x, y = pos.y, z = pos.z, cr = cr, channel = channel}
end

local function save_tube_db()
	-- reset tp-tube cache
	cache = {}

	local fields = {version = tp_tube_db_version}
	for key, val in pairs(tp_tube_db) do
		fields[key] = serialize_tube_db_entry(val)
	end
	storage:from_table({fields = fields})
end

local function save_tube_db_entry(hash)
	-- reset tp-tube cache
	cache = {}

	local val = tp_tube_db[hash]
	storage:set_string(hash, val and serialize_tube_db_entry(val) or "")
end

local function migrate_tube_db()
	local old_version = tp_tube_db.version or 0
	tp_tube_db.version = nil
	if old_version < 2.0 then
		local tmp_db = {}
		for _, val in pairs(tp_tube_db) do
			if(val.channel ~= "") then -- skip unconfigured tubes
				tmp_db[hash(val)] = val
			end
		end
		tp_tube_db = tmp_db
	end
	save_tube_db()
end

local function read_tube_db()
	local file = not storage:contains("version") and io.open(filename, "r")
	if not file then
		tp_tube_db = {}

		for key, val in pairs(storage:to_table().fields) do
			if tonumber(key) then
				tp_tube_db[key] = deserialize_tube_db_entry(key, val)
			elseif key == "version" then
				tp_tube_db.version = tonumber(val)
			else
				error("Unknown field in teleport tube DB: " .. key)
			end
		end

		if tp_tube_db.version == nil then
			tp_tube_db.version = tp_tube_db_version
			storage:set_string("version", tp_tube_db.version)
		elseif tp_tube_db.version > tp_tube_db_version then
			error("Cannot read teleport tube DB of version " .. tp_tube_db.version)
		end
	else
		local file_content = file:read("*all")
		io.close(file)

		pipeworks.logger("Moving teleport tube DB into mod storage from " .. filename)

		if file_content and file_content ~= "" then
			tp_tube_db = minetest.deserialize(file_content)
		else
			tp_tube_db = {version = 2.0}
		end
	end

	if(not tp_tube_db.version or tonumber(tp_tube_db.version) < tp_tube_db_version) then
		migrate_tube_db()
	end
	tp_tube_db.version = nil

	return tp_tube_db
end

-- debug formatter for coordinates used below
local fmt = function(pos)
	return pos.x..", "..pos.y..", "..pos.z
end

-- updates or adds a tube
local function set_tube(pos, channel, can_receive)
	local tubes = tp_tube_db or read_tube_db()
	local hash = hash(pos)
	local tube = tubes[hash]
	if tube then
		tube.channel = channel
		tube.cr = can_receive
		save_tube_db_entry(hash)
		return
	end

	-- we haven't found any tp tube to update, so lets add it
	-- but sanity check that the hash has not already been inserted.
	-- if so, complain very loudly and refuse the update so the player knows something is amiss.
	-- to catch regressions of https://github.com/minetest-mods/pipeworks/issues/166
	local existing = tp_tube_db[hash]
	if  existing ~= nil then
		local e = "error"
		minetest.log(e, "pipeworks teleport tube update refused due to position hash collision")
		minetest.log(e, "collided hash: "..hash)
		minetest.log(e, "tried-to-place tube: "..fmt(pos))
		minetest.log(e, "existing tube: "..fmt(existing))
		return
	end

	tp_tube_db[hash] = {x=pos.x,y=pos.y,z=pos.z,channel=channel,cr=can_receive}
	save_tube_db_entry(hash)
end

local function remove_tube(pos)
	local tubes = tp_tube_db or read_tube_db()
	local hash = hash(pos)
	tubes[hash] = nil
	save_tube_db_entry(hash)
end

local function read_node_with_vm(pos)
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	return minetest.get_name_from_content_id(data[area:index(pos.x, pos.y, pos.z)])
end

local function get_receivers(pos, channel)
	local hash = minetest.hash_node_position(pos)
	if cache[hash] then
		-- re-use cached result
		return cache[hash]
	end

	local tubes = tp_tube_db or read_tube_db()
	local receivers = {}
	for key, val in pairs(tubes) do
		-- skip all non-receivers and the tube that it came from as early as possible, as this is called often
		if (val.cr == 1 and val.channel == channel and (val.x ~= pos.x or val.y ~= pos.y or val.z ~= pos.z)) then
			local is_loaded = (minetest.get_node_or_nil(val) ~= nil)
			local node_name = is_loaded and minetest.get_node(pos).name or read_node_with_vm(val)

			if minetest.registered_nodes[node_name] and minetest.registered_nodes[node_name].is_teleport_tube then
				table.insert(receivers, val)
			else
				tp_tube_db[key] = nil
				save_tube_db_entry(key)
			end
		end
	end
	-- cache the result for next time
	cache[hash] = receivers
	return receivers
end

local function update_meta(meta, can_receive)
	meta:set_int("can_receive", can_receive and 1 or 0)
	local cr_state = can_receive and "on" or "off"
	local itext = S("Channels are public by default").."\n"..
		S("Use <player>:<channel> for fully private channels").."\n"..
		S("Use <player>\\;<channel> for private receivers")
	local size = "8.5,4"
	meta:set_string("formspec",
		"formspec_version[2]"..
		"size["..size.."]"..
		pipeworks.fs_helpers.get_prepends(size) ..
		"image[0.5,o;1,1;pipeworks_teleport_tube_inv.png]"..
		"label[1.5,0.5;"..S("Teleporting Tube").."]"..
		"field[0.5,1.6;4.3,0.75;channel;"..S("Channel")..";${channel}]"..
		"button[4.8,1.6;1.5,0.75;set_channel;"..S("Set").."]"..
		"label[7.0,0.5;"..S("Receive").."]"..
		"image_button[7.0,0.75;1,0.6;pipeworks_button_" .. cr_state .. ".png;cr" .. (can_receive and 0 or 1) .. ";;;false;pipeworks_button_interm.png]"..
		"button_exit[6.3,1.6;2,0.75;close;"..S("Close").."]"..
		"label[0.5,2.7;"..itext.."]")
end

pipeworks.register_tube("pipeworks:teleport_tube", {
	description = S("Teleporting Pneumatic Tube Segment"),
	inventory_image = "pipeworks_teleport_tube_inv.png",
	noctr = { "pipeworks_teleport_tube_noctr.png" },
	plain = { "pipeworks_teleport_tube_plain.png" },
	ends = { "pipeworks_teleport_tube_end.png" },
	short = "pipeworks_teleport_tube_short.png",
	node_def = {
		is_teleport_tube = true,
		tube = {
			can_go = function(pos,node,velocity,stack)
				velocity.x = 0
				velocity.y = 0
				velocity.z = 0

				local channel = minetest.get_meta(pos):get_string("channel")
				if channel == "" then return {} end

				local target = get_receivers(pos, channel)
				if target[1] == nil then return {} end

				local d = math.random(1,#target)
				pos.x = target[d].x
				pos.y = target[d].y
				pos.z = target[d].z
				return pipeworks.meseadjlist
			end,
			on_repair = function(pos, node)
				local meta = minetest.get_meta(pos)
				local channel = meta:get_string("channel")
				minetest.swap_node(pos, { name = node.name, param2 = node.param2 })
				pipeworks.scan_for_tube_objects(pos)
				if channel ~= "" then
					local can_receive = meta:get_int("can_receive")
					set_tube(pos, channel, can_receive)
					local cr_description = (can_receive == 1) and "sending and receiving" or "sending"
					meta:set_string("infotext", S("Teleportation Tube @1 on '@2'", cr_description, channel))
				end
			end
		},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			update_meta(meta, true)
			meta:set_string("infotext", S("Unconfigured Teleportation Tube"))
		end,
		on_receive_fields = function(pos,formname,fields,sender)
			if not fields.channel -- ignore escaping or clientside manipulation of the form
			or (fields.quit and not fields.key_enter_field)
			or not pipeworks.may_configure(pos, sender) then
				return
			end
			local new_channel = tostring(fields.channel):trim()

			local meta = minetest.get_meta(pos)
			local can_receive = meta:get_int("can_receive")

			-- check for private channels each time before actually changing anything
			-- to not even allow switching between can_receive states of private channels
			if new_channel ~= "" then
				local sender_name = sender:get_player_name()
				local name, mode = new_channel:match("^([^:;]+)([:;])")
				if name and mode and name ~= sender_name then
					--channels starting with '[name]:' can only be used by the named player
					if mode == ":" then
						minetest.chat_send_player(sender_name, S("Sorry, channel '@1' is reserved for exclusive use by @2",
							new_channel, name))
						return

					--channels starting with '[name];' can be used by other players, but cannot be received from
					elseif mode == ";" and (fields.cr1 or (can_receive ~= 0 and not fields.cr0)) then
						minetest.chat_send_player(sender_name, S("Sorry, receiving from channel '@1' is reserved for @2",
							new_channel, name))
						return
					end
				end
			end

			local dirty = false

			-- was the channel changed?
			local channel = meta:get_string("channel")
			if new_channel ~= channel and (fields.key_enter_field == "channel" or fields.set_channel) then
				channel = new_channel
				meta:set_string("channel", channel)
				dirty = true
			end

			-- test if a can_receive button was pressed
			if fields.cr0 and can_receive ~= 0 then
				can_receive = 0
				update_meta(meta, false)
				dirty = true
			elseif fields.cr1 and can_receive ~= 1 then
				can_receive = 1
				update_meta(meta, true)
				dirty = true
			end

			-- save if we changed something, handle the empty channel while we're at it
			if dirty then
				if channel ~= "" then
					set_tube(pos, channel, can_receive)
					local cr_description = (can_receive == 1) and "sending and receiving" or "sending"
					meta:set_string("infotext", S("Teleportation Tube @1 on '@2'", cr_description, channel))
				else
					-- remove empty channel tubes, to not have to search through them
					remove_tube(pos)
					meta:set_string("infotext", S("Unconfigured Teleportation Tube"))
				end
			end
		end,
		on_destruct = function(pos)
			remove_tube(pos)
		end
	},
})

if minetest.get_modpath("mesecons_mvps") ~= nil then
	mesecon.register_on_mvps_move(function(moved_nodes)
		for _, n in ipairs(moved_nodes) do
			if string.find(n.node.name, "pipeworks:teleport_tube") ~= nil then
				local meta = minetest.get_meta(n.pos)
				set_tube(n.pos, meta:get_string("channel"), meta:get_int("can_receive"))
			end
		end
	end)
end

-- Expose teleport tube database API for other mods
pipeworks.tptube = {
	hash = hash,
	save_tube_db = save_tube_db,
	save_tube_db_entry = save_tube_db_entry,
	get_db = function() return tp_tube_db or read_tube_db() end,
	set_tube = set_tube,
	update_meta = update_meta,
	tp_tube_db_version = tp_tube_db_version
}
