local S = core.get_translator("pipeworks")

if core.get_modpath("unified_inventory") then
	core.register_craftitem("pipeworks:text_req", {
		description = S("Requirements"),
		inventory_image = "text_req.png",
		groups = {not_in_creative_inventory = 1},
		stack_max = 1,
	})

	core.register_craftitem("pipeworks:text_div1000", {
		description = S("Liters (divide by 1000 for m³)"),
		inventory_image = "text_div1000.png",
		groups = {not_in_creative_inventory = 1},
		stack_max = 1,
	})

	unified_inventory.register_craft_type("fluidshaped", {
		description = S("Shaped Fluid Craft"),
		icon = "pipeworks_autocrafter.png",
		width = 3,
		height = 4,
	})

	unified_inventory.register_on_craft_registered(
		function (item_name, options)
			if options.type ~= "fluidshaped" then return end
			options.items[10] = "pipeworks:text_req"
			options.items[11] = pipeworks.liquids[options.fluid.type].source .. " " .. (options.fluid.amount * 1000)
			options.items[12] = "pipeworks:text_div1000"
		end
	)
end

-- cache some recipe data to avoid calling the slow function
-- core.get_craft_result() every second
local autocrafterCache = {}

local craft_time = 1
local next = next

local function get_item_info(stack)
	local name = stack:get_name()
	local def = minetest.registered_items[name]
	local description = def and def.description or S("Unknown item")
	return description, name
end

-- returns false if we shouldn't bother attempting to start the timer again
-- after this
local function update_meta(meta, enabled)
	local state = enabled and "on" or "off"
	meta:set_int("enabled", enabled and 1 or 0)
	local list_backgrounds = ""
	if minetest.get_modpath("i3") or minetest.get_modpath("mcl_formspec") then
		list_backgrounds = "style_type[box;colors=#666]"
		for i = 0, 2 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					1.5 + (i * 1.25) .. "," .. 0.25 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 3 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					5.28 + 1.25 + (i * 1.25) .. "," .. 0.25 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 7 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					1.5 + (i * 1.25) .. "," .. 5 + (j * 1.25) .. ";1,1;]"
			end
		end
	end
	local size = "11.5,14"
	local fluid = meta:get("fluidtype")
	local amount = meta:get_float("fluidamount")
	local fluid_cap = meta:get_float("fluidcap")
	local bar_height = 8.25 * amount / fluid_cap
	local fs =
		"formspec_version[4]" ..
		"size[" .. size .. "]" ..
		pipeworks.fs_helpers.get_prepends(size) ..
		list_backgrounds ..
		"list[context;recipe;1.47,0.22;3,3;]" ..
		"image[5.25,1.45;1,1;[combine:16x16^[noalpha^[colorize:#141318:255]" ..
		"list[context;output;5.25,1.45;1,1;]" ..
		"image_button[5.25,2.6;1,0.6;pipeworks_button_" .. state .. ".png;" ..
		state .. ";;;false;pipeworks_button_interm.png]" ..
		"list[context;dst;6.53,0.22;4,3;]" ..
		"list[context;src;1.47,5;8,3;]" ..--
		pipeworks.fs_helpers.get_inv(9,1.25) ..
		"listring[current_player;main]" ..
		"listring[context;src]" ..
		"listring[current_player;main]" ..
		"listring[context;dst]" ..
		"listring[current_player;main]" ..
		"image[0.22," .. (8.5 - bar_height) .. ";1," .. bar_height .. ";pipeworks_fluid_" .. (fluid or "air") .. ".png]" ..
		"image[0.22,0.25;1,8.25;pipeworks_fluidbar.png]"
	if minetest.get_modpath("digilines") then
		fs = fs .. "field[1.47,4;4.5,0.75;channel;" .. S("Channel") ..
			";${channel}]" ..
			"button[6.25,4;1.5,0.75;set_channel;" .. S("Set") .. "]" ..
			"button_exit[8.05,4;2,0.75;close;" .. S("Close") .. "]"
	end
	meta:set_string("formspec", fs)

	-- toggling the button doesn't quite call for running a recipe change check
	-- so instead we run a minimal version for infotext setting only
	-- this might be more written code, but actually executes less
	local output = meta:get_inventory():get_stack("output", 1)
	if output:is_empty() then -- doesn't matter if paused or not
		meta:set_string("infotext", S("unconfigured Autocrafter"))
		return false
	end

	local description, name = get_item_info(output)
	local infotext = enabled and S("'@1' Autocrafter (@2)", description, name)
				or S("paused '@1' Autocrafter", description)

	meta:set_string("infotext", infotext)
	return enabled
