local S = minetest.get_translator("pipeworks")
local assumed_eye_pos = vector.new(0, 1.5, 0)

local function delay(x)
	return (function() return x end)
end

local function set_wielder_formspec(data, meta)
	local size = "10.2,"..(7+data.wield_inv_height)
	local list_background = ""
	if minetest.get_modpath("i3") then
		list_background = "style_type[box;colors=#666]"
		for i=0, data.wield_inv_height-1 do
			for j=0, data.wield_inv_width-1 do
				list_background = list_background .. "box[".. ((10-data.wield_inv_width)*0.5)+(i*1.25) ..",".. 1+(j*1.25) ..";1,1;]"
			end
		end
	end
	meta:set_string("formspec",
		"formspec_version[2]" ..
		"size["..size.."]"..
		pipeworks.fs_helpers.get_prepends(size)..
		"item_image[0.5,0.5;1,1;"..data.name_base.."_off]"..
		"label[1.5,1;"..minetest.formspec_escape(data.description).."]"..
		list_background ..
		"list[context;"..minetest.formspec_escape(data.wield_inv_name)..";"..((10-data.wield_inv_width)*0.5)..",1;"..data.wield_inv_width..","..data.wield_inv_height..";]"..
		pipeworks.fs_helpers.get_inv((2+data.wield_inv_height)) ..
		"listring[context;"..minetest.formspec_escape(data.wield_inv_name).."]" ..
		"listring[current_player;main]"
	)
	meta:set_string("infotext", data.description)
end

local can_tool_dig_node = function(nodename, toolcaps, toolname)
	--pipeworks.logger("can_tool_dig_node() STUB nodename="..tostring(nodename).." toolname="..tostring(toolname).." toolcaps: "..dump(toolcaps))
	-- brief documentation of minetest.get_dig_params() as it's not yet documented in lua_api.txt:
	-- takes two arguments, a node's block groups and a tool's capabilities,
	-- both as they appear in their respective definitions.
	-- returns a table with the following fields:
	-- diggable: boolean, can this tool dig this node at all
	-- time: float, time needed to dig with this tool
	-- wear: int, number of wear points to inflict on the item
	local nodedef = minetest.registered_nodes[nodename]
	-- don't explode due to nil def in event of unknown node!
	if (nodedef == nil) then return false end

	local nodegroups = nodedef.groups
	local diggable = minetest.get_dig_params(nodegroups, toolcaps).diggable
	if not diggable then
		-- a pickaxe can't actually dig leaves based on it's groups alone,
		-- but a player holding one can - the game seems to fall back to the hand.
		-- fall back to checking the hand's properties if the tool isn't the correct one.
		local hand_caps = minetest.registered_items[""].tool_capabilities
		diggable = minetest.get_dig_params(nodegroups, hand_caps).diggable
	end
	return diggable
end

local function wielder_on(data, wielder_pos, wielder_node)
	data.fixup_node(wielder_pos, wielder_node)
	if wielder_node.name ~= data.name_base.."_off" then return end
	wielder_node.name = data.name_base.."_on"
	minetest.swap_node(wielder_pos, wielder_node)
	minetest.check_for_falling(wielder_pos)
	local wielder_meta = minetest.get_meta(wielder_pos)
	local inv = wielder_meta:get_inventory()
	local wield_inv_name = data.wield_inv_name
	local wieldindex
	for i, stack in ipairs(inv:get_list(wield_inv_name)) do
		if not stack:is_empty() then
			wieldindex = i
			break
		end
	end
	if not wieldindex then
		if not data.ghost_inv_name then return end
		wield_inv_name = data.ghost_inv_name
		inv:set_stack(wield_inv_name, 1, ItemStack(data.ghost_tool))
		wieldindex = 1
	end
	local dir = minetest.facedir_to_dir(wielder_node.param2)
	-- under/above is currently intentionally left switched
	-- even though this causes some problems with deployers and e.g. seeds
	-- as there are some issues related to nodebreakers otherwise breaking 2 nodes afar.
	-- solidity would have to be checked as well,
	-- but would open a whole can of worms related to difference in nodebreaker/deployer behavior
	-- and the problems of wielders acting on themselves if below is solid
	local under_pos = vector.subtract(wielder_pos, dir)
	local above_pos = vector.subtract(under_pos, dir)
	local pitch
	local yaw
	if dir.z < 0 then
		yaw = 0
		pitch = 0
	elseif dir.z > 0 then
		yaw = math.pi
		pitch = 0
	elseif dir.x < 0 then
		yaw = 3*math.pi/2
		pitch = 0
	elseif dir.x > 0 then
		yaw = math.pi/2
		pitch = 0
	elseif dir.y > 0 then
		yaw = 0
		pitch = -math.pi/2
	else
		yaw = 0
		pitch = math.pi/2
	end
	local virtplayer = pipeworks.create_fake_player({
		name = data.masquerade_as_owner and wielder_meta:get_string("owner")
			or ":pipeworks:" .. minetest.pos_to_string(wielder_pos),
		formspec = wielder_meta:get_string("formspec"),
		look_dir = vector.multiply(dir, -1),
		look_pitch = pitch,
		look_yaw = yaw,
		sneak = data.sneak,
		position = vector.subtract(wielder_pos, assumed_eye_pos),
		inventory = inv,
		wield_index = wieldindex,
		wield_list = wield_inv_name
	})

	local pointed_thing = { type="node", under=under_pos, above=above_pos }
	data.act(virtplayer, pointed_thing)
	if data.eject_drops then
		for i, stack in ipairs(inv:get_list("main")) do
			if not stack:is_empty() then
				pipeworks.tube_inject_item(wielder_pos, wielder_pos, dir, stack)
				inv:set_stack("main", i, ItemStack(""))
			end
		end
	end
