-- autorouting for pipes

function pipe_scanforobjects(pos)
	pipe_autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_loaded")
	pipe_autoroute(pos, "_loaded")

	pipe_autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_empty")
	pipe_autoroute(pos, "_empty")
end

function pipe_autoroute(pos, state)
	nctr = minetest.env:get_node(pos)
	if (string.find(nctr.name, "pipeworks:pipe_") == nil) then return end

	pipes_scansurroundings(pos)

	nsurround = pxm..pxp..pym..pyp..pzm..pzp
	if nsurround == "000000" then nsurround = "110000" end
	minetest.env:add_node(pos, { name = "pipeworks:pipe_"..nsurround..state })
end

-- autorouting for pneumatic tubes

function tube_scanforobjects(pos)
	if pos == nil then return end
	print("tubes_scanforobjects called at pos "..dump(pos))
	tube_autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   })
	tube_autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   })
	tube_autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   })
	tube_autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   })
	tube_autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	tube_autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 })
	tube_autoroute(pos)
end

function in_table(table,element)
	for _,el in ipairs(table) do
		if el==element then return true end
	end
	return false
end

function is_tube(nodename)
	return in_table(tubenodes,nodename)
end

function tube_autoroute(pos)
	local pxm=0
	local pxp=0
	local pym=0
	local pyp=0
	local pzm=0
	local pzp=0

	local nxm = minetest.env:get_node({ x=pos.x-1, y=pos.y  , z=pos.z   })
	local nxp = minetest.env:get_node({ x=pos.x+1, y=pos.y  , z=pos.z   })
	local nym = minetest.env:get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })
	local nyp = minetest.env:get_node({ x=pos.x  , y=pos.y+1, z=pos.z   })
	local nzm = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	local nzp = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z+1 })

	local nctr = minetest.env:get_node(pos)

-- handle the tubes themselves

	if is_tube(nxm.name) then pxm=1 end
	if is_tube(nxp.name) then pxp=1 end
	if is_tube(nym.name) then pym=1 end
	if is_tube(nyp.name) then pyp=1 end
	if is_tube(nzm.name) then pzm=1 end
	if is_tube(nzp.name) then pzp=1 end

-- handle regular filters

	if string.find(nxm.name, "pipeworks:filter") ~= nil
	  and nxm.param2 == 0 then
		pxm=1 end
	if string.find(nxp.name, "pipeworks:filter") ~= nil
	  and nxp.param2 == 2 then
		pxp=1 end
	if string.find(nzm.name, "pipeworks:filter") ~= nil
	  and nzm.param2 == 3 then
		pzm=1 end
	if string.find(nzp.name, "pipeworks:filter") ~= nil
	  and nzp.param2 == 1 then
		pzp=1 end

-- handle mese filters

	if string.find(nxm.name, "pipeworks:mese_filter") ~= nil
	  and nxm.param2 == 0 then
		pxm=1 end
	if string.find(nxp.name, "pipeworks:mese_filter") ~= nil
	  and nxp.param2 == 2 then
		pxp=1 end
	if string.find(nzm.name, "pipeworks:mese_filter") ~= nil
	  and nzm.param2 == 3 then
		pzm=1 end
	if string.find(nzp.name, "pipeworks:mese_filter") ~= nil
	  and nzp.param2 == 1 then
		pzp=1 end

-- handle deployers

	if string.find(nxm.name, "pipeworks:deployer_") ~= nil
	  and nxm.param2 == 1 then
		pxm=1 end
	if string.find(nxp.name, "pipeworks:deployer_") ~= nil
	  and nxp.param2 == 3 then
		pxp=1 end
	if string.find(nzm.name, "pipeworks:deployer_") ~= nil
	  and nzm.param2 == 0 then
		pzm=1 end
	if string.find(nzp.name, "pipeworks:deployer_") ~= nil
	  and nzp.param2 == 2 then
		pzp=1 end

	if string.find(nxm.name, "technic:deployer_") ~= nil
	  and nxm.param2 == 1 then
		pxm=1 end
	if string.find(nxp.name, "technic:deployer_") ~= nil
	  and nxp.param2 == 3 then
		pxp=1 end
	if string.find(nzm.name, "technic:deployer_") ~= nil
	  and nzm.param2 == 0 then
		pzm=1 end
	if string.find(nzp.name, "technic:deployer_") ~= nil
	  and nzp.param2 == 2 then
		pzp=1 end

--node breakers

	if string.find(nxm.name, "pipeworks:nodebreaker_") ~= nil
	  and nxm.param2 == 1 then
		pxm=1 end
	if string.find(nxp.name, "pipeworks:nodebreaker_") ~= nil
	  and nxp.param2 == 3 then
		pxp=1 end
	if string.find(nzm.name, "pipeworks:nodebreaker_") ~= nil
	  and nzm.param2 == 0 then
		pzm=1 end
	if string.find(nzp.name, "pipeworks:nodebreaker_") ~= nil
	  and nzp.param2 == 2 then
		pzp=1 end

	if string.find(nxm.name, "technic:nodebreaker_") ~= nil
	  and nxm.param2 == 1 then
		pxm=1 end
	if string.find(nxp.name, "technic:nodebreaker_") ~= nil
	  and nxp.param2 == 3 then
		pxp=1 end
	if string.find(nzm.name, "technic:nodebreaker_") ~= nil
	  and nzm.param2 == 0 then
		pzm=1 end
	if string.find(nzp.name, "technic:nodebreaker_") ~= nil
	  and nzp.param2 == 2 then
		pzp=1 end

