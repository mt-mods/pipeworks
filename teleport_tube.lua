local filename=minetest.get_worldpath() .. "/teleport_tubes"

local tp_tube_db = nil -- nil forces a read

local function read_tube_db()
	local file = io.open(filename, "r")
	if file ~= nil then
		local file_content = file:read("*all")
		io.close(file)

		if file_content and file_content ~= "" then
			tp_tube_db = minetest.deserialize(file_content)
			return tp_tube_db-- we read sucessfully
		end
	end
	tp_tube_db = {}
	return tp_tube_db
end

local function save_tube_db()
	local file, err = io.open(filename, "w")
	if file then
		file:write(minetest.serialize(tp_tube_db))
		io.close(file)
	else
		error(err)
	end
end

-- updates or adds a tube
local function set_tube(pos, channel, can_receive)
	local tubes = tp_tube_db or read_tube_db()
	for _, val in ipairs(tubes) do
		if val.x == pos.x and val.y == pos.y and val.z == pos.z then
			val.channel = channel
			val.cr = can_receive
			save_tube_db()
			return
		end
	end

	-- we haven't found any tp tube to update, so lets add it
	table.insert(tp_tube_db,{x=pos.x,y=pos.y,z=pos.z,channel=channel,cr=cr})
	save_tube_db()
end

local function remove_tube(pos)
	local tubes = tp_tube_db or read_tube_db()
	local newtbl = {}
	for _, val in ipairs(tubes) do
		if val.x ~= pos.x or val.y ~= pos.y or val.z ~= pos.z then
			table.insert(newtbl, val)
		end
	end
	tp_tube_db = newtbl
	save_tube_db()
end

local function read_node_with_vm(pos)
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	return minetest.get_name_from_content_id(data[area:index(pos.x, pos.y, pos.z)])
end

local function get_receivers(pos,channel)
	local tubes = tp_tube_db or read_tube_db()
	local receivers = {}
	local changed = false
	for _, val in ipairs(tubes) do
		-- skip all non-receivers and the tube that it came from as early as possible, as this is called often
		if (val.cr == 1 and val.channel == channel and (val.x ~= pos.x or val.y ~= pos.y or val.z ~= pos.z)) then
			local is_loaded = (minetest.get_node_or_nil(val) ~= nil)
			local node_name = is_loaded and minetest.get_node(pos).name or read_node_with_vm(val)

			if minetest.registered_nodes[node_name] and minetest.registered_nodes[node_name].is_teleport_tube then
				table.insert(receivers, val)
			else
				val.to_remove = true
				changed = true
			end
		end
	end
	if changed then
		local updated = {}
		for _, val in ipairs(tubes) do
			if not val.to_remove then
				table.insert(updated, val)
			end
		end
		tp_tube_db = updated
		save_tube_db()
	end
	return receivers
end

local teleport_noctr_textures={"pipeworks_teleport_tube_noctr.png","pipeworks_teleport_tube_noctr.png","pipeworks_teleport_tube_noctr.png",
		"pipeworks_teleport_tube_noctr.png","pipeworks_teleport_tube_noctr.png","pipeworks_teleport_tube_noctr.png"}
local teleport_plain_textures={"pipeworks_teleport_tube_plain.png","pipeworks_teleport_tube_plain.png","pipeworks_teleport_tube_plain.png",
		"pipeworks_teleport_tube_plain.png","pipeworks_teleport_tube_plain.png","pipeworks_teleport_tube_plain.png"}
local teleport_end_textures={"pipeworks_teleport_tube_end.png","pipeworks_teleport_tube_end.png","pipeworks_teleport_tube_end.png",
		"pipeworks_teleport_tube_end.png","pipeworks_teleport_tube_end.png","pipeworks_teleport_tube_end.png"}
local teleport_short_texture="pipeworks_teleport_tube_short.png"
local teleport_inv_texture="pipeworks_teleport_tube_inv.png"

local function set_teleport_tube_formspec(meta, can_receive)
	local cr = (can_receive ~= 0)
	meta:set_string("formspec","size[10.5,1;]"..
			"field[0,0.5;7,1;channel;Channel:;${channel}]"..
			"button[8,0;2.5,1;"..(cr and "cr0" or "cr1")..";"..
			(cr and "Send and Receive" or "Send only").."]")
end

pipeworks.register_tube("pipeworks:teleport_tube","Teleporting Pneumatic Tube Segment",teleport_plain_textures,
	teleport_noctr_textures,teleport_end_textures,teleport_short_texture,teleport_inv_texture, {
	is_teleport_tube = true,
	tube = {
		can_go = function(pos,node,velocity,stack)
			velocity.x = 0
			velocity.y = 0
			velocity.z = 0
			local meta = minetest.get_meta(pos)
			local channel = meta:get_string("channel")
			local target = get_receivers(pos, channel)
			if target[1] == nil then return {} end
			local d = math.random(1,#target)
			pos.x = target[d].x
			pos.y = target[d].y
			pos.z = target[d].z
			return pipeworks.meseadjlist
		end
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("channel","")
		meta:set_int("can_receive",1)
		set_tube(pos, "", 1)
		set_teleport_tube_formspec(meta, 1)
	end,
	on_receive_fields = function(pos,formname,fields,sender)
		local meta = minetest.get_meta(pos)
		local can_receive = meta:get_int("can_receive")

		if fields.channel then
			-- check for private channels
			local sender_name = sender:get_player_name()
			local name, mode = fields.channel:match("^([^:;]+)([:;])")
			if name and mode and name ~= sender_name then
				--channels starting with '[name]:' can only be used by the named player
				if mode == ":" then
					minetest.chat_send_player(sender_name, "Sorry, channel '"..fields.channel.."' is reserved for exclusive use by "..name)
					return
				
				--channels starting with '[name];' can be used by other players, but cannot be received from
				elseif mode == ";" and (fields.cr1 or (can_receive ~= 0 and not fields.cr0)) then
					minetest.chat_send_player(sender_name, "Sorry, receiving from channel '"..fields.channel.."' is reserved for "..name)
					return
				end
			end
			-- save channel if we set one
			meta:set_string("channel", fields.channel)
		end
		-- make sure we have a channel, either the newly set one or the one from metadata
		local channel = fields.channel or meta:get_string("channel")

		if fields.cr0 and can_receive ~= 0 then
			can_receive = 0
			meta:set_int("can_receive", can_receive)
		elseif fields.cr1 and can_receive ~= 1 then
			can_receive = 1
			meta:set_int("can_receive", can_receive)
		end

		set_tube(pos, fields.channel, can_receive)
		set_teleport_tube_formspec(meta, can_receive)
	end,
	on_destruct = function(pos)
		remove_tube(pos)
	end
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
