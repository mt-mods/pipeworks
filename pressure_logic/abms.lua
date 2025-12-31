-- reimplementation of new_flow_logic branch: processing functions
-- written 2017 by thetaepsilon



local flowlogic = {}
flowlogic.helpers = {}
pipeworks.flowlogic = flowlogic



-- borrowed from above: might be useable to replace the above coords tables
local make_coords_offsets = function(pos, include_base)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},
	}
	if include_base then table.insert(coords, pos) end
	return coords
end



-- local debuglog = function(msg) print("## "..msg) end



--~ local formatvec = function(vec) local sep="," return "("..tostring(vec.x)..sep..tostring(vec.y)..sep..tostring(vec.z)..")" end



-- new version of liquid check
-- accepts a limit parameter to only delete fluid blocks that the receptacle can accept,
-- and returns it so that the receptacle can update it's pressure values.
local check_for_liquids_v2 = function(pos, limit, current_type)
	if limit == 0 then return 0, current_type end
	local coords = make_coords_offsets(pos, false)
	local total = 0
	local fluid_type = (core.get_meta(pos):get_float("pipeworks.pressure") > 0.001) and current_type
	local fluid_nodename = fluid_type and pipeworks.liquids[current_type].source
	for _, tpos in ipairs(coords) do
		local name = core.get_node(tpos).name
		if name == core.registered_nodes[name].liquid_alternative_source then -- if node is fluid source
			if not fluid_type then
				fluid_type = pipeworks.fluid_types[name]
				if fluid_type then fluid_nodename = name end
			end
			if name == fluid_nodename then
				core.remove_node(tpos)
				total = total + 1
				if total >= limit then break end
			end
		end
	end
	--pipeworks.logger("check_for_liquids_v2@"..formatvec(pos).." total "..total)

	return total, fluid_type
end
flowlogic.check_for_liquids_v2 = check_for_liquids_v2



local label_pressure = "pipeworks.pressure"
local get_pressure_access = function(pos)
	local metaref = core.get_meta(pos)
	return {
		get = function()
			return metaref:get_float(label_pressure)
		end,
		set = function(v)
			metaref:set_float(label_pressure, v)
		end
	}
end

local label_type = "pipeworks.fluid_type"
local get_fluid_type_access = function(pos)
	local metaref = core.get_meta(pos)
	return {
		get = function()
			return metaref:get(label_type)
		end,
		set = function(v)
			metaref:set_string(label_type, v)
		end
	}
end

-- logging is unreliable when something is crashing...
--[[
local nilexplode = function(caller, label, value)
	if value == nil then
		error(caller..": "..label.." was nil")
	end
end
--]]



local finitemode = pipeworks.toggles.finite
local finites = pipeworks.toggles.finites
flowlogic.run = function(pos, node)
	local nodename = node.name
	-- get the current pressure value.
	local nodepressure = get_pressure_access(pos)
	local currentpressure = nodepressure.get()
	local oldpressure = currentpressure
	local nodefluidtype = get_fluid_type_access(pos)
	local currentfluidtype = nodefluidtype.get()
	local finitemode = finitemode or finites[currentfluidtype]

	-- if node is an input: run intake phase
	local inputdef = pipeworks.flowables.inputs.list[nodename]
	if inputdef then
		currentpressure, currentfluidtype = flowlogic.run_input(pos, node, currentpressure, inputdef, currentfluidtype)
		--debuglog("post-intake currentpressure is "..currentpressure)
		--nilexplode("run()", "currentpressure", currentpressure)
	end

	-- balance pressure with neighbours
	currentpressure, currentfluidtype = flowlogic.balance_pressure(pos, node, currentpressure, currentfluidtype)

	-- if node is an output: run output phase
	local outputdef = pipeworks.flowables.outputs.list[nodename]
	if outputdef then
		currentpressure, currentfluidtype = flowlogic.run_output(
			pos,
			node,
			currentpressure,
			oldpressure,
			outputdef,
			finitemode,
			currentfluidtype)
	end

	-- if node has pressure transitions: determine new node
	if pipeworks.flowables.transitions.list[nodename] then
		local newnode = flowlogic.run_transition(node, currentpressure, currentfluidtype)
		--pipeworks.logger("flowlogic.run()@"..formatvec(pos).." transition, new node name = "..dump(newnode).." pressure "..tostring(currentpressure))
		core.swap_node(pos, newnode)
		flowlogic.run_transition_post(pos, newnode)
	end

	-- set the new pressure and type
	nodepressure.set(currentpressure)
	nodefluidtype.set(currentfluidtype)