-- autocrafter

	if string.find(nxm.name, "pipeworks:autocrafter") ~= nil then pxm = 1 end
	if string.find(nxp.name, "pipeworks:autocrafter") ~= nil then pxp = 1 end
	if string.find(nym.name, "pipeworks:autocrafter") ~= nil then pym = 1 end
	if string.find(nyp.name, "pipeworks:autocrafter") ~= nil then pyp = 1 end
	if string.find(nzm.name, "pipeworks:autocrafter") ~= nil then pzm = 1 end
	if string.find(nzp.name, "pipeworks:autocrafter") ~= nil then pzp = 1 end

--chests

	-- check for left/right connects

	if string.find(nxm.name, "default:chest") ~= nil
	  and (nxm.param2 == 0 or nxm.param2 == 2) then
		pxm=1 end
	if string.find(nxp.name, "default:chest") ~= nil
	  and (nxp.param2 == 0 or nxp.param2 == 2) then
		pxp=1 end

	if string.find(nzm.name, "default:chest") ~= nil
	  and (nzm.param2 == 1 or nzm.param2 == 3) then
		pzm=1 end
	if string.find(nzp.name, "default:chest") ~= nil
	  and (nzp.param2 == 1 or nzp.param2 == 3) then
		pzp=1 end

	-- check for backside connects

	if string.find(nxm.name, "default:chest") ~= nil
	  and nxm.param2 == 1 then
		pxm = 1 end

	if string.find(nxp.name, "default:chest") ~= nil
	  and nxp.param2 == 3 then
		pxp = 1 end

	if string.find(nzm.name, "default:chest") ~= nil
	  and nzm.param2 == 0 then
		pzm = 1 end

	if string.find(nzp.name, "default:chest") ~= nil
	  and nzp.param2 == 2 then
		pzp = 1 end

	-- check for top/bottom connections

	if string.find(nym.name, "default:chest") ~= nil then pym = 1 end
	if string.find(nyp.name, "default:chest") ~= nil then pyp = 1 end

	-- does not scan for the front side of the node.

--chests

	-- check for left/right connects

	if string.find(nxm.name, "default:furnace") ~= nil
	  and (nxm.param2 == 0 or nxm.param2 == 2) then
		pxm=1 end
	if string.find(nxp.name, "default:furnace") ~= nil
	  and (nxp.param2 == 0 or nxp.param2 == 2) then
		pxp=1 end

	if string.find(nzm.name, "default:furnace") ~= nil
	  and (nzm.param2 == 1 or nzm.param2 == 3) then
		pzm=1 end
	if string.find(nzp.name, "default:furnace") ~= nil
	  and (nzp.param2 == 1 or nzp.param2 == 3) then
		pzp=1 end

	-- check for backside connects

	if string.find(nxm.name, "default:furnace") ~= nil
	  and nxm.param2 == 1 then
		pxm = 1 end

	if string.find(nxp.name, "default:furnace") ~= nil
	  and nxp.param2 == 3 then
		pxp = 1 end

	if string.find(nzm.name, "default:furnace") ~= nil
	  and nzm.param2 == 0 then
		pzm = 1 end

	if string.find(nzp.name, "default:furnace") ~= nil
	  and nzp.param2 == 2 then
		pzp = 1 end

	-- check for bottom connection

	if string.find(nyp.name, "default:furnace") ~= nil then pyp = 1 end

	-- does not scan for the front or top side of the node.

-- Apply the final routing decisions to the existing tube (if any)

	nsurround = pxm..pxp..pym..pyp..pzm..pzp
	if is_tube(nctr.name) then
		local meta=minetest.env:get_meta(pos)
		local meta0=meta:to_table()
		nctr.name=string.sub(nctr.name,1,-7)..nsurround
		minetest.env:add_node(pos, nctr)
		local meta=minetest.env:get_meta(pos)
		meta:from_table(meta0)
	end

end

-- auto-rotation code for various devices the tubes attach to

function pipes_scansurroundings(pos)
	pxm=0
	pxp=0
	pym=0
	pyp=0
	pzm=0
	pzp=0

	nxm = minetest.env:get_node({ x=pos.x-1, y=pos.y  , z=pos.z   })
	nxp = minetest.env:get_node({ x=pos.x+1, y=pos.y  , z=pos.z   })
	nym = minetest.env:get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })
	nyp = minetest.env:get_node({ x=pos.x  , y=pos.y+1, z=pos.z   })
	nzm = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	nzp = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z+1 })

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

end

function pipe_look_for_stackable_tanks(pos)
	local tym = minetest.env:get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })

	if string.find(tym.name, "pipeworks:storage_tank_") ~= nil or
	    string.find(tym.name, "pipeworks:expansion_tank_") ~= nil then
		minetest.env:add_node(pos, { name =  "pipeworks:expansion_tank_0", param2 = tym.param2})
	end
end

