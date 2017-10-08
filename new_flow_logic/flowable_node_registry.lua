-- registry of flowable node behaviours in new flow logic
-- written 2017 by thetaepsilon

-- the actual registration functions which edit these tables can be found in flowable_node_registry_install.lua
-- this is because the ABM code needs to inspect these tables,
-- but the registration code needs to reference said ABM code.
-- so those functions were split out to resolve a circular dependency.



pipeworks.flowables = {}
pipeworks.flowables.list = {}
pipeworks.flowables.list.all = {}
-- pipeworks.flowables.list.nodenames = {}

-- simple flowables - balance pressure in any direction
pipeworks.flowables.list.simple = {}
pipeworks.flowables.list.simple_nodenames = {}

-- simple intakes - try to absorb any adjacent water nodes
pipeworks.flowables.inputs = {}
pipeworks.flowables.inputs.list = {}
pipeworks.flowables.inputs.nodenames = {}

-- outputs - takes pressure from pipes and update world to do something with it
pipeworks.flowables.outputs = {}
pipeworks.flowables.outputs.list = {}
-- not currently any nodenames arraylist for this one as it's not currently needed.

-- nodes with registered node transitions
-- nodes will be switched depending on pressure level
pipeworks.flowables.transitions = {}
pipeworks.flowables.transitions.list = {}	-- master list
pipeworks.flowables.transitions.simple = {}	-- nodes that change based purely on pressure
pipeworks.flowables.transitions.mesecons = {}	-- table of mesecons rules to apply on transition



-- checks if a given node can flow in a given direction.
-- used to implement directional devices such as pumps,
-- which only visually connect in a certain direction.
-- node is the usual name + param structure.
-- direction is an x/y/z vector of the flow direction;
-- this function answers the question "can this node flow in this direction?"
pipeworks.flowables.flow_check = function(node, direction)
	minetest.log("warning", "pipeworks.flowables.flow_check() stub!")
	return true
end
