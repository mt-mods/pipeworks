-- this bit of code modifies the default chests and furnaces to be compatible
-- with pipeworks.
--
-- the formspecs found here are basically copies of the ones from minetest_game
-- plus bits from pipeworks' sorting tubes

local fs_helpers = pipeworks.fs_helpers

tube_entry = "^pipeworks_tube_connection_wooden.png"

local base_chest_formspec = "size[8,9]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

local function update_chest_formspec(pos)
	local meta = minetest.get_meta(pos)
	local formspec = base_chest_formspec ..
		"list[current_name;main;0,0.3;8,4;]" ..
		"listring[current_name;main]" ..
		fs_helpers.cycling_button(
			meta,
			pipeworks.button_base,
			"splitstacks",
			{
				pipeworks.button_off,
				pipeworks.button_on
			}
		)..pipeworks.button_label
	meta:set_string("formspec", formspec)
end

minetest.override_item("default:chest", {
	tiles = {
		"default_chest_top.png"..tube_entry,
		"default_chest_top.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_front.png"
	},
	groups = {choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1},
	tube = {
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
		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
	},
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		update_chest_formspec(pos)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not pipeworks.may_configure(pos, sender) then return end
		fs_helpers.on_receive_fields(pos, fields)
		update_chest_formspec(pos)
	end,
})

-- =====================

local function get_locked_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec = base_chest_formspec ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"listring[nodemeta:" .. spos .. ";main]"
	return formspec
end

local function setup_locked_formspec(pos, meta)
	meta:set_string("formspec",
		get_locked_chest_formspec(pos) ..
		fs_helpers.cycling_button(
			meta,
			pipeworks.button_base,
			"splitstacks",
			{
				pipeworks.button_off,
				pipeworks.button_on
			}
		)..pipeworks.button_label
	)
end

minetest.override_item("default:chest_locked", {
	tiles = {
		"default_chest_top.png"..tube_entry,
		"default_chest_top.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_side.png"..tube_entry,
		"default_chest_lock.png"
	},
	groups = {choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1, tubedevice_receiver = 1},
	tube = {
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
		connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
	},
	after_place_node = function (pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Locked Chest (owned by "..
		meta:get_string("owner")..")")
		pipeworks.after_place(pos)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if default.can_interact_with_node(clicker, pos) then
			local meta = minetest.get_meta(pos)
			local formspec = meta:get_string("formspec")
			print("on_rightclick")
			print(dump(formspec))
			setup_locked_formspec(pos, meta, clicker)
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				get_locked_chest_formspec(pos)
			)
		end
		return itemstack
	end,
	on_key_use = function(pos, player)
		local secret = minetest.get_meta(pos):get_string("key_lock_secret")
		local itemstack = player:get_wielded_item()
		local key_meta = itemstack:get_meta()

		if key_meta:get_string("secret") == "" then
			key_meta:set_string("secret", minetest.parse_json(itemstack:get_metadata()).secret)
			itemstack:set_metadata("")
		end

		if secret ~= key_meta:get_string("secret") then
			return
		end
		setup_locked_formspec(pos, minetest.get_meta(pos))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		setup_locked_formspec(pos, meta)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if not pipeworks.may_configure(pos, sender) then return end
		fs_helpers.on_receive_fields(pos, fields)
		local formspec = get_locked_chest_formspec(pos)
		print("on_receive_fields")
		print(dump(formspec))

		if formspec == "" then
			meta:set_string("formspec", formspec)
		else
			setup_locked_formspec(pos, minetest.get_meta(pos))
		end
	end,
	after_dig_node = pipeworks.after_dig
})
