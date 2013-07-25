
--register aliases for when someone had technic installed, but then uninstalled it but not pipeworks
minetest.register_alias("technic:nodebreaker_off", "pipeworks:nodebreaker_off")
minetest.register_alias("technic:nodebreaker_on", "pipeworks:nodebreaker_on")
minetest.register_alias("technic:node_breaker_off", "pipeworks:nodebreaker_off") --old name
minetest.register_alias("technic:node_breaker_on", "pipeworks:nodebreaker_on") --old name

minetest.register_craft({
	output = 'pipeworks:nodebreaker_off 1',
	recipe = {
		{'default:wood', 'default:pick_mese','default:wood'},
		{'default:stone', 'mesecons:piston','default:stone'},
		{'default:stone', 'mesecons:mesecon','default:stone'},
	}
})

function hacky_swap_node(pos,name)
	local node=minetest.get_node(pos)
	local meta=minetest.get_meta(pos)
	local meta0=meta:to_table()
	node.name=name
	minetest.add_node(pos, node)
	local meta=minetest.get_meta(pos)
	meta:from_table(meta0)
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

local function facedir_to_dir(facedir)
	--a table of possible dirs
	return ({{x=0, y=0, z=1},
					{x=1, y=0, z=0},
					{x=0, y=0, z=-1},
					{x=-1, y=0, z=0},
					{x=0, y=-1, z=0},
					{x=0, y=1, z=0}})
					
					--indexed into by a table of correlating facedirs
					[({[0]=1, 2, 3, 4, 
						5, 2, 6, 4,
						6, 2, 5, 4,
						1, 5, 3, 6,
						1, 6, 3, 5,
						1, 4, 3, 2})
						
						--indexed into by the facedir in question
						[facedir]]
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

function break_node (pos, facedir)
	
	--locate the outgoing velocity, front, and back of the node via facedir_to_dir
	local vel = facedir_to_dir(facedir);
	local front = {x=pos.x - vel.x, y=pos.y - vel.y, z=pos.z - vel.z}
	local back = {x=pos.x + vel.x, y=pos.y + vel.y, z=pos.z + vel.z}
	
	local node = minetest.get_node(front)
	if node.name == "air" or node.name == "ignore" then
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
	if #def ~= 0 and not def.diggable or (def.can_dig and not def.can_dig(front, digger)) then --node is not diggable
		return
	end

	--handle node drops
	local drops = minetest.get_node_drops(node.name, "default:pick_mese")
	for _, dropped_item in ipairs(drops) do
		local item1 = tube_item({x=pos.x, y=pos.y, z=pos.z}, dropped_item)
		item1:get_luaentity().start_pos = {x=pos.x, y=pos.y, z=pos.z}
		item1:setvelocity(vel)
		item1:setacceleration({x=0, y=0, z=0})
	end

	minetest.remove_node(front)

	--handle post-digging callback
	if def.after_dig_node then
		-- Copy pos and node because callback can modify them
		local pos_copy = {x=front.x, y=front.y, z=front.z}
		local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
		def.after_dig_node(pos_copy, node_copy, oldmetadata, digger)
	end

	--run digging event callbacks
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		-- Copy pos and node because callback can modify them
		local pos_copy = {x=front.x, y=front.y, z=front.z}
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
	tube = {connect_sides={back=1}},
	after_place_node = function (pos, placer)
		tube_scanforobjects(pos, placer)
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
	end,
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
	tube = {connect_sides={back=1}},
	after_place_node = function (pos, placer)
		tube_scanforobjects(pos, placer)
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
	end,
	after_dig_node = tube_scanforobjects,
})
