-- Pipeworks mod by Vanessa Ezekowitz - 2012-08-05
--
-- Entirely my own code.  This mod merely supplies enough nodes to build 
-- a bunch of pipes in all directions and with all types of junctions
--
-- License: WTFPL
--

-- uncomment the following dofile line to enable the old pipe nodes.
-- dofile(minetest.get_modpath("pipeworks").."/oldpipes.lua")

-- tables

minetest.register_alias("pipeworks:pipe", "pipeworks:pipe_000000_empty")

local leftstub = {
	{ -32/64, -2/64, -6/64,   1/64, 2/64, 6/64 },	-- pipe segment against -X face
	{ -32/64, -4/64, -5/64,   1/64, 4/64, 5/64 },
	{ -32/64, -5/64, -4/64,   1/64, 5/64, 4/64 },
	{ -32/64, -6/64, -2/64,   1/64, 6/64, 2/64 },

	{ -32/64, -3/64, -8/64, -30/64, 3/64, 8/64 },	-- (the flange for it)
	{ -32/64, -5/64, -7/64, -30/64, 5/64, 7/64 },
	{ -32/64, -6/64, -6/64, -30/64, 6/64, 6/64 },
	{ -32/64, -7/64, -5/64, -30/64, 7/64, 5/64 },
	{ -32/64, -8/64, -3/64, -30/64, 8/64, 3/64 }
}

local rightstub = {
	{ -1/64, -2/64, -6/64,  32/64, 2/64, 6/64 },	-- pipe segment against +X face
	{ -1/64, -4/64, -5/64,  32/64, 4/64, 5/64 },
	{ -1/64, -5/64, -4/64,  32/64, 5/64, 4/64 },
	{ -1/64, -6/64, -2/64,  32/64, 6/64, 2/64 },

	{ 30/64, -3/64, -8/64, 32/64, 3/64, 8/64 },	-- (the flange for it)
	{ 30/64, -5/64, -7/64, 32/64, 5/64, 7/64 },
	{ 30/64, -6/64, -6/64, 32/64, 6/64, 6/64 },
	{ 30/64, -7/64, -5/64, 32/64, 7/64, 5/64 },
	{ 30/64, -8/64, -3/64, 32/64, 8/64, 3/64 }
}

local bottomstub = {
	{ -2/64, -32/64, -6/64,   2/64, 1/64, 6/64 },	-- pipe segment against -Y face
	{ -4/64, -32/64, -5/64,   4/64, 1/64, 5/64 },
	{ -5/64, -32/64, -4/64,   5/64, 1/64, 4/64 },
	{ -6/64, -32/64, -2/64,   6/64, 1/64, 2/64 },

	{ -3/64, -32/64, -8/64, 3/64, -30/64, 8/64 },	-- (the flange for it)
	{ -5/64, -32/64, -7/64, 5/64, -30/64, 7/64 },
	{ -6/64, -32/64, -6/64, 6/64, -30/64, 6/64 },
	{ -7/64, -32/64, -5/64, 7/64, -30/64, 5/64 },
	{ -8/64, -32/64, -3/64, 8/64, -30/64, 3/64 }
}


local topstub = {
	{ -2/64, -1/64, -6/64,   2/64, 32/64, 6/64 },	-- pipe segment against +Y face
	{ -4/64, -1/64, -5/64,   4/64, 32/64, 5/64 },
	{ -5/64, -1/64, -4/64,   5/64, 32/64, 4/64 },
	{ -6/64, -1/64, -2/64,   6/64, 32/64, 2/64 },

	{ -3/64, 30/64, -8/64, 3/64, 32/64, 8/64 },	-- (the flange for it)
	{ -5/64, 30/64, -7/64, 5/64, 32/64, 7/64 },
	{ -6/64, 30/64, -6/64, 6/64, 32/64, 6/64 },
	{ -7/64, 30/64, -5/64, 7/64, 32/64, 5/64 },
	{ -8/64, 30/64, -3/64, 8/64, 32/64, 3/64 }
}

