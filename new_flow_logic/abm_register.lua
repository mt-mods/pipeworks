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
