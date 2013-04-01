minetest.register_craft({
	output = 'pipeworks:deployer_off 1',
	recipe = {
		{'default:wood', 'default:chest','default:wood'},
		{'default:stone', 'mesecons:piston','default:stone'},
		{'default:stone', 'mesecons:mesecon','default:stone'},

	}
})

deployer_on = function(pos, node)
	local pos1={}
	pos1.x=pos.x
	pos1.y=pos.y
	pos1.z=pos.z
	local pos2={}
	pos2.x=pos.x
	pos2.y=pos.y
	pos2.z=pos.z
	if node.param2==3 then
		pos1.x=pos1.x+1
		pos2.x=pos2.x+2
	end
	if node.param2==2 then
		pos1.z=pos1.z+1
		pos2.z=pos2.z+2
	end
	if node.param2==1 then
		pos1.x=pos1.x-1
		pos2.x=pos2.x-2
	end
	if node.param2==0 then
		pos1.z=pos1.z-1
		pos2.z=pos2.z-2
	end

	if node.name == "pipeworks:deployer_off" then
		hacky_swap_node(pos,"pipeworks:deployer_on")
		nodeupdate(pos)
			local meta = minetest.env:get_meta(pos);
		
		local inv = meta:get_inventory()
		local invlist=inv:get_list("main")
		for i,stack in ipairs(invlist) do

		if stack:get_name() ~=nil and stack:get_name() ~="" and minetest.env:get_node(pos1).name == "air" then
			local placer={}
			function placer:get_player_name() return "deployer" end
			function placer:getpos() return pos end
			function placer:get_player_control() return {jump=false,right=false,left=false,LMB=false,RMB=false,sneak=false,aux1=false,down=false,up=false} end
			local stack2=minetest.item_place(stack,placer,{type="node", under=pos1, above=pos2})
			invlist[i]=stack2
			inv:set_list("main",invlist)
			return
		end
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





