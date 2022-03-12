local materials = {
	dirt = "default:dirt",
	sand = "default:sand",
	desert_stone = "default:desert_stone",
	gravel = "default:gravel",
	copper_ingot = "default:copper_ingot",
	steel_ingot = "default:steel_ingot",
	gold_ingot = "default:gold_ingot",
	tin_ingot = "default:tin_ingot",
    mese = "default:mese",
    mese_crystal = "default:mese_crystal",
	mese_crystal_fragment = "default:mese_crystal_fragment",
	torch = "default:torch",
	diamond = "default:diamond",
	clay_lump = "default:clay_lump",
	water_bucket = "bucket:bucket_water",
	empty_bucket = "bucket:bucket_empty",
	dye_dark_grey = "dye:dark_grey",
	silicon = "mesecons_materials:silicon",
    stone = "default:stone",
    glass = "default:glass",
}

if minetest.get_modpath("mcl_core") then
	materials = {
		dirt = "mcl_core:dirt",
		sand = "mcl_core:sand",
		gravel = "mcl_core:gravel",
		steel_ingot = "mcl_core:iron_ingot",
		gold_ingot = "mcl_core:gold_ingot",
        mese = "default:mese",
        mese_crystal = "default:mese_crystal",
		mese_crystal_fragment = "mesecons:redstone",
		torch = "mcl_torches:torch",
		diamond = "mcl_core:diamond",
		clay_lump = "mcl_core:clay_lump",
		water_bucket = "mcl_buckets:bucket_water",
		empty_bucket = "mcl_buckets:bucket_empty",
		dye_dark_grey = "mcl_dye:dark_grey",
		-- Use iron where no equivalent
		copper_ingot = "mcl_core:iron_ingot",
		tin_ingot = "mcl_core:iron_ingot",
		silver_ingot = "mcl_core:iron_ingot",
		silicon = "mesecons_materials:silicon",
        stone = "default:stone",
        glass = "default:glass",
	}
elseif minetest.get_modpath("fl_ores") and minetest.get_modpath("fl_stone") then
	materials = {
		dirt = "fl_topsoil:dirt",
		sand = "fl_stone:sand",
		desert_stone = "fl_stone:desert_stone",
		gravel = "fl_topsoil:gravel",
		steel_ingot = "fl_ores:iron_ingot",
		gold_ingot = "fl_ores:gold_ingot",
        mese = "fl_ores:iron_ingot",
        mese_crystal = "fl_ores:iron_ingot",
		mese_crystal_fragment = "fl_ores:iron_ingot",
		torch = "fl_light_sources:torch",
		diamond = "fl_ores:diamond",
		clay_lump = "fl_bricks:clay_lump",
		water_bucket = "fl_bucket:bucket_water",
		empty_bucket = "fl_bucket:bucket",
		dye_dark_grey = "fl_dyes:dark_grey_dye",
		copper_ingot = "fl_ores:copper_ingot",
		tin_ingot = "fl_ores:tin_ingot",
		silver_ingot = "fl_ores:iron_ingot",
		silicon = "mesecons_materials:silicon",
        stone = "fl_stone:stone",
        glass = "fl_glass:framed_glass",
	}
elseif minetest.get_modpath("hades_core") then
	materials = {
		dirt = "hades_core:dirt",
		sand = "hades_core:fertile_sand",
		gravel = "hades_core:gravel",
		steel_ingot = "hades_core:steel_ingot",
		gold_ingot = "hades_core:gold_ingot",
        mese = "default:mese",
        mese_crystal = "default:mese_crystal",
		mese_crystal_fragment = "hades_core:mese_crystal_fragment",
		torch = "hades_torches:torch",
		diamond = "hades_core:diamond",
		clay_lump = "hades_core:clay_lump",
		dye_dark_grey = "dye:dark_grey",
		copper_ingot = "hades_core:copper_ingot",
		tin_ingot = "hades_core:tin_ingot",
		--[[
			Since hades doesnt have buckets or water for the user,
			using dirt from near water to pull the water out
		]]
		water_bucket = "hades_core:dirt",
		empty_bucket = "hades_core:fertile_sand",
		-- Set this to steel unless hadesextraores is present
		silver_ingot = "hades_core:steel_ingot",
		silicon = "hades_materials:silicon",
        stone = "default:stone",
        glass = "default:glass",
	}

	if minetest.get_modpath("hades_bucket") then
		materials["water_bucket"] = "hades_bucket:bucket_water"
		materials["empty_bucket"] = "hades_bucket:bucket_empty"
	end
	if minetest.get_modpath("hades_extraores") then
		materials["silver_ingot"] = "hades_extraores:silver_ingot"
	end
end

-- Crafting recipes for pipes

minetest.register_craft( {
    output = "pipeworks:pipe_1_empty 12",
    recipe = {
            { materials.steel_ingot, materials.steel_ingot, materials.steel_ingot },
            { "", "", "" },
            { materials.steel_ingot, materials.steel_ingot, materials.steel_ingot }
    },
})

minetest.register_craft( {
    output = "pipeworks:straight_pipe_empty 3",
    recipe = {
            { "pipeworks:pipe_1_empty", "pipeworks:pipe_1_empty", "pipeworks:pipe_1_empty" },
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
    { "", materials.steel_ingot, "" },
    { "", "pipeworks:pipe_1_empty", "" },
    { "", materials.steel_ingot, "" },
},
})