end



local simple_neighbour_offsets = {
		{x=0, y=-1,z= 0},
		{x=0, y= 1,z= 0},
		{x=-1,y= 0,z= 0},
		{x= 1,y= 0,z= 0},
		{x= 0,y= 0,z=-1},
		{x= 0,y= 0,z= 1},
}
local get_neighbour_positions = function(pos, node)
	-- local dname = "get_neighbour_positions@"..formatvec(pos).." "
	-- get list of node neighbours.
	-- if this node is directional and only flows on certain sides,
	-- invoke the callback to retrieve the set.
	-- for simple flowables this is just an auto-gen'd list of all six possible neighbours.
	local candidates = {}
	if pipeworks.flowables.list.simple[node.name] then
		candidates = simple_neighbour_offsets
	else
		-- directional flowables: call the callback to get the list
		local directional = pipeworks.flowables.list.directional[node.name]
		if directional then
			--pipeworks.logger(dname.."invoking neighbourfn")
			local offsets = directional.neighbourfn(node)
			candidates = offsets
		end
	end

	-- then, check each possible neighbour to see if they can be reached from this node.
	local connections = {}
	local tconnections = {}
	local offsets = {}
	for _, offset in ipairs(candidates) do
		local npos = vector.add(pos, offset)
		local neighbour = core.get_node(npos)
		local nodename = neighbour.name
		local is_simple = (pipeworks.flowables.list.simple[nodename])
		if is_simple then
			table.insert(connections, get_pressure_access(npos))
			table.insert(tconnections, get_fluid_type_access(npos))
			table.insert(offsets, offset)
		else
			-- if target node is also directional, check if it agrees it can flow in that direction
			local directional = pipeworks.flowables.list.directional[nodename]
			if directional then
				--pipeworks.logger(dname.."directionality test for offset "..formatvec(offset))
				local towards_origin = vector.multiply(offset, -1)
				--pipeworks.logger(dname.."vector passed to directionfn: "..formatvec(towards_origin))
				local result = directional.directionfn(neighbour, towards_origin)
				--pipeworks.logger(dname.."result: "..tostring(result))
				if result then
					table.insert(connections, get_pressure_access(npos))
					table.insert(tconnections, get_fluid_type_access(npos))
					table.insert(offsets, offset)
				end
			end
		end
	end

	return connections, tconnections, offsets
end



