-- register new flow logic ABMs
-- written 2017 by thetaepsilon



local register = {}
pipeworks.flowlogic.abmregister = register

local flowlogic = pipeworks.flowlogic

-- A possible DRY violation here...
-- DISCUSS: should it be possible later on to raise the the rate of ABMs, or lower the chance?
-- Currently all the intervals and chances are hardcoded below.



-- register node list for the main logic function.
-- see flowlogic.run() in abms.lua.

local register_flowlogic_abm = function(nodename)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			flowlogic.run(pos, node)
		end
	})
end
register.flowlogic = register_flowlogic_abm



-- register a node name for the pressure balancing ABM.
-- currently this only exists as a per-node function to allow nodes to be registered outside pipeworks.
--[[
local register_abm_balance = function(nodename)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			flowlogic.balance_pressure(pos, node)
		end
	})
end
register.balance = register_abm_balance
]]

-- register a node for the input ABM.
-- intakefn is run on the node to determine how much water can be taken (and update it's environment accordingly).
-- maxpressure is the maximum pressure that this input can drive, beyond which pressure will not be raised.
local register_abm_input = function(nodename, maxpressure, intakefn)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			flowlogic.run_input(pos, node, maxpressure, intakefn)
		end
	})
end
register.input = register_abm_input

-- register a node for the output ABM.
-- threshold determines the minimum pressure, over which outputfn is called.
-- outputfn is then given the current pressure, and returns the pressure relieved by the output process.
-- outputfn is expected to update environment, nearby world etc. as appropriate for the node.
--[[
local register_abm_output = function(nodename, threshold, outputfn)
	minetest.register_abm({
		nodenames = { nodename },
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			flowlogic.run_output(pos, node, threshold, outputfn)
		end
	})
end
register.output = register_abm_output
]]

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
