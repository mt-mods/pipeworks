-- registration of pipework's own pipes.
-- written 2017 by thetaepsilon



-- global values and thresholds for water behaviour
-- TODO: add some way of setting this per-world
local thresholds = {}
-- limit on pump pressure - will not absorb more than can be taken
thresholds.pump_pressure = 2
-- activation threshold for spigot
-- should not be below 1, as spigot helper code indiscriminately places a water source node if run.
thresholds.spigot_min = 1



local pipes_full_nodenames = pipeworks.pipes_full_nodenames
local pipes_empty_nodenames = pipeworks.pipes_empty_nodenames

local register = pipeworks.flowables.register
local flowlogic = pipeworks.flowlogic



-- FIXME: DRY principle for names, move this to devices.lua?
-- FIXME: all devices still considered simple
local pump_on = "pipeworks:pump_on"
local pump_off = "pipeworks:pump_off"
local spigot_off = "pipeworks:spigot"
local spigot_on = "pipeworks:spigot_pouring"

if pipeworks.enable_pipes then
	--[[
	for _, pipe in ipairs(pipes_full_nodenames) do
		register.simple(pipe)
	end
	for _, pipe in ipairs(pipes_empty_nodenames) do
		register.simple(pipe)
	end
	]]

	if pipeworks.enable_pipe_devices then
		register.simple(pump_off)
		register.simple(pump_on)
		register.simple(spigot_on)
		register.simple(spigot_off)

		register.intake_simple(pump_on, thresholds.pump_pressure)
		-- TODO: the code doesn't currently care if the spigot is the visually flowing node or not.
		-- So some mechanism to register on/off states would be nice
		register.output(spigot_off, thresholds.spigot_min, flowlogic.helpers.output_spigot)
		register.output(spigot_on, thresholds.spigot_min, flowlogic.helpers.output_spigot)
	end
end
