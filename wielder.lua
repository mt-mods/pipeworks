local assumed_eye_pos = vector.new(0, 1.5, 0)

local function delay(x)
	return (function() return x end)
end

local function wielder_on(data, wielder_pos, wielder_node)
	if wielder_node.name ~= data.name_base.."_off" then return end
	wielder_node.name = data.name_base.."_on"
	minetest.swap_node(wielder_pos, wielder_node)
	nodeupdate(wielder_pos)
	local wielder_meta = minetest.get_meta(wielder_pos)
	local inv = wielder_meta:get_inventory()
	local invlist = inv:get_list("main")
	local wieldindex, wieldstack
	for i, stack in ipairs(invlist) do
		if not stack:is_empty() then
			wieldindex = i
			wieldstack = stack
			break
		end
	end
	if not wieldindex then return end
	local dir = minetest.facedir_to_dir(wielder_node.param2)
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
	local virtplayer = {
		get_inventory_formspec = delay(wielder_meta:get_string("formspec")),
		get_look_dir = delay(vector.multiply(dir, -1)),
		get_look_pitch = delay(pitch),
		get_look_yaw = delay(yaw),
		get_player_control = delay({ jump=false, right=false, left=false, LMB=false, RMB=false, sneak=data.sneak, aux1=false, down=false, up=false }),
		get_player_control_bits = delay(data.sneak and 64 or 0),
		get_player_name = delay(data.masquerade_as_owner and wielder_meta:get_string("owner") or ":pipeworks:"..minetest.pos_to_string(wielder_pos)),
		is_player = delay(true),
		is_fake_player = true,
		set_inventory_formspec = delay(),
		getpos = delay(vector.subtract(wielder_pos, assumed_eye_pos)),
		get_hp = delay(20),
		get_inventory = delay(inv),
		get_wielded_item = delay(wieldstack),
		get_wield_index = delay(wieldindex),
		get_wield_list = delay("main"),
		moveto = delay(),
		punch = delay(),
		remove = delay(),
		right_click = delay(),
		setpos = delay(),
		set_hp = delay(),
		set_properties = delay(),
		set_wielded_item = function(self, item) inv:set_stack("main", wieldindex, item) end,
		set_animation = delay(),
		set_attach = delay(),
		set_detach = delay(),
		set_bone_position = delay(),
	}
	local pointed_thing = { type="node", under=under_pos, above=above_pos }
	virtplayer:set_wielded_item(data.on_act(virtplayer, pointed_thing) or wieldstack)
end

local function wielder_off(data, pos, node)
	if node.name == data.name_base.."_on" then
		node.name = data.name_base.."_off"
		minetest.swap_node(pos, node)
		nodeupdate(pos)
	end
end

local function register_wielder(data)
	for _, state in ipairs({ "off", "on" }) do
		local groups = { snappy=2, choppy=2, oddly_breakable_by_hand=2, mesecon=2, tubedevice=1, tubedevice_receiver=1 }
		if state == "on" then groups.not_in_creative_inventory = 1 end
		local tile_images = {}
		for _, face in ipairs({ "top", "bottom", "side2", "side1", "back", "front" }) do
			table.insert(tile_images, data.texture_base.."_"..face..(data.texture_stateful[face] and "_"..state or "")..".png")
		end
		minetest.register_node(data.name_base.."_"..state, {
			description = data.description,
			tile_images = tile_images,
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
				insert_object = function(pos,node,stack,direction)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:add_item("main",stack)
				end,
				can_insert = function(pos,node,stack,direction)
					local meta = minetest.get_meta(pos)
					local inv = meta:get_inventory()
					return inv:room_for_item("main",stack)
				end,
				input_inventory = "main",
				connect_sides = {back=1},
				can_remove = function(pos, node, stack, dir)
					return stack:get_count()
				end,
			},
			is_ground_content = true,
			paramtype2 = "facedir",
			tubelike = 1,
			groups = groups,
			sounds = default.node_sound_stone_defaults(),
			drop = data.name_base.."_off",
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec",
						"invsize[8,9;]"..
						"item_image[0,0;1,1;"..data.name_base.."_off]"..
						"label[1,0;"..minetest.formspec_escape(data.description).."]"..
						"list[current_name;main;4,1;3,3;]"..
						"list[current_player;main;0,5;8,4;]")
				meta:set_string("infotext", data.description)
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
end

if pipeworks.enable_deployer then
	register_wielder({
		name_base = "pipeworks:deployer",
		description = "Deployer",
		texture_base = "pipeworks_deployer",
		texture_stateful = { front = true },
		masquerade_as_owner = true,
		sneak = false,
		on_act = function(virtplayer, pointed_thing)
			local wieldstack = virtplayer:get_wielded_item()
			return (minetest.registered_items[wieldstack:get_name()] or {on_place=minetest.item_place}).on_place(wieldstack, virtplayer, pointed_thing)
		end,
	})
	minetest.register_craft({
		output = "pipeworks:deployer_off",
		recipe = {
			{ "group:wood",    "default:chest",    "group:wood"    },
			{ "default:stone", "mesecons:piston",  "default:stone" },
			{ "default:stone", "mesecons:mesecon", "default:stone" },
		}
	})
	-- aliases for when someone had technic installed, but then uninstalled it but not pipeworks
	minetest.register_alias("technic:deployer_off", "pipeworks:deployer_off")
	minetest.register_alias("technic:deployer_on", "pipeworks:deployer_on")
end

if pipeworks.enable_dispenser then
	register_wielder({
		name_base = "pipeworks:dispenser",
		description = "Dispenser",
		texture_base = "pipeworks_dispenser",
		texture_stateful = { front = true },
		masquerade_as_owner = false,
		sneak = true,
		on_act = function(virtplayer, pointed_thing)
			local wieldstack = virtplayer:get_wielded_item()
			return (minetest.registered_items[wieldstack:get_name()] or {on_drop=minetest.item_drop}).on_drop(wieldstack, virtplayer, virtplayer:getpos())
		end,
	})
	minetest.register_craft({
		output = "pipeworks:dispenser_off",
		recipe = {
			{ "default:desert_sand", "default:chest",    "default:desert_sand" },
			{ "default:stone",       "mesecons:piston",  "default:stone"       },
			{ "default:stone",       "mesecons:mesecon", "default:stone"       },
		}
	})
end
