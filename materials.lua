local materials = {
    stone = "default:stone",
    desert_stone = "default:desert_stone",
    desert_sand = "default:desert_sand",
    chest = "default:chest",
    copper_ingot = "default:copper_ingot",
    steel_ingot = "default:steel_ingot",
    gold_ingot = "default:gold_ingot",
    mese = "default:mese",
    mese_crystal = "default:mese_crystal",
    mese_crystal_fragment = "default:mese_crystal_fragment",
    teleporter = "default:mese",
    glass = "default:glass"
}

if minetest.get_modpath("mcl_core") then
    materials = {
        stone = "mcl_core:stone",
        desert_stone = "mcl_core:redsandstone",
        desert_sand = "mcl_core:sand",
        chest = "mcl_chests:chest",
        steel_ingot = "mcl_core:iron_ingot",
        gold_ingot = "mcl_core:gold_ingot",
        mese = "mesecons_torch:redstoneblock",
        mese_crystal = "mesecons:redstone",
        mese_crystal_fragment = "mesecons:redstone",
        teleporter = "mesecons_torch:redstoneblock",
        copper_ingot = "mcl_copper:copper_ingot",
        glass = "mcl_core:glass",
    }
elseif minetest.get_modpath("fl_ores") and minetest.get_modpath("fl_stone") then
    materials = {
        stone = "fl_stone:stone",
        desert_stone = "fl_stone:desert_stone",
        desert_sand = "fl_stone:desert_sand",
        chest = "fl_storage:wood_chest",
        steel_ingot = "fl_ores:iron_ingot",
        gold_ingot = "fl_ores:gold_ingot",
        mese = "fl_ores:iron_ingot",
        mese_crystal = "fl_ores:iron_ingot",
        mese_crystal_fragment = "fl_ores:iron_ingot",
        teleporter = "fl_ores:iron_ingot",
        copper_ingot = "fl_ores:copper_ingot",
        glass = "fl_glass:framed_glass",
    }
elseif minetest.get_modpath("hades_core") then
    materials = {
        stone = "hades_core:stone",
        desert_stone = "hades_core:stone_baked",
        desert_sand = "hades_core:volcanic_sand",
        chest = "hades_chests:chest";
        steel_ingot = "hades_core:steel_ingot",
        gold_ingot = "hades_core:gold_ingot",
        mese = "hades_core:mese",
        mese_crystal = "hades_core:mese_crystal",
        mese_crystal_fragment = "hades_core:mese_crystal_fragment",
        teleporter = "hades_materials:teleporter_device",
        copper_ingot = "hades_core:copper_ingot",
        tin_ingot = "hades_core:tin_ingot",
        glass = "hades_core:glass",
    }
    if minetest.get_modpath("hades_default") then
        materials.desert_sand = "hades_default:desert_sand"
    end
end

return materials