end

local function count_index(invlist)
	local index = {}
	for _, stack in pairs(invlist) do
		stack = ItemStack(stack)
		if not stack:is_empty() then
			local stack_name = stack:get_name()
			index[stack_name] = (index[stack_name] or 0) + stack:get_count()
		end
	end
	return index
end

local function get_item_info(stack)
	local name = stack:get_name()
	local def = core.registered_items[name]
	local description = def and def.description or S("Unknown item")
	return description, name
end

-- Get best matching recipe for what user has put in crafting grid.
-- This function does not consider crafting method (mix vs craft)
local function get_matching_craft(output_name, example_recipe, fluid_input)
	local recipes
	if fluid_input then
		recipes = pipeworks.fluid_recipes:get_all(output_name, fluid_input.type)
	else
		recipes = core.get_all_craft_recipes(output_name)
	end
	if not recipes then
		return example_recipe
	end

	if 1 == #recipes then
		return recipes[1].items
	end

	local index_example = count_index(example_recipe)
	local best_score = 0
	local index_recipe, best_index, score, group
	for i = 1, #recipes do
		score = 0
		index_recipe = count_index(recipes[i].items)
		for recipe_item_name, _ in pairs(index_recipe) do
			if index_example[recipe_item_name] then
				score = score + 1
			elseif recipe_item_name:sub(1, 6) == "group:" then
				group = recipe_item_name:sub(7)
				for example_item_name, _ in pairs(index_example) do
					if core.get_item_group(
						example_item_name, group) ~= 0
					then
						score = score + 1
						break
					end
				end
			end
		end
		if best_score < score then
			best_index = i
			best_score = score
		end
	end

	return best_index and recipes[best_index].items or example_recipe
end

local function get_craft(pos, inventory, hash)
	local hash = hash or core.hash_node_position(pos)
	local craft = autocrafterCache[hash]
	if craft then return craft end

	local example_recipe = inventory:get_list("recipe")
	local output, decremented_input = core.get_craft_result({
		method = "normal", width = 3, items = example_recipe
	})

	local fluid
	if (not output) or output.item:is_empty() then
		output, decremented_input, fluid = pipeworks.fluid_recipes:get({
			items = example_recipe, fluid_type = core.get_meta(pos):get("fluidtype") -- GOHERE
		})
	end

	local recipe = example_recipe
	if output and not output.item:is_empty() then
		recipe = get_matching_craft(output.item:get_name(), example_recipe, fluid)
	end

	craft = {
		fluid = fluid,
		recipe = recipe,
		consumption = count_index(recipe),
		output = output,
		decremented_input = decremented_input.items
	}
	autocrafterCache[hash] = craft
	return craft
end

