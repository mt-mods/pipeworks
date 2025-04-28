local S = core.get_translator("pipeworks")

-- Pipeworks mod by Vanessa Ezekowitz - 2013-07-13
--
-- This mod supplies various steel pipes and plastic pneumatic tubes
-- and devices that they can connect to.
--

pipeworks = {
	ui_cat_tube_list = {},
	worldpath = minetest.get_worldpath(),
	modpath = minetest.get_modpath("pipeworks"),
	register_fluid = function(self, alias, name, density, description)
		local def = core.registered_nodes[alias]
		self.liquids[name] = {
			def = def,
			source = def.liquid_alternative_source,
			description = description or string.gsub(def.description, "%s?"..S("Source").."%s?", ""),
			flowing = def.liquid_alternative_flowing,
			density = density, -- in g/cm³ as standard
		}
		self.fluid_types[def.liquid_alternative_source] = name
	end,
	liquids = {},
	fluid_types = {}, -- easier indexing
	gravity = {x=0, y=-0.025, z=0}, -- pressure bias factor, SI unit unspecified
}

-- fluid registration
pipeworks:register_fluid("mapgen_water_source", "water", 1.05, S("Water"))
pipeworks:register_fluid("mapgen_river_water_source", "river_water", 1, S("River Water"))
pipeworks:register_fluid("mapgen_lava_source", "lava", 4, S("Lava"))

dofile(pipeworks.modpath.."/default_settings.lua")
-- Read the external config file if it exists.
local worldsettingspath = pipeworks.worldpath.."/pipeworks_settings.txt"
local worldsettingsfile = io.open(worldsettingspath, "r")
if worldsettingsfile then
	worldsettingsfile:close()
	dofile(worldsettingspath)
end
if pipeworks.toggles.pipe_mode == "pressure" then
	minetest.log("warning", "pipeworks pressure logic mode comes with caveats and differences in behaviour, you have been warned!")
end
if pipeworks.entity_update_interval >= 0.2 and pipeworks.enable_accelerator_tube then
	minetest.log("warning", "pipeworks accelerator tubes will not entirely work with an entity update interval 0.2 or above.")
end

pipeworks.logger = function(msg)
	minetest.log("action", "[pipeworks] "..msg)
end

-------------------------------------------
-- Load the various other parts of the mod

-- early auto-detection for finite fluids mode if not explicitly disabled
if pipeworks.toggles.finite == nil then
	dofile(pipeworks.modpath.."/autodetect-finite-water.lua")
end

if minetest.get_modpath("signs_lib") then
	dofile(pipeworks.modpath.."/signs_compat.lua")
end

local logicdir = "/pressure_logic/"

-- note that even with these files the new flow logic is not yet default.
-- registration will take place but no actual ABMs/node logic will be installed,
-- unless the toggle flag is specifically enabled in the per-world settings flag.
-- -- disregard previous comments, new flow logic is default now
dofile(pipeworks.modpath..logicdir.."flowable_node_registry.lua")
dofile(pipeworks.modpath..logicdir.."abms.lua")
dofile(pipeworks.modpath..logicdir.."abm_register.lua")
dofile(pipeworks.modpath..logicdir.."flowable_node_registry_install.lua")

dofile(pipeworks.modpath.."/common.lua")
dofile(pipeworks.modpath.."/models.lua")
dofile(pipeworks.modpath.."/autoplace_pipes.lua")
dofile(pipeworks.modpath.."/autoplace_tubes.lua")
dofile(pipeworks.modpath.."/luaentity.lua")
dofile(pipeworks.modpath.."/item_transport.lua")
dofile(pipeworks.modpath.."/flowing_logic.lua")
dofile(pipeworks.modpath.."/filter-injector.lua")
dofile(pipeworks.modpath.."/chests.lua")
dofile(pipeworks.modpath.."/trashcan.lua")
dofile(pipeworks.modpath.."/wielder.lua")
dofile(pipeworks.modpath.."/tubes/registration.lua")
dofile(pipeworks.modpath.."/tubes/routing.lua")
dofile(pipeworks.modpath.."/tubes/sorting.lua")
dofile(pipeworks.modpath.."/tubes/signal.lua")
dofile(pipeworks.modpath.."/tubes/embedded_tube.lua")
dofile(pipeworks.modpath.."/tubes/pane_embedded_tube.lua")
dofile(pipeworks.modpath.."/tubes/tags.lua")

if pipeworks.enable_teleport_tube then
	dofile(pipeworks.modpath.."/tubes/teleport.lua")
end
if pipeworks.enable_lua_tube and minetest.get_modpath("mesecons") then
	dofile(pipeworks.modpath.."/tubes/lua.lua")
end
if pipeworks.enable_sand_tube or pipeworks.enable_mese_sand_tube then
	dofile(pipeworks.modpath.."/tubes/vacuum.lua")
end

if pipeworks.enable_pipes then
	dofile(pipeworks.modpath.."/pipes.lua")
end
if pipeworks.enable_pipe_devices then
	dofile(pipeworks.modpath.."/devices.lua")
end
if pipeworks.enable_redefines then
	dofile(pipeworks.modpath.."/compat-chests.lua")
end
if pipeworks.enable_redefines and (minetest.get_modpath("default") or minetest.get_modpath("hades_core")) then
	dofile(pipeworks.modpath.."/compat-furnaces.lua")
end
if pipeworks.enable_redefines and minetest.get_modpath("mcl_furnaces") then
	dofile(pipeworks.modpath.."/mcl_furnaces.lua")
end
if pipeworks.enable_autocrafter then
	dofile(pipeworks.modpath.."/autocrafter.lua")
end

dofile(pipeworks.modpath.."/crafts.lua")

minetest.register_alias("pipeworks:pipe", "pipeworks:pipe_110000_empty")

-- Unified Inventory categories integration

if minetest.get_modpath("unified_inventory") and unified_inventory.registered_categories then
	if not unified_inventory.registered_categories["automation"] then
		unified_inventory.register_category("automation", {
			symbol = "pipeworks:lua_tube000000",
			label = "Automation components"
		})
	end
	unified_inventory.add_category_items("automation", pipeworks.ui_cat_tube_list)
end

minetest.log("info", "Pipeworks loaded!")
