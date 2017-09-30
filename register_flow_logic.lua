-- register new flow logic ABMs
-- written 2017 by thetaepsilon

local pipes_full_nodenames = pipeworks.pipes_full_nodenames
local pipes_empty_nodenames = pipeworks.pipes_empty_nodenames

-- run pressure balancing ABM over all water-moving nodes
-- FIXME: DRY principle, get this from elsewhere in the code
local pump_on = "pipeworks:pump_on"
local pump_off = "pipeworks:pump_off"
local spigot_off = "pipeworks:spigot"
local spigot_on = "pipeworks:spigot_pouring"

local pipes_all_nodenames = pipes_full_nodenames
for _, pipe in ipairs(pipes_empty_nodenames) do
	table.insert(pipes_all_nodenames, pipe)
end

if pipeworks.enable_pipe_devices then
	table.insert(pipes_all_nodenames, pump_off)
	table.insert(pipes_all_nodenames, pump_on)
	table.insert(pipes_all_nodenames, spigot_on)
	table.insert(pipes_all_nodenames, spigot_off)
end


if pipeworks.enable_pipes then
	minetest.register_abm({
		nodenames = pipes_all_nodenames,
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.balance_pressure(pos, node)
		end
	})
end

if pipeworks.enable_pipe_devices then
	-- absorb water into pumps if it'll fit
	minetest.register_abm({
		nodenames = { pump_on },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.run_pump_intake(pos, node)
		end
	})
	-- output water from spigots
	-- add both "on/off" spigots so one can be used to indicate a certain level of fluid.
	minetest.register_abm({
		nodenames = { spigot_on, spigot_off },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.run_spigot_output(pos, node)
		end
	})
end
