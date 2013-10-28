--define the functions from https://github.com/minetest/minetest/pull/834 while waiting for the devs to notice it
local function dir_to_facedir(dir, is6d)
	--account for y if requested
	if is6d and math.abs(dir.y) > math.abs(dir.x) and math.abs(dir.y) > math.abs(dir.z) then
		
		--from above
		if dir.y < 0 then
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 19
				else
					return 13
				end
			else
				if dir.z < 0 then
					return 10
				else
					return 4
				end
			end
		
		--from below
		else
			if math.abs(dir.x) > math.abs(dir.z) then
				if dir.x < 0 then
					return 15
				else
					return 17
				end
			else
				if dir.z < 0 then
					return 6
				else
					return 8
				end
			end
		end
	
	--otherwise, place horizontally
	elseif math.abs(dir.x) > math.abs(dir.z) then
		if dir.x < 0 then
			return 3
		else
			return 1
		end
	else
		if dir.z < 0 then
			return 2
		else
			return 0
		end
	end
end

local function facedir_to_dir(facedir)
	--a table of possible dirs
	return ({{x=0, y=0, z=1},
					{x=1, y=0, z=0},
					{x=0, y=0, z=-1},
					{x=-1, y=0, z=0},
					{x=0, y=-1, z=0},
					{x=0, y=1, z=0}})
					
					--indexed into by a table of correlating facedirs
					[({[0]=1, 2, 3, 4,
						5, 2, 6, 4,
						6, 2, 5, 4,
						1, 5, 3, 6,
						1, 6, 3, 5,
						1, 4, 3, 2})
						
						--indexed into by the facedir in question
						[facedir]]
end

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
	nctr = minetest.get_node(pos)
	if (string.find(nctr.name, "pipeworks:pipe_") == nil) then return end

	pipes_scansurroundings(pos)

	nsurround = pxm..pxp..pym..pyp..pzm..pzp
	if nsurround == "000000" then nsurround = "110000" end
	minetest.add_node(pos, { name = "pipeworks:pipe_"..nsurround..state })
end

-- autorouting for pneumatic tubes

function tube_scanforobjects(pos)
	if pos == nil then return end
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

if pipeworks == nil then
    pipeworks = {}
end

-- this was tested experimentally, because I can't the whole bit arithematic

-- with these facingRight means "We're facing the right side of whatever it is"
pipeworks.connects = {
    -- a filter's output is on the right, input on the left
    facingLeft = function (i,param2)
        -- measured with a mese filter
        if i == 1 then
            return param2 == 2 or param2 == 6 or param2 == 10 or param2 == 20
        elseif i == 2 then
            return param2 == 0 or param2 == 4 or param2 == 8 or param2 == 22
        elseif i == 3 then
            return param2 == 7 or param2 == 9 or param2 == 12 or param2 == 18
        elseif i == 4 then
            return param2 == 5 or param2 == 11 or param2 == 14 or param2 == 16
        elseif i == 5 then
            return param2 == 1 or param2 == 13 or param2 == 17 or param2 == 21
        elseif i == 6 then
            return param2 == 3 or param2 == 15 or param2 == 19
        end
    end,
    facingRight = function (i,param2)
        -- measured with a mese filter
        if i == 1 then
            return param2 == 0 or param2 == 4 or param2 == 8 or param2 == 22
        elseif i == 2 then
            return param2 == 2 or param2 == 6 or param2 == 10 or param2 == 20
        elseif i == 3 then
            return param2 == 5 or param2 == 11 or param2 == 14 or param2 == 16
        elseif i == 4 then
            return param2 == 7 or param2 == 9 or param2 == 12 or param2 == 18
        elseif i == 5 then
            return param2 == 3 or param2 == 15 or param2 == 19
        elseif i == 6 then
            return param2 == 1 or param2 == 13 or param2 == 17 or param2 == 21
        end
    end,
    facingFront = function (i,param2)
        -- measured with a chest and a technic:nodebreaker
        if i == 1 then
            return param2 == 3 or param2 == 7 or param2 == 11 or param2 == 21
        elseif i == 2 then
            return param2 == 1 or param2 == 5 or param2 == 9
        elseif i == 3 then
            return param2 == 4 or param2 == 10 or param2 == 14 or param2 == 19
        elseif i == 4 then
            return param2 == 6 or param2 == 8 or param2 == 15 or param2 == 17
        elseif i == 5 then
            return param2 == 14 or param2 == 18 or param2 == 22 or param2 == 2
        elseif i == 6 then
            return param2 == 12 or param2 == 16 or param2 == 20 or param2 == 0
        end
    end,
    facingSide = function (i,param2)
        -- aka not top or bottom
        -- measured with a chair
        if i == 1 or i == 2 then
            return not (param2 >= 12 and param2 <= 19)
        elseif i == 3 or i == 4 then
            return not ((param2 >= 0 and param2 < 4) or (param2 >= 20 and param2 <= 22))
        elseif i == 5 or i == 6 then
            return not (param2 >= 4 and param2 <= 11)
        end
    end,
    facingTop = function(i,param2)
        -- measured with a chair
        if i == 1 then
            return param2 >= 16 and param2 <= 20
        elseif i == 2 then
            return param2 >= 12 and param2 < 16
        elseif i == 3 then
            return param2 >= 0 and param2 < 4
        elseif i == 4 then
            return param2 >= 21 and param2 < 23
        elseif i == 5 then
            return param2 >= 4 and param2 < 8
        elseif i == 6 then
            return param2 >= 8 and param2 < 12
            -- else error bad value for i
        end
    end
}

