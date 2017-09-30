-- register new flow logic ABMs
-- written 2017 by thetaepsilon



local register = {}
pipeworks.flowlogic.abmregister = register



-- note that checking for feature toggles (because otherwise certain pipes aren't define)
-- is now done by flowable_nodes_add_pipes.lua
--[[
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
]]

local register_abm_balance = function(nodename)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.flowlogic.balance_pressure(pos, node)
		end
	})
end
register.balance = register_abm_balance
for nodename, _ in pairs(pipeworks.flowables.list.simple) do
	register_abm_balance(nodename)
end

local register_abm_input = function(nodename, properties)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.flowlogic.run_pump_intake(pos, node)
		end
	})
end
register.input = register_abm_input

if pipeworks.enable_pipe_devices then
	-- absorb water into pumps if it'll fit
	for nodename, properties in pairs(pipeworks.flowables.inputs.list) do
		register_abm_input(nodename, properties)
	end

	-- output water from spigots
	-- add both "on/off" spigots so one can be used to indicate a certain level of fluid.
	-- temp. disabled as the node names were moved to flowable_node_add_pipes.lua
	--[[
	minetest.register_abm({
		nodenames = { spigot_on, spigot_off },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.run_spigot_output(pos, node)
		end
	})
	]]
end
