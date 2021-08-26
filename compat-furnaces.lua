-- this file is basically a modified copy of
-- minetest_game/mods/default/furnaces.lua

-- translation support
local S = minetest.get_translator("pipeworks")
local DS = minetest.get_translator("default")

local fs_helpers = pipeworks.fs_helpers

local tube_entry = "^pipeworks_tube_connection_stony.png"

local function active_formspec(fuel_percent, item_percent, pos, meta)
	local formspec =
		"size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[current_name;src;2.75,0.5;1,1;]"..
		"list[current_name;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png^[lowpart:"..
		(100-fuel_percent)..":default_furnace_fire_fg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
		"list[current_name;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_name;dst]"..
		"listring[current_player;main]"..
		"listring[current_name;src]"..
		"listring[current_player;main]"..
		"listring[current_name;fuel]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25) ..
			fs_helpers.cycling_button(
				meta,
				"image_button[0,3.5;1,0.6",
				"split_material_stacks",
				{
					pipeworks.button_off,
					pipeworks.button_on
				}
			).."label[0.9,3.51;"..S("Allow splitting incoming material (not fuel) stacks from tubes").."]"
	return formspec
end

local function inactive_formspec(pos, meta)
	local formspec = "size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[current_name;src;2.75,0.5;1,1;]"..
	"list[current_name;fuel;2.75,2.5;1,1;]"..
	"image[2.75,1.5;1,1;default_furnace_fire_bg.png]"..
	"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"list[current_name;dst;4.75,0.96;2,2;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	"listring[current_name;dst]"..
	"listring[current_player;main]"..
	"listring[current_name;src]"..
	"listring[current_player;main]"..
	"listring[current_name;fuel]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0, 4.25) ..
		fs_helpers.cycling_button(
			meta,
			"image_button[0,3.5;1,0.6",
			"split_material_stacks",
			{
				pipeworks.button_off,
				pipeworks.button_on
			}
		).."label[0.9,3.51;"..S("Allow splitting incoming material (not fuel) stacks from tubes").."]"
	return formspec
end

--
-- Node callback functions that are the same for active and inactive furnace
--

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
			if inv:is_empty("src") then
				meta:set_string("infotext", DS("Furnace is empty"))
			end
			return stack:get_count()
		else
			return 0
		end
	elseif listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function furnace_node_timer(pos, elapsed)
	--
	-- Inizialize metadata
	--
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local src_time = meta:get_float("src_time") or 0
	local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

	local inv = meta:get_inventory()
	local srclist, fuellist

	local cookable, cooked
	local fuel

	local update = true
	while update do
		update = false

		srclist = inv:get_list("src")
		fuellist = inv:get_list("fuel")

		--
		-- Cooking
		--

		-- Check if we have cookable content
		local aftercooked
		cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		cookable = cooked.time ~= 0

		-- Check if we have enough fuel to burn
		if fuel_time < fuel_totaltime then
			-- The furnace is currently active and has enough fuel
			fuel_time = fuel_time + elapsed
			-- If there is a cookable item then check if it is ready yet
			if cookable then
				src_time = src_time + elapsed
				if src_time >= cooked.time then
					-- Place result in dst list if possible
					if inv:room_for_item("dst", cooked.item) then
						inv:add_item("dst", cooked.item)
						inv:set_stack("src", 1, aftercooked.items[1])
						src_time = src_time - cooked.time
						update = true
					end
				end
			end
		else
			-- Furnace ran out of fuel
			if cookable then
				-- We need to get new fuel
				local afterfuel
				fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})

				if fuel.time == 0 then
					-- No valid fuel in fuel list
					fuel_totaltime = 0
					src_time = 0
				else
					-- prevent blocking of fuel inventory (for automatization mods)
					local is_fuel = minetest.get_craft_result({method = "fuel", width = 1, items = {afterfuel.items[1]:to_string()}})
					if is_fuel.time == 0 then
						table.insert(fuel.replacements, afterfuel.items[1])
						inv:set_stack("fuel", 1, "")
					else
						-- Take fuel from fuel list
						inv:set_stack("fuel", 1, afterfuel.items[1])
					end
					-- Put replacements in dst list or drop them on the furnace.
					local replacements = fuel.replacements
					if replacements[1] then
						local leftover = inv:add_item("dst", replacements[1])
						if not leftover:is_empty() then
							local above = vector.new(pos.x, pos.y + 1, pos.z)
							local drop_pos = minetest.find_node_near(above, 1, {"air"}) or above
							minetest.item_drop(replacements[1], nil, drop_pos)
						end
					end
					update = true
					fuel_totaltime = fuel.time + (fuel_time - fuel_totaltime)
					src_time = src_time + elapsed
				end
			else
				-- We don't need to get new fuel since there is no cookable item
				fuel_totaltime = 0
				src_time = 0
			end
			fuel_time = 0
		end

		elapsed = 0
	end

	if fuel and fuel_totaltime > fuel.time then
		fuel_totaltime = fuel.time
	end
	if srclist[1]:is_empty() then
		src_time = 0
	end

	--
	-- Update formspec, infotext and node
	--
	local formspec = inactive_formspec(pos, meta)
	local item_state
	local item_percent = 0
	if cookable then
		item_percent = math.floor(src_time / cooked.time * 100)
		if item_percent > 100 then
			item_state = DS("100% (output full)")
		else
			item_state = DS("@1%", item_percent)
		end
	else
		if srclist[1]:is_empty() then
			item_state = DS("Empty")
		else
			item_state = DS("Not cookable")
		end
	end

	local fuel_state = DS("Empty")
	local active = DS("Furnace inactive")
	local result = false

	if fuel_totaltime ~= 0 then
		active = DS("Furnace active")
		local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
		fuel_state = DS("@1%", fuel_percent)
		formspec = active_formspec(fuel_percent, item_percent, pos, meta)
		swap_node(pos, "default:furnace_active")
		-- make sure timer restarts automatically
		result = true
	else
		if not fuellist[1]:is_empty() then
			fuel_state = DS("@1%", "0")
		end
		swap_node(pos, "default:furnace")
		-- stop timer on the inactive furnace
		minetest.get_node_timer(pos):stop()
	end

	local infotext = active.." "..DS("(Item: @1; Fuel: @2)", item_state, fuel_state)

	--
	-- Set meta values
	--
	meta:set_float("fuel_totaltime", fuel_totaltime)
	meta:set_float("fuel_time", fuel_time)
	meta:set_float("src_time", src_time)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end

