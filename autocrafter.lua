
local S = core.get_translator("pipeworks")

local has_digilines = core.get_modpath("digilines")

-- Autocrafter rate-limiting settings
local craft_time = tonumber(core.settings:get("pipeworks_autocrafter_craft_time")) or 1
local batch_size = tonumber(core.settings:get("pipeworks_autocrafter_catch_up_batch_size")) or 100

-- Cache of fake player and recipe items used by each autocrafter
local autocrafter_cache = {}

-- Index of group items used in recipes, self-populating when accessed
local group_index = {}

----------------------
-- Helper functions --
----------------------

-- Turns any list of items or groups into a list of nine itemstacks
local function normalize_items(items)
	for i=1, 9 do
		local item = items[i]
		local t = type(item)
		if t == "string" then
			if item:sub(1, 6) == "group:" then
				-- Swap out the group for its representative
				if not group_index[item] then
					return
				end
				items[i] = ItemStack(group_index[item].icon)
			elseif not core.registered_items[item] then
				return
			else
				items[i] = ItemStack(item)
			end
		elseif t ~= "userdata" then
			-- Fill the gap
			items[i] = ItemStack("")
		end
	end
	return items
end

-- Stacks identical items with eachother and removes empty stacks
local function stack_items(items)
	local stacked = {}
	for _,item in ipairs(items) do
		for _,stack in ipairs(stacked) do
			item = stack:add_item(item)
		end
		if not item:is_empty() then
			stacked[#stacked+1] = item
		end
	end
	return stacked
end

-- Adds items to an inventory list the same way as InvRef.add_item()
local function add_to_list(list, stack)
	local empty = {}
	for _,s in ipairs(list) do
		if s:is_empty() then
			empty[#empty+1] = s
		else
			stack = s:add_item(stack)
			if stack:is_empty() then
				return true
			end
		end
	end
	for _,s in ipairs(empty) do
		stack = s:add_item(stack)
		if stack:is_empty() then
			return true
		end
	end
	return false
end

-- Checks if an item can be added to a list without using empty slots
local function can_stack_in_list(list, stack)
	for _,item in ipairs(list) do
		if not item:is_empty() and item:item_fits(stack) then
			return true
		end
	end
	return false
end

-- Makes recipes with width 1-2 fit the 3x3 grid correctly
local function widen_recipe(items, width)
	if width == 1 and #items > 1 then
		items[4], items[2] = items[2], nil
		items[7], items[3] = items[3], nil
	elseif width == 2 then
		items[3], items[4], items[5], items[7] = nil, items[3], items[4], items[5]
		items[8], items[6] = items[6], nil
	end
	-- Width 0 is shapeless, width 3 doesn't need widening
	return items
end

----------------------
-- Autocrafter code --
----------------------

local function get_cache(pos)
	local hash = core.hash_node_position(pos)
	local cache = autocrafter_cache[hash]
	if not cache then
		cache = {}
		autocrafter_cache[hash] = cache
	end
	return cache
end

local function invalidate_cache(pos)
	local hash = core.hash_node_position(pos)
	autocrafter_cache[hash] = nil
end

local function get_fake_player(pos)
	local cache = get_cache(pos)
	local fake_player = cache.fake_player
	if not fake_player then
		local fake_inv = fakelib.create_inventory({craft = 9})
		fake_player = fakelib.create_player({inventory = fake_inv})
		cache.fake_player = fake_player
	end
	return fake_player
end

local function get_craft_result(items, fake_player)
	local output, leftover = core.get_craft_result({method = "normal", width = 3, items = items})
	output, leftover = output.item, leftover.items
	if output:is_empty() then
		return
	end
	-- Execute on_craft callbacks using a fake inventory and player
	local fake_inv = fake_player:get_inventory()
	fake_inv:set_list("craft", leftover)
	output = core.on_craft(output, fake_player, items, fake_inv)
	if output:is_empty() then
		return
	end
	-- Split additional outputs from replacement items
	local recipe_items = {}
	for _,item in ipairs(items) do
		recipe_items[item:get_name()] = true
	end
	local outputs, replacements = {output}, {}
	for _,stack in ipairs(fake_inv:get_list("craft")) do
		if not stack:is_empty() then
			if recipe_items[stack:get_name()] then
				table.insert(replacements, stack)
			else
				table.insert(outputs, stack)
			end
		end
	end
	return outputs, replacements
end

local function start_autocrafter(pos)
	local meta = core.get_meta(pos)
	if meta:get_int("enabled") == 1 or meta:get_int("queued") > 0 then
		local timer = core.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(craft_time)
		end
	end
end

local function set_craft(pos, recipe, output)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_stack("output", 1, output)
	inv:set_list("recipe", recipe)
	get_cache(pos).required_items = nil
	local desc = output:get_short_description()
	local name = output:get_name()
	meta:set_string("infotext", S("'@1' Autocrafter (@2)", desc, name))
	start_autocrafter(pos)
end

local function set_craft_by_input(pos, input)
	local recipe = normalize_items(input)
	if not recipe then
		return
	end
	local outputs = get_craft_result(recipe, get_fake_player(pos))
	if not outputs then
		return
	end
	set_craft(pos, recipe, outputs[1])
	return true
end

local function set_craft_by_output(pos, output)
	local recipes = core.get_all_craft_recipes(output:get_name())
	if not recipes then
		return
	end
	local best_score, best_recipe = 0
	for _,recipe in ipairs(recipes) do
		if recipe.type == "normal" then
			-- Recipes with fewer items score higher
			local score = 10 - #recipe.items
			-- Recipes with more yeild are better
			score = score + ItemStack(recipe.output):get_count()
			for _,item in ipairs(recipe.items) do
				if item == output then
					-- Avoid dyeing/repairing recipes
					score = 0 ; break
				elseif item:sub(1, 6) == "group:" then
					 -- Recipes that use groups are better
					score = score + 1
				elseif not core.registered_items[item] then
					-- Never use a recipe with an unknown item
					score = -1 ; break
				elseif core.get_item_group(item, "not_in_creative_inventory") > 0 then
					-- Avoid recipes using hidden items, e.g. slabs to full blocks
					score = 1 ; break
				end
			end
			if score > best_score or not best_recipe and score >= 0 then
				best_score = score
				best_recipe = recipe
			end
		end
	end
	if not best_recipe then
		return
	end
	local items = widen_recipe(best_recipe.items, best_recipe.width)
	return set_craft_by_input(pos, items)
end

local function get_ingredients(src, recipe)
	local items = {}
	for i, stack in ipairs(src) do
		if not stack:is_empty() then
			items[i] = stack:get_name()
		end
	end
	local ingredients = {}
	for i, item in ipairs(recipe) do
		if item:is_empty() then
			ingredients[i] = ItemStack("")
		else
			local found = false
			local match_items = {[item:get_name()] = true}
			local group = item:get_meta():get("group")
			if group and group_index[group] then
				match_items = group_index[group].items
			end
			for j, name in pairs(items) do
				if match_items[name] then
					ingredients[i] = src[j]:take_item()
					if src[j]:is_empty() then
						items[j] = nil
					end
					found = true ; break
				end
			end
			if not found then
				-- Abort if any ingredient is missing
				return
			end
		end
	end
	return ingredients
end

local function autocraft(inv, recipe, fake_player, keep_items)
	local src = inv:get_list("src")
	local ingredients = get_ingredients(src, recipe)
	if not ingredients then
		return
	end
	local outputs, replacements = get_craft_result(ingredients, fake_player)
	if not outputs then
		-- Broken recipe, clear the output
		inv:set_stack("output", 1, "")
		return
	end
	-- Put the outputs in the lists, not directly in the inventory
	local dst = inv:get_list("dst")
	local list = keep_items > 1 and src or dst
	for _,item in ipairs(outputs) do
		if not add_to_list(list, item) then
			return
		end
	end
	if #replacements > 0 then
		list = keep_items > 0 and src or dst
		for _,item in ipairs(replacements) do
			if not add_to_list(list, item) then
				return
			end
		end
	end
	-- Crafting was sucessful, so the modified lists can be saved
	inv:set_list("src", src)
	inv:set_list("dst", dst)
	return true
end

local function reset_autocrafter(pos)
	core.get_node_timer(pos):stop()
	local meta = core.get_meta(pos)
	meta:set_string("infotext", S("Unconfigured Autocrafter"))
	meta:get_inventory():set_stack("output", 1, "")
	meta:set_int("queued", 0)
	meta:set_int("catch_up", 0)
	invalidate_cache(pos)
end

local function run_autocrafter(pos, elapsed)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if inv:is_empty("output") then
		return false
	end
	local enabled = meta:get_int("enabled") == 1
	local queued = meta:get_int("queued")
	local crafts_remaining = meta:get_int("catch_up") + math.floor(elapsed / craft_time)
	if not enabled then
		if queued == 0 then
			return false
		end
		crafts_remaining = math.min(crafts_remaining, queued)
	end
	local recipe = inv:get_list("recipe")
	local fake_player = get_fake_player(pos)
	local keep_items = meta:get_int("keep_items")
	local continue = true
	for _=1, math.min(crafts_remaining, batch_size) do
		if not autocraft(inv, recipe, fake_player, keep_items) then
			crafts_remaining = 0
			continue = false
			break
		end
		crafts_remaining = crafts_remaining - 1
		queued = queued - 1
	end
	meta:set_int("catch_up", crafts_remaining)
	meta:set_int("queued", enabled and 0 or queued)
	-- Send a digiline message when the queued crafts have completed
	if has_digilines and not enabled and queued == 0 then
		local channel = meta:get_string("channel")
		digilines.receptor_send(pos, digilines.rules.default, channel, {finished = true})
	end
	return continue and (enabled or crafts_remaining > 0 or queued > 0)
end

local function update_formspec(meta)
	local list_backgrounds = ""
	if core.get_modpath("i3") or core.get_modpath("mcl_formspec") then
		list_backgrounds = "style_type[box;colors=#666]"
		for i = 0, 2 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					0.22 + (i * 1.25) .. "," .. 0.22 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 3 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					5.28 + (i * 1.25) .. "," .. 0.22 + (j * 1.25) .. ";1,1;]"
			end
		end
		for i = 0, 7 do
			for j = 0, 2 do
				list_backgrounds = list_backgrounds .. "box[" ..
					0.22 + (i * 1.25) .. "," .. 5.2 + (j * 1.25) .. ";1,1;]"
			end
		end
	end
	local state = meta:get_int("enabled") == 1 and "on" or "off"
	local keep_items = meta:get_int("keep_items")
	local text = S(({"Output all items", "Keep non-consumables", "Keep all items"})[keep_items+1])
	local size = "10.2,14.2"
	local fs =
		"formspec_version[2]".."size["..size.."]"..
		pipeworks.fs_helpers.get_prepends(size)..
		list_backgrounds..
		"list[context;recipe;0.22,0.22;3,3;]"..
		"image[4,1.45;1,1;[combine:16x16^[noalpha^[colorize:#141318:255]"..
		"list[context;output;4,1.45;1,1;]" ..
		"image_button[4,0.45;1,0.6;pipeworks_button_"..state..".png;"..
		state..";;;false;pipeworks_button_interm.png]"..
		"image_button[4,2.75;1,1;pipeworks_arrow_"..keep_items..".png;keep_items;;;false;]"..
		"tooltip[keep_items;"..text.."]"..
		"list[context;dst;5.28,0.22;4,3;]"..
		"list[context;src;0.22,5.2;8,3;]"..
		pipeworks.fs_helpers.get_inv(9.2)..
		"listring[current_player;main]"..
		"listring[context;src]"..
		"listring[current_player;main]"..
		"listring[context;dst]"..
		"listring[current_player;main]"..
		"listring[context;recipe]"..
		"listring[current_player;main]"..
		"listring[context;output]"..
		"listring[current_player;main]"
	if has_digilines then
		fs = fs.."field[0.5,4.2;5,0.75;channel;"..S("Digilines Channel")..";${channel}]"..
			"button[5.6,4.2;2,0.75;set_channel;"..S("Set").."]"..
			"button_exit[7.7,4.2;2,0.75;close;"..S("Close").."]"
	end
	meta:set_string("formspec", fs)
end

local function receive_fields(pos, _, fields, player)
	if (fields.quit and not fields.key_enter_field) or not pipeworks.may_configure(pos, player) then
		return
	end
	local meta = core.get_meta(pos)
	if fields.on then
		meta:set_int("enabled", 0)
		update_formspec(meta)
		core.get_node_timer(pos):stop()
	elseif fields.off then
		meta:set_int("enabled", 1)
		update_formspec(meta)
		start_autocrafter(pos)
	end
	if fields.channel then
		meta:set_string("channel", fields.channel)
	end
	if fields.keep_items then
		local keep = (meta:get_int("keep_items") + 1) % 3
		meta:set_int("keep_items", keep)
		update_formspec(meta)
	end
end

local function get_required_items(pos)
	local cache = get_cache(pos)
	local items = cache.required_items
	if not items then
		local inv = core.get_meta(pos):get_inventory()
		items = stack_items(inv:get_list("recipe"))
		-- Swap each item or group with an index of matching items
		for i, item in ipairs(items) do
			local match_items = {[item:get_name()] = true}
			local group = item:get_meta():get("group")
			if group and group_index[group] then
				match_items = group_index[group].items
			end
			items[i] = match_items
		end
		cache.required_items = items
	end
	return items
end

local function get_outputs(pos)
	local cache = get_cache(pos)
	local outputs = cache.outputs
	if not outputs then
		local inv = core.get_meta(pos):get_inventory()
		local recipe = inv:get_list("recipe")
		outputs = get_craft_result(recipe, get_fake_player(pos))
	end
	return outputs
end

local function can_insert_stack(pos, stack)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:room_for_item("src", stack) then
		return false
	end
	if inv:is_empty("output") then
		-- No recipe, so accept all items
		return true
	end
	local src = inv:get_list("src")
	if can_stack_in_list(src, stack) then
		-- The incoming item stacks with an existing item
		return true
	end
	local required_items = get_required_items(pos)
	local empty = 0
	-- Also account for outputs if they are being kept
	-- Replacements don't need space because they will replace themselves
	if meta:get_int("keep_items") == "2" then
		local outputs = get_outputs(pos)
		if outputs then
			for i, item in ipairs(outputs) do
				if not can_stack_in_list(src, item) then
					empty = empty - 1
				end
			end
		end
	end
	-- Loop backwards to find empty slots quicker
	for i=#src, 1, -1 do
		local item = src[i]
		if item:is_empty() then
			empty = empty + 1
		else
			local name = item:get_name()
			local copy = ItemStack(item)
			for i, match_items in pairs(required_items) do
				if match_items[name] then
					copy:take_item()
					required_items[i] = nil
					if copy:is_empty() then
						break
					end
				end
			end
			if #required_items == 0 then
				return true
			end
		end
		if empty > #required_items then
			return true
		end
	end
	-- At this point there are recipe items missing and not enough empty slots,
	-- so only accept the stack if it is one of the missing items.
	local name = stack:get_name()
	for _,match_items in pairs(required_items) do
		if match_items[name] then
			return true
		end
	end
	return false
end

local function parse_recipe(msg)
	local recipe = {}
	if #msg < 3 then
		return
	end
	for y = 0, 2, 1 do
		local row = msg[y + 1]
		if type(row) == "table" then
			for x = 1, 3, 1 do
				local slot = y * 3 + x
				recipe[slot] = row[x]
			end
		end
	end
	return recipe
end

local function format_recipe(list)
	local recipe = {}
	for y = 0, 2, 1 do
		local row = {}
		for x = 1, 3, 1 do
			local slot = y * 3 + x
			local item = list[slot]
			item = item:get_meta():get("group") or item:get_name()
			table.insert(row, item)
		end
		table.insert(recipe, row)
	end
	return recipe
end

local function digilines_action(pos, _, channel, msg)
	local meta = core.get_meta(pos)
	if channel ~= meta:get_string("channel") then
		return
	end
	local inv = meta:get_inventory()
	if type(msg) == "string" then
		if msg == "single" then
			msg = {command = "craft", amount = 1}
		elseif msg == "on" then
			msg = {command = "set", active = true}
		elseif msg == "off" then
			msg = {command = "set", active = false}
		elseif msg == "get_recipe" then
			msg = {command = "get"}
		else
			msg = {command = msg}
		end
	elseif type(msg) ~= "table" then
		return
	end
	if not msg.command and #msg > 0 then
		msg = {command = "set", recipe = msg}
	end
	if msg.command == "get" then
		local output = inv:get_stack("output", 1)
		local keep_items = ({"none", "replacements", "all"})[meta:get_int("keep_items")+1]
		digilines.receptor_send(pos, digilines.rules.default, channel, {
			recipe = format_recipe(inv:get_list("recipe")),
			result = {name = output:get_name(), count = output:get_count()},
			keep_items = keep_items,
			active = meta:get_int("enabled") == 1,
		})
	elseif msg.command == "set" then
		local start = false
		if msg.recipe or type(msg.input) == "table" then
			local recipe = msg.input or parse_recipe(msg.recipe)
			if recipe and set_craft_by_input(pos, recipe) then
				start = true
			end
		elseif msg.output then
			local output = ItemStack(msg.output)
			if not output:is_empty() and set_craft_by_output(pos, output) then
				start = true
			end
		end
		if msg.active ~= nil then
			meta:set_int("enabled", msg.active and 1 or 0)
			if msg.active then
				start = true
			end
		end
		if msg.keep_items then
			local keep_items = ({none = 0, replacements = 1, all = 2})[msg.keep_items]
			if keep_items then
				meta:set_int("keep_items", keep_items)
				update_formspec(meta)
			end
		end
		if start then
			start_autocrafter(pos)
		end
	elseif msg.command == "craft" and meta:get_int("enabled") ~= 1 then
		local amount = math.max(tonumber(msg.amount) or 1, 1) + meta:get_int("queued")
		meta:set_int("queued", amount)
		start_autocrafter(pos)
	elseif msg.command == "purge" then
		for i, stack in ipairs(inv:get_list("src")) do
			local item = type(msg.item) == "string" and msg.item or nil
			if not stack:is_empty() and (not item or stack:get_name() == item) then
				inv:set_stack("src", i, inv:add_item("dst", stack))
			end
		end
	end
	return
end

core.register_node("pipeworks:autocrafter", {
	description = S("Autocrafter"),
	drawtype = "normal",
	tiles = {"pipeworks_autocrafter.png"},
	groups = {
		snappy = 3, tubedevice = 1, tubedevice_receiver = 1,
		dig_generic = 1, axey = 1, handy = 1, pickaxey = 1
	},
	is_ground_content = false,
	_mcl_hardness = 0.8,
	tube = {
		insert_object = function(pos, node, stack, direction)
			local inv = core.get_meta(pos):get_inventory()
			local leftover = inv:add_item("src", stack)
			start_autocrafter(pos)
			return leftover
		end,
		can_insert = function(pos, node, stack, direction)
			return can_insert_stack(pos, stack)
		end,
		input_inventory = "dst",  -- Actually the output inventory
		connect_sides = {left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1},
	},
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_int("keep_items", 1)
		local inv = meta:get_inventory()
		inv:set_size("src", 3 * 8)
		inv:set_size("recipe", 3 * 3)
		inv:set_size("dst", 4 * 3)
		inv:set_size("output", 1)
		update_formspec(meta)
	end,
	can_dig = function(pos, player)
		local inv = core.get_meta(pos):get_inventory()
		return inv:is_empty("src") and inv:is_empty("dst")
	end,
	after_place_node = pipeworks.scan_for_tube_objects,
	after_dig_node = pipeworks.scan_for_tube_objects,
	on_receive_fields = receive_fields,
	on_destruct = invalidate_cache,
	allow_metadata_inventory_put = function(pos, list, index, stack, player)
		if not pipeworks.may_configure(pos, player) then
			return 0
		end
		local inv = core.get_meta(pos):get_inventory()
		if list == "recipe" then
			inv:set_stack(list, index, ItemStack(stack:get_name()))
			if not set_craft_by_input(pos, inv:get_list("recipe")) then
				reset_autocrafter(pos)
			end
			return 0
		elseif list == "output" then
			if not set_craft_by_output(pos, stack) then
				reset_autocrafter(pos)
			end
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, list, index, stack, player)
		if not pipeworks.may_configure(pos, player) then
			return 0
		end
		local inv = core.get_meta(pos):get_inventory()
		if list == "recipe" then
			inv:set_stack(list, index, "")
			if not set_craft_by_input(pos, inv:get_list("recipe")) then
				reset_autocrafter(pos)
			end
			return 0
		elseif list == "output" then
			inv:set_list("recipe", {})
			inv:set_list("output", {})
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if not pipeworks.may_configure(pos, player) then
			return 0
		end
		local inv = core.get_meta(pos):get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		if to_list == "output" then
			if not set_craft_by_output(pos, stack) then
				reset_autocrafter(pos)
			end
			return 0
		elseif from_list == "output" then
			inv:set_list("recipe", {})
			inv:set_list("output", {})
			return 0
		end
		if from_list == "recipe" or to_list == "recipe" then
			if from_list == "recipe" then
				inv:set_stack(from_list, from_index, "")
			end
			if to_list == "recipe" then
				inv:set_stack(to_list, to_index, ItemStack(stack:get_name()))
			end
			if not set_craft_by_input(pos, inv:get_list("recipe")) then
				reset_autocrafter(pos)
			end
			return 0
		end
		return count
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if from_list == "dst" and to_list == "src" then
			start_autocrafter(pos)
		end
	end,
    on_metadata_inventory_put = function(pos, list, index, stack, player)
		if list == "src" then
			start_autocrafter(pos)
		end
	end,
	on_metadata_inventory_take = function(pos, list, index, stack, player)
		if list == "dst" then
			start_autocrafter(pos)
		end
	end,
	on_timer = run_autocrafter,
	digilines = {
		receptor = {},
		effector = {
			action = digilines_action,
		},
	},
})
table.insert(pipeworks.ui_cat_tube_list, "pipeworks:autocrafter")

-- V1 had actual items in the crafting grid,
-- V2 replaced these with virtual items, dropped the content on update and set "virtual_items" to string "1",
-- V3 added an output inventory and changed the formspec, adding a button for enabling/disabling,
-- V4 changed the formspec again, adding a button for changing what items to output.
local function upgrade_autocrafter(pos)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if inv:get_size("output") == 0 then  -- V1 or V2
		inv:set_size("output", 1)
		inv:set_size("recipe", 9)
		meta:set_int("enabled", 1)
		if meta:get_string("virtual_items") == "1" then  -- V2
			meta:set_string("virtual_items", "")
		else  -- V1
			local recipe = inv:get_list("recipe")
			for i, stack in ipairs(recipe) do
				if not stack:is_empty() then
					core.add_item(pos, stack)
					inv:set_stack("recipe", i, stack:get_name())
				end
			end
		end
		set_craft_by_input(pos, inv:get_list("recipe"))
	end
	update_formspec(meta)
end

core.register_lbm({
    label = "Autocrafter Upgrade",
    name = "pipeworks:autocrafter_upgrade",
    nodenames = {"pipeworks:autocrafter"},
    run_at_every_load = false,
    action = upgrade_autocrafter,
})

----------------------
-- Group index code --
----------------------

local is_core_mod = {
	default = true,    -- Minetest Game
	mcl_core = true,   -- Mineclone/Mineclonia
	hades_core = true, -- Hades Revisited
}

local function get_group_icon(group, items, count)
	if count == 1 then
		-- Only one item in group, return a normal item
		return ItemStack(next(items))
	end
	-- Find the best representative for this group
	local is_group = {}
	for _,g in ipairs(group:sub(7):split(",")) do
		is_group[g] = true
	end
	local best_score, best_item = 0, next(items)
	for item in pairs(items) do
		if core.get_item_group(item, "not_in_creative_inventory") == 0 then
			local score = 1
			local mod, name = item:match("^([^:]+):(.+)$")
			if is_group[mod] and is_group[name] then
				score = 5
			elseif is_core_mod[mod] and is_group[name] then
				score = 4
			elseif is_group[name] then
				score = 3
			elseif is_group[mod] and name:find("white") then
				score = 2
			end
			if score > best_score or (score == best_score and #item < #best_item) then
				best_item = item
				best_score = score
			end
		end
	end
	-- Create a special group item
	local icon = ItemStack({
		name = best_item,
		meta = {
			description = group,
			group = group,
			count_meta = "G",
			count_alignment = "10",
		},
	})
	return icon
end

local function get_group_items(group)
	local groups = group:sub(7):split(",")
	local items, count = {}, 0
	for name, def in pairs(core.registered_items) do
		-- The item must have all the required groups, e.g. "group:dye,color_red"
		local all_matching = true
		for _,g in ipairs(groups) do
			if not def.groups[g] or def.groups[g] == 0 then
				all_matching = false
				break
			end
		end
		if all_matching then
			items[name] = true
			count = count + 1
		end
	end
	return items, count
end

local function find_group(t, group)
	local found = false
	local items, count = get_group_items(group)
	if count > 0 then
		found = {items = items, icon = get_group_icon(group, items, count)}
	end
	t[group] = found
	return found
end

-- Use a metatable to make access cleaner
setmetatable(group_index, {__index = find_group})
