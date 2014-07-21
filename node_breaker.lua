
--register aliases for when someone had technic installed, but then uninstalled it but not pipeworks
minetest.register_alias("technic:nodebreaker_off", "pipeworks:nodebreaker_off")
minetest.register_alias("technic:nodebreaker_on", "pipeworks:nodebreaker_on")
minetest.register_alias("technic:node_breaker_off", "pipeworks:nodebreaker_off") --old name
minetest.register_alias("technic:node_breaker_on", "pipeworks:nodebreaker_on") --old name

minetest.register_craft({
	output = 'pipeworks:nodebreaker_off 1',
	recipe = {
		{'group:wood', 'default:pick_mese','group:wood'},
		{'default:stone', 'mesecons:piston','default:stone'},
		{'default:stone', 'mesecons:mesecon','default:stone'},
	}
})

local function swap_node(pos, name)
    local node = minetest.get_node(pos)
    if node.name == name then
        return
    end
    node.name = name
    minetest.swap_node(pos, node)
end

--define the functions from https://github.com/minetest/minetest/pull/834 while waiting for the devs to notice it
local function dir_to_facedir(dir, is6d)
	--account for y if requested
	if is6d and math.abs(dir.y) > math.abs(dir.x) and math.abs(dir.y) > math.abs(dir.z) then
		
		--from above
		if dir.y < 0 then
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 19
				else
					return 13
				end
			else
				if dir.z < 0 then
					return 10
				else
					return 4
				end
			end
		
		--from below
		else
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 15
				else
					return 17
				end
			else
				if dir.z < 0 then
					return 6
				else
					return 8
				end
			end
		end
	
	--otherwise, place horizontally
	elseif math.abs(dir.x) > math.abs(dir.z) then
		if dir.x < 0 then
			return 3
		else
			return 1
		end
	else
		if dir.z < 0 then
			return 2
		else
			return 0
		end
	end
end

local function delay(x)
	return (function() return x end)
end

local function break_node (pos, facedir)
	--locate the outgoing velocity, front, and back of the node via facedir_to_dir
	if type(facedir) ~= "number" or facedir < 0 or facedir > 23 then return end

	local vel = minetest.facedir_to_dir(facedir)
	local front = {x=pos.x - vel.x, y=pos.y - vel.y, z=pos.z - vel.z}
	
	local node = minetest.get_node(front)
	--if node.name == "air" or node.name == "ignore" then
	--	return nil
	--elseif minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].liquidtype ~= "none" then
	--	return nil
	--end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	
	if inv:get_size("ghost_pick") ~= 1 then -- Legacy code
		inv:set_size("ghost_pick", 1)
		inv:set_size("main", 100)
	end

	local pick_inv = "pick"
	local pick = inv:get_stack("pick", 1)
	if pick:is_empty() then
		pick = ItemStack("default:pick_mese")
		inv:set_stack("ghost_pick", 1, pick)
		pick_inv = "ghost_pick"
	end
	local pitch
	local yaw
	if vel.z < 0 then
		yaw = 0
		pitch = 0
	elseif vel.z > 0 then
		yaw = math.pi
		pitch = 0
	elseif vel.x < 0 then
		yaw = 3*math.pi/2
		pitch = 0
	elseif vel.x > 0 then
		yaw = math.pi/2
		pitch = 0
	elseif vel.y > 0 then
		yaw = 0
		pitch = -math.pi/2
	else
		yaw = 0
		pitch = math.pi/2
	end
	local digger = {
		get_inventory_formspec = delay(""),
		get_look_dir = delay({x = -vel.x, y = -vel.y, z = -vel.z}),
		get_look_pitch = delay(pitch),
		get_look_yaw = delay(yaw),
		get_player_control = delay({jump=false, right=false, left=false, LMB=false, RMB=false, sneak=false, aux1=false, down=false, up=false}),
		get_player_control_bits = delay(0),
		get_player_name = delay(meta:get_string("owner")),
		is_player = delay(true),
		is_fake_player = true,
		set_inventory_formspec = delay(),
		getpos = delay({x = pos.x, y = pos.y - 1.5, z = pos.z}), -- Player height
		get_hp = delay(20),
		get_inventory = delay(inv),
		get_wielded_item = delay(pick),
		get_wield_index = delay(1),
		get_wield_list = delay(pick_inv),
		moveto = delay(),
		punch = delay(),
		remove = delay(),
		right_click = delay(),
		setpos = delay(),
		set_hp = delay(),
		set_properties = delay(),
		set_wielded_item = function(self, stack)
			if stack:get_name() == pick:get_name() then
				inv:set_stack(pick_inv, 1, stack)
			else
				inv:add_item("main", stack)
				inv:set_stack(pick_inv, 1, ItemStack(""))
			end
		end,
		set_animation = delay(),
		set_attach = delay(),
		set_detach = delay(),
		set_bone_position = delay(),
	}
	
	local pickdef = minetest.registered_items[pick:get_name()]
	local pickcopy = ItemStack(pick)
	if pick_inv == "pick" and pickdef and pickdef.on_use then
		local pos_under, pos_above = {x = pos.x - vel.x, y = pos.y - vel.y, z = pos.z - vel.z}, {x = pos.x - 2*vel.x, y = pos.y - 2*vel.y, z = pos.z - 2*vel.z}
		local pointed_thing = {type="node", under=pos_under, above=pos_above}
		inv:set_stack(pick_inv, 1, pickdef.on_use(pick, digger, pointed_thing) or pick)
	else
		minetest.node_dig(front, node, digger)
	end
	
	
	local newpick = inv:get_stack(pick_inv, 1)
	if newpick:get_name() == pickcopy:get_name() and newpick:get_count() == pickcopy:get_count() and newpick:get_metadata() == pickcopy:get_metadata() and pickdef and (not pickdef.wear_represents or pickdef.wear_represents == "mechanical_wear") then
		inv:set_stack(pick_inv, 1, pickcopy) -- Do not wear pick out
	end

	for i = 1, 100 do
		local dropped_item = inv:get_stack("main", i)
		if not dropped_item:is_empty() then
			local item1 = pipeworks.tube_item({x=pos.x, y=pos.y, z=pos.z}, dropped_item)
			item1:get_luaentity().start_pos = {x=pos.x, y=pos.y, z=pos.z}
			item1:setvelocity(vel)
			item1:setacceleration({x=0, y=0, z=0})
			inv:set_stack("main", i, ItemStack(""))
		end
	end