--a function for determining which side of the node we are on
local function nodeside(node, tubedir)
    --get a vector pointing back
    local backdir = facedir_to_dir(node.param2)

    --check whether the vector is equivalent to the tube direction; if it is, the tube's on the backside
    if backdir.x == tubedir.x and backdir.y == tubedir.y and backdir.z == tubedir.z then
        return "back"
    end

    --check whether the vector is antiparallel with the tube direction; that indicates the front
    if backdir.x == -tubedir.x and backdir.y == -tubedir.y and backdir.z == -tubedir.z then
        return "front"
    end

    --facedir is defined in terms of the top-bottom axis of the node; we'll take advantage of that
    local topdir = ({[0]={x=0, y=1, z=0},
    {x=0, y=0, z=1},
    {x=0, y=0, z=-1},
    {x=1, y=0, z=0},
    {x=-1, y=0, z=0},
    {x=0, y=-1, z=0}})[math.floor(node.param2/4)]

    --is this the top?
    if topdir.x == tubedir.x and topdir.y == tubedir.y and topdir.z == tubedir.z then
        return "top"
    end

    --or the bottom?
    if topdir.x == -tubedir.x and topdir.y == -tubedir.y and topdir.z == -tubedir.z then
        return "bottom"
    end

    --we shall apply some maths to obtain the right-facing vector
    local rightdir = {x=topdir.y*backdir.z - backdir.y*topdir.z,
    y=topdir.z*backdir.x - backdir.z*topdir.x,
    z=topdir.x*backdir.y - backdir.x*topdir.y}

    --is this the right side?
    if rightdir.x == tubedir.x and rightdir.y == tubedir.y and rightdir.z == tubedir.z then
        return "right"
    end

    --or the left?
    if rightdir.x == -tubedir.x and rightdir.y == -tubedir.y and rightdir.z == -tubedir.z then
        return "left"
    end

    --we should be done by now; initiate panic mode
    minetest.log("error", "nodeside has been confused by its parameters; see pipeworks autoplace.lua, line 382")
end