--
-- Node definitions
--

minetest.register_node(":default:furnace", {
	description = DS("Furnace"),
	tiles = {
		"default_furnace_top.png"..tube_entry,
		"default_furnace_bottom.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		"default_furnace_front.png"
	},
	groups = {cracky = 2, tubedevice = 1, tubedevice_receiver = 1},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1.0)
			end
			if direction.y == 1 then
				return inv:add_item("fuel", stack)
			else
				return inv:add_item("src", stack)
			end
		end,
		can_insert = function(pos,node,stack,direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:room_for_item("fuel", stack)
			else
				if meta:get_int("split_material_stacks") == 1 then
					stack = stack:peek_item(1)
				end
				return inv:room_for_item("src", stack)
			end
		end,
		input_inventory = "dst",
		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
	},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	on_timer = furnace_node_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", inactive_formspec(pos, meta))
		local inv = meta:get_inventory()
		inv:set_size('src', 1)
		inv:set_size('fuel', 1)
		inv:set_size('dst', 4)
	end,

	on_metadata_inventory_move = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether furnace can burn or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "src", drops)
		default.get_inventory_drops(pos, "fuel", drops)
		default.get_inventory_drops(pos, "dst", drops)
		drops[#drops+1] = "default:furnace"
		minetest.remove_node(pos)
		return drops
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_receive_fields = function(pos, formname, fields, sender)
		if not pipeworks.may_configure(pos, sender) then return end
		fs_helpers.on_receive_fields(pos, fields)
		local meta = minetest.get_meta(pos)
		local formspec = inactive_formspec(pos, meta)
		meta:set_string("formspec", formspec)
	end,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig,
	on_rotate = pipeworks.on_rotate
})

minetest.register_node(":default:furnace_active", {
	description = DS("Furnace"),
	tiles = {
		"default_furnace_top.png"..tube_entry,
		"default_furnace_bottom.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		"default_furnace_side.png"..tube_entry,
		{
			image = "default_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	groups = {cracky = 2, tubedevice = 1, tubedevice_receiver = 1, not_in_creative_inventory = 1},
	tube = {
		insert_object = function(pos,node,stack,direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1.0)
			end
			if direction.y == 1 then
				return inv:add_item("fuel", stack)
			else
				return inv:add_item("src", stack)
			end
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:room_for_item("fuel", stack)
			else
				if meta:get_int("split_material_stacks") == 1 then
					stack = stack:peek_item(1)
				end
				return inv:room_for_item("src", stack)
			end
		end,
		input_inventory = "dst",
		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
	},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "default:furnace",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	on_timer = furnace_node_timer,

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_receive_fields = function(pos, formname, fields, sender)
		if not pipeworks.may_configure(pos, sender) then return end
		fs_helpers.on_receive_fields(pos, fields)
		local meta = minetest.get_meta(pos)
		local formspec = active_formspec(0, 0, pos, meta)
		meta:set_string("formspec", formspec)
	end,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig,
	on_rotate = pipeworks.on_rotate
})

