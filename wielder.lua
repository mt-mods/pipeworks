local S = minetest.get_translator("pipeworks")

local function set_wielder_formspec(data, meta)
	local width, height = data.wield_inv.width, data.wield_inv.height
	local size = "10.2,"..(data.wield_inv.height + 7)
	local list_bg = ""
	if minetest.get_modpath("i3") or minetest.get_modpath("mcl_formspec") then
		list_bg = "style_type[box;colors=#666]"
		for i=0, height-1 do
			for j=0, width-1 do
				list_bg = list_bg.."box["..((10-width)*0.5)+(i*1.25)..","..1+(j*1.25)..";1,1;]"
			end
		end
	end
	meta:set_string("formspec",
		"formspec_version[2]size["..size.."]"..
		pipeworks.fs_helpers.get_prepends(size)..list_bg..
		"item_image[0.5,0.5;1,1;pipeworks:"..data.name.."_off]"..
		"label[1.5,1;"..minetest.formspec_escape(data.description).."]"..
		"list[context;"..data.wield_inv.name..";"..((10-width)*0.5)..",1;"..width..","..height..";]"..
		pipeworks.fs_helpers.get_inv((height+2)).."listring[]"
	)
	meta:set_string("infotext", data.description)
end

local function wielder_on(data, pos, node)
	if node.name ~= "pipeworks:"..data.name.."_off" then
		return
	end
	node.name = "pipeworks:"..data.name.."_on"
	minetest.swap_node(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local wield_index
	for i, stack in ipairs(inv:get_list(data.wield_inv.name)) do
		if not stack:is_empty() then
			wield_index = i
			break
		end
	end
	if not wield_index and not data.wield_hand then
		return
	end
	local dir = minetest.facedir_to_dir(node.param2)
	local fakeplayer = fakelib.create_player({
		name = meta:get_string("owner"),
		direction = vector.multiply(dir, -1),
		position = pos,
		inventory = inv,
		wield_index = wield_index or 1,
		wield_list = data.wield_inv.name,
	})
	-- Under and above positions are intentionally switched.
	local pointed = {
		type = "node",
		under = vector.subtract(pos, dir),
		above = vector.subtract(pos, vector.multiply(dir, 2)),
	}
	data.action(fakeplayer, pointed)
	if data.eject_drops then
		for i, stack in ipairs(inv:get_list("main")) do
			if not stack:is_empty() then
				pipeworks.tube_inject_item(pos, pos, dir, stack)
				inv:set_stack("main", i, ItemStack(""))
			end
		end
	end
end

local function wielder_off(data, pos, node)
	if node.name == "pipeworks:"..data.name.."_on" then
		node.name = "pipeworks:"..data.name.."_off"
		minetest.swap_node(pos, node)
	end
end

local function register_wielder(data)
	for _,state in ipairs({"off", "on"}) do
		local groups = {
			snappy = 2, choppy = 2, oddly_breakable_by_hand = 2,
			mesecon = 2, tubedevice = 1, tubedevice_receiver = 1,
			axey = 1, handy = 1, pickaxey = 1,
			not_in_creative_inventory = state == "on" and 1 or nil
		}
		local tiles = {}
		for _,side in ipairs({"top", "bottom", "side2", "side1", "back", "front"}) do
			local suffix = data.stateful_sides[side] and "_"..state or ""
			table.insert(tiles, "pipeworks_"..data.name.."_"..side..suffix..".png")
		end
		minetest.register_node("pipeworks:"..data.name.."_"..state, {
			description = data.description,
			tiles = tiles,
			paramtype2 = "facedir",
			groups = groups,
			is_ground_content = false,
			_mcl_hardness = 0.6,
			_sound_def = {
				key = "node_sound_stone_defaults",
			},
			drop = "pipeworks:"..data.name.."_off",
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
				can_insert = function(pos, node, stack, direction)
					if data.block_back_insert then
						local dir = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
						if vector.equals(direction, dir) then
							return false
						end
					end
					local inv = minetest.get_meta(pos):get_inventory()
					return inv:room_for_item(data.wield_inv.name, stack)
				end,
				insert_object = function(pos, node, stack)
					local inv = minetest.get_meta(pos):get_inventory()
					return inv:add_item(data.wield_inv.name, stack)
				end,
				input_inventory = "main",
				connect_sides = data.connect_sides,
				can_remove = function(pos, node, stack)
					return stack:get_count()
				end,
			},
			on_construct = function(pos)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				inv:set_size(data.wield_inv.name, data.wield_inv.width * data.wield_inv.height)
				if data.eject_drops then
					inv:set_size("main", 32)
				end
				set_wielder_formspec(data, meta)
			end,
			after_place_node = function(pos, placer)
				pipeworks.scan_for_tube_objects(pos)
				if not placer then
					return
				end
				local node = minetest.get_node(pos)
				node.param2 = minetest.dir_to_facedir(placer:get_look_dir(), true)
				minetest.set_node(pos, node)
				minetest.get_meta(pos):set_string("owner", placer:get_player_name())
			end,
			after_dig_node = function(pos, oldnode, oldmetadata, digger)
				for _,stack in ipairs(oldmetadata.inventory.main or {}) do
					if not stack:is_empty() then
						minetest.add_item(pos, stack)
					end
				end
				pipeworks.scan_for_tube_objects(pos)
			end,
			on_rotate = pipeworks.on_rotate,
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
	table.insert(pipeworks.ui_cat_tube_list, "pipeworks:"..data.name.."_off")
end

if pipeworks.enable_node_breaker then
	register_wielder({
		name = "nodebreaker",
		description = S("Node Breaker"),
		stateful_sides = {top = true, bottom = true, side2 = true, side1 = true, front = true},
		connect_sides = {top = 1, bottom = 1, left = 1, right = 1, back = 1},
		block_back_insert = false,
		wield_inv = {name = "pick", width = 1, height = 1},
		wield_hand = true,
		action = function(fakeplayer, pointed)
			local stack = fakeplayer:get_wielded_item()
			local old_stack = ItemStack(stack)
			local item_def = minetest.registered_items[stack:get_name()]
			if item_def.on_use then
				fakeplayer:set_wielded_item(item_def.on_use(stack, fakeplayer, pointed) or stack)
			else
				local node = minetest.get_node(pointed.under)
				local node_def = minetest.registered_nodes[node.name]
				if not node_def or not node_def.on_dig then
					return
				end
				-- Check if the tool can dig the node
				local tool = stack:get_tool_capabilities()
				if not minetest.get_dig_params(node_def.groups, tool).diggable then
					-- Try using hand if tool can't dig the node
					local hand = ItemStack():get_tool_capabilities()
					if not minetest.get_dig_params(node_def.groups, hand).diggable then
						return
					end
				end
				node_def.on_dig(pointed.under, node, fakeplayer)
				local sound = node_def.sounds and node_def.sounds.dug
				if sound then
					minetest.sound_play(sound.name, {pos = pointed.under, gain = sound.gain})
				end
				stack = fakeplayer:get_wielded_item()
			end
			if stack:get_name() == old_stack:get_name() then
				-- Don't mechanically wear out tool
				if stack:get_wear() ~= old_stack:get_wear() and stack:get_count() == old_stack:get_count()
						and (item_def.wear_represents == nil or item_def.wear_represents == "mechanical_wear") then
					print("replaced")
					fakeplayer:set_wielded_item(old_stack)
				end
			elseif not stack:is_empty() then
				-- Tool got replaced by something else, treat it as a drop.
				fakeplayer:get_inventory():add_item("main", stack)
				fakeplayer:set_wielded_item("")
			end
		end,
		eject_drops = true,
	})
	minetest.register_alias("technic:nodebreaker_off", "pipeworks:nodebreaker_off")
	minetest.register_alias("technic:nodebreaker_on", "pipeworks:nodebreaker_on")
	minetest.register_alias("technic:node_breaker_off", "pipeworks:nodebreaker_off")
	minetest.register_alias("technic:node_breaker_on", "pipeworks:nodebreaker_on")
	minetest.register_alias("auto_tree_tap:off", "pipeworks:nodebreaker_off")
	minetest.register_alias("auto_tree_tap:on", "pipeworks:nodebreaker_on")
end

if pipeworks.enable_deployer then
	register_wielder({
		name = "deployer",
		description = S("Deployer"),
		stateful_sides = {front = true},
		connect_sides = {back = 1},
		wield_inv = {name = "main", width = 3, height = 3},
		action = function(fakeplayer, pointed)
			local stack = fakeplayer:get_wielded_item()
			local def = minetest.registered_items[stack:get_name()]
			if def and def.on_place then
				fakeplayer:set_wielded_item(def.on_place(stack, fakeplayer, pointed) or stack)
			end
		end,
		eject_drops = false,
	})
	minetest.register_alias("technic:deployer_off", "pipeworks:deployer_off")
	minetest.register_alias("technic:deployer_on", "pipeworks:deployer_on")
end

if pipeworks.enable_dispenser then
	-- Override minetest.item_drop to negate its hardcoded offset
	-- when the dropper is a fake player.
	local item_drop = minetest.item_drop
	-- luacheck: ignore 122
	function minetest.item_drop(stack, dropper, pos)
		if dropper and dropper.is_fake_player then
			pos = vector.new(pos.x, pos.y - 1.2, pos.z)
		end
		return item_drop(stack, dropper, pos)
	end
	register_wielder({
		name = "dispenser",
		description = S("Dispenser"),
		stateful_sides = {front = true},
		connect_sides = {back = 1},
		wield_inv = {name = "main", width = 3, height = 3},
		action = function(fakeplayer)
			local stack = fakeplayer:get_wielded_item()
			local def = minetest.registered_items[stack:get_name()]
			if def and def.on_drop then
				local pos = fakeplayer:get_pos()
				fakeplayer:set_wielded_item(def.on_drop(stack, fakeplayer, pos) or stack)
			end
		end,
		eject_drops = false,
	})
end
