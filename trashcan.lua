local S = core.get_translator("pipeworks")
local fs_helpers = pipeworks.fs_helpers

core.register_node("pipeworks:trashcan", {
	description = S("Trash Can"),
	drawtype = "normal",
	tiles = {
		"pipeworks_trashcan_bottom.png",
		"pipeworks_trashcan_bottom.png",
		"pipeworks_trashcan_side.png",
		"pipeworks_trashcan_side.png",
		"pipeworks_trashcan_side.png",
		"pipeworks_trashcan_side.png",
	},
	groups = {snappy = 3, tubedevice = 1, tubedevice_receiver = 1, dig_generic = 4, axey=1, handy=1, pickaxey=1},
	is_ground_content = false,
	_mcl_hardness=0.8,
	tube = {
		insert_object = function(pos, node, stack, direction)
			return ItemStack("")
		end,
		connect_sides = {left = 1, right = 1, front = 1, back = 1, top = 1, bottom = 1},
		priority = 1, -- Lower than anything else
	},
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local fs = table.concat({
			fs_helpers.prepends(10.25, 8.5),
			fs_helpers.node_label("pipeworks:trashcan"),
			fs_helpers.inv_list(4.625, 1.25, 1, 1, "trash"),
			fs_helpers.player_inv(0.25, 3.5),
		})
		meta:set_string("formspec", fs)
		meta:set_string("infotext", S("Trash Can"))
		meta:get_inventory():set_size("trash", 1)
	end,
	after_place_node = pipeworks.after_place,
	after_dig_node = pipeworks.after_dig,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		core.get_meta(pos):get_inventory():set_stack(listname, index, ItemStack(""))
	end,
})
pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = "pipeworks:trashcan"