end

local function wielder_off(data, pos, node)
	if node.name == data.name_base.."_on" then
		node.name = data.name_base.."_off"
		minetest.swap_node(pos, node)
		minetest.check_for_falling(pos)
	end
end

local function register_wielder(data)
	data.fixup_node = data.fixup_node or function (pos, node) end
	data.fixup_oldmetadata = data.fixup_oldmetadata or function (m) return m end
	for _, state in ipairs({ "off", "on" }) do
		local groups = { snappy=2, choppy=2, oddly_breakable_by_hand=2, mesecon=2, tubedevice=1, tubedevice_receiver=1 }
		if state == "on" then groups.not_in_creative_inventory = 1 end
		local tile_images = {}
		for _, face in ipairs({ "top", "bottom", "side2", "side1", "back", "front" }) do
			table.insert(tile_images, data.texture_base.."_"..face..(data.texture_stateful[face] and "_"..state or "")..".png")
		end
		minetest.register_node(data.name_base.."_"..state, {
			description = data.description,
			tiles = tile_images,
			mesecons = {
				effector = {
					rules = pipeworks.rules_all,
					action_on = function (pos, node)
						wielder_on(data, pos, node)
					end,
					action_off = function (pos, node)
						wielder_off(data, pos, node)
					end,
				},
			},
			tube = {
				can_insert = function(pos, node, stack, tubedir)
					if not data.tube_permit_anteroposterior_insert then
						local nodedir = minetest.facedir_to_dir(node.param2)
						if vector.equals(tubedir, nodedir) or vector.equals(tubedir, vector.multiply(nodedir, -1)) then
							return false
						end
					end
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:room_for_item(data.wield_inv_name, stack)
				end,
				insert_object = function(pos, node, stack, tubedir)
					if not data.tube_permit_anteroposterior_insert then
						local nodedir = minetest.facedir_to_dir(node.param2)
						if vector.equals(tubedir, nodedir) or vector.equals(tubedir, vector.multiply(nodedir, -1)) then
							return stack
						end
					end
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:add_item(data.wield_inv_name, stack)
				end,
				input_inventory = data.wield_inv_name,
				connect_sides = data.tube_connect_sides,
				can_remove = function(pos, node, stack, tubedir)
					return stack:get_count()
				end,
			},
			is_ground_content = true,
			paramtype2 = "facedir",
			tubelike = 1,
			groups = groups,
			_sound_def = {
				key = "node_sound_stone_defaults",
			},
			drop = data.name_base.."_off",
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)
				set_wielder_formspec(data, meta)
				local inv = meta:get_inventory()
				inv:set_size(data.wield_inv_name, data.wield_inv_width*data.wield_inv_height)
				if data.ghost_inv_name then
					inv:set_size(data.ghost_inv_name, 1)
				end
				if data.eject_drops then
					inv:set_size("main", 100)
				end
			end,
			after_place_node = function (pos, placer)
				pipeworks.scan_for_tube_objects(pos)
				local placer_pos = placer:get_pos()
				if placer_pos and placer:is_player() then placer_pos = vector.add(placer_pos, assumed_eye_pos) end
				if placer_pos then
					local dir = vector.subtract(pos, placer_pos)
					local node = minetest.get_node(pos)
					node.param2 = minetest.dir_to_facedir(dir, true)
					minetest.set_node(pos, node)
					minetest.log("action", "real (6d) facedir: " .. node.param2)
				end
				minetest.get_meta(pos):set_string("owner", placer:get_player_name())
			end,
			can_dig = (data.can_dig_nonempty_wield_inv and delay(true) or function(pos, player)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:is_empty(data.wield_inv_name)
			end),
			after_dig_node = function(pos, oldnode, oldmetadata, digger)
				-- The legacy-node fixup is done here in a
				-- different form from the standard fixup,
				-- rather than relying on a standard fixup
				-- in an on_dig callback, because some
				-- non-standard diggers (such as technic's
				-- mining drill) don't respect on_dig.
				oldmetadata = data.fixup_oldmetadata(oldmetadata)
				for _, stack in ipairs(oldmetadata.inventory[data.wield_inv_name] or {}) do
					if not stack:is_empty() then
						minetest.add_item(pos, stack)
					end
				end
				pipeworks.scan_for_tube_objects(pos)
			end,
			on_rotate = pipeworks.on_rotate,
			on_punch = data.fixup_node,
			allow_metadata_inventory_put = function(pos, listname, index, stack, player)
				if not pipeworks.may_configure(pos, player) then return 0 end
				return stack:get_count()
			end,
			allow_metadata_inventory_take = function(pos, listname, index, stack, player)
				if not pipeworks.may_configure(pos, player) then return 0 end
				return stack:get_count()
			end,
			allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
				if not pipeworks.may_configure(pos, player) then return 0 end
				return count
			end
		})
	end