local frontstub = {
	{ -6/64, -2/64, -32/64,   6/64, 2/64, 1/64 },	-- pipe segment against -Z face
	{ -5/64, -4/64, -32/64,   5/64, 4/64, 1/64 },
	{ -4/64, -5/64, -32/64,   4/64, 5/64, 1/64 },
	{ -2/64, -6/64, -32/64,   2/64, 6/64, 1/64 },

	{ -8/64, -3/64, -32/64, 8/64, 3/64, -30/64 },	-- (the flange for it)
	{ -7/64, -5/64, -32/64, 7/64, 5/64, -30/64 },
	{ -6/64, -6/64, -32/64, 6/64, 6/64, -30/64 },
	{ -5/64, -7/64, -32/64, 5/64, 7/64, -30/64 },
	{ -3/64, -8/64, -32/64, 3/64, 8/64, -30/64 }
}

local backstub = {
	{ -6/64, -2/64, -1/64,   6/64, 2/64, 32/64 },	-- pipe segment against -Z face
	{ -5/64, -4/64, -1/64,   5/64, 4/64, 32/64 },
	{ -4/64, -5/64, -1/64,   4/64, 5/64, 32/64 },
	{ -2/64, -6/64, -1/64,   2/64, 6/64, 32/64 },

	{ -8/64, -3/64, 30/64, 8/64, 3/64, 32/64 },	-- (the flange for it)
	{ -7/64, -5/64, 30/64, 7/64, 5/64, 32/64 },
	{ -6/64, -6/64, 30/64, 6/64, 6/64, 32/64 },
	{ -5/64, -7/64, 30/64, 5/64, 7/64, 32/64 },
	{ -3/64, -8/64, 30/64, 3/64, 8/64, 32/64 }
} 

local selectboxes = {
	{ -32/64,  -8/64,  -8/64,  8/64,  8/64,  8/64 },
	{ -8/64 ,  -8/64,  -8/64, 32/64,  8/64,  8/64 },
	{ -8/64 , -32/64,  -8/64,  8/64,  8/64,  8/64 },
	{ -8/64 ,  -8/64,  -8/64,  8/64, 32/64,  8/64 },
	{ -8/64 ,  -8/64, -32/64,  8/64,  8/64,  8/64 },
	{ -8/64 ,  -8/64,  -8/64,  8/64,  8/64, 32/64 }
}

bendsphere = {	
	{ -4/64, -4/64, -4/64, 4/64, 4/64, 4/64 },
	{ -5/64, -3/64, -3/64, 5/64, 3/64, 3/64 },
	{ -3/64, -5/64, -3/64, 3/64, 5/64, 3/64 },
	{ -3/64, -3/64, -5/64, 3/64, 3/64, 5/64 }
}

pumpbody = {
	{ -6/16, -8/16, -6/16, 6/16, 8/16, 6/16 }
}

valvebody = {
	{ -4/16, -4/16, -4/16, 4/16, 4/16, 4/16 }
}

valvehandle_on = {
	{ -5/16, 4/16, -1/16, 0, 5/16, 1/16 }
}

valvehandle_off = {
	{ -1/16, 4/16, -5/16, 1/16, 5/16, 0 }
}


-- Local Functions

local dbg = function(s)
	if DEBUG == 1 then
		print('[PIPEWORKS] ' .. s)
	end
end

function fix_newpipe_names(table, replacement)
	outtable={}
	for i in ipairs(table) do
		outtable[i]=string.gsub(table[i], "_XXXXX", replacement)
	end

	return outtable
end

local function addbox(t, b)
	for i in ipairs(b)
		do table.insert(t, b[i])
	end
end

