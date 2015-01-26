local autocrafterCache = {}  -- caches some recipe data to avoid to call the slow function minetest.get_craft_result() every second

local function count_index(invlist)
	local index = {}
	for _, stack in ipairs(invlist) do
		local stack_name = stack:get_name()
		index[stack_name] = (index[stack_name] or 0) + stack:get_count()
	end
	return index
end

local function get_cached_craft(pos)
	local hash = minetest.hash_node_position(pos)
	return hash, autocrafterCache[hash]
end

-- note, that this function assumes allready being updated to virtual items
-- and doesn't handle recipes with stacksizes > 1
local function on_recipe_change(pos, inventory)
	if not inventory then return end
	local recipe = inventory:get_list("recipe")
	if not recipe then return end

	local recipe_changed = false
	local hash, craft = get_cached_craft(pos)

	if not craft then
		recipe_changed = true
	else
		-- check if it changed
		local cached_recipe =  craft.recipe
		for i = 1, 9 do
			if recipe[i]:get_name() ~= cached_recipe[i]:get_name() then
				recipe_changed = true
				break
			end
		end
	end

	if recipe_changed then
		local output, decremented_input = minetest.get_craft_result({method = "normal", width = 3, items = recipe})
		craft = {recipe = recipe, output = output, decremented_input = decremented_input}
		autocrafterCache[hash] = craft
	end

	return craft
end

local function update_autocrafter(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("virtual_items") == "" then
		meta:set_string("virtual_items", "1")
		local inv = meta:get_inventory()
		for idx, stack in ipairs(inv:get_list("recipe")) do
			minetest.item_drop(stack, "", pos)
			stack:set_count(1)
			stack:set_wear(0)
			inv:set_stack("recipe", idx, stack)
		end
		on_recipe_change(pos, inv)
	end
end

local function autocraft(inventory, pos)
	if not inventory then return end
	local recipe = inventory:get_list("recipe")
	if not recipe then return end

	local hash, craft = get_cached_craft(pos)
	if craft == nil then
		update_autocrafter(pos) -- only does some unnecessary calls for "old" autocrafters
		craft = on_recipe_change(pos, inventory)
	end

	local output_item = craft.output.item
	if output_item:is_empty() or not inventory:room_for_item("dst", output_item) then return end

	-- determine how much we have to consume each craft
	local consumption = {}
	for _, item in ipairs(recipe) do
		if item and not item:is_empty() then
			local item_name = item:get_name()
			consumption[item_name] = (consumption[item_name] or 0) + 1
		end
	end

	local inv_index = count_index(inventory:get_list("src"))
	-- check if we have enough materials available
	for itemname, number in pairs(consumption) do
		if (not inv_index[itemname]) or inv_index[itemname] < number then return end
	end

	-- consume materials
	for itemname, number in pairs(consumption) do
		for i = 1, number do -- We have to do that since remove_item does not work if count > stack_max
			inventory:remove_item("src", ItemStack(itemname))
		end
	end

	-- craft the result into the dst inventory and add any "replacements" as well
	inventory:add_item("dst", output_item)
	for i = 1, 9 do
		inventory:add_item("dst", craft.decremented_input.items[i])
	end
end

minetest.register_node("pipeworks:autocrafter", {
	description = "Autocrafter", 
	drawtype = "normal", 
	tiles = {"pipeworks_autocrafter.png"}, 
	groups = {snappy = 3, tubedevice = 1, tubedevice_receiver = 1}, 
	tube = {insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end, 
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end, 
		input_inventory = "dst", 
		connect_sides = {left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1}}, 
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"size[8,11]"..
				"list[current_name;recipe;0,0;3,3;]"..
				"list[current_name;src;0,3.5;8,3;]"..
				"list[current_name;dst;4,0;4,3;]"..
				"list[current_player;main;0,7;8,4;]")
		meta:set_string("infotext", "Autocrafter")
		meta:set_string("virtual_items", "1")
		local inv = meta:get_inventory()
		inv:set_size("src", 3*8)
		inv:set_size("recipe", 3*3)
		inv:set_size("dst", 4*3)
	end,
	on_punch = update_autocrafter,
	can_dig = function(pos, player)
		update_autocrafter(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return (inv:is_empty("src") and inv:is_empty("dst"))
	end, 
	after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end,
	after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
		autocrafterCache[minetest.hash_node_position(pos)] = nil
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		update_autocrafter(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		if listname == "recipe" then
			local stack_copy = ItemStack(stack)
			stack_copy:set_count(1)
			inv:set_stack(listname, index, stack_copy)
			on_recipe_change(pos, inv)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		update_autocrafter(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		if listname == "recipe" then
			inv:set_stack(listname, index, ItemStack(""))
			on_recipe_change(pos, inv)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		update_autocrafter(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		stack:set_count(count)
		if from_list == "recipe" then
			inv:set_stack(from_list, from_index, ItemStack(""))
			on_recipe_change(pos, inv)
			return 0
		elseif to_list == "recipe" then
			local stack_copy = ItemStack(stack)
			stack_copy:set_count(1)
			inv:set_stack(to_list, to_index, stack_copy)
			on_recipe_change(pos, inv)
			return 0
		else
			return stack:get_count()
		end
	end,
})

minetest.register_abm({nodenames = {"pipeworks:autocrafter"}, interval = 1, chance = 1, 
			action = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				autocraft(inv, pos)
			end
})