end

if pipeworks.enable_node_breaker then
	local data
	-- see after end of data table for other use of these variables
	local name_base = "pipeworks:nodebreaker"
	local wield_inv_name = "pick"
	data = {
		name_base = name_base,
		description = S("Node Breaker"),
		texture_base = "pipeworks_nodebreaker",
		texture_stateful = { top = true, bottom = true, side2 = true, side1 = true, front = true },
		tube_connect_sides = { top=1, bottom=1, left=1, right=1, back=1 },
		tube_permit_anteroposterior_insert = false,
		wield_inv_name = wield_inv_name,
		wield_inv_width = 1,
		wield_inv_height = 1,
		can_dig_nonempty_wield_inv = true,
		ghost_inv_name = "ghost_pick",
		ghost_tool = ":",	-- hand by default
		fixup_node = function (pos, node)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			-- Node breakers predating the visible pick slot
			-- may have been partially updated.  This code
			-- fully updates them.	Some have been observed
			-- to have no pick slot at all; first add one.
			if inv:get_size("pick") ~= 1 then
				inv:set_size("pick", 1)
			end
			-- Originally, they had a ghost pick in a "pick"
			-- inventory, no other inventory, and no form.
			-- The partial update of early with-form node
			-- breaker code gives them "ghost_pick" and "main"
			-- inventories, but leaves the old ghost pick in
			-- the "pick" inventory, and doesn't add a form.
			-- First perform that partial update.
			if inv:get_size("ghost_pick") ~= 1 then
				inv:set_size("ghost_pick", 1)
				inv:set_size("main", 100)
			end
			-- If the node breaker predates the visible pick
			-- slot, which we can detect by it not having a
			-- form, then the pick slot needs to be cleared
			-- of the old ghost pick.
			if (meta:get_string("formspec") or "") == "" then
				inv:set_stack("pick", 1, ItemStack(""))
			end
			-- Finally, unconditionally set the formspec
			-- and infotext.  This not only makes the
			-- pick slot visible for node breakers where
			-- it wasn't before; it also updates the form
			-- for node breakers that had an older version
			-- of the form, and sets infotext where it was
			-- missing for early with-form node breakers.
			set_wielder_formspec(data, meta)
		end,
		fixup_oldmetadata = function (oldmetadata)
			-- Node breakers predating the visible pick slot,
			-- with node form, kept their ghost pick in an
			-- inventory named "pick", the same name as the
			-- later visible pick slot.  The pick must be
			-- removed to avoid spilling it.
			if not oldmetadata.fields.formspec then
				return { inventory = { pick = {} }, fields = oldmetadata.fields }
			else
				return oldmetadata
			end
		end,
		masquerade_as_owner = true,
		sneak = false,
		act = function(virtplayer, pointed_thing)
			if minetest.is_protected(vector.add(virtplayer:get_pos(), assumed_eye_pos), virtplayer:get_player_name()) then
				return
			end

			--local dname = "nodebreaker.act() "
			local wieldstack = virtplayer:get_wielded_item()
			local oldwieldstack = ItemStack(wieldstack)
			local on_use = (minetest.registered_items[wieldstack:get_name()] or {}).on_use
			if on_use then
				--pipeworks.logger(dname.."invoking on_use "..tostring(on_use))
				wieldstack = on_use(wieldstack, virtplayer, pointed_thing) or wieldstack
				virtplayer:set_wielded_item(wieldstack)
			else
				local under_node = minetest.get_node(pointed_thing.under)
				local def = minetest.registered_nodes[under_node.name]
				if not def then
					-- do not dig an unknown node
					return
				end
				-- check that the current tool is capable of destroying the
				-- target node.
				-- if we can't, don't dig, and leave the wield stack unchanged.
				-- note that wieldstack:get_tool_capabilities() returns hand
				-- properties if the item has none of it's own.
				if can_tool_dig_node(under_node.name,
						wieldstack:get_tool_capabilities(),
						wieldstack:get_name()) then
					def.on_dig(pointed_thing.under, under_node, virtplayer)
					local sound = def.sounds and def.sounds.dug
					if sound then
						minetest.sound_play(sound.name,
							{pos=pointed_thing.under, gain=sound.gain})
					end
					wieldstack = virtplayer:get_wielded_item()
				--~ else
					--pipeworks.logger(dname.."couldn't dig node!")
				end
			end
			local wieldname = wieldstack:get_name()
			if wieldname == oldwieldstack:get_name() then
				-- don't mechanically wear out tool
				if wieldstack:get_count() == oldwieldstack:get_count() and
						wieldstack:get_metadata() == oldwieldstack:get_metadata() and
						((minetest.registered_items[wieldstack:get_name()] or {}).wear_represents or "mechanical_wear") == "mechanical_wear" then
					virtplayer:set_wielded_item(oldwieldstack)
				end
			elseif wieldname ~= "" then
				-- tool got replaced by something else:
				-- treat it as a drop
				virtplayer:get_inventory():add_item("main", wieldstack)
				virtplayer:set_wielded_item(ItemStack(""))
			end
		end,
		eject_drops = true,
	}
	register_wielder(data)
	pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = "pipeworks:nodebreaker_off"
	-- aliases for when someone had technic installed, but then uninstalled it but not pipeworks
	minetest.register_alias("technic:nodebreaker_off", "pipeworks:nodebreaker_off")
	minetest.register_alias("technic:nodebreaker_on", "pipeworks:nodebreaker_on")
	minetest.register_alias("technic:node_breaker_off", "pipeworks:nodebreaker_off")
	minetest.register_alias("technic:node_breaker_on", "pipeworks:nodebreaker_on")
	-- turn legacy auto-tree-taps into node breakers
	dofile(pipeworks.modpath.."/legacy.lua")

	-- register LBM for transition to cheaper node breakers
	local lbm_id = "pipeworks:refund_node_breaker_pick"
	minetest.register_lbm({
		name = lbm_id,
		label = "Give back mese pick for pre-transition node breakers",
		run_at_every_load = false,
		nodenames = { name_base.."_on", name_base.."_off" },
		action = function(pos, node)
			pipeworks.logger(lbm_id.." entry, nodename="..node.name)
			local invref = minetest.get_meta(pos):get_inventory()
			invref:add_item(wield_inv_name, ItemStack("default:pick_mese"))
		end
	})