function tube_autoroute(pos)
	local active = {0, 0, 0, 0, 0, 0}
    local nctr = minetest.get_node(pos)
    if not is_tube(nctr.name) then return end

    local adjustments = {
        { x=-1, y=0, z=0 },
        { x=1, y=0, z=0  },
        { x=0, y=-1, z=0 },
        { x=0, y=1, z=0  },
        { x=0, y=0, z=-1 },
        { x=0, y=0, z=1 }
    }
    -- xm = 1, xp = 2, ym = 3, yp = 4, zm = 5, zp = 6

    local positions = {}
    local nodes = {}
    for i,adj in ipairs(adjustments) do
        positions[i] = {x=pos.x+adj.x, y=pos.y+adj.y, z=pos.z+adj.z}
        nodes[i] = minetest.get_node(positions[i])
    end

    for i,node in ipairs(nodes) do
        local idef = minetest.registered_nodes[node.name]
        -- handle the tubes themselves
        if is_tube(node.name) then
            active[i] = 1
        -- handle new style connectors
        elseif idef.tube and idef.tube.connects then
            -- connects returns true if self can connect w/ neighboring position
            -- it uses facesFront, facesTop etc to determine this
            -- pipeworks.connects.facingFront...
            if idef.tube.connects(i,param2) then active[i] = 1 end
        -- oops, handle the *other* newstyle connectors
        elseif idef.tube and idef.tube.connect_side then
            local dir = adjustments[i]
            if idef.connect_sides[nodeside(node, {x=-dir.x, y=-dir.y, z=-dir.z})] then active[i] = 1 end

        -- legacy stuff follows
        elseif string.find(node.name, "pipeworks:filter") ~= nil or string.find(node.name, "pipeworks:mese_filter") ~= nil then
            -- filters only connect to pipes on their output (despite appearances)
            -- input has to be a chest or furnace or something
            if pipeworks.connects.facingRight(i,node.param2)
                then
                    active[i] = 1
                end
        elseif
            -- not the front
            string.find(node.name, "pipeworks:deployer_") ~= nil or
            string.find(node.name, "pipeworks:nodebreaker_") ~= nil or
            string.find(node.name, "technic:nodebreaker_") ~= nil
            then
                if not pipeworks.connects.facingFront(i,node.param2) then active[i] = 1 end
        elseif
            string.find(node.name, "default:furnace") ~= nil or
            string.find(node.name, "default:chest") or
            string.find(node.name, "default:chest_locked")
            then
                if not pipeworks.connects.facingFront(i,node.param2) or
                    pipeworks.connects.facingTop(i,node.param2) then active[i] = 1 end
        elseif string.find(node.name, "pipeworks:autocrafter") ~= nil then
            active[i] = 1
        end
    end

    -- all sides checked, now figure which tube to use.

    nsurround = ""
    for i,n in ipairs(active) do
        nsurround = nsurround .. n
    end
    local newname=string.sub(nctr.name,1,-7)..nsurround
    if newname == nctr.name then return end
    local meta=minetest.get_meta(pos)
    local meta0=meta:to_table() -- XXX: hacky_swap_node
    nctr.name = newname
    minetest.add_node(pos, nctr)
    local meta=minetest.get_meta(pos)
    meta:from_table(meta0)
	local nctr = minetest.get_node(pos)
end

-- auto-rotation code for various devices the tubes attach to

function pipes_scansurroundings(pos)
	pxm=0
	pxp=0
	pym=0
	pyp=0
	pzm=0
	pzp=0

	nxm = minetest.get_node({ x=pos.x-1, y=pos.y  , z=pos.z   })
	nxp = minetest.get_node({ x=pos.x+1, y=pos.y  , z=pos.z   })
	nym = minetest.get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })
	nyp = minetest.get_node({ x=pos.x  , y=pos.y+1, z=pos.z   })
	nzm = minetest.get_node({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	nzp = minetest.get_node({ x=pos.x  , y=pos.y  , z=pos.z+1 })

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

end

function pipe_look_for_stackable_tanks(pos)
	local tym = minetest.get_node({ x=pos.x  , y=pos.y-1, z=pos.z   })

	if string.find(tym.name, "pipeworks:storage_tank_") ~= nil or
	    string.find(tym.name, "pipeworks:expansion_tank_") ~= nil then
		minetest.add_node(pos, { name =  "pipeworks:expansion_tank_0", param2 = tym.param2})
	end
end

