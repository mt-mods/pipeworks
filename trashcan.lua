local S = minetest.get_translator("pipeworks")
local voidname = "pipeworks:trashcan"
minetest.register_node(voidname, {
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
	pipe_connections = { top = 1, bottom = 1, front = 1, back = 1, left = 1, right = 1},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local size = "10.2,9"
		local list_background = ""
		if minetest.get_modpath("i3") or minetest.get_modpath("mcl_formspec") then
			list_background = "style_type[box;colors=#666]box[4.5,2;1,1;]"
		end
		meta:set_string("formspec",
			"formspec_version[2]" ..
			"size["..size.."]"..
			pipeworks.fs_helpers.get_prepends(size) ..
			"item_image[0.5,0.5;1,1;pipeworks:trashcan]"..
			"label[1.5,1;"..S("Trash Can").."]"..
			list_background..
			"list[context;trash;4.5,2;1,1;]"..
			--"list[current_player;main;0,3;8,4;]" ..
			pipeworks.fs_helpers.get_inv(4)..
			"listring[context;trash]"..
			"listring[current_player;main]"
		)
		meta:set_string("infotext", S("Trash Can"))
		meta:get_inventory():set_size("trash", 1)
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.get_meta(pos):get_inventory():set_stack(listname, index, ItemStack(""))
	end,
	after_place_node = function(pos)
		pipeworks.scan_for_pipe_objects(pos)
		pipeworks.after_place(pos)
	end,
	after_dig_node = function(pos)
		pipeworks.scan_for_pipe_objects(pos)
		pipeworks.after_dig(pos)
	end,
})
pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = voidname
pipeworks.flowables.register.simple(voidname)
pipeworks.flowables.register.output(voidname, 0, 0, function(pos, node, currentpressure, finitemode, currentfluidtype) return 4, currentfluidtype end, function()end)
