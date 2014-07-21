minetest.register_craft({
	output = "pipeworks:dispenser_off",
	recipe = {
		{ "default:desert_sand", "default:chest",    "default:desert_sand" },
		{ "default:stone",       "mesecons:piston",  "default:stone"       },
		{ "default:stone",       "mesecons:mesecon", "default:stone"       },
	}
})

local function delay(x)
	return (function() return x end)
end

local function dispenser_on(pos, node)
	if node.name ~= "pipeworks:dispenser_off" then
		return
	end

	node.name = "pipeworks:dispenser_on"
	minetest.swap_node(pos, node)
	nodeupdate(pos)

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local invlist = inv:get_list("main")
	for i, stack in ipairs(invlist) do
		if stack:get_name() ~= nil and stack:get_name() ~= "" then
			local dir = minetest.facedir_to_dir(node.param2)
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
			local dropper_pos = {x = pos.x, y = pos.y - 1.5, z = pos.z} -- Player height
			local dropper = {
				get_inventory_formspec = delay(meta:get_string("formspec")),
				get_look_dir = delay({x = -dir.x, y = -dir.y, z = -dir.z}),
				get_look_pitch = delay(pitch),
				get_look_yaw = delay(yaw),
				get_player_control = delay({jump=false, right=false, left=false, LMB=false, RMB=false, sneak=true, aux1=false, down=false, up=false}),
				get_player_control_bits = delay(0),
				get_player_name = delay(":pipeworks:"..minetest.pos_to_string(pos)),
				is_player = delay(true),
				is_fake_player = true,
				set_inventory_formspec = delay(),
				getpos = delay(dropper_pos),
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
			local stack2
			if minetest.registered_items[stack:get_name()] then
				stack2 = minetest.registered_items[stack:get_name()].on_drop(stack, dropper, dropper_pos) or stack
			end
			inv:set_stack("main", i, stack2)
			return
		end
	end
end

local dispenser_off = function(pos, node)
	if node.name == "pipeworks:dispenser_on" then
		node.name = "pipeworks:dispenser_off"
		minetest.swap_node(pos, node)
		nodeupdate(pos)
	end
end

for _, state in ipairs({ "off", "on" }) do
	local grps = { snappy=2, choppy=2, oddly_breakable_by_hand=2, mesecon=2, tubedevice=1, tubedevice_receiver=1 }
	if state == "on" then grps.not_in_creative_inventory = 1 end
	minetest.register_node("pipeworks:dispenser_"..state, {
		description = "Dispenser",
		tile_images = {
			"pipeworks_dispenser_top.png",
			"pipeworks_dispenser_bottom.png",
			"pipeworks_dispenser_side2.png",
			"pipeworks_dispenser_side1.png",
			"pipeworks_dispenser_back.png",
			"pipeworks_dispenser_front_"..state..".png",
		},
		mesecons = {
			effector = {
				rules = pipeworks.rules_all,
				action_on = dispenser_on,
				action_off = dispenser_off,
			},
		},
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
			connect_sides={back=1},
			can_remove = function(pos, node, stack, dir)
				return stack:get_count()
			end},
		is_ground_content = true,
		paramtype2 = "facedir",
		tubelike = 1,
		groups = grps,
		sounds = default.node_sound_stone_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec",
					"invsize[8,9;]"..
					"label[0,0;Dispenser]"..
					"list[current_name;main;4,1;3,3;]"..
					"list[current_player;main;0,5;8,4;]")
			meta:set_string("infotext", "Dispenser")
			local inv = meta:get_inventory()
			inv:set_size("main", 3*3)
		end,
		can_dig = function(pos,player)
			local meta = minetest.get_meta(pos)
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
		end,
	})
end