local function autoroute(pos, state)

	local nctr = minetest.env:get_node(pos)
	if (string.find(nctr.name, "pipeworks:pipe_") == nil) then return end

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

	if (string.find(nxm.name, "pipeworks:pipe_") ~= nil) then pxm=1 end
	if (string.find(nxp.name, "pipeworks:pipe_") ~= nil) then pxp=1 end
	if (string.find(nym.name, "pipeworks:pipe_") ~= nil) then pym=1 end
	if (string.find(nyp.name, "pipeworks:pipe_") ~= nil) then pyp=1 end
	if (string.find(nzm.name, "pipeworks:pipe_") ~= nil) then pzm=1 end
	if (string.find(nzp.name, "pipeworks:pipe_") ~= nil) then pzp=1 end

	local nsurround = pxm..pxp..pym..pyp..pzm..pzp
	
	if nsurround == "000000" then nsurround = "110000" end

	minetest.env:add_node(pos, { name = "pipeworks:pipe_"..nsurround..state })
end

-- now define the nodes!

for xm = 0, 1 do
for xp = 0, 1 do
for ym = 0, 1 do
for yp = 0, 1 do
for zm = 0, 1 do
for zp = 0, 1 do
	outboxes = {}
	outsel = {}
	outimgs = {}
	if yp==1 then
		addbox(outboxes, topstub)
		table.insert(outsel, selectboxes[4])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end
	if ym==1 then
		addbox(outboxes, bottomstub)
		table.insert(outsel, selectboxes[3])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end
	if xp==1 then
		addbox(outboxes, rightstub)
		table.insert(outsel, selectboxes[2])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end
	if xm==1 then
		addbox(outboxes, leftstub)
		table.insert(outsel, selectboxes[1])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end
	if zp==1 then
		addbox(outboxes, backstub)
		table.insert(outsel, selectboxes[6])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end
	if zm==1 then
		addbox(outboxes, frontstub)
		table.insert(outsel, selectboxes[5])
		table.insert(outimgs, "pipeworks_pipe_end.png")
	else
		table.insert(outimgs, "pipeworks_plain.png")
	end

	jx = xp+xm
	jy = yp+ym
	jz = zp+zm

	if (jx==1 and jy==1 and jz~=1) or (jx==1 and jy~=1 and jz==1) or (jx~= 1 and jy==1 and jz==1) then
		addbox(outboxes, bendsphere)
	end

	if (jx==2 and jy~=2 and jz~=2) then
		table.remove(outimgs, 5)
		table.remove(outimgs, 5)
		table.insert(outimgs, 5, "pipeworks_windowed_XXXXX.png")
		table.insert(outimgs, 5, "pipeworks_windowed_XXXXX.png")
	end

	if (jx~=2 and jy~=2 and jz==2) or (jx~=2 and jy==2 and jz~=2) then
		table.remove(outimgs, 3)
		table.remove(outimgs, 3)
		table.insert(outimgs, 3, "pipeworks_windowed_XXXXX.png")
		table.insert(outimgs, 3, "pipeworks_windowed_XXXXX.png")
	end

	pname = xm..xp..ym..yp..zm..zp

	minetest.register_node("pipeworks:pipe_"..pname.."_empty", {
		description = "Pipe segment (empty, "..pname..").",
		drawtype = "nodebox",
		tiles = fix_newpipe_names(outimgs, "_empty"),
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = outsel
		},
		node_box = {
			type = "fixed",
			fixed = outboxes
		},
		groups = {snappy=3, pipe=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = "pipeworks:pipe_110000_empty",
		after_place_node = function(pos)
			autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_empty")
			autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_empty")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_empty")
			autoroute(pos, "_empty")
		end,
		after_dig_node = function(pos)
			autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_empty")
			autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_empty")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_empty")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_empty")
		end
	})

	minetest.register_node("pipeworks:pipe_"..pname.."_loaded", {
		description = "Pipe segment (loaded, "..pname..").",
		drawtype = "nodebox",
		tiles = fix_newpipe_names(outimgs, "_loaded"),
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = outsel
		},
		node_box = {
			type = "fixed",
			fixed = outboxes
		},
		groups = {snappy=3, pipe=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = "pipeworks:pipe_110000_loaded",
		after_place_node = function(pos)
			autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_loaded")
			autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_loaded")
			autoroute(pos, "_loaded")
		end,
		after_dig_node = function(pos)
			autoroute({ x=pos.x-1, y=pos.y  , z=pos.z   }, "_loaded")
			autoroute({ x=pos.x+1, y=pos.y  , z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y-1, z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y+1, z=pos.z   }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z-1 }, "_loaded")
			autoroute({ x=pos.x  , y=pos.y  , z=pos.z+1 }, "_loaded")
		end
	})
