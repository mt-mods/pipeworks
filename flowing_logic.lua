-- This file provides the actual flow and pathfinding logic that makes water
-- move through the pipes.
--
-- Contributed by mauvebic, 2013-01-03, with tweaks by Vanessa Ezekowitz
--

local check4liquids = function(pos)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},	}
	for i =1,6 do
		local name = minetest.get_node(coords[i]).name
		if string.find(name,'water') then 
			minetest.remove_node(coords[i])
			return true
		end
	end
	return false
end

local check4inflows = function(pos,node)
	local coords = {
		{x=pos.x,y=pos.y-1,z=pos.z},
		{x=pos.x,y=pos.y+1,z=pos.z},
		{x=pos.x-1,y=pos.y,z=pos.z},
		{x=pos.x+1,y=pos.y,z=pos.z},
		{x=pos.x,y=pos.y,z=pos.z-1},
		{x=pos.x,y=pos.y,z=pos.z+1},	}
	local newnode = false
	local source = false
	for i =1,6 do
		if newnode then break end
		local name = minetest.get_node(coords[i]).name
		if (name == 'pipeworks:pump_on' and check4liquids(coords[i])) or string.find(name,'_loaded') then
			if string.find(name,'_loaded') then
				local source = minetest.get_meta(coords[i]):get_string('source')
				if source == minetest.pos_to_string(pos) then break end
			end
			newnode = string.gsub(node.name,'empty','loaded')
			source = {x=coords[i].x,y=coords[i].y,z=coords[i].z}
			if newnode ~= nil then dbg(newnode) end
		end
	end
	if newnode then 
		dbg(newnode..' to replace '..node.name) 
		minetest.add_node(pos,{name=newnode, param2 = node.param2}) 
		minetest.get_meta(pos):set_string('source',minetest.pos_to_string(source))
	end
end

local checksources = function(pos,node)
	local sourcepos = minetest.string_to_pos(minetest.get_meta(pos):get_string('source'))
	if not sourcepos then return end
	local source = minetest.get_node(sourcepos).name
	local newnode = false
	if not ((source == 'pipeworks:pump_on' and check4liquids(sourcepos)) or string.find(source,'_loaded') or source == 'ignore' ) then
		newnode = string.gsub(node.name,'loaded','empty')
	end

	if newnode then dbg(newnode..' to replace '..node.name) end
	if newnode then 
		minetest.add_node(pos,{name=newnode, param2 = node.param2}) 
		minetest.get_meta(pos):set_string('source','')
	end
end

local update_outlet = function(pos)
	local top = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z}).name
	if string.find(top,'_loaded') then
		local name = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name
		if name == 'air' or name == "default:water_source" or name == "default:water_flowing" then 
			minetest.add_node({x=pos.x,y=pos.y-1,z=pos.z},{name='default:water_source'}) 
		end
	elseif minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name == 'default:water_source' then
		minetest.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
	end
end

local spigot_check = function(pos,node)
	local fdir=node.param2
	local check = {{x=pos.x,y=pos.y,z=pos.z+1},{x=pos.x+1,y=pos.y,z=pos.z},{x=pos.x,y=pos.y,z=pos.z-1},{x=pos.x-1,y=pos.y,z=pos.z}	}
	dbg(fdir..' checking '..minetest.pos_to_string(check[fdir+1])..' for spigot at '..minetest.pos_to_string(pos))
	local top = minetest.get_node(check[fdir+1]).name
	dbg('found '..top)
	local name = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name
	if string.find(top,'_loaded') and (name == 'air' or name == "default:water_source" or name == "default:water_flowing") then 
		minetest.add_node({x=pos.x,y=pos.y-1,z=pos.z},{name='default:water_source'})
		minetest.add_node(pos,{name='pipeworks:spigot_pouring', param2 = fdir})
	else
		if minetest.get_node(pos).name == 'pipeworks:spigot_pouring' then
			minetest.add_node({x=pos.x,y=pos.y,z=pos.z},{name='pipeworks:spigot', param2 = fdir})
			if name == 'air' or name == "default:water_source" or name == "default:water_flowing" then
				minetest.remove_node({x=pos.x,y=pos.y-1,z=pos.z})
			end
		end
	end
end

table.insert(pipes_empty_nodenames,"pipeworks:valve_on_empty")
table.insert(pipes_empty_nodenames,"pipeworks:valve_off_empty")
table.insert(pipes_empty_nodenames,"pipeworks:valve_on_loaded")
table.insert(pipes_empty_nodenames,"pipeworks:entry_panel_empty")
table.insert(pipes_empty_nodenames,"pipeworks:flow_sensor_empty")

table.insert(pipes_full_nodenames,"pipeworks:valve_on_empty")
table.insert(pipes_full_nodenames,"pipeworks:valve_off_empty")
table.insert(pipes_full_nodenames,"pipeworks:valve_on_loaded")
table.insert(pipes_full_nodenames,"pipeworks:entry_panel_loaded")
table.insert(pipes_full_nodenames,"pipeworks:flow_sensor_loaded")

minetest.register_abm({
	nodenames = pipes_empty_nodenames,
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider) check4inflows(pos,node) end
})

minetest.register_abm({
	nodenames = pipes_full_nodenames,
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider) checksources(pos,node) end
})

minetest.register_abm({
	nodenames = {'pipeworks:outlet','pipeworks:spigot','pipeworks:spigot_pouring'},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider) 
		if node.name == 'pipeworks:outlet' then update_outlet(pos)
		elseif node.name == 'pipeworks:spigot' or node.name == 'pipeworks:spigot_pouring' then spigot_check(pos,node) end
	end
})
