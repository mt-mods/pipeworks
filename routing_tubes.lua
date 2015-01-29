-- the default tube and default textures
pipeworks.register_tube("pipeworks:tube", "Pneumatic tube segment")
minetest.register_craft( {
	output = "pipeworks:tube_1 6",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "", "", "" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

if pipeworks.enable_accelerator_tube then
	local accelerator_noctr_textures = {"pipeworks_accelerator_tube_noctr.png", "pipeworks_accelerator_tube_noctr.png", "pipeworks_accelerator_tube_noctr.png",
					    "pipeworks_accelerator_tube_noctr.png", "pipeworks_accelerator_tube_noctr.png", "pipeworks_accelerator_tube_noctr.png"}
	local accelerator_plain_textures = {"pipeworks_accelerator_tube_plain.png" ,"pipeworks_accelerator_tube_plain.png", "pipeworks_accelerator_tube_plain.png",
					    "pipeworks_accelerator_tube_plain.png", "pipeworks_accelerator_tube_plain.png", "pipeworks_accelerator_tube_plain.png"}
	local accelerator_end_textures = {"pipeworks_accelerator_tube_end.png", "pipeworks_accelerator_tube_end.png", "pipeworks_accelerator_tube_end.png",
					  "pipeworks_accelerator_tube_end.png", "pipeworks_accelerator_tube_end.png", "pipeworks_accelerator_tube_end.png"}
	local accelerator_short_texture = "pipeworks_accelerator_tube_short.png"
	local accelerator_inv_texture = "pipeworks_accelerator_tube_inv.png"

	pipeworks.register_tube("pipeworks:accelerator_tube", "Accelerating Pneumatic Tube Segment", accelerator_plain_textures,
				accelerator_noctr_textures, accelerator_end_textures, accelerator_short_texture, accelerator_inv_texture,
				{tube = {can_go = function(pos, node, velocity, stack)
						 velocity.speed = velocity.speed+1
						 return pipeworks.notvel(pipeworks.meseadjlist, velocity)
					end}
	})

	minetest.register_craft( {
		output = "pipeworks:accelerator_tube_1 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "default:mese_crystal_fragment", "default:steel_ingot", "default:mese_crystal_fragment" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

end

if pipeworks.enable_crossing_tube then
	local crossing_noctr_textures = {"pipeworks_crossing_tube_noctr.png", "pipeworks_crossing_tube_noctr.png", "pipeworks_crossing_tube_noctr.png",
					 "pipeworks_crossing_tube_noctr.png", "pipeworks_crossing_tube_noctr.png", "pipeworks_crossing_tube_noctr.png"}
	local crossing_plain_textures = {"pipeworks_crossing_tube_plain.png" ,"pipeworks_crossing_tube_plain.png", "pipeworks_crossing_tube_plain.png",
					 "pipeworks_crossing_tube_plain.png", "pipeworks_crossing_tube_plain.png", "pipeworks_crossing_tube_plain.png"}
	local crossing_end_textures = {"pipeworks_crossing_tube_end.png", "pipeworks_crossing_tube_end.png", "pipeworks_crossing_tube_end.png",
				       "pipeworks_crossing_tube_end.png", "pipeworks_crossing_tube_end.png", "pipeworks_crossing_tube_end.png"}
	local crossing_short_texture = "pipeworks_crossing_tube_short.png"
	local crossing_inv_texture = "pipeworks_crossing_tube_inv.png"

	pipeworks.register_tube("pipeworks:crossing_tube", "Crossing Pneumatic Tube Segment", crossing_plain_textures,
				crossing_noctr_textures, crossing_end_textures, crossing_short_texture, crossing_inv_texture,
				{tube = {can_go = function(pos, node, velocity, stack)
						 return {velocity}
					end}
	})

	minetest.register_craft( {
		output = "pipeworks:crossing_tube_1 5",
		recipe = {
			{ "", "pipeworks:tube_1", "" },
			{ "pipeworks:tube_1", "pipeworks:tube_1", "pipeworks:tube_1" },
			{ "", "pipeworks:tube_1", "" }
		},
	})
end

if pipeworks.enable_one_way_tube then
	minetest.register_node("pipeworks:one_way_tube", {
		description = "One way tube",
		tiles = {"pipeworks_one_way_tube_top.png", "pipeworks_one_way_tube_top.png", "pipeworks_one_way_tube_output.png",
			"pipeworks_one_way_tube_input.png", "pipeworks_one_way_tube_side.png", "pipeworks_one_way_tube_top.png"},
		paramtype2 = "facedir",
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {type = "fixed",
			fixed = {{-1/2, -9/64, -9/64, 1/2, 9/64, 9/64}}},
		groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 2, tubedevice = 1},
		legacy_facedir_simple = true,
		sounds = default.node_sound_wood_defaults(),
		tube = {
			connect_sides = {left = 1, right = 1},
			can_go = function(pos, node, velocity, stack)
				return {velocity}
			end,
			can_insert = function(pos, node, stack, direction)
				local dir = minetest.facedir_to_right_dir(node.param2)
				return vector.equals(dir, direction)
			end,
			priority = 75 -- Higher than normal tubes, but lower than receivers
		},
	})
	minetest.register_craft({
		output = "pipeworks:one_way_tube 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "group:stick", "default:mese_crystal", "homedecor:plastic_sheeting" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})
end
