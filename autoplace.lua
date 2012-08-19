
function pipe_autoroute(pos, state)

	nctr = minetest.env:get_node(pos)
	if (string.find(nctr.name, "pipeworks:pipe_") == nil) then return end

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

	pipe_checkfordevice(pos, "valve")
	pipe_checkfordevice(pos, "pump")
	
	nsurround = pxm..pxp..pym..pyp..pzm..pzp
	
	if nsurround == "000000" then nsurround = "110000" end

	minetest.env:add_node(pos, { name = "pipeworks:pipe_"..nsurround..state })
end

function pipe_device_autorotate(pos, state, bname)

	local nctr = minetest.env:get_node(pos)

	pxm=0
	pxp=0
	pzm=0
	pzp=0

	nxm = minetest.env:get_node({ x=pos.x-1, y=pos.y  , z=pos.z   })
	nxp = minetest.env:get_node({ x=pos.x+1, y=pos.y  , z=pos.z   })
	nzm = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z-1 })
	nzp = minetest.env:get_node({ x=pos.x  , y=pos.y  , z=pos.z+1 })

	if (string.find(nxm.name, "pipeworks:pipe_") ~= nil) then pxm=1 end
	if (string.find(nxp.name, "pipeworks:pipe_") ~= nil) then pxp=1 end
	if (string.find(nzm.name, "pipeworks:pipe_") ~= nil) then pzm=1 end
	if (string.find(nzp.name, "pipeworks:pipe_") ~= nil) then pzp=1 end

	pipe_checkfordevice(pos, "pump")
	pipe_checkfordevice(pos, "valve")

	if (pxm+pxp) ~= 0 then
		minetest.env:add_node(pos, { name = bname..state.."_x" })
		return
	end

	if (pzm+pzp) ~= 0 then
		minetest.env:add_node(pos, { name = bname..state.."_z" })
	end
	
end

pipe_checkfordevice = function(pos, bname)
	if (string.find(nxm.name, "pipeworks:"..bname.."_off_x") ~= nil) or
	   (string.find(nxm.name, "pipeworks:"..bname.."_on_x") ~= nil) then
		pxm=1
	end

	if (string.find(nxp.name, "pipeworks:"..bname.."_off_x") ~= nil) or
	   (string.find(nxp.name, "pipeworks:"..bname.."_on_x") ~= nil) then
		pxp=1
	end

	if (string.find(nzm.name, "pipeworks:"..bname.."_off_z") ~= nil) or
	   (string.find(nzm.name, "pipeworks:"..bname.."_on_z") ~= nil) then
		pzm=1
	end

	if (string.find(nzp.name, "pipeworks:"..bname.."_off_z") ~= nil) or
	   (string.find(nzp.name, "pipeworks:"..bname.."_on_z") ~= nil) then
		pzp=1
	end
end

pipe_scanforobjects = function(pos)
	pipe_autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_loaded")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_loaded")

	pipe_autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_empty")
	pipe_autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_empty")
end

