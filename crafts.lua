-- Crafting recipes for pipeworks

-- If the technic mod is present, then don't bother registering these recipes
-- as that mod supplies its own.

if io.open(minetest.get_modpath("pipeworks").."/../technic/init.lua", "r") == nil then

	-- If homedecor is not installed, we need to register a few of its crafts
	-- manually so we can use them.

	if minetest.get_modpath("homedecor") == nil then

		minetest.register_craftitem(":homedecor:plastic_sheeting", {
			description = "Plastic sheet",
			inventory_image = "pipeworks_plastic_sheeting.png",
		})

		minetest.register_craft({
		        type = "cooking",
		        output = "homedecor:plastic_sheeting",
		        recipe = "default:junglegrass",
		})

		minetest.register_craft({
		        type = 'fuel',
		        recipe = 'homedecor:plastic_sheeting',
		        burntime = 30,
		})
	end

	minetest.register_craft( {
	        output = "pipeworks:pipe_110000_empty 12",
	        recipe = {
	                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" },
	                { "", "", "" },
	                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" }
	        },
	})

	minetest.register_craft( {
	        output = "pipeworks:pump_off 2",
	        recipe = {
	                { "default:stone", "default:steel_ingot", "default:stone" },
	                { "moreores:copper_ingot", "default:mese_crystal_fragment", "moreores:copper_ingot" },
	                { "default:steel_ingot", "default:steel_ingot", "default:steel_ingot" }
	        },
	})

	minetest.register_craft( {
	        output = "pipeworks:valve_off 2",
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
	                { "", "default:steel_ingot", "" },
	                { "default:steel_ingot", "", "default:steel_ingot" }
	        },
	})

	minetest.register_craft( {
	        output = "pipeworks:spigot 3",
	        recipe = {
	                { "pipeworks:pipe_110000_empty", "" },
	                { "", "pipeworks:pipe_110000_empty" },
	        },
	})

	minetest.register_craft( {
		output = "pipeworks:tube 12",
		recipe = {
		        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
		        { "", "", "" },
		        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		output = "pipeworks:mese_tube_000000 2",
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
		    "pipeworks:tube_000000",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment"
		},
	})

	minetest.register_craft( {
		output = "pipeworks:detector_tube_off_000000 2",
		recipe = {
		        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
		        { "default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment" },
		        { "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		output = "pipeworks:filter 2",
		recipe = {
		        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" },
		        { "default:stick", "default:mese_crystal", "homedecor:plastic_sheeting" },
		        { "default:steel_ingot", "default:steel_ingot", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
        output = "pipeworks:entry_panel 2",
        recipe = {
		{ "", "default:steel_ingot", "" },
                { "", "pipeworks:pipe_110000_empty", "" },
		{ "", "default:steel_ingot", "" },
        },
	})

end
