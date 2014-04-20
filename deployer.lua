
--register aliases for when someone had technic installed, but then uninstalled it but not pipeworks
minetest.register_alias("technic:deployer_off", "pipeworks:deployer_off")
minetest.register_alias("technic:deployer_on", "pipeworks:deployer_on")

minetest.register_craft({
	output = 'pipeworks:deployer_off 1',
	recipe = {
		{'group:wood', 'default:chest','group:wood'},
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

local function delay(x)
	return (function() return x end)
end

local function deployer_on(pos, node)
	if node.name ~= "pipeworks:deployer_off" then
		return
	end
	
	--locate the above and under positions
	local dir = minetest.facedir_to_dir(node.param2)
	local pos_under, pos_above = {x = pos.x - dir.x, y = pos.y - dir.y, z = pos.z - dir.z}, {x = pos.x - 2*dir.x, y = pos.y - 2*dir.y, z = pos.z - 2*dir.z}
	
	swap_node(pos, "pipeworks:deployer_on")
	nodeupdate(pos)
	
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local invlist = inv:get_list("main")
	for i, stack in ipairs(invlist) do
		if stack:get_name() ~= nil and stack:get_name() ~= "" then--and minetest.get_node(pos_under).name == "air" then --obtain the first non-empty item slot
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
			local placer = {
				get_inventory_formspec = delay(meta:get_string("formspec")),
				get_look_dir = delay({x = -dir.x, y = -dir.y, z = -dir.z}),
				get_look_pitch = delay(pitch),
				get_look_yaw = delay(yaw),
				get_player_control = delay({jump=false, right=false, left=false, LMB=false, RMB=false, sneak=false, aux1=false, down=false, up=false}),
				get_player_control_bits = delay(0),
				get_player_name = delay(meta:get_string("owner")),
				is_player = delay(true),
				set_inventory_formspec = delay(),
				getpos = delay({x = pos.x, y = pos.y - 1.5, z = pos.z}), -- Player height
				get_hp = delay(20),
				get_inventory = delay(inv),
				get_wielded_item = delay(stack),
				get_wield_index = delay(i),
				get_wield_list = delay("main"),
				moveto = delay(),
				punch = delay(),
				remove = delay(),
				right_click = delay(),
				setpos = delay(),
				set_hp = delay(),
				set_properties = delay(),
				set_wielded_item = function(self, item) inv:set_stack("main", i, item) end,
				set_animation = delay(),
				set_attach = delay(),
				set_detach = delay(),
				set_bone_position = delay(),
			}
			local stack2 = minetest.item_place(stack, placer, {type="node", under=pos_under, above=pos_above})
			if minetest.setting_getbool("creative_mode") and not minetest.get_modpath("unified_inventory") then --infinite stacks ahoy!
				stack2:take_item()
			end
			invlist[i] = stack2
			inv:set_list("main", invlist)
			return
		end
	end
end

local deployer_off = function(pos, node)
	if node.name == "pipeworks:deployer_on" then
		swap_node(pos, "pipeworks:deployer_off")
		nodeupdate(pos)
	end
end

minetest.register_node("pipeworks:deployer_off", {
	description = "Deployer",
	tile_images = {"pipeworks_deployer_top.png","pipeworks_deployer_bottom.png","pipeworks_deployer_side2.png","pipeworks_deployer_side1.png",
			"pipeworks_deployer_back.png","pipeworks_deployer_front_off.png"},
	mesecons = {effector={rules=pipeworks.rules_all,action_on=deployer_on,action_off=deployer_off}},
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("main",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("main",stack)
		end,
		input_inventory="main",
		connect_sides={back=1}},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1, tubedevice_receiver=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,9;]"..
				"label[0,0;Deployer]"..
				"list[current_name;main;4,1;3,3;]"..
				"list[current_player;main;0,5;8,4;]")
		meta:set_string("infotext", "Deployer")
		local inv = meta:get_inventory()
		inv:set_size("main", 3*3)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
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
			node.param2 = minetest.dir_to_facedir(dir, true)
			minetest.set_node(pos, node)
			minetest.log("action", "real (6d) facedir: " .. node.param2)
		end
		
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end,
	after_dig_node = pipeworks.scan_for_tube_objects,
})

minetest.register_node("pipeworks:deployer_on", {
	description = "Deployer",
	tile_images = {"pipeworks_deployer_top.png","pipeworks_deployer_bottom.png","pipeworks_deployer_side2.png","pipeworks_deployer_side1.png",
			"pipeworks_deployer_back.png","pipeworks_deployer_front_on.png"},
	mesecons = {effector={rules=pipeworks.rules_all,action_on=deployer_on,action_off=deployer_off}},
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("main",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("main",stack)
		end,
		input_inventory="main",
		connect_sides={back=1}},
	is_ground_content = true,
	paramtype2 = "facedir",
	tubelike=1,
	drop = "pipeworks:deployer_off",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1, tubedevice_receiver=1,not_in_creative_inventory=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,9;]"..
				"label[0,0;Deployer]"..
				"list[current_name;main;4,1;3,3;]"..
				"list[current_player;main;0,5;8,4;]")
		meta:set_string("infotext", "Deployer")
		local inv = meta:get_inventory()
		inv:set_size("main", 3*3)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
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
			node.param2 = minetest.dir_to_facedir(dir, true)
			minetest.set_node(pos, node)
			minetest.log("action", "real (6d) facedir: " .. node.param2)
		end
		
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end,
	after_dig_node = pipeworks.scan_for_tube_objects,
})