end

if pipeworks.enable_deployer then
	register_wielder({
		name_base = "pipeworks:deployer",
		description = S("Deployer"),
		texture_base = "pipeworks_deployer",
		texture_stateful = { front = true },
		tube_connect_sides = { back=1 },
		tube_permit_anteroposterior_insert = true,
		wield_inv_name = "main",
		wield_inv_width = 3,
		wield_inv_height = 3,
		can_dig_nonempty_wield_inv = false,
		masquerade_as_owner = true,
		sneak = false,
		act = function(virtplayer, pointed_thing)
			if minetest.is_protected(vector.add(virtplayer:get_pos(), assumed_eye_pos), virtplayer:get_player_name()) then
				return
			end

			local wieldstack = virtplayer:get_wielded_item()
			virtplayer:set_wielded_item((minetest.registered_items[wieldstack:get_name()] or {on_place=minetest.item_place}).on_place(wieldstack, virtplayer, pointed_thing) or wieldstack)
		end,
		eject_drops = false,
	})
	pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = "pipeworks:deployer_off"
	-- aliases for when someone had technic installed, but then uninstalled it but not pipeworks
	minetest.register_alias("technic:deployer_off", "pipeworks:deployer_off")
	minetest.register_alias("technic:deployer_on", "pipeworks:deployer_on")
end

if pipeworks.enable_dispenser then
	register_wielder({
		name_base = "pipeworks:dispenser",
		description = S("Dispenser"),
		texture_base = "pipeworks_dispenser",
		texture_stateful = { front = true },
		tube_connect_sides = { back=1 },
		tube_permit_anteroposterior_insert = true,
		wield_inv_name = "main",
		wield_inv_width = 3,
		wield_inv_height = 3,
		can_dig_nonempty_wield_inv = false,
		masquerade_as_owner = false,
		sneak = true,
		act = function(virtplayer, pointed_thing)
			local wieldstack = virtplayer:get_wielded_item()
			virtplayer:set_wielded_item((minetest.registered_items[wieldstack:get_name()] or
				{on_drop=minetest.item_drop}).on_drop(wieldstack, virtplayer, virtplayer:get_pos()) or
				wieldstack)
		end,
		eject_drops = false,
	})
	pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = "pipeworks:dispenser_off"
end