flowlogic.balance_pressure = function(pos, node, currentpressure, currentfluidtype)
	if not pipeworks.liquids[currentfluidtype] then return 0, nil end
	-- local dname = "flowlogic.balance_pressure()@"..formatvec(pos).." "
	-- check the pressure of all nearby flowable nodes, and average it out.

	-- unconditionally include self in nodes to average over.
	-- result of averaging will be returned as new pressure for main flow logic callback

	-- pressure handles to average over
	local connections, tconnections, offsets = get_neighbour_positions(pos, node)

	if #connections == 0 then return currentpressure, currentfluidtype end

	local total_pressure = currentpressure

	-- cached values
	local pressures = {}
	local fluid_types = {}
	local biases = {}

	-- same-type connections
	local migrate = {}

	-- connections that force current fluid out
	local intrusive = {}

	for k, connection in ipairs(connections) do
		-- cache values
		pressures[k] = connection.get()
		fluid_types[k] = tconnections[k].get()
		biases[k] = (pipeworks.liquids[fluid_types[k]] and (pressures[k] * pipeworks.liquids[fluid_types[k]].density * vector.dot(pipeworks.gravity, offsets[k]))) or 0 -- get gravitational bias
		biases[k] = math.max(math.min(biases[k], pressures[k]), -pressures[k])
		if biases[k] then pressures[k] = pressures[k] - biases[k] end -- apply bias
		if (not fluid_types[k]) or (pressures[k] < 0.001) or currentfluidtype == fluid_types[k] then
			-- get same-type connections
			migrate[#migrate + 1] = k
			-- for each neighbour, add neighbour's pressure to the total to balance out
			if currentfluidtype == fluid_types[k] then total_pressure = total_pressure + pressures[k] end
		elseif pressures[k] > (2 * currentpressure) then -- check for high-pressure "intrusive" connections
			intrusive[#intrusive + 1] = k
		end
	end

	if #migrate == 0 then return currentpressure, currentfluidtype end

	-- average values
	local pressure_count = #migrate + 1
	local currentpressure = total_pressure / pressure_count
	for k, migrated in ipairs(migrate) do
		pressures[migrated] = currentpressure
		currentfluidtype = currentfluidtype or fluid_types[migrated]
		fluid_types[migrated] = currentfluidtype
	end

	if #intrusive > 0 then
		-- take from most "intrusive" connection
		local add = currentpressure / #migrate
		if #intrusive == 1 then
			local intruder = intrusive[1]
			-- put current fluid in migration
			for _, migrated in ipairs(migrate) do
				pressures[migrated] = pressures[migrated] + add
			end
			-- overwritingly distribute intrusive
			currentfluidtype = fluid_types[intruder]
			currentpressure = (pressures[intruder] - biases[intruder]) * 0.5
			pressures[intruder] = currentpressure + biases[intruder]
		else
			-- find most "intrusive" connection
			local highest_pressure = 0
			local most_intrusive
			for _, intruder in ipairs(intrusive) do
				if pressures[intruder] > highest_pressure then
					most_intrusive = intruder
				end
			end
			-- put current fluid in migration
			for _, migrated in ipairs(migrate) do
				pressures[migrated] = pressures[migrated] + add
			end
			-- overwritingly distribute intrusive
			currentfluidtype = fluid_types[most_intrusive]
			currentpressure = (pressures[most_intrusive] - biases[most_intrusive]) * 0.5
			pressures[most_intrusive] = currentpressure + biases[most_intrusive]
		end
	end

	-- unapply biases
	for k, bias in pairs(biases) do
		pressures[k] = pressures[k] + bias
	end

	-- set pressures and types
	for k, pressure in ipairs(pressures) do
		connections[k].set(pressure)
		tconnections[k].set(fluid_types[k])
	end

	return currentpressure, currentfluidtype
end



flowlogic.run_input = function(pos, node, currentpressure, inputdef, currentfluidtype)
	-- intakefn allows a given input node to define it's own intake logic.
	-- this function will calculate the maximum amount of fluid that can be taken in;
	-- the intakefn will be given this and is expected to return the actual absorption amount.

	local maxpressure = inputdef.maxpressure
	local intake_limit = maxpressure - currentpressure
	if intake_limit <= 0 then return currentpressure, currentfluidtype end

	local actual_intake, newtype = inputdef.intakefn(pos, intake_limit, currentfluidtype)
	--pipeworks.logger("run_input@"..formatvec(pos).." oldpressure "..currentpressure.." intake_limit "..intake_limit.." actual_intake "..actual_intake)
	if actual_intake <= 0 then return currentpressure, newtype end

	local newpressure = actual_intake + currentpressure
	--debuglog("run_input() end, oldpressure "..currentpressure.." intake_limit "..intake_limit.." actual_intake "..actual_intake.." newpressure "..newpressure)
	return newpressure, newtype
end



-- flowlogic output helper implementation:
-- outputs fluid by trying to place fluid nodes nearby in the world.
-- neighbours is a list of node offsets to try placing fluid in.
-- this is a constructor function, returning another function which satisfies the output helper requirements.
-- note that this does *not* take rotation into account.
flowlogic.helpers.make_neighbour_output_fixed = function(neighbours)
	return function(pos, node, currentpressure, finitemode, currentfluidtype)
		if not currentfluidtype then return 0, currentfluidtype end
		local finitemode = finitemode or finites[currentfluidtype]
		local taken = 0
		for _, offset in pairs(neighbours) do
			local npos = vector.add(pos, offset)
			local name = core.get_node(npos).name
			if currentpressure < 1 then break end
			-- take pressure anyway in non-finite mode, even if node is fluid source already.
			-- in non-finite mode, pressure has to be sustained to keep the sources there.
			-- so in non-finite mode, placing fluid is dependent on the target node;
			-- draining pressure is not.
			local canplace = (name == "air") or (core.registered_nodes[name] == core.registered_nodes[name].liquid_alternative_flowing)
			if canplace then
				core.swap_node(npos, {name=pipeworks.liquids[currentfluidtype].source})
			end
			if (not finitemode) or canplace then
				taken = taken + 1
				currentpressure = currentpressure - 1
			end
		end
		return taken, currentfluidtype
	end
end

-- complementary function to the above when using non-finite mode:
-- removes fluid sources from neighbor positions when the output is "off" due to lack of pressure.
flowlogic.helpers.make_neighbour_cleanup_fixed = function(neighbours)
	return function(pos, node, currentpressure)
		--pipeworks.logger("neighbour_cleanup_fixed@"..formatvec(pos))
		for _, offset in pairs(neighbours) do
			local npos = vector.add(pos, offset)
			local name = core.get_node(npos).name
			if (name == core.registered_nodes[name].liquid_alternative_source) then
				--pipeworks.logger("neighbour_cleanup_fixed removing "..formatvec(npos))
				core.remove_node(npos)
			end
		end
	end
end



flowlogic.run_output = function(pos, node, currentpressure, oldpressure, outputdef, finitemode, currentfluidtype)
	-- processing step for fluid output devices.
	-- takes care of checking a minimum pressure value and updating the resulting pressure level
	-- the outputfn is provided the current pressure and returns the pressure "taken".
	-- as an example, using this with the above spigot function,
	-- the spigot function tries to output a fluid source if it will fit in the world.
	--pipeworks.logger("flowlogic.run_output() pos "..formatvec(pos).." old -> currentpressure "..tostring(oldpressure).." "..tostring(currentpressure).." finitemode "..tostring(finitemode))
	local finitemode = finitemode or finites[currentfluidtype]
	local upper = outputdef.upper
	local lower = outputdef.lower
	local result = currentpressure
	local threshold
	if finitemode then threshold = lower else threshold = upper end
	if currentpressure > threshold then
		local takenpressure
		takenpressure, currentfluidtype = outputdef.outputfn(pos, node, currentpressure, finitemode, currentfluidtype)
		local newpressure = currentpressure - takenpressure
		if newpressure < 0 then newpressure = 0 end
		result = newpressure
	end
	if (not finitemode) and (currentpressure < lower) and (oldpressure < lower) then
		--pipeworks.logger("flowlogic.run_output() invoking cleanup currentpressure="..tostring(currentpressure))
		outputdef.cleanupfn(pos, node, currentpressure, currentfluidtype)
	end
	return result, currentfluidtype
end



-- determine which node to switch to based on current pressure
flowlogic.run_transition = function(node, currentpressure, currentfluidtype) --WISHME: maybe use fluid type in transitions
	local simplesetdef = pipeworks.flowables.transitions.simple[node.name]
	local result = node
	local found = false

	-- simple transition sets: assumes all nodes in the set share param values.
	if simplesetdef then
		-- assumes that the set has been checked to contain at least one element...
		local nodename_prev = simplesetdef[1].nodename
		local result_nodename = node.name

		for _, element in ipairs(simplesetdef) do
			-- find the highest element that is below the current pressure.
			local threshold = element.threshold
			if threshold > currentpressure then
				result_nodename = nodename_prev
				found = true
				break
			end
			nodename_prev = element.nodename
		end

		-- use last element if no threshold is greater than current pressure
		if not found then
			result_nodename = nodename_prev
			found = true
		end

		-- preserve param1/param2 values
		result = { name=result_nodename, param1=node.param1, param2=node.param2 }
	end

	if not found then
		pipeworks.logger("flowlogic.run_transition() BUG no transition " ..
			"definitions found! node.name=" .. node.name ..
			" currentpressure=" .. tostring(currentpressure))
	end

	return result
end

-- post-update hook for run_transition
-- among other things, updates mesecons if present.
-- node here means the new node, returned from run_transition() above
flowlogic.run_transition_post = function(pos, node)
	local mesecons_def = core.registered_nodes[node.name].mesecons
	local mesecons_rules = pipeworks.flowables.transitions.mesecons[node.name]
	if core.get_modpath("mesecons") and (mesecons_def ~= nil) and mesecons_rules then
		if type(mesecons_def) ~= "table" then
			pipeworks.logger("flowlogic.run_transition_post() BUG mesecons def for "..node.name.."not a table: got "..tostring(mesecons_def))
		else
			local receptor = mesecons_def.receptor
			if receptor then
				local state = receptor.state
				if state == mesecon.state.on then
					mesecon.receptor_on(pos, mesecons_rules)
				elseif state == mesecon.state.off then
					mesecon.receptor_off(pos, mesecons_rules)
				end
			end
		end
	end
end