-- From a consumption table with groups and an inventory index,
-- build a consumption table without groups
local function calculate_consumption(inv_index, consumption_with_groups)
	inv_index = table.copy(inv_index)
	consumption_with_groups = table.copy(consumption_with_groups)

	-- table of items to actually consume
	local consumption = {}
	-- table of ingredients defined as one or more groups each
	local grouped_ingredients = {}

	-- First consume all non-group requirements
	-- This is done to avoid consuming a non-group item which
	-- is also in a group
	for key, count in pairs(consumption_with_groups) do
		if key:sub(1, 6) == "group:" then
			-- build table with group recipe items while looping
			grouped_ingredients[key] = key:sub(7):split(',')
		else
			-- if the item to consume doesn't exist in inventory
			-- or not enough of them, abort crafting
			if not inv_index[key] or inv_index[key] < count then
				return nil
			end

			consumption[key] = (consumption[key] or 0) + count
			consumption_with_groups[key] = consumption_with_groups[key] - count
			assert(consumption_with_groups[key] == 0)
			consumption_with_groups[key] = nil
			inv_index[key] = inv_index[key] - count
			assert(inv_index[key] >= 0)
		end
	end

	-- helper function to resolve matching ingredients with multiple group
	-- requirements
	local function ingredient_groups_match_item(ingredient_groups, name)
		local found = 0
		local count_ingredient_groups = #ingredient_groups
		for i = 1, count_ingredient_groups do
			if core.get_item_group(name,
				ingredient_groups[i]) ~= 0
			then
				found = found + 1
			end
		end
		return found == count_ingredient_groups
	end

	-- Next, resolve groups using the remaining items in the inventory
	if next(grouped_ingredients) ~= nil then
		local take
		for itemname, count in pairs(inv_index) do
			if count > 0 then
				-- groupname is the string as defined by recipe.
				--  e.g. group:dye,color_blue
				-- groups holds the group names split into a list
				--  ready to be passed to core.get_item_group()
				for groupname, groups in pairs(grouped_ingredients) do
					if consumption_with_groups[groupname] > 0
						and ingredient_groups_match_item(groups, itemname)
					then
						take = math.min(count,
							consumption_with_groups[groupname])
						consumption_with_groups[groupname] =
							consumption_with_groups[groupname] - take

						assert(consumption_with_groups[groupname] >= 0)
						consumption[itemname] =
							(consumption[itemname] or 0) + take

						inv_index[itemname] =
							inv_index[itemname] - take
						assert(inv_index[itemname] >= 0)
					end
				end
			end
		end
	end

	-- Finally, check everything has been consumed
	for key, count in pairs(consumption_with_groups) do
		if count > 0 then
			return nil
		end
	end

	return consumption
end

local function has_room_for_output(list_output, index_output)
	local name
	local empty_count = 0
	for _, item in pairs(list_output) do
		if item:is_empty() then
			empty_count = empty_count + 1
		else
			name = item:get_name()
			if index_output[name] then
				index_output[name] = index_output[name] - item:get_free_space()
			end
		end
	end
	for _, count in pairs(index_output) do
		if count > 0 then
			empty_count = empty_count - 1
		end
	end
	if empty_count < 0 then
		return false
	end

	return true
end

-- returns true if not enough fluid
local function check_fluid_insufficiency(req, input)
	if not req then return false end
	if not input then return true end
	if input.type ~= req.type then return true end
	if input.amount < req.amount then return true end
end

local function autocraft(inventory, craft, fluid)
	if not craft then return false end

	-- check if output and all replacements fit in dst
	local output = craft.output.item
	local out_items = count_index(craft.decremented_input)
	local craftfluid = craft.fluid
	out_items[output:get_name()] =
			(out_items[output:get_name()] or 0) + output:get_count()

	if not has_room_for_output(inventory:get_list("dst"), out_items) then
		return false
	end

	-- check if we have enough material available
	local inv_index = count_index(inventory:get_list("src"))
	local consumption = calculate_consumption(inv_index, craft.consumption)
	if (not consumption) or (craftfluid and check_fluid_insufficiency(craftfluid, fluid)) then
		return false
	end

	-- consume material
	for itemname, number in pairs(consumption) do
		-- We have to do that since remove_item does not work if count > stack_max
		for _ = 1, number do
			inventory:remove_item("src", ItemStack(itemname))
		end
	end
	if craftfluid then fluid.amount = fluid.amount - craftfluid.amount end

	-- craft the result into the dst inventory and add any "replacements" as well
	inventory:add_item("dst", output)
	local leftover
	for i = 1, 9 do
		leftover = inventory:add_item("dst", craft.decremented_input[i])
		if leftover and not leftover:is_empty() then
			core.log("warning", "[pipeworks] autocrafter didn't " ..
				"calculate output space correctly.")
		end
	end
	return true
end

