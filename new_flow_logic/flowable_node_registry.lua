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