end
end
end
end
end
end

-- the pump module

pumpboxes = {}
addbox(pumpboxes, leftstub)
addbox(pumpboxes, pumpbody)
addbox(pumpboxes, rightstub)

minetest.register_node("pipeworks:pump_on", {
	description = "Pump Module (on)",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_pump_sides.png",
		"pipeworks_pump_sides.png",
		"pipeworks_pump_ends.png",
		"pipeworks_pump_ends.png",
		"pipeworks_pump_on.png",
		"pipeworks_pump_on.png"
	},
	paramtype = "light",
	selection_box = {
             	type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	node_box = {
		type = "fixed",
		fixed = pumpboxes
	},
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
})

minetest.register_node("pipeworks:pump_off", {
	description = "Pump Module (off)",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_pump_sides.png",
		"pipeworks_pump_sides.png",
		"pipeworks_pump_ends.png",
		"pipeworks_pump_ends.png",
		"pipeworks_pump_off.png",
		"pipeworks_pump_off.png"
	},
	paramtype = "light",
	selection_box = {
             	type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	node_box = {
		type = "fixed",
		fixed = pumpboxes
	},
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
})

-- valve module

valveboxes = {}
addbox(valveboxes, leftstub)
addbox(valveboxes, valvebody)
addbox(valveboxes, valvehandle_off)
addbox(valveboxes, rightstub)

minetest.register_node("pipeworks:valve_off", {
	description = "Valve (off)",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_valvebody_top_off.png",
		"pipeworks_valvebody_bottom.png",
		"pipeworks_valvebody_ends.png",
		"pipeworks_valvebody_ends.png",
		"pipeworks_valvebody_sides.png",
		"pipeworks_valvebody_sides.png",
	},
	paramtype = "light",
	selection_box = {
             	type = "fixed",
		fixed = { -5/16, -4/16, -5/16, 6/16, 8/16, 6/16 }
	},
	node_box = {
		type = "fixed",
		fixed = valveboxes
	},
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
})

valveboxes = {}
addbox(valveboxes, leftstub)
addbox(valveboxes, valvebody)
addbox(valveboxes, valvehandle_on)
addbox(valveboxes, rightstub)

minetest.register_node("pipeworks:valve_on", {
	description = "Valve (on)",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_valvebody_top_on.png",
		"pipeworks_valvebody_bottom.png",
		"pipeworks_valvebody_ends.png",
		"pipeworks_valvebody_ends.png",
		"pipeworks_valvebody_sides.png",
		"pipeworks_valvebody_sides.png",
	},
	paramtype = "light",
	selection_box = {
             	type = "fixed",
		fixed = { -5/16, -4/16, -5/16, 6/16, 8/16, 6/16 }
	},
	node_box = {
		type = "fixed",
		fixed = valveboxes
	},
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
})

minetest.register_on_punchnode(function (pos, node)
	if node.name=="pipeworks:valve_on" then 
		minetest.env:add_node(pos, { name = "pipeworks:valve_off" })
	end
end)

minetest.register_on_punchnode(function (pos, node)
	if node.name=="pipeworks:valve_off" then 
		minetest.env:add_node(pos, { name = "pipeworks:valve_on" })
	end
end)


minetest.register_on_punchnode(function (pos, node)
	if node.name=="pipeworks:pump_on" then 
		minetest.env:add_node(pos, { name = "pipeworks:pump_off" })
	end
end)

minetest.register_on_punchnode(function (pos, node)
	if node.name=="pipeworks:pump_off" then 
		minetest.env:add_node(pos, { name = "pipeworks:pump_on" })
	end
end)

print("Pipeworks loaded!")
