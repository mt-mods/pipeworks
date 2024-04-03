pipeworks.chests = {}

-- register a chest to connect with pipeworks tubes.
-- will autoconnect to tubes and add tube inlets to the textures
-- it is highly recommended to allow the user to change the "splitstacks" int (1 to enable) in the node meta
-- but that can't be done by this function

-- @param override: additional overrides, such as stuff to modify the node formspec
-- @param connect_sides: which directions the chests shall connect to
function pipeworks.override_chest(chestname, override, connect_sides)
	local old_def = minetest.registered_nodes[chestname]

	local tube_entry = "^pipeworks_tube_connection_wooden.png"
	override.tiles = override.tiles or old_def.tiles
	-- expand the tiles table if it has been shortened
	if #override.tiles < 6 then
		for i = #override.tiles, 6 do
			override.tiles[i] = override.tiles[#override.tiles]
		end
	end
	-- add inlets to the sides that connect to tubes
	local tile_directions = {"top", "bottom", "right", "left", "back", "front"}
	for i, direction in ipairs(tile_directions) do
		if connect_sides[direction] then
			if type(override.tiles[i]) == "string" then
				override.tiles[i] = override.tiles[i] .. tube_entry
			elseif type(override.tiles[i]) == "table" and not override.tiles[i].animation then
				override.tiles[i].name = override.tiles[i].name .. tube_entry
			end
		end
	end

	local old_after_place_node = override.after_place_node or old_def.after_place_node or function()  end
	override.after_place_node = function(pos, placer)
		old_after_place_node(pos, placer)
		pipeworks.after_place(pos)
	end

	local old_after_dig = override.after_dig or old_def.after_dig or function()  end
	override.after_dig_node = function(pos, oldnode, oldmetadata, digger)
		old_after_dig(pos, oldnode, oldmetadata, digger)
		pipeworks.after_dig(pos, oldnode, oldmetadata, digger)
	end

	local old_on_rotate
	if override.on_rotate ~= nil then
		old_on_rotate = override.on_rotate
	elseif old_def.on_rotate ~= nil then
		old_on_rotate = old_def.on_rotate
	else
		old_on_rotate = function()  end
	end
	-- on_rotate = false -> rotation disabled, no need to update tubes
	-- everything else: undefined by the most common screwdriver mods
	if type(old_on_rotate) == "function" then
		override.on_rotate = function(pos, node, user, mode, new_param2)
			if old_on_rotate(pos, node, user, mode, new_param2) ~= false then
				return pipeworks.on_rotate(pos, node, user, mode, new_param2)
			else
				return false
			end
		end
	end

	override.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if meta:get_int("splitstacks") == 1 then
				stack = stack:peek_item(1)
			end
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = connect_sides
	}

	-- Add the extra groups
	override.groups = override.groups or old_def.groups or {}
	override.groups.tubedevice = 1
	override.groups.tubedevice_receiver = 1

	minetest.override_item(chestname, override)
	pipeworks.chests[chestname] = true
end

-- this bit of code modifies the default and hades chests to be compatible
-- with pipeworks.

local fs_helpers = pipeworks.fs_helpers

-- formspec helper to add the splitstacks switch
local function add_pipeworks_switch(formspec, pos)
	-- based on the sorting tubes
	formspec = formspec ..
			fs_helpers.cycling_button(
				minetest.get_meta(pos),
				pipeworks.button_base,
				"splitstacks",
				{
					pipeworks.button_off,
					pipeworks.button_on
				}
			)..pipeworks.button_label
	return formspec
end

-- helper to add the splitstacks switch to a node-formspec
local function update_node_formspec(pos)
	local meta = minetest.get_meta(pos)
	local old_fs = meta:get_string("formspec")
	local new_fs = add_pipeworks_switch(old_fs, pos)
	meta:set_string("formspec", new_fs)
end


