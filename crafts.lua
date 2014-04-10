-- Crafting recipes for pipes

minetest.register_craft( {
        output = "pipeworks:pipe_1_empty 12",
        recipe = {
                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" },
                { "", "", "" },
                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" }
        },
})

minetest.register_craft( {
        output = "pipeworks:spigot 3",
        recipe = {
                { "pipeworks:pipe_1_empty", "" },
                { "", "pipeworks:pipe_1_empty" },
        },
})

minetest.register_craft( {
	output = "pipeworks:entry_panel_empty 2",
	recipe = {
		{ "", "default:steel_ingot", "" },
		{ "", "pipeworks:pipe_1_empty", "" },
		{ "", "default:steel_ingot", "" },
	},
})

-- Various ancillary pipe devices

minetest.register_craft( {
        output = "pipeworks:pump_off 2",
        recipe = {
                { "default:stone", "default:steel_ingot", "default:stone" },
                { "moreores:copper_ingot", "default:mese_crystal_fragment", "moreores:copper_ingot" },
                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" }
        },
})

minetest.register_craft( {
        output = "pipeworks:valve_off_empty 2",
        recipe = {
                { "", "default:stick", "" },
                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" },
                { "", "default:steel_ingot", "" }
        },
})

minetest.register_craft( {
        output = "pipeworks:storage_tank_0 2",
        recipe = {
                { "", "default:steel_ingot", "default:steel_ingot" },
                { "default:steel_ingot", "default:glass", "default:steel_ingot" },
                { "default:steel_ingot", "default:steel_ingot", "" }
        },
})

minetest.register_craft( {
        output = "pipeworks:grating 2",
        recipe = {
                { "default:steel_ingot", "", "default:steel_ingot" },
                { "", "pipeworks:pipe_1_empty", "" },
                { "default:steel_ingot", "", "default:steel_ingot" }
        },
})

minetest.register_craft( {
        output = "pipeworks:flow_sensor_empty 2",
        recipe = {
                { "pipeworks:pipe_1_empty", "mesecons:mesecon", "pipeworks:pipe_1_empty" },
        },
})

minetest.register_craft( {
        output = "pipeworks:fountainhead 2",
        recipe = {
                { "pipeworks:pipe_1_empty" },
				{ "pipeworks:pipe_1_empty" }
        },
})


-- Crafting recipes for pneumatic tubes

-- If homedecor is not installed, we need to register its crafting chain for
-- plastic sheeting so that pipeworks remains compatible with it.

if minetest.get_modpath("homedecor") == nil then

	minetest.register_craftitem(":homedecor:plastic_sheeting", {
		description = "Plastic sheet",
		inventory_image = "homedecor_plastic_sheeting.png",
	})

	minetest.register_craftitem(":homedecor:plastic_base", {
		description = "Unprocessed Plastic base",
		wield_image = "homedecor_plastic_base.png",
		inventory_image = "homedecor_plastic_base_inv.png",
	})

	minetest.register_craft({
		type = "shapeless",
		output = 'homedecor:plastic_base 4',
		recipe = { "group:leaves",
			   "group:leaves",
			   "group:leaves",
			   "group:leaves",
			   "group:leaves",
			   "group:leaves"
		}
	})

	minetest.register_craft({
		type = "cooking",
		output = "homedecor:plastic_sheeting",
		recipe = "homedecor:plastic_base",
	})

	minetest.register_craft({
		type = 'fuel',
		recipe = 'homedecor:plastic_base',
		burntime = 30,
	})

	minetest.register_craft({
		type = 'fuel',
		recipe = 'homedecor:plastic_sheeting',
		burntime = 30,
	})

end

minetest.register_craft( {
	output = "pipeworks:one_way_tube 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:stick", "default:mese_crystal", "homedecor:plastic_sheeting" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})


minetest.register_craft( {
	output = "pipeworks:tube_1 6",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "", "", "" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:mese_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "", "default:mese_crystal", "" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	type = "shapeless",
	output = "pipeworks:mese_tube_000000",
	recipe = {
	    "pipeworks:tube_1",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment"
	},
})

minetest.register_craft( {
	output = "pipeworks:conductor_tube_off_1 6",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "mesecons:mesecon", "mesecons:mesecon", "mesecons:mesecon" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:detector_tube_off_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "mesecons:mesecon", "mesecons_materials:silicon", "mesecons:mesecon" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:accelerator_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:mese_crystal_fragment", "default:steel_ingot", "default:mese_crystal_fragment" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:teleport_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:desert_stone", "default:mese_block", "default:desert_stone" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:sand_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:sand", "default:sand", "default:sand" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:sand_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:desert_sand", "default:desert_sand", "default:desert_sand" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:sand_tube_1",
	recipe = {
	        { "default:desert_sand", "pipeworks:tube_1", "default:desert_sand" },
	},
})

minetest.register_craft( {
	output = "pipeworks:mese_sand_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:sand", "default:mese_crystal", "default:sand" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:mese_sand_tube_1 2",
	recipe = {
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
	        { "default:desert_sand", "default:mese_crystal", "default:desert_sand" },
	        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:crossing_tube_1 5",
	recipe = {
	        { "", "pipeworks:tube_1", "" },
	        { "pipeworks:tube_1", "pipeworks:tube_1", "pipeworks:tube_1" },
	        { "", "pipeworks:tube_1", "" }
	},
})


minetest.register_craft( {
	type = "shapeless",
	output = "pipeworks:mese_sand_tube_1",
	recipe = {
  "pipeworks:sand_tube_1",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment",
		"default:mese_crystal_fragment"
	},
})

-- Various ancillary tube devices

minetest.register_craft( {
	output = "pipeworks:filter 2",
	recipe = {
	        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" },
	        { "default:stick", "default:mese_crystal", "homedecor:plastic_sheeting" },
	        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:mese_filter 2",
	recipe = {
	        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" },
	        { "default:stick", "default:mese", "homedecor:plastic_sheeting" },
	        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" }
	},
})

minetest.register_craft( {
	output = "pipeworks:autocrafter 2",
	recipe = {
	        { "default:steel_ingot", "default:mese_crystal", "default:steel_ingot" },
	        { "homedecor:plastic_sheeting", "default:steel_ingot", "homedecor:plastic_sheeting" },
	        { "default:steel_ingot", "default:mese_crystal", "default:steel_ingot" }
	},
})


