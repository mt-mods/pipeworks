-- This file provides the actual flow and pathfinding logic that makes water
-- move through the pipes.
--
-- Contributed by mauvebic, 2013-01-03, rewritten a bit by Vanessa Ezekowitz
--

local finitewater = minetest.settings:get_bool("liquid_finite")

pipeworks.check_for_liquids = function(pos)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},	}
	for i =1,6 do
		local name = minetest.get_node(coords[i]).name
		if name and string.find(name,"water") then
			if finitewater then minetest.remove_node(coords[i]) end
			return true
		end
	end
	return false
end

pipeworks.check_for_inflows = function(pos,node)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},
	}
	local newnode = false
	local source = false
	for i = 1, 6 do
		if newnode then break end
		local testnode = minetest.get_node(coords[i])
		local name = testnode.name
		if name and (name == "pipeworks:pump_on" and pipeworks.check_for_liquids(coords[i])) or string.find(name,"_loaded") then
			if string.find(name,"_loaded") then
				source = minetest.get_meta(coords[i]):get_string("source")
				if source == minetest.pos_to_string(pos) then break end
			end
			if string.find(name, "valve") or string.find(name, "sensor") then

				if ((i == 3 or i == 4) and minetest.facedir_to_dir(testnode.param2).x ~= 0)
				  or ((i == 5 or i == 6) and minetest.facedir_to_dir(testnode.param2).z ~= 0)
				  or ((i == 1 or i == 2) and minetest.facedir_to_dir(testnode.param2).y ~= 0) then

					newnode = string.gsub(node.name,"empty","loaded")
					source = {x=coords[i].x,y=coords[i].y,z=coords[i].z}
				end
			else
				newnode = string.gsub(node.name,"empty","loaded")
				source = {x=coords[i].x,y=coords[i].y,z=coords[i].z}
			end
		end
	end
	if newnode then 
		minetest.add_node(pos,{name=newnode, param2 = node.param2}) 
		minetest.get_meta(pos):set_string("source",minetest.pos_to_string(source))
	end
end

pipeworks.check_sources = function(pos,node)
	local sourcepos = minetest.string_to_pos(minetest.get_meta(pos):get_string("source"))
	if not sourcepos then return end
	local source = minetest.get_node(sourcepos).name
	local newnode = false
	if source and not ((source == "pipeworks:pump_on" and pipeworks.check_for_liquids(sourcepos)) or string.find(source,"_loaded") or source == "ignore" ) then
		newnode = string.gsub(node.name,"loaded","empty")
	end

	if newnode then 
		minetest.add_node(pos,{name=newnode, param2 = node.param2}) 
		minetest.get_meta(pos):set_string("source","")
	end
end

pipeworks.spigot_check = function(pos, node)
	local belowname = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name
	if belowname and (belowname == "air" or belowname == "default:water_flowing" or belowname == "default:water_source") then 
		local spigotname = minetest.get_node(pos).name
		local fdir=node.param2 % 4
		local check = {
			{x=pos.x,y=pos.y,z=pos.z+1},
			{x=pos.x+1,y=pos.y,z=pos.z},
			{x=pos.x,y=pos.y,z=pos.z-1},
			{x=pos.x-1,y=pos.y,z=pos.z}
		}
		local near_node = minetest.get_node(check[fdir+1])
		if near_node and string.find(near_node.name, "_loaded") then
			if spigotname and spigotname == "pipeworks:spigot" then
				minetest.add_node(pos,{name = "pipeworks:spigot_pouring", param2 = fdir})
				if finitewater or belowname ~= "default:water_source" then
					minetest.add_node({x=pos.x,y=pos.y-1,z=pos.z},{name = "default:water_source"})
				end
			end
		else
			if spigotname == "pipeworks:spigot_pouring" then
				minetest.add_node({x=pos.x,y=pos.y,z=pos.z},{name = "pipeworks:spigot", param2 = fdir})
				if belowname == "default:water_source" and not finitewater then
					minetest.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
				end
			end
		end
	end
end

pipeworks.fountainhead_check = function(pos, node)
	local abovename = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z}).name
	if abovename and (abovename == "air" or abovename == "default:water_flowing" or abovename == "default:water_source") then 
		local fountainhead_name = minetest.get_node(pos).name
		local near_node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		if near_node and string.find(near_node.name, "_loaded") then
			if fountainhead_name and fountainhead_name == "pipeworks:fountainhead" then
				minetest.add_node(pos,{name = "pipeworks:fountainhead_pouring"})
				if finitewater or abovename ~= "default:water_source" then
					minetest.add_node({x=pos.x,y=pos.y+1,z=pos.z},{name = "default:water_source"})
				end
			end
		else
			if fountainhead_name == "pipeworks:fountainhead_pouring" then
				minetest.add_node({x=pos.x,y=pos.y,z=pos.z},{name = "pipeworks:fountainhead"})
				if abovename == "default:water_source" and not finitewater then
					minetest.remove_node({x=pos.x,y=pos.y+1,z=pos.z})
				end
			end
		end
	end
end



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



-- new version of liquid check
-- accepts a limit parameter to only delete water blocks that the receptacle can accept,
-- and returns it so that the receptacle can update it's pressure values.
-- this should ensure that water blocks aren't vanished from existance.
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
