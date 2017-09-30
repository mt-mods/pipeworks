-- reimplementation of new_flow_logic branch: processing functions
-- written 2017 by thetaepsilon



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



-- new version of liquid check
-- accepts a limit parameter to only delete water blocks that the receptacle can accept,
-- and returns it so that the receptacle can update it's pressure values.
-- this should ensure that water blocks aren't vanished from existance.
-- will take care of zero or negative-valued limits.
pipeworks.check_for_liquids_v2 = function(pos, limit)
	if not limit then
		limit = 6
	end
	local coords = make_coords_offsets(pos, false)
	local total = 0
	for index, tpos in ipairs(coords) do
		if total >= limit then break end
		local name = minetest.get_node(tpos).name
		if name == "default:water_source" then
			minetest.remove_node(tpos)
			total = total + 1
		end
	end
	return total
end




local label_pressure = "pipeworks.water_pressure"
local label_haspressure = "pipeworks.is_pressure_node"
pipeworks.balance_pressure = function(pos, node)
	-- debuglog("balance_pressure() "..node.name.." at "..pos.x.." "..pos.y.." "..pos.z)
	-- check the pressure of all nearby nodes, and average it out.
	-- for the moment, only balance neighbour nodes if it already has a pressure value.
	-- XXX: maybe this could be used to add fluid behaviour to other mod's nodes too?

	-- unconditionally include self in nodes to average over
	local meta = minetest.get_meta(pos)
	local currentpressure = meta:get_float(label_pressure)
	meta:set_int(label_haspressure, 1)
	local connections = { meta }
	local totalv = currentpressure
	local totalc = 1

	-- then handle neighbours, but if not a pressure node don't consider them at all
	for _, npos in ipairs(make_coords_offsets(pos, false)) do
		local neighbour = minetest.get_meta(npos)
		local haspressure = (neighbour:get_int(label_haspressure) ~= 0)
		if haspressure then
			local n = neighbour:get_float(label_pressure)
			table.insert(connections, neighbour)
			totalv = totalv + n
			totalc = totalc + 1
		end
	end

	local average = totalv / totalc
	for _, targetmeta in ipairs(connections) do
		targetmeta:set_float(label_pressure, average)
	end
end



pipeworks.run_pump_intake = function(pos, node)
	-- try to absorb nearby water nodes, but only up to limit.
	-- NB: check_for_liquids_v2 handles zero or negative from the following subtraction

	local properties = pipeworks.flowables.inputs.list[node.name]
	local maxpressure = properties.maxpressure

	local meta = minetest.get_meta(pos)
	local currentpressure = meta:get_float(label_pressure)
	
	local intake_limit = maxpressure - currentpressure
	local actual_intake = pipeworks.check_for_liquids_v2(pos, intake_limit)
	local newpressure = actual_intake + currentpressure
	-- debuglog("oldpressure "..currentpressure.." intake_limit "..intake_limit.." actual_intake "..actual_intake.." newpressure "..newpressure)
	meta:set_float(label_pressure, newpressure)
end



pipeworks.run_spigot_output = function(pos, node)
	-- try to output a water source node if there's enough pressure and space below.
	local meta = minetest.get_meta(pos)
	local currentpressure = meta:get_float(label_pressure)
	if currentpressure > 1 then
		local below = {x=pos.x, y=pos.y-1, z=pos.z}
		local name = minetest.get_node(below).name
		if (name == "air") or (name == "default:water_flowing") then
			minetest.set_node(below, {name="default:water_source"})
			meta:set_float(label_pressure, currentpressure - 1)
		end
	end
end