end

local node_breaker_on = function(pos, node)
	if node.name == "pipeworks:nodebreaker_off" then
		swap_node(pos, "pipeworks:nodebreaker_on")
		break_node(pos, node.param2)
		nodeupdate(pos)
	end
end

local node_breaker_off = function(pos, node)
	if node.name == "pipeworks:nodebreaker_on" then
		swap_node(pos, "pipeworks:nodebreaker_off")
		nodeupdate(pos)
	end
end

minetest.register_node("pipeworks:nodebreaker_off", {
	description = "Node Breaker",
	tile_images = {"pipeworks_nodebreaker_top_off.png","pipeworks_nodebreaker_bottom_off.png","pipeworks_nodebreaker_side2_off.png","pipeworks_nodebreaker_side1_off.png",
			"pipeworks_nodebreaker_back.png","pipeworks_nodebreaker_front_off.png"},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1, tubedevice_receiver=1},
	mesecons= {effector={rules=pipeworks.rules_all,action_on=node_breaker_on, action_off=node_breaker_off}},
	sounds = default.node_sound_stone_defaults(),
	tube = {connect_sides = {left = 1, right = 1, back = 1, top = 1, bottom = 1},
		input_inventory = "pick",
		insert_object = function(pos, node, stack, direction)
			local vel = minetest.facedir_to_dir(node.param2)
			if math.abs(vel.x) == math.abs(direction.x) and math.abs(vel.y) == math.abs(direction.y) and math.abs(vel.z) == math.abs(direction.z) then
				return stack
			end
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("pick", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local vel = minetest.facedir_to_dir(node.param2)
			if math.abs(vel.x) == math.abs(direction.x) and math.abs(vel.y) == math.abs(direction.y) and math.abs(vel.z) == math.abs(direction.z) then
				return false
			end
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("pick", stack)
		end,
		can_remove = function(pos, node, stack, dir)
			return stack:get_count()
		end},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("pick", 1)
		inv:set_size("ghost_pick", 1)
		inv:set_size("main", 100)
		--inv:set_stack("pick", 1, ItemStack("default:pick_mese"))
		meta:set_string("formspec",
				"invsize[8,6;]"..
				"label[0,0;Node breaker]"..
				"list[current_name;pick;3.5,0;1,1;]"..
				"list[current_player;main;0,2;8,4;]")
		meta:set_string("infotext", "Node Breaker")
	end,
	after_place_node = function (pos, placer)
		pipeworks.scan_for_tube_objects(pos, placer)
		local placer_pos = placer:getpos()
		
		--correct for the player's height
		if placer:is_player() then placer_pos.y = placer_pos.y + 1.5 end
		
		--correct for 6d facedir
		if placer_pos then
			local dir = {
				x = pos.x - placer_pos.x,
				y = pos.y - placer_pos.y,
				z = pos.z - placer_pos.z
			}
			local node = minetest.get_node(pos)
			node.param2 = dir_to_facedir(dir, true)
			minetest.set_node(pos, node)
			minetest.log("action", "real (6d) facedir: " .. node.param2)
		end
		
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if oldmetadata.inventory.pick and oldmetadata.fields.formspec then
			local stack = oldmetadata.inventory.pick[1]
			if not stack:is_empty() then
				minetest.add_item(pos, stack)
			end
		end
		pipeworks.scan_for_tube_objects(pos, oldnode, oldmetadata, digger)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return stack:get_count()
	end
})

