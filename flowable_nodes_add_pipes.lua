-- conditional registration of pipe nodes for the new pipe logic, depending on enable flags.
-- otherwise register_flow_logic.lua would be attempting to register ABMs for non-existant nodes.
-- written 2017 by thetaepsilon



-- global values and thresholds for water behaviour
-- TODO: add some way of setting this per-world
local thresholds = {}
-- limit on pump pressure - will not absorb more than can be taken
thresholds.pump_pressure = 2



local pipes_full_nodenames = pipeworks.pipes_full_nodenames
local pipes_empty_nodenames = pipeworks.pipes_empty_nodenames

local register = pipeworks.flowables.register



-- FIXME: DRY principle for names, move this to devices.lua?
-- FIXME: all devices still considered simple
local pump_on = "pipeworks:pump_on"
local pump_off = "pipeworks:pump_off"
local spigot_off = "pipeworks:spigot"
local spigot_on = "pipeworks:spigot_pouring"

if pipeworks.enable_pipes then
	for _, pipe in ipairs(pipes_full_nodenames) do
		register.simple(pipe)
	end
	for _, pipe in ipairs(pipes_empty_nodenames) do
		register.simple(pipe)
	end

	if pipeworks.enable_pipe_devices then
		register.simple(pump_off)
		register.simple(pump_on)
		register.simple(spigot_on)
		register.simple(spigot_off)

		register.intake_simple(pump_on, thresholds.pump_pressure)
	end
end
