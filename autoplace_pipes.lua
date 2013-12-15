-- autorouting for pipes

local function autoroute_pipes(pos, state)
	local nctr = minetest.get_node(pos)
	if (string.find(nctr.name, "pipeworks:pipe_") == nil) then return end

	local nsurround = pipeworks.scan_pipe_surroundings(pos)

	if nsurround == "000000" then nsurround = "110000" end
	minetest.add_node(pos, { name = "pipeworks:pipe_"..nsurround..state })
end

function pipeworks.scan_for_pipe_objects(pos)
	autoroute_pipes({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_loaded")
	autoroute_pipes({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_loaded")
	autoroute_pipes({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_loaded")
	autoroute_pipes({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_loaded")
	autoroute_pipes({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_loaded")
	autoroute_pipes({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_loaded")
	autoroute_pipes(pos, "_loaded")

	autoroute_pipes({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_empty")
	autoroute_pipes({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_empty")
	autoroute_pipes({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_empty")
	autoroute_pipes({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_empty")
	autoroute_pipes({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_empty")
	autoroute_pipes({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_empty")
	autoroute_pipes(pos, "_empty")
end

-- auto-rotation code for various devices the tubes attach to

function pipeworks.scan_pipe_surroundings(pos)
	local pxm=0
	local pxp=0
	local pym=0
	local pyp=0
	local pzm=0
	local pzp=0

	local nxm = minetest.get_node({ x=pos.x-1, y=pos.y  , z=pos.z   })
	local nxp = minetest.get_node({ x=pos.x+1, y=pos.y  , z=pos.z   })
	local nym = minetest.get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })
	local nyp = minetest.get_node({ x=pos.x  , y=pos.y+1, z=pos.z   })
	local nzm = minetest.get_node({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	local nzp = minetest.get_node({ x=pos.x  , y=pos.y  , z=pos.z+1 })

	if (string.find(nxm.name, "pipeworks:pipe_") ~= nil) then pxm=1 end
	if (string.find(nxp.name, "pipeworks:pipe_") ~= nil) then pxp=1 end
	if (string.find(nym.name, "pipeworks:pipe_") ~= nil) then pym=1 end
	if (string.find(nyp.name, "pipeworks:pipe_") ~= nil) then pyp=1 end
	if (string.find(nzm.name, "pipeworks:pipe_") ~= nil) then pzm=1 end
	if (string.find(nzp.name, "pipeworks:pipe_") ~= nil) then pzp=1 end

-- Special handling for valves...

	if (string.find(nxm.name, "pipeworks:valve") ~= nil)
	  and (nxm.param2 == 0 or nxm.param2 == 2) then
		pxm=1
	end

	if (string.find(nxp.name, "pipeworks:valve") ~= nil)
	  and (nxp.param2 == 0 or nxp.param2 == 2) then
		pxp=1
	end

	if (string.find(nzm.name, "pipeworks:valve") ~= nil)
	  and (nzm.param2 == 1 or nzm.param2 == 3) then
		pzm=1
	end

	if (string.find(nzp.name, "pipeworks:valve") ~= nil)
	  and (nzp.param2 == 1 or nzp.param2 == 3) then
		pzp=1
	end

-- ...flow sensors...

	if (string.find(nxm.name, "pipeworks:flow_sensor") ~= nil)
	  and (nxm.param2 == 0 or nxm.param2 == 2) then
		pxm=1
	end

	if (string.find(nxp.name, "pipeworks:flow_sensor") ~= nil)
	  and (nxp.param2 == 0 or nxp.param2 == 2) then
		pxp=1
	end

	if (string.find(nzm.name, "pipeworks:flow_sensor") ~= nil)
	  and (nzm.param2 == 1 or nzm.param2 == 3) then
		pzm=1
	end

	if (string.find(nzp.name, "pipeworks:flow_sensor") ~= nil)
	  and (nzp.param2 == 1 or nzp.param2 == 3) then
		pzp=1
	end

-- ...spigots...

	if (string.find(nxm.name, "pipeworks:spigot") ~= nil)
	  and nxm.param2 == 1 then
		pxm=1
	end

	if (string.find(nxp.name, "pipeworks:spigot") ~= nil)
	  and nxp.param2 == 3 then
		pxp=1
	end

	if (string.find(nzm.name, "pipeworks:spigot") ~= nil)
	  and nzm.param2 == 0 then
		pzm=1
	end

	if (string.find(nzp.name, "pipeworks:spigot") ~= nil)
	  and nzp.param2 == 2 then
		pzp=1
	end

-- ...sealed pipe entry/exit...

	if (string.find(nxm.name, "pipeworks:entry_panel") ~= nil)
	  and (nxm.param2 == 1 or nxm.param2 == 3) then
		pxm=1
	end

	if (string.find(nxp.name, "pipeworks:entry_panel") ~= nil)
	  and (nxp.param2 == 1 or nxp.param2 == 3) then
		pxp=1
	end

	if (string.find(nzm.name, "pipeworks:entry_panel") ~= nil)
	  and (nzm.param2 == 0 or nzm.param2 == 2) then
		pzm=1
	end

	if (string.find(nzp.name, "pipeworks:entry_panel") ~= nil)
	  and (nzp.param2 == 0 or nzp.param2 == 2) then
		pzp=1
	end

	if (string.find(nym.name, "pipeworks:entry_panel") ~= nil)
	  and nym.param2 == 13 then
		pym=1
	end

	if (string.find(nyp.name, "pipeworks:entry_panel") ~= nil)
	  and nyp.param2 == 13 then
		pyp=1
	end


-- ...pumps, grates...

	if (string.find(nym.name, "pipeworks:grating") ~= nil) or
	   (string.find(nym.name, "pipeworks:pump") ~= nil) then
		pym=1
	end

-- ...fountainheads...

	if (string.find(nyp.name, "pipeworks:fountainhead") ~= nil) then
		pyp=1
	end

-- ... and storage tanks.

	if (string.find(nym.name, "pipeworks:storage_tank_") ~= nil) then
		pym=1
	end

	if (string.find(nyp.name, "pipeworks:storage_tank_") ~= nil) then
		pyp=1
	end

-- ...extra devices specified via the function's parameters
-- ...except that this part is not implemented yet
--
-- xxx = nxm, nxp, nym, nyp, nzm, or nzp depending on the direction to check
-- yyy = pxm, pxp, pym, pyp, pzm, or pzp accordingly.
--
--	if string.find(xxx.name, "modname:nodename") ~= nil then
--		yyy = 1
--	end
--
-- for example:
--
--	if string.find(nym.name, "aero:outlet") ~= nil then
--		pym = 1
--	end
--

	return pxm..pxp..pym..pyp..pzm..pzp
end

function pipeworks.look_for_stackable_tanks(pos)
	local tym = minetest.get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })

	if string.find(tym.name, "pipeworks:storage_tank_") ~= nil or
	    string.find(tym.name, "pipeworks:expansion_tank_") ~= nil then
		minetest.add_node(pos, { name =  "pipeworks:expansion_tank_0", param2 = tym.param2})
	end
end

