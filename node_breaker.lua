if minetest.get_modpath("technic") then --technic installed
	--register aliases in order to use technic's node breakers
	minetest.register_alias("pipeworks:nodebreaker_off", "technic:nodebreaker_off")
	minetest.register_alias("pipeworks:nodebreaker_on", "technic:nodebreaker_on")
	return
end

--register aliases for when someone had technic installed, but then uninstalled it but not pipeworks
minetest.register_alias("technic:nodebreaker_off", "pipeworks:nodebreaker_off")
minetest.register_alias("technic:nodebreaker_on", "pipeworks:nodebreaker_on")

minetest.register_craft({
	output = 'pipeworks:nodebreaker_off 1',
	recipe = {
		{'default:wood', 'default:pick_mese','default:wood'},
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

node_breaker_on = function(pos, node)
	if node.name == "pipeworks:nodebreaker_off" then
		hacky_swap_node(pos,"pipeworks:nodebreaker_on")
		break_node(pos,node.param2)
		nodeupdate(pos)
	end
end

node_breaker_off = function(pos, node)
	if node.name == "pipeworks:nodebreaker_on" then
		hacky_swap_node(pos,"pipeworks:nodebreaker_off")
		nodeupdate(pos)
	end
end

function break_node (pos, n_param)
	local pos1 = {x=pos.x, y=pos.y, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y, z=pos.z}

	--param2 3=x+ 1=x- 2=z+ 0=z-
	local x_velocity, z_velocity = 0, 0
	if n_param == 3 then
		pos2.x = pos2.x + 1
		pos1.x = pos1.x - 1
		x_velocity = -1
	elseif n_param == 2 then
		pos2.z = pos2.z + 1
		pos1.z = pos1.z - 1
		z_velocity = -1
	elseif n_param == 1 then
		pos2.x = pos2.x - 1
		pos1.x = pos1.x + 1
		x_velocity = 1
	elseif n_param == 0 then
		pos2.z = pos2.z - 1
		pos1.x = pos1.z + 1
		z_velocity = 1
	end

	local node = minetest.env:get_node(pos2)
	if node.name == "air" or name == "ignore" then
		return nil
	elseif minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].liquidtype ~= "none" then
		return nil
	end

	local digger = {
		get_player_name = function() return "node_breaker" end,
		getpos = function() return pos end,
		get_player_control = function() return {jump=false,right=false,left=false,LMB=false,RMB=false,sneak=false,aux1=false,down=false,up=false} end,
	}

	--check node to make sure it is diggable
	local def = ItemStack({name=node.name}):get_definition()
	if #def ~= 0 and not def.diggable or (def.can_dig and not def.can_dig(pos2, digger)) then --node is not diggable
		return
	end

	--handle node drops
	local drops = minetest.get_node_drops(node.name, "default:pick_mese")
	for _, dropped_item in ipairs(drops) do
		local item1 = tube_item({x=pos.x, y=pos.y, z=pos.z}, dropped_item)
		item1:get_luaentity().start_pos = {x=pos.x, y=pos.y, z=pos.z}
		item1:setvelocity({x=x_velocity, y=0, z=z_velocity})
		item1:setacceleration({x=0, y=0, z=0})
	end

	minetest.env:remove_node(pos2)

	--handle post-digging callback
	if def.after_dig_node then
		-- Copy pos and node because callback can modify them
		local pos_copy = {x=pos2.x, y=pos2.y, z=pos2.z}
		local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
		def.after_dig_node(pos_copy, node_copy, oldmetadata, digger)
	end

	--run digging event callbacks
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		-- Copy pos and node because callback can modify them
		local pos_copy = {x=pos2.x, y=pos2.y, z=pos2.z}
		local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
		callback(pos_copy, node_copy, digger)
	end
end

minetest.register_node("pipeworks:nodebreaker_off", {
	description = "Node Breaker",
	tile_images = {"pipeworks_nodebreaker_top_off.png","pipeworks_nodebreaker_bottom_off.png","pipeworks_nodebreaker_side2_off.png","pipeworks_nodebreaker_side1_off.png",
			"pipeworks_nodebreaker_back.png","pipeworks_nodebreaker_front_off.png"},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1},
	mesecons= {effector={action_on=node_breaker_on, action_off=node_breaker_off}},
	sounds = default.node_sound_stone_defaults(),
	after_place_node = tube_scanforobjects,
	after_dig_node = tube_scanforobjects,
})

minetest.register_node("pipeworks:nodebreaker_on", {
	description = "Node Breaker",
	tile_images = {"pipeworks_nodebreaker_top_on.png","pipeworks_nodebreaker_bottom_on.png","pipeworks_nodebreaker_side2_on.png","pipeworks_nodebreaker_side1_on.png",
			"pipeworks_nodebreaker_back.png","pipeworks_nodebreaker_front_on.png"},
	mesecons= {effector={action_on=node_breaker_on, action_off=node_breaker_off}},
	is_ground_content = true,
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2, mesecon = 2,tubedevice=1,not_in_creative_inventory=1},
	sounds = default.node_sound_stone_defaults(),
	after_place_node = tube_scanforobjects,
	after_dig_node = tube_scanforobjects,
})
