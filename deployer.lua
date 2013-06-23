if minetest.get_modpath("technic") then --technic installed
	--register aliases in order to use technic's deployers
	minetest.register_alias("pipeworks:deployer_off", "technic:deployer_off")
	minetest.register_alias("pipeworks:deployer_on", "technic:deployer_on")
	return
end

--register aliases for when someone had technic installed, but then uninstalled it but not pipeworks
minetest.register_alias("technic:deployer_off", "pipeworks:deployer_off")
minetest.register_alias("technic:deployer_on", "pipeworks:deployer_on")

minetest.register_craft({
	output = 'pipeworks:deployer_off 1',
	recipe = {
		{'default:wood', 'default:chest','default:wood'},
		{'default:stone', 'mesecons:piston','default:stone'},
		{'default:stone', 'mesecons:mesecon','default:stone'},
	}
})

function hacky_swap_node(pos,name)
	local node=minetest.env:get_node(pos)
	local meta=minetest.env:get_meta(pos)
	local meta0=meta:to_table()
	node.name=name
	minetest.env:add_node(pos, node)
	local meta=minetest.env:get_meta(pos)
	meta:from_table(meta0)
end

deployer_on = function(pos, node)
	if node.name ~= "pipeworks:deployer_off" then
		return
	end

	local pos1 = {x=pos.x, y=pos.y, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y, z=pos.z}
	if node.param2 == 3 then
		pos1.x, pos2.x = pos1.x + 1, pos2.x + 2
	elseif node.param2 == 2 then
		pos1.z, pos2.z = pos1.z + 1, pos2.z + 2
	elseif node.param2 == 1 then
		pos1.x, pos2.x = pos1.x - 1, pos2.x - 2
	elseif node.param2 == 0 then
		pos1.z, pos2.z = pos1.z - 1, pos2.z - 2
	end

	hacky_swap_node(pos,"pipeworks:deployer_on")
	nodeupdate(pos)
	
	local inv = minetest.env:get_meta(pos):get_inventory()
	local invlist = inv:get_list("main")
	for i, stack in ipairs(invlist) do
		if stack:get_name() ~= nil and stack:get_name() ~= "" and minetest.env:get_node(pos1).name == "air" then --obtain the first non-empty item slow
			local placer = {
				get_player_name = function() return "deployer" end,
				getpos = function() return pos end,
				get_player_control = function() return {jump=false,right=false,left=false,LMB=false,RMB=false,sneak=false,aux1=false,down=false,up=false} end,
			}
			local stack2 = minetest.item_place(stack, placer, {type="node", under=pos1, above=pos2})
			if minetest.setting_getbool("creative_mode") and not minetest.get_modpath("unified_inventory") then --infinite stacks ahoy!
				stack2:take_item()
			end
			invlist[i] = stack2
			inv:set_list("main", invlist)
			return
		end
	end
end

deployer_off = function(pos, node)
	if node.name == "pipeworks:deployer_on" then
		hacky_swap_node(pos,"pipeworks:deployer_off")
		nodeupdate(pos)
	end
end

minetest.register_node("pipeworks:deployer_off", {
	description = "Deployer",
	tile_images = {"pipeworks_deployer_top.png","pipeworks_deployer_bottom.png","pipeworks_deployer_side2.png","pipeworks_deployer_side1.png",
			"pipeworks_deployer_back.png","pipeworks_deployer_front_off.png"},
	mesecons = {effector={action_on=deployer_on,action_off=deployer_off}},
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("main",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("main",stack)
		end,
		input_inventory="main"},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1, tubedevice_receiver=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
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
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = tube_scanforobjects,
	after_dig_node = tube_scanforobjects,
})

minetest.register_node("pipeworks:deployer_on", {
	description = "Deployer",
	tile_images = {"pipeworks_deployer_top.png","pipeworks_deployer_bottom.png","pipeworks_deployer_side2.png","pipeworks_deployer_side1.png",
			"pipeworks_deployer_back.png","pipeworks_deployer_front_on.png"},
	mesecons = {effector={action_on=deployer_on,action_off=deployer_off}},
	tube={insert_object=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:add_item("main",stack)
		end,
		can_insert=function(pos,node,stack,direction)
			local meta=minetest.env:get_meta(pos)
			local inv=meta:get_inventory()
			return inv:room_for_item("main",stack)
		end,
		input_inventory="main"},
	is_ground_content = true,
	paramtype2 = "facedir",
	tubelike=1,
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1, tubedevice_receiver=1,not_in_creative_inventory=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
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
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = tube_scanforobjects,
	after_dig_node = tube_scanforobjects,
})
