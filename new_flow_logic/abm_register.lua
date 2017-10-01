-- register new flow logic ABMs
-- written 2017 by thetaepsilon



local register = {}
pipeworks.flowlogic.abmregister = register



-- register a node name for the pressure balancing ABM.
-- currently this only exists as a per-node function to allow nodes to be registered outside pipeworks.
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

-- register a node for the input ABM.
-- intakefn is run on the node to determine how much water can be taken (and update it's environment accordingly).
-- maxpressure is the maximum pressure that this input can drive, beyond which pressure will not be raised.
local register_abm_input = function(nodename, maxpressure, intakefn)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			pipeworks.flowlogic.run_input(pos, node, maxpressure, intakefn)
		end
	})
end
register.input = register_abm_input

-- old spigot ABM code, not yet migrated
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
