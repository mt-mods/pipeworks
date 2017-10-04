-- flowable node registry: add entries and install ABMs if new flow logic is enabled
-- written 2017 by thetaepsilon



-- use for hooking up ABMs as nodes are registered
local abmregister = pipeworks.flowlogic.abmregister

-- registration functions
pipeworks.flowables.register = {}
local register = pipeworks.flowables.register

-- some sanity checking for passed args, as this could potentially be made an external API eventually
local checkexists = function(nodename)
	if type(nodename) ~= "string" then error("pipeworks.flowables nodename must be a string!") end
	return pipeworks.flowables.list.all[nodename]
end

local insertbase = function(nodename)
	if checkexists(nodename) then error("pipeworks.flowables duplicate registration!") end
	pipeworks.flowables.list.all[nodename] = true
	-- table.insert(pipeworks.flowables.list.nodenames, nodename)
end

local regwarning = function(kind, nodename)
	local tail = ""
	if not pipeworks.toggles.pressure_logic then tail = " but pressure logic not enabled" end
	--pipeworks.logger(kind.." flow logic registry requested for "..nodename..tail)
end

-- Register a node as a simple flowable.
-- Simple flowable nodes have no considerations for direction of flow;
-- A cluster of adjacent simple flowables will happily average out in any direction.
register.simple = function(nodename)
	insertbase(nodename)
	pipeworks.flowables.list.simple[nodename] = true
	table.insert(pipeworks.flowables.list.simple_nodenames, nodename)
	if pipeworks.toggles.pressure_logic then
		abmregister.balance(nodename)
	end
	regwarning("simple", nodename)
end

local checkbase = function(nodename)
	if not checkexists(nodename) then error("pipeworks.flowables node doesn't exist as a flowable!") end
end

-- Register a node as a simple intake.
-- Expects node to be registered as a flowable (is present in flowables.list.all),
-- so that water can move out of it.
-- maxpressure is the maximum pipeline pressure that this node can drive.
-- possible WISHME here: technic-driven high-pressure pumps
register.intake_simple = function(nodename, maxpressure)
	checkbase(nodename)
	pipeworks.flowables.inputs.list[nodename] = { maxpressure=maxpressure }
	table.insert(pipeworks.flowables.inputs.nodenames, nodename)
	if pipeworks.toggles.pressure_logic then
		abmregister.input(nodename, maxpressure, pipeworks.flowlogic.check_for_liquids_v2)
	end
	regwarning("simple intake", nodename)
end

-- Register a node as an output.
-- Expects node to already be a flowable.
-- threshold and outputfn are currently as documented for register_abm_output() in abm_register.lua.
register.output = function(nodename, threshold, outputfn)
	checkbase(nodename)
	pipeworks.flowables.outputs.list[nodename] = { threshold=threshold, outputfn=outputfn }
	if pipeworks.toggles.pressure_logic then
		abmregister.output(nodename, threshold, outputfn)
	end
	regwarning("output node", nodename)
end

-- TODOs here:
-- The spigot's output behaviour (and possibly the fountain) could be abstracted out into a "simple output" of sorts,
-- which tries to place water nodes around it.
-- possibly this could be given a helper function to determine which faces a node should try,
-- to allow things like rotation or other param values determining "direction" to be respected.