minetest.register_node("pipeworks:nodebreaker_on", {
	description = "Node Breaker",
	tile_images = {"pipeworks_nodebreaker_top_on.png","pipeworks_nodebreaker_bottom_on.png","pipeworks_nodebreaker_side2_on.png","pipeworks_nodebreaker_side1_on.png",
			"pipeworks_nodebreaker_back.png","pipeworks_nodebreaker_front_on.png"},
	mesecons= {effector={rules=pipeworks.rules_all,action_on=node_breaker_on, action_off=node_breaker_off}},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1,not_in_creative_inventory=1, tubedevice_receiver=1},
	sounds = default.node_sound_stone_defaults(),
	drop = "pipeworks:nodebreaker_off",
	tube = {connect_sides = {left = 1, right = 1, back = 1, top = 1, bottom = 1},
		input_inventory = "pick",
		insert_object = function(pos, node, stack, direction)
			local vel = minetest.facedir_to_dir(node.param2)
			if math.abs(vel.x) == math.abs(direction.x) and math.abs(vel.y) == math.abs(direction.y) and math.abs(vel.z) == math.abs(direction.z) then
				return stack
			end
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("pick", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local vel = minetest.facedir_to_dir(node.param2)
			if math.abs(vel.x) == math.abs(direction.x) and math.abs(vel.y) == math.abs(direction.y) and math.abs(vel.z) == math.abs(direction.z) then
				return false
			end
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("pick", stack)
		end,
		can_remove = function(pos, node, stack, dir)
			return stack:get_count()
		end},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("pick", 1)
		inv:set_size("ghost_pick", 1)
		inv:set_size("main", 100)
		meta:set_string("formspec",
				"invsize[8,6;]"..
				"label[0,0;Node breaker]"..
				"list[current_name;pick;3.5,0;1,1;]"..
				"list[current_player;main;0,2;8,4;]")
		--inv:set_stack("pick", 1, ItemStack("default:pick_mese"))
		meta:set_string("infotext", "Node Breaker")
	end,
	after_place_node = function (pos, placer)
		pipeworks.scan_for_tube_objects(pos, placer)
		local placer_pos = placer:getpos()
		
		--correct for the player's height
		if placer:is_player() then placer_pos.y = placer_pos.y + 1.5 end
		
		--correct for 6d facedir
		if placer_pos then
			local dir = {
				x = pos.x - placer_pos.x,
				y = pos.y - placer_pos.y,
				z = pos.z - placer_pos.z
			}
			local node = minetest.get_node(pos)
			node.param2 = dir_to_facedir(dir, true)
			minetest.set_node(pos, node)
			minetest.log("action", "real (6d) facedir: " .. node.param2)
		end
		
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if oldmetadata.inventory.pick and oldmetadata.fields.formspec then
			local stack = oldmetadata.inventory.pick[1]
			if not stack:is_empty() then
				minetest.add_item(pos, stack)
			end
		end
		pipeworks.scan_for_tube_objects(pos, oldnode, oldmetadata, digger)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if player:get_player_name() ~= meta:get_string("owner") and meta:get_string("owner") ~= "" then
			return 0
		end
		return stack:get_count()
	end
})
