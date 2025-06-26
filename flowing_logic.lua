-- This file provides the actual flow and pathfinding logic that makes water
-- move through the pipes.
--
-- Contributed by mauvebic, 2013-01-03, rewritten a bit by Vanessa Ezekowitz
--

local finitewater = core.settings:get_bool("liquid_finite")

pipeworks.check_for_liquids = function(pos)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},	}
	for i =1,6 do
		local name = core.get_node(coords[i]).name
		if name and string.find(name,"water") then
			if finitewater then core.remove_node(coords[i]) end
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
		local testnode = core.get_node(coords[i])
		local name = testnode.name
		if name and (name == "pipeworks:pump_on" and pipeworks.check_for_liquids(coords[i])) or string.find(name,"_loaded") then
			if string.find(name,"_loaded") then
				source = core.get_meta(coords[i]):get_string("source")
				if source == core.pos_to_string(pos) then break end
			end
			if string.find(name, "valve") or string.find(name, "sensor")
			  or string.find(name, "straight_pipe") or string.find(name, "panel") then

				if ((i == 3 or i == 4) and core.facedir_to_dir(testnode.param2).x ~= 0)
				  or ((i == 5 or i == 6) and core.facedir_to_dir(testnode.param2).z ~= 0)
				  or ((i == 1 or i == 2) and core.facedir_to_dir(testnode.param2).y ~= 0) then

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
		core.add_node(pos,{name=newnode, param2 = node.param2})
		core.get_meta(pos):set_string("source",core.pos_to_string(source))
	end
end

pipeworks.check_sources = function(pos,node)
	local sourcepos = core.string_to_pos(core.get_meta(pos):get_string("source"))
	if not sourcepos then return end
	local source = core.get_node(sourcepos).name
	local newnode = false
	if source and not ((source == "pipeworks:pump_on" and pipeworks.check_for_liquids(sourcepos)) or string.find(source,"_loaded") or source == "ignore" ) then
		newnode = string.gsub(node.name,"loaded","empty")
	end

	if newnode then
		core.add_node(pos,{name=newnode, param2 = node.param2})
		core.get_meta(pos):set_string("source","")
	end
end

pipeworks.spigot_check = function(pos, node)
	local belowname = core.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name
	if belowname and (belowname == "air" or belowname == pipeworks.liquids.water.flowing or belowname == pipeworks.liquids.water.source) then
		local spigotname = core.get_node(pos).name
		local fdir=node.param2 % 4
		local check = {
			{x=pos.x,y=pos.y,z=pos.z+1},
			{x=pos.x+1,y=pos.y,z=pos.z},
			{x=pos.x,y=pos.y,z=pos.z-1},
			{x=pos.x-1,y=pos.y,z=pos.z}
		}
		local near_node = core.get_node(check[fdir+1])
		if near_node and string.find(near_node.name, "_loaded") then
			if spigotname and spigotname == "pipeworks:spigot" then
				core.add_node(pos,{name = "pipeworks:spigot_pouring", param2 = fdir})
				if finitewater or belowname ~= pipeworks.liquids.water.source then
					core.add_node({x=pos.x,y=pos.y-1,z=pos.z},{name = pipeworks.liquids.water.source})
				end
			end
		else
			if spigotname == "pipeworks:spigot_pouring" then
				core.add_node({x=pos.x,y=pos.y,z=pos.z},{name = "pipeworks:spigot", param2 = fdir})
				if belowname == pipeworks.liquids.water.source and not finitewater then
					core.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
				end
			end
		end
	end
end

pipeworks.fountainhead_check = function(pos, node)
	local abovename = core.get_node({x=pos.x,y=pos.y+1,z=pos.z}).name
	if abovename and (abovename == "air" or abovename == pipeworks.liquids.water.flowing or abovename == pipeworks.liquids.water.source) then
		local fountainhead_name = core.get_node(pos).name
		local near_node = core.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		if near_node and string.find(near_node.name, "_loaded") then
			if fountainhead_name and fountainhead_name == "pipeworks:fountainhead" then
				core.add_node(pos,{name = "pipeworks:fountainhead_pouring"})
				if finitewater or abovename ~= pipeworks.liquids.water.source then
					core.add_node({x=pos.x,y=pos.y+1,z=pos.z},{name = pipeworks.liquids.water.source})
				end
			end
		else
			if fountainhead_name == "pipeworks:fountainhead_pouring" then
				core.add_node({x=pos.x,y=pos.y,z=pos.z},{name = "pipeworks:fountainhead"})
				if abovename == pipeworks.liquids.water.source and not finitewater then
					core.remove_node({x=pos.x,y=pos.y+1,z=pos.z})
				end
			end
		end
	end
end
