local autocrafterCache = {}

function addCacheEntry(pos, recipe, result, new)
	if autocrafterCache[pos.x] == nil then autocrafterCache[pos.x] = {} end
	if autocrafterCache[pos.x][pos.y] == nil then autocrafterCache[pos.x][pos.y] = {} end
	if autocrafterCache[pos.x][pos.y][pos.z] == nil then autocrafterCache[pos.x][pos.z] = {} end
	autocrafterCache[pos.x][pos.y][pos.z] = {["recipe"] = recipe, ["result"] = result, ["new"] = new}
end

function getCacheEntry(pos)
	if autocrafterCache[pos.x] == nil then return nil, nil, nil end
	if autocrafterCache[pos.x][pos.y] == nil then return nil, nil, nil end
	if autocrafterCache[pos.x][pos.y][pos.z] == nil then return nil, nil, nil end
	return autocrafterCache[pos.x][pos.y][pos.z]["recipe"], autocrafterCache[pos.x][pos.y][pos.z]["result"], autocrafterCache[pos.x][pos.y][pos.z]["new"]
end

function autocraft(inventory, pos)
	local recipe = inventory:get_list("recipe")
		local recipe_last
		local result
		local new

		recipe_last, result, new = getCacheEntry(pos)
		if recipe_last ~= nil then
			local recipeUnchanged = true
			for i = 1, 9 do
				--print ("recipe_base"..i.." ")
				--print (recipe[i]:get_name())
				--print (recipe[i]:get_count())
				--print (recipe_last[i]:get_name())
				--print (recipe_last[i]:get_count())
				if recipe[i]:get_name() ~= recipe_last[i]:get_name() then
					recipeUnchanged = False
					break
				end
				if recipe[i]:get_count() ~= recipe_last[i]:get_count() then
					recipeUnchanged = False
					break
				end
			end
			if recipeUnchanged then
				-- print("autocrafter recipe unchanged")
			else
				print("autocrafter recipe changed at pos("..pos.x..","..pos.y..","..pos.z..")")
				for i = 1, 9 do
						recipe_last[i] = recipe[i]
						recipe[i] = ItemStack({name = recipe[i]:get_name(), count = 1})
				end
				result, new = minetest.get_craft_result({method = "normal", width = 3, items = recipe})
				addCacheEntry(pos, recipe_last, result, new)
			end
		else
			print("first call for this autocrafter at pos("..pos.x..","..pos.y..","..pos.z..")")
			recipe_last = {}
			for i = 1, 9 do
				recipe_last[i] = recipe[i]
				--print (recipe_last[i]:get_name())
				recipe[i] = ItemStack({name = recipe[i]:get_name(), count = 1})
			end
			result, new = minetest.get_craft_result({method = "normal", width = 3, items = recipe})
			addCacheEntry(pos, recipe_last, result, new)
		end

		local input = inventory:get_list("input")
	if result.item:is_empty() then return end
	result = result.item
	if not inventory:room_for_item("dst", result) then return end
	local to_use = {}
	for _, item in ipairs(recipe) do
		if item~= nil and not item:is_empty() then
			if to_use[item:get_name()] == nil then
				to_use[item:get_name()] = 1
			else
				to_use[item:get_name()] = to_use[item:get_name()]+1
			end
		end
	end
	local stack
	for itemname, number in pairs(to_use) do
		stack = ItemStack({name = itemname, count = number})
		if not inventory:contains_item("src", stack) then return end
	end
	for itemname, number in pairs(to_use) do
		stack = ItemStack({name = itemname, count = number})
		inventory:remove_item("src", stack)
	end
	inventory:add_item("dst", result)
	for i = 1, 9 do
		inventory:add_item("dst", new.items[i])
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
		local inv = meta:get_inventory()
		inv:set_size("src", 3*8)
		inv:set_size("recipe", 3*3)
		inv:set_size("dst", 4*3)
	end, 
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos); 
		local inv = meta:get_inventory()
		return (inv:is_empty("src") and inv:is_empty("recipe") and inv:is_empty("dst"))
	end, 
	after_place_node = tube_scanforobjects, 
	after_dig_node = tube_scanforobjects, 
})

minetest.register_abm({nodenames = {"pipeworks:autocrafter"}, interval = 1, chance = 1, 
			action = function(pos, node)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				autocraft(inv, pos)
			end
})