-- Various ancillary pipe devices

minetest.register_craft( {
    output = "pipeworks:pump_off 2",
    recipe = {
            { materials.stone, materials.steel_ingot, materials.stone },
            { materials.copper_ingot, materials.mese_crystal_fragment, materials.copper_ingot },
            { materials.steel_ingot, materials.steel_ingot, materials.steel_ingot }
    },
})

minetest.register_craft( {
    output = "pipeworks:valve_off_empty 2",
    recipe = {
            { "", "group:stick", "" },
            { materials.steel_ingot, materials.steel_ingot, materials.steel_ingot },
            { "", materials.steel_ingot, "" }
    },
})

minetest.register_craft( {
    output = "pipeworks:storage_tank_0 2",
    recipe = {
            { "", materials.steel_ingot, materials.steel_ingot },
            { materials.steel_ingot, materials.glass, materials.steel_ingot },
            { materials.steel_ingot, materials.steel_ingot, "" }
    },
})

minetest.register_craft( {
    output = "pipeworks:grating 2",
    recipe = {
            { materials.steel_ingot, "", materials.steel_ingot },
            { "", "pipeworks:pipe_1_empty", "" },
            { materials.steel_ingot, "", materials.steel_ingot }
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

-- injectors

minetest.register_craft( {
	output = "pipeworks:filter 2",
	recipe = {
	        { materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" },
	        { "group:stick", materials.mese_crystal, "basic_materials:plastic_sheet" },
	        { materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" }
	},
})

minetest.register_craft( {
	output = "pipeworks:mese_filter 2",
	recipe = {
	        { materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" },
	        { "group:stick", materials.mese, "basic_materials:plastic_sheet" },
	        { materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" }
	},
})

if minetest.get_modpath("digilines") then
	minetest.register_craft( {
		output = "pipeworks:digiline_filter 2",
		recipe = {
			{ materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" },
			{ "group:stick", "digilines:wire_std_00000000", "basic_materials:plastic_sheet" },
			{ materials.steel_ingot, materials.steel_ingot, "basic_materials:plastic_sheet" }
		},
	})
end

-- other

minetest.register_craft( {
	output = "pipeworks:autocrafter 2",
	recipe = {
	        { materials.steel_ingot, materials.mese_crystal, materials.steel_ingot },
	        { "basic_materials:plastic_sheet", materials.steel_ingot, "basic_materials:plastic_sheet" },
	        { materials.steel_ingot, materials.mese_crystal, materials.steel_ingot }
	},
})

minetest.register_craft( {
	output = "pipeworks:steel_block_embedded_tube 1",
	recipe = {
		{ materials.steel_ingot, materials.steel_ingot, materials.steel_ingot },
		{ materials.steel_ingot, "pipeworks:tube_1", materials.steel_ingot },
		{ materials.steel_ingot, materials.steel_ingot, materials.steel_ingot }
	},
})

minetest.register_craft( {
	output = "pipeworks:steel_pane_embedded_tube 1",
	recipe = {
		{ "", materials.steel_ingot, "" },
		{ "", "pipeworks:tube_1", "" },
		{ "", materials.steel_ingot, "" }
	},
})

minetest.register_craft({
	output = "pipeworks:trashcan",
	recipe = {
		{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
		{ materials.steel_ingot, "", materials.steel_ingot },
		{ materials.steel_ingot, materials.steel_ingot, materials.steel_ingot },
	},
})

minetest.register_craft( {
	output = "pipeworks:teleport_tube_1 2",
	recipe = {
	        { "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
	        { materials.desert_stone, materials.mese, materials.desert_stone },
	        { "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
	},
})

if pipeworks.enable_priority_tube then
	minetest.register_craft( {
		output = "pipeworks:priority_tube_1 6",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ materials.gold_ingot, "", materials.gold_ingot },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})
end

if pipeworks.enable_accelerator_tube then
	minetest.register_craft( {
		output = "pipeworks:accelerator_tube_1 2",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ materials.mese_crystal_fragment, materials.steel_ingot, materials.mese_crystal_fragment },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})
end

if pipeworks.enable_crossing_tube then
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
	minetest.register_craft({
		output = "pipeworks:one_way_tube 2",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ "group:stick", materials.mese_crystal, "basic_materials:plastic_sheet" },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})
end

if pipeworks.enable_mese_tube then
	minetest.register_craft( {
		output = "pipeworks:mese_tube_000000 2",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ "", materials.mese_crystal, "" },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})

	minetest.register_craft( {
		type = "shapeless",
		output = "pipeworks:mese_tube_000000",
		recipe = {
			"pipeworks:tube_1",
			materials.mese_crystal,
			materials.mese_crystal,
			materials.mese_crystal,
			materials.mese_crystal,
		},
	})
end

if pipeworks.enable_mese_sand_tube then
	minetest.register_craft( {
		output = "pipeworks:mese_sand_tube_1 2",
		recipe = {
			{"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{"group:sand",                 materials.mese_crystal,       "group:sand" },
			{"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})

	minetest.register_craft( {
		type = "shapeless",
		output = "pipeworks:mese_sand_tube_1",
		recipe = {
			"pipeworks:sand_tube_1",
			materials.mese_crystal_fragment,
			materials.mese_crystal_fragment,
			materials.mese_crystal_fragment,
			materials.mese_crystal_fragment,
		},
	})
end