-- returns false to stop the timer, true to continue running
-- is started only from start_autocrafter(pos) after sanity checks and
-- recipe is cached
local function run_autocrafter(pos, elapsed)
	local meta = core.get_meta(pos)
	local inventory = meta:get_inventory()
	local craft = get_craft(pos, inventory)
	local output_item = craft.output.item
	-- only use crafts that have an actual result
	if output_item:is_empty() then
		meta:set_string("infotext", S("unconfigured Autocrafter: unknown recipe"))
		return false
	end

	local fluid = {type = meta:get("fluidtype"), amount = meta:get_float("fluidamount")}
	for _ = 1, math.floor(elapsed / craft_time) do
		local continue = autocraft(inventory, craft, fluid)
		if not continue then return false end
		meta:set_float("fluidamount", fluid.amount)
		update_meta(meta, meta:get_int("enabled") == 1)
	end
	return true
end

local function start_crafter(pos)
	local meta = core.get_meta(pos)
	if meta:get_int("enabled") == 1 then
		local timer = core.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(craft_time)
		end
	end
end

local function after_inventory_change(pos)
	start_crafter(pos)
end

-- note, that this function assumes allready being updated to virtual items
-- and doesn't handle recipes with stacksizes > 1
local function after_recipe_change(pos, inventory)
	local hash = core.hash_node_position(pos)
	local meta = core.get_meta(pos)
	autocrafterCache[hash] = nil
	-- if we emptied the grid, there's no point in keeping it running or cached
	if inventory:is_empty("recipe") then
		core.get_node_timer(pos):stop()
		meta:set_string("infotext", S("unconfigured Autocrafter"))
		inventory:set_stack("output", 1, "")
		return
	end
	local craft = get_craft(pos, inventory, hash)
	local output_item = craft.output.item
	local description, name = get_item_info(output_item)
	meta:set_string("infotext", S("'@1' Autocrafter (@2)", description, name))
	inventory:set_stack("output", 1, output_item)

	after_inventory_change(pos)
end

-- clean out unknown items and groups, which would be handled like unknown
-- items in the crafting grid
-- if Luanti supports query by group one day, this might replace them
-- with a canonical version instead
local function normalize(item_list)
	for i = 1, #item_list do
		local name = item_list[i]
		if not core.registered_items[name] then
			item_list[i] = ""
		end
	end
	return item_list
end

local function on_output_change(pos, inventory, stack)
	if not stack then
		inventory:set_list("output", {})
		inventory:set_list("recipe", {})
	else
		local input = core.get_craft_recipe(stack:get_name())
		if not input.items or input.type ~= "normal" then return end
		local items, width = normalize(input.items), input.width
		local item_idx, width_idx = 1, 1
		for i = 1, 9 do
			if width_idx <= width then
				inventory:set_stack("recipe", i, items[item_idx])
				item_idx = item_idx + 1
			else
				inventory:set_stack("recipe", i, ItemStack(""))
			end
			width_idx = (width_idx < 3) and (width_idx + 1) or 1
		end
		-- we'll set the output slot in after_recipe_change to the actual
		-- result of the new recipe
	end
	after_recipe_change(pos, inventory)
end

