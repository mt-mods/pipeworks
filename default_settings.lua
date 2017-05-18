-- Various settings

local prefix = "pipeworks_"

local settings = {
	enable_pipes = true,
	enable_autocrafter = true,
	enable_deployer = true,
	enable_dispenser = true,
	enable_node_breaker = true,
	enable_teleport_tube = true,
	enable_pipe_devices = true,
	enable_redefines = true,
	enable_mese_tube = true,
	enable_detector_tube = true,
	enable_digiline_detector_tube = true,
	enable_conductor_tube = true,
	enable_accelerator_tube = true,
	enable_crossing_tube = true,
	enable_sand_tube = true,
	enable_mese_sand_tube = true,
	enable_one_way_tube = true,
	enable_priority_tube = true,
	enable_cyclic_mode = true,
	drop_on_routing_fail = false,

	delete_item_on_clearobject = true,
}

for name, value in pairs(settings) do
	local setting_type = type(value)
	if setting_type == "boolean" then
		pipeworks[name] = minetest.settings:get_bool(prefix..name)
		if pipeworks[name] == nil then
			pipeworks[name] = value
		end
	else
		pipeworks[name] = value
	end
end
