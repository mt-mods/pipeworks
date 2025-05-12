-- Pipeworks mod by Vanessa Ezekowitz - 2013-07-13
--
-- This mod supplies various steel pipes and plastic pneumatic tubes
-- and devices that they can connect to.
--

pipeworks = {
	ui_cat_tube_list = {},
	worldpath = core.get_worldpath(),
	modpath = core.get_modpath("pipeworks"),
	liquids = {
		water = {
			source = core.registered_nodes["mapgen_water_source"].name,
			flowing = core.registered_nodes["mapgen_water_source"].liquid_alternative_flowing
		},
		river_water = {
			source = core.registered_nodes["mapgen_river_water_source"].name,
			flowing = core.registered_nodes["mapgen_river_water_source"].liquid_alternative_flowing
		}
	}
}

dofile(pipeworks.modpath.."/default_settings.lua")
-- Read the external config file if it exists.
local worldsettingspath = pipeworks.worldpath.."/pipeworks_settings.txt"
local worldsettingsfile = io.open(worldsettingspath, "r")
if worldsettingsfile then
	worldsettingsfile:close()
	dofile(worldsettingspath)
end
if pipeworks.toggles.pipe_mode == "pressure" then
	core.log("warning", "pipeworks pressure logic mode comes with caveats and differences in behaviour, you have been warned!")
end
if pipeworks.entity_update_interval >= 0.2 and pipeworks.enable_accelerator_tube then
	core.log("warning", "pipeworks accelerator tubes will not entirely work with an entity update interval 0.2 or above.")
end

pipeworks.logger = function(msg)
	core.log("action", "[pipeworks] "..msg)
end

-------------------------------------------
-- Load the various other parts of the mod

-- early auto-detection for finite water mode if not explicitly disabled
if pipeworks.toggles.finite_water == nil then
	dofile(pipeworks.modpath.."/autodetect-finite-water.lua")
end

if core.get_modpath("signs_lib") then
	dofile(pipeworks.modpath.."/signs_compat.lua")
end

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
if pipeworks.enable_lua_tube and core.get_modpath("mesecons") then
	dofile(pipeworks.modpath.."/tubes/lua.lua")
end
if pipeworks.enable_sand_tube or pipeworks.enable_mese_sand_tube then
	dofile(pipeworks.modpath.."/tubes/vacuum.lua")
end

local logicdir = "/pressure_logic/"

-- note that even with these files the new flow logic is not yet default.
-- registration will take place but no actual ABMs/node logic will be installed,
-- unless the toggle flag is specifically enabled in the per-world settings flag.
dofile(pipeworks.modpath..logicdir.."flowable_node_registry.lua")
dofile(pipeworks.modpath..logicdir.."abms.lua")
dofile(pipeworks.modpath..logicdir.."abm_register.lua")
dofile(pipeworks.modpath..logicdir.."flowable_node_registry_install.lua")

if pipeworks.enable_pipes then
	dofile(pipeworks.modpath.."/pipes.lua")
end
if pipeworks.enable_pipe_devices then
	dofile(pipeworks.modpath.."/devices.lua")
end
if pipeworks.enable_redefines then
	dofile(pipeworks.modpath.."/compat-chests.lua")
end
if pipeworks.enable_redefines and (core.get_modpath("default") or core.get_modpath("hades_core")) then
	dofile(pipeworks.modpath.."/compat-furnaces.lua")
end
if pipeworks.enable_redefines and core.get_modpath("mcl_furnaces") then
	dofile(pipeworks.modpath.."/mcl_furnaces.lua")
end
if pipeworks.enable_autocrafter then
	dofile(pipeworks.modpath.."/autocrafter.lua")
end

dofile(pipeworks.modpath.."/crafts.lua")

core.register_alias("pipeworks:pipe", "pipeworks:pipe_110000_empty")

-- Unified Inventory categories integration

if core.get_modpath("unified_inventory") and unified_inventory.registered_categories then
	if not unified_inventory.registered_categories["automation"] then
		local symbol
		if pipeworks.enable_lua_tube then
			symbol = "pipeworks:lua_tube000000"
		else
			symbol = "pipeworks:mese_filter" -- fallback when lua tube isn't registered
		end
		unified_inventory.register_category("automation", {
			symbol = symbol,
			label = "Automation components"
		})
	end
	unified_inventory.add_category_items("automation", pipeworks.ui_cat_tube_list)
end

core.log("info", "Pipeworks loaded!")