-- returns false if we shouldn't bother attempting to start the timer again
-- after this
local function update_meta(meta, enabled)
	local state = enabled and "on" or "off"
	meta:set_int("enabled", enabled and 1 or 0)
	local list_backgrounds = ""
	if core.get_modpath("i3") or core.get_modpath("mcl_formspec") then
		list_backgrounds = "style_type[box;colors=#666]"
		for i = 0, 2 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					1.5 + (i * 1.25) .. "," .. 0.25 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 3 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					5.28 + 1.25 + (i * 1.25) .. "," .. 0.25 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 7 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					1.5 + (i * 1.25) .. "," .. 5 + (j * 1.25) .. ";1,1;]"
			end
		end
	end
	local size = "11.5,14"
	local fluid = meta:get("fluidtype")
	local amount = meta:get_float("fluidamount")
	local fluid_cap = meta:get_float("fluidcap")
	local bar_height = 8.25 * amount / fluid_cap
	local fs =
		"formspec_version[4]" ..
		"size[" .. size .. "]" ..
		pipeworks.fs_helpers.get_prepends(size) ..
		list_backgrounds ..
		"list[context;recipe;1.47,0.22;3,3;]" ..
		"image[5.25,1.45;1,1;[combine:16x16^[noalpha^[colorize:#141318:255]" ..
		"list[context;output;5.25,1.45;1,1;]" ..
		"image_button[5.25,2.6;1,0.6;pipeworks_button_" .. state .. ".png;" ..
		state .. ";;;false;pipeworks_button_interm.png]" ..
		"list[context;dst;6.53,0.22;4,3;]" ..
		"list[context;src;1.47,5;8,3;]" ..--
		pipeworks.fs_helpers.get_inv(9,1.25) ..
		"listring[current_player;main]" ..
		"listring[context;src]" ..
		"listring[current_player;main]" ..
		"listring[context;dst]" ..
		"listring[current_player;main]" ..
		"image[0.22," .. (8.5 - bar_height) .. ";1," .. bar_height .. ";pipeworks_fluid_" .. (fluid or "air") .. ".png]" ..
		"image[0.22,0.25;1,8.25;pipeworks_fluidbar.png]"
	if core.get_modpath("digilines") then
		fs = fs .. "field[1.47,4;4.5,0.75;channel;" .. S("Channel") ..
			";${channel}]" ..
			"button[6.25,4;2,0.75;set_channel;" .. S("Set") .. "]" ..
			"button_exit[8.45,4;2,0.75;close;" .. S("Close") .. "]"
	end
	meta:set_string("formspec", fs)

	-- toggling the button doesn't quite call for running a recipe change check
	-- so instead we run a minimal version for infotext setting only
	-- this might be more written code, but actually executes less
	local output = meta:get_inventory():get_stack("output", 1)
	if output:is_empty() then -- doesn't matter if paused or not
		meta:set_string("infotext", S("unconfigured Autocrafter"))
		return false
	end

	local description, name = get_item_info(output)
	local infotext = enabled and S("'@1' Autocrafter (@2)", description, name)
				or S("paused '@1' Autocrafter", description)

	meta:set_string("infotext", infotext)
	return enabled
end

-- 1st version of the autocrafter had actual items in the crafting grid
-- the 2nd replaced these with virtual items, dropped the content on update and
--   set "virtual_items" to string "1"
-- the third added an output inventory, changed the formspec and added a button
--   for enabling/disabling
-- so we work out way backwards on this history and update each single case
--   to the newest version
local function upgrade_autocrafter(pos, meta)
	local meta = meta or core.get_meta(pos)
	local inv = meta:get_inventory()

	if inv:get_size("output") == 0 then -- we are version 2 or 1
		inv:set_size("output", 1)
		-- migrate the old autocrafters into an "enabled" state
		update_meta(meta, true)

		if meta:get_string("virtual_items") == "1" then -- we are version 2
			-- we already dropped stuff, so lets remove the metadatasetting
			-- (we are not being called again for this node)
			meta:set_string("virtual_items", "")
		else -- we are version 1
			local recipe = inv:get_list("recipe")
			if not recipe then return end
			for idx, stack in ipairs(recipe) do
				if not stack:is_empty() then
					core.add_item(pos, stack)
					stack:set_count(1)
					stack:set_wear(0)
					inv:set_stack("recipe", idx, stack)
				end
			end
		end

		-- update the recipe, cache, and start the crafter
		autocrafterCache[core.hash_node_position(pos)] = nil
		after_recipe_change(pos, inv)
	end
end

pipeworks.fluid_recipes = {
	trie = {}
}