if minetest.get_modpath("default") then
	-- add the pipeworks switch into the default chest formspec
	local old_get_chest_formspec = default.chest.get_chest_formspec
	-- luacheck: ignore 122
	default.chest.get_chest_formspec = function(pos)
		local old_fs = old_get_chest_formspec(pos)
		local node = minetest.get_node(pos)
		-- not all chests using this formspec necessary connect to pipeworks
		if pipeworks.chests[node.name] then
			local new_fs = add_pipeworks_switch(old_fs, pos)
			return new_fs
		else
			return old_fs
		end
	end

	-- get the fields from the chest formspec, we can do this bc. newest functions are called first
	-- https://github.com/minetest/minetest/blob/d4b10db998ebeb689b3d27368e30952a42169d03/doc/lua_api.md?plain=1#L5840
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname == "default:chest" then
			local pn = player:get_player_name()
			local pos = default.chest.open_chests[pn].pos
			local chest = pos and minetest.get_node(pos)
			local is_pipeworks_chest = chest and pipeworks.chests[chest]
			if is_pipeworks_chest and not fields.quit and pipeworks.may_configure(pos, player) then
				-- Pipeworks Switch
				fs_helpers.on_receive_fields(pos, fields)
				minetest.show_formspec(player:get_player_name(),
						"default:chest",
						default.chest.get_chest_formspec(pos))
			end
			-- Do NOT return true here, the callback from default still needs to run
			return false
		end
	end)

	local connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1}
	local connect_sides_open = {left = 1, right = 1, back = 1, bottom = 1}

	pipeworks.override_chest("default:chest", {}, connect_sides)
	pipeworks.override_chest("default:chest_open", {}, connect_sides_open)
	pipeworks.override_chest("default:chest_locked", {}, connect_sides)
	pipeworks.override_chest("default:chest_locked_open", {}, connect_sides_open)
elseif minetest.get_modpath("hades_chests") then
	local chest_colors = {"", "white", "grey", "dark_grey", "black", "blue", "cyan", "dark_green", "green", "magenta",
						  "orange", "pink", "red", "violet", "yellow"}
	for _, color in ipairs(chest_colors) do
		local chestname = (color == "" and "hades_chests:chest")
				or "hades_chests:chest_" .. color
		local chestname_protected = (color == "" and "hades_chests:chest_locked")
				or "hades_chests:chest_" .. color .. "_locked"
		local old_def = minetest.registered_nodes[chestname]

		-- chest formspec-creation functions are local, we need to find other ways
		-- normal chests use node formspecs, we can hack into these
		local old_on_construct = old_def.on_construct
		local override = {
			on_construct = function(pos)
				old_on_construct(pos)
				update_node_formspec(pos)
			end,
			on_receive_fields = function(pos, formname, fields, player)
				if not fields.quit and pipeworks.may_configure(pos, player) then
					-- Pipeworks Switch
					fs_helpers.on_receive_fields(pos, fields)
					update_node_formspec(pos)
				end
			end,
			-- chest's on_rotate is "simple", but we assumed the api from the mtg screwdriver mod
			-- this will keep the same behavior, but supports the code above
			on_rotate = screwdriver.rotate_simple
		}

		-- locked chests uses local functions to create their formspec - we need to copy these
		-- https://codeberg.org/Wuzzy/Hades_Revisited/src/branch/master/mods/hades_chests/init.lua
		local function get_locked_chest_formspec(pos)
			local spos = pos.x .. "," .. pos.y .. "," ..pos.z
			local formspec =
				"size[10,9]"..
				"list[nodemeta:".. spos .. ";main;0,0;10,4;]"..
				"list[current_player;main;0,5;10,4;]"..
				"listring[]"..
				"background9[8,8;10,9;hades_chests_chestui.png;true;8]"

			-- change from pipeworks
			local new_fs = add_pipeworks_switch(formspec, pos)
			return new_fs
		end

		local function has_locked_chest_privilege(meta, player)
			local name = player:get_player_name()
			if name ~= meta:get_string("owner") and not minetest.check_player_privs(name, "protection_bypass") then
				return false
			end
			return true
		end

		-- store, which chest a formspec submission belongs to
		-- {player1 = pos1, player2 = pos2, ...}
		local open_chests = {}
		minetest.register_on_leaveplayer(function(player)
			open_chests[player:get_player_name()] = nil
		end)

		local override_protected = {
			on_rightclick = function(pos, node, clicker)
				local meta = minetest.get_meta(pos)
				if has_locked_chest_privilege(meta, clicker) then
					minetest.show_formspec(
							clicker:get_player_name(),
							"hades_chests:chest_locked",
							get_locked_chest_formspec(pos)
					)
					open_chests[clicker:get_player_name()] = pos
				else
					minetest.sound_play({ name = "hades_chests_locked", gain = 0.3 }, { max_hear_distance = 10 }, true)
				end
			end,
			on_rotate = screwdriver.rotate_simple
		}

		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname == "hades_chests:chest_locked" then
				local pn = player:get_player_name()
				local pos = open_chests[pn]
				if not fields.quit and pos and pipeworks.may_configure(pos, player) then
					-- Pipeworks Switch
					fs_helpers.on_receive_fields(pos, fields)
					minetest.show_formspec(pn, "hades_chests:chest_locked", get_locked_chest_formspec(pos))
				end
				-- Do NOT return true here, the callback from hades still needs to run (if they add one)
				return false
			end
		end)

		local connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1}
		pipeworks.override_chest(chestname, override, connect_sides)
		pipeworks.override_chest(chestname_protected, override_protected, connect_sides)
	end
end