--[[def = {items = {
	<strictly width 3 or shapeless>
},
output = out|{outs}, -- Itemstacks
fluid = {
	type = <type>,
	amount = <float amount>
}}
]]
pipeworks.fluid_recipes.register = function(self, def)
	if def.output == nil then return end
	if def.items == nil then return end
	local newdef = {
		items = {},
		fluid = def.fluid,
		shaped = def.shaped
	}
	local path = self.trie

	for _,v in ipairs(def.items) do
		if type(v) == "table" then
			for _,w in ipairs(v) do
				newdef.items[#newdef.items + 1] = w
				local child = {}
				if path[w] then
					child = path[w]
				end
				path[w] = child
				path = child
			end
		else
			newdef.items[#newdef.items + 1] = v
			local child = {}
			if path[v] then
				child = path[v]
			end
			path[v] = child
			path = child
		end
	end

	if core.get_modpath("unified_inventory") then
		unified_inventory.register_craft({
			output = def.output,
			type = "fluidshaped",
			items = newdef.items,
			fluid = newdef.fluid,
			width = 3,
		})
	end

	if type(def.output) == "table" then
		newdef.output = def.output
	else
		newdef.output = {item = def.output}
	end

	if not path.fluid then path.fluid = {} end
	if not path.output then path.output = {} end

	path.fluid[newdef.fluid.type] = newdef.fluid
	path.output[newdef.fluid.type] = newdef.output
	path.tail = true
	self[#self + 1] = newdef
end

--[[ input = {
	input = <ItemStack list>,
	fluid_type = <fluidtype>
} ]]
pipeworks.fluid_recipes.get = function(self, input)
	local path = self.trie
	local empty = {item = ItemStack("")}
	local dec_input = table.copy(input)
	for k,v in ipairs(dec_input.items) do
		path = path[v:get_name()]
		if path == nil then return empty, input end
		dec_input.items[k] = ItemStack(v)
		dec_input.items[k]:set_count(v:get_count()-1)
		if path == nil then return empty, input end
		if path.tail then
			if path.output[dec_input.fluid_type] then
				return path.output[dec_input.fluid_type], dec_input, path.fluid[dec_input.fluid_type]
			else
				return empty, input
			end
		end
	end
	return empty, input
end

-- name = <string>
-- fluid_type = <string>
pipeworks.fluid_recipes.get_all = function(self, name, fluid_type)
	local out = {}
	for _,v in ipairs(self) do
		if v.output[fluid_type] and v.output[fluid_type].item:get_name() == name then
			out[#out + 1] = v
		end
	end
	return out
end

core.register_node("pipeworks:autocrafter", {
	description = S("Autocrafter"),
	drawtype = "normal",
	tiles = {"pipeworks_autocrafter.png"},
	groups = {snappy = 3, tubedevice = 1, tubedevice_receiver = 1, dig_generic = 1, axey=1, handy=1, pickaxey=1},
	is_ground_content = false,
	_mcl_hardness=0.8,
	pipe_connections = { top = 1, bottom = 1, left = 1, right = 1, front = 1, back = 1 },
	tube = {insert_object = function(pos, node, stack, direction)
			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			local added = inv:add_item("src", stack)
			after_inventory_change(pos)
			return added
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
		input_inventory = "dst",
		connect_sides = {
			left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1
			}
	},
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_float("fluidcap", 8)
		local inv = meta:get_inventory()
		inv:set_size("src", 3 * 8)
		inv:set_size("recipe", 3 * 3)
		inv:set_size("dst", 4 * 3)
		inv:set_size("output", 1)
		update_meta(meta, false)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if (fields.quit and not fields.key_enter_field)
			or not pipeworks.may_configure(pos, sender)
		then
			return
		end
		local meta = core.get_meta(pos)
		if fields.on then
			update_meta(meta, false)
			core.get_node_timer(pos):stop()
		elseif fields.off then
			if update_meta(meta, true) then
				start_crafter(pos)
			end
		end
		if fields.channel then
			meta:set_string("channel", fields.channel)
		end
	end,
	can_dig = function(pos, player)
		upgrade_autocrafter(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		return (inv:is_empty("src") and inv:is_empty("dst"))
	end,
	after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
		pipeworks.scan_for_pipe_objects(pos)
	end,
	after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
		pipeworks.scan_for_pipe_objects(pos)
	end,
	on_destruct = function(pos)
		autocrafterCache[core.hash_node_position(pos)] = nil
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not pipeworks.may_configure(pos, player) then return 0 end
		upgrade_autocrafter(pos)
		local inv = core.get_meta(pos):get_inventory()
		if listname == "recipe" then
			stack:set_count(1)
			inv:set_stack(listname, index, stack)
			after_recipe_change(pos, inv)
			return 0
		elseif listname == "output" then
			on_output_change(pos, inv, stack)
			return 0
		end
		after_inventory_change(pos)
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if not pipeworks.may_configure(pos, player) then
			core.log("action", string.format("%s attempted to take from " ..
				"autocrafter at %s",
				player:get_player_name(), core.pos_to_string(pos)))
			return 0
		end
		upgrade_autocrafter(pos)
		local inv = core.get_meta(pos):get_inventory()
		if listname == "recipe" then
			inv:set_stack(listname, index, ItemStack(""))
			after_recipe_change(pos, inv)
			return 0
		elseif listname == "output" then
			on_output_change(pos, inv, nil)
			return 0
		end
		after_inventory_change(pos)
		return stack:get_count()
	end,
	allow_metadata_inventory_move = function(
			pos, from_list, from_index, to_list, to_index, count, player)

		if not pipeworks.may_configure(pos, player) then return 0 end
		upgrade_autocrafter(pos)
		local inv = core.get_meta(pos):get_inventory()
		local stack = inv:get_stack(from_list, from_index)

		if to_list == "output" then
			on_output_change(pos, inv, stack)
			return 0
		elseif from_list == "output" then
			on_output_change(pos, inv, nil)
			if to_list ~= "recipe" then
				return 0
			end -- else fall through to recipe list handling
		end

		if from_list == "recipe" or to_list == "recipe" then
			if from_list == "recipe" then
				inv:set_stack(from_list, from_index, ItemStack(""))
			end
			if to_list == "recipe" then
				stack:set_count(1)
				inv:set_stack(to_list, to_index, stack)
			end
			after_recipe_change(pos, inv)
			return 0
		end

		after_inventory_change(pos)
		return count
	end,
	on_timer = run_autocrafter,
	digilines = {
		receptor = {},
		effector = {
			action = function(pos,node,channel,msg)
				local meta = core.get_meta(pos)
				if channel ~= meta:get_string("channel") then return end
				if type(msg) == "table" then
					if #msg < 3 then return end
					local inv = meta:get_inventory()
					for y = 0, 2, 1 do
						local row = msg[y + 1]
						for x = 1, 3, 1 do
							local slot = y * 3 + x
							if type(row) == "table" and core.registered_items[row[x]] then
								inv:set_stack("recipe", slot, ItemStack(
									row[x]))
							else
								inv:set_stack("recipe", slot, ItemStack(""))
							end
						end
					end
					after_recipe_change(pos,inv)
				elseif msg == "get_recipe" then
					local meta = core.get_meta(pos)
					local inv = meta:get_inventory()
					local recipe = {}
					for y = 0, 2, 1 do
						local row = {}
						for x = 1, 3, 1 do
							local slot = y * 3 + x
							table.insert(row, inv:get_stack(
									"recipe", slot):get_name())
						end
						table.insert(recipe, row)
					end
					local setchan = meta:get_string("channel")
					local output = inv:get_stack("output", 1)
					digilines.receptor_send(pos, digilines.rules.default, setchan, {
						recipe = recipe,
						result = {
							name = output:get_name(),
							count = output:get_count(),
						}
					  })
				elseif msg == "off" then
					update_meta(meta, false)
					core.get_node_timer(pos):stop()
				elseif msg == "on" then
					if update_meta(meta, true) then
						start_crafter(pos)
					end
				elseif msg == "single" then
					run_autocrafter(pos,1)
				end
			end,
		},
	},
})

-- autocrafter fluid stuff
local autocraftername = "pipeworks:autocrafter"
pipeworks.flowables.register.simple(autocraftername)
pipeworks.flowables.register.output(autocraftername, 0, 0, function(pos, node, currentpressure, finitemode, fluid_type)
	if fluid_type == nil  then return 0, fluid_type end -- you can't put empty in something and expect displacement
	local meta = core.get_meta(pos)
	local fluid_cap = meta:get_float("fluidcap")
	local fluid_amount = meta:get_float("fluidamount")
	local current_fluid_type = meta:get("fluidtype")
	if current_fluid_type ~= fluid_type then
		if fluid_amount == 0 then
			meta:set_string("fluidtype", fluid_type)
		else
			return 0, fluid_type
		end
	end
	local taken = math.min(fluid_cap - fluid_amount, currentpressure)
	meta:set_float("fluidamount", fluid_amount + taken)
	update_meta(meta, meta:get_int("enabled") == 1)
	return taken, fluid_type
end, function()end)

pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list + 1] = autocraftername
