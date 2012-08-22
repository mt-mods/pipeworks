-- List of devices for use by the autoplace algorithm

pipes_devicelist = {
	"pump",
	"valve",
	"storage_tank"
}

-- tables

minetest.register_alias("pipeworks:pump", "pipeworks:pump_off_x")
minetest.register_alias("pipeworks:pump_off", "pipeworks:pump_off_x")
minetest.register_alias("pipeworks:valve", "pipeworks:valve_off_x")
minetest.register_alias("pipeworks:valve_off", "pipeworks:valve_off_x")

pipe_pumpbody_x = {
	{ -6/16, -8/16, -6/16, 6/16, 8/16, 6/16 }
}

pipe_pumpbody_z = {
	{ -6/16, -8/16, -6/16, 6/16, 8/16, 6/16 }
}

pipe_valvebody_x = {
	{ -4/16, -4/16, -4/16, 4/16, 4/16, 4/16 }
}

pipe_valvebody_z = {
	{ -4/16, -4/16, -4/16, 4/16, 4/16, 4/16 }
}

pipe_valvehandle_on_x = {
	{ -5/16, 4/16, -1/16, 0, 5/16, 1/16 }
}

pipe_valvehandle_on_z = {
	{ -1/16, 4/16, -5/16, 1/16, 5/16, 0 }
}

pipe_valvehandle_off_x = {
	{ -1/16, 4/16, -5/16, 1/16, 5/16, 0 }
}

pipe_valvehandle_off_z = {
	{ -5/16, 4/16, -1/16, 0, 5/16, 1/16 }
}

-- Now define the nodes.

local states = { "on", "off" }
local dgroups = ""

for s in ipairs(states) do

	if states[s] == "off" then
		dgroups = {snappy=3, pipe=1}
	else
		dgroups = {snappy=3, pipe=1, not_in_creative_inventory=1}
	end

	local pumpboxes = {}
	pipe_addbox(pumpboxes, pipe_leftstub)
	pipe_addbox(pumpboxes, pipe_pumpbody_x)
	pipe_addbox(pumpboxes, pipe_rightstub)
	local tilex = "pipeworks_pump_ends.png"
	local tilez = "pipeworks_pump_"..states[s]..".png"

	minetest.register_node("pipeworks:pump_"..states[s].."_x", {
		description = "Pump Module ("..states[s]..")",
		drawtype = "nodebox",
		tiles = {
			"pipeworks_pump_top_x.png",
			"pipeworks_pump_sides.png",
			tilex,
			tilex,
			"pipeworks_pump_sides.png",
			tilez
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
		groups = dgroups,
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		after_place_node = function(pos)
			pipe_device_autorotate(pos, states[s], "pipeworks:pump")
			pipe_scanforobjects(pos)
		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:pump_off_x"
	})
	
	local pumpboxes = {}
	pipe_addbox(pumpboxes, pipe_frontstub)
	pipe_addbox(pumpboxes, pipe_pumpbody_z)
	pipe_addbox(pumpboxes, pipe_backstub)

	minetest.register_node("pipeworks:pump_"..states[s].."_z", {
		description = "Pump Module ("..states[s]..", Z-axis)",
		drawtype = "nodebox",
		tiles = {
			"pipeworks_pump_top_z.png",
			"pipeworks_pump_sides.png",
			tilez,
			tilez,
			"pipeworks_pump_sides.png",
			tilex
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
		groups = {snappy=3, pipe=1, not_in_creative_inventory=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		after_place_node = function(pos)
			pipe_device_autorotate(pos, states[s], "pipeworks:pump")
			pipe_scanforobjects(pos)
		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:pump_off_x"
	})

	local valveboxes = {}
	pipe_addbox(valveboxes, pipe_leftstub)
	pipe_addbox(valveboxes, pipe_valvebody_x)
	if states[s] == "off" then 
		pipe_addbox(valveboxes, pipe_valvehandle_off_x)
	else
		pipe_addbox(valveboxes, pipe_valvehandle_on_x)
	end
	pipe_addbox(valveboxes, pipe_rightstub)
	local tilex = "pipeworks_valvebody_ends.png"
	local tilez = "pipeworks_valvebody_sides.png"

	minetest.register_node("pipeworks:valve_"..states[s].."_x", {
		description = "Valve ("..states[s]..")",
		drawtype = "nodebox",
		tiles = {
			"pipeworks_valvebody_top_"..states[s].."_x.png",
			"pipeworks_valvebody_bottom.png",
			tilex,
			tilex,
			tilez,
			tilez,
		},
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = { -8/16, -4/16, -5/16, 8/16, 5/16, 5/16 }
		},
		node_box = {
			type = "fixed",
			fixed = valveboxes
		},
		groups = dgroups,
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		after_place_node = function(pos)
			pipe_device_autorotate(pos, states[s], "pipeworks:valve")
			pipe_scanforobjects(pos)
		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:valve_off_x",
		pipelike=1,
		on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("pipelike",1)
		end,
	})

	local valveboxes = {}
	pipe_addbox(valveboxes, pipe_frontstub)
	pipe_addbox(valveboxes, pipe_valvebody_z)
	if states[s] == "off" then 
		pipe_addbox(valveboxes, pipe_valvehandle_off_z)
	else
		pipe_addbox(valveboxes, pipe_valvehandle_on_z)
	end
	pipe_addbox(valveboxes, pipe_backstub)

	minetest.register_node("pipeworks:valve_"..states[s].."_z", {
		description = "Valve ("..states[s]..", Z-axis)",
		drawtype = "nodebox",
		tiles = {
			"pipeworks_valvebody_top_"..states[s].."_z.png",
			"pipeworks_valvebody_bottom.png",
			tilez,
			tilez,
			tilex,
			tilex,
		},
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = { -5/16, -4/16, -8/16, 5/16, 5/16, 8/16 }
		},
		node_box = {
			type = "fixed",
			fixed = valveboxes
		},
		groups = {snappy=3, pipe=1, not_in_creative_inventory=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		after_place_node = function(pos)
			pipe_device_autorotate(pos, states[s], "pipeworks:valve")
			pipe_scanforobjects(pos)

		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:valve_off_x",
		pipelike=1,
		on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_int("pipelike",1)
		end,
	})
end

-- intake grate

minetest.register_node("pipeworks:intake", {
	description = "Intake grate",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_intake_top.png",
		"pipeworks_intake_sides.png",
		"pipeworks_intake_sides.png",
		"pipeworks_intake_sides.png",
		"pipeworks_intake_sides.png",
		"pipeworks_intake_sides.png"
	},
	selection_box = {
             	type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	paramtype = "light",
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
	after_place_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	pipelike=1,
	on_construct = function(pos)
	local meta = minetest.env:get_meta(pos)
	meta:set_int("pipelike",1)
	end,
})

-- outlet grate

minetest.register_node("pipeworks:outlet", {
	description = "Outlet grate",
	drawtype = "nodebox",
	tiles = {
		"pipeworks_outlet_top.png",
		"pipeworks_outlet_sides.png",
		"pipeworks_outlet_sides.png",
		"pipeworks_outlet_sides.png",
		"pipeworks_outlet_sides.png",
		"pipeworks_outlet_sides.png"
	},
	selection_box = {
             	type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
	},
	paramtype = "light",
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
	after_place_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	pipelike=1,
	on_construct = function(pos)
	local meta = minetest.env:get_meta(pos)
	meta:set_int("pipelike",1)
	end,
})

-- tank

minetest.register_node("pipeworks:storage_tank_x", {
	description = "Fluid Storage Tank",
	tiles = {
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_sides.png",
		"pipeworks_storage_tank_sides.png"
	},
	paramtype = "light",
	groups = {snappy=3, pipe=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
	after_place_node = function(pos)
		pipe_device_autorotate(pos, nil, "pipeworks:storage_tank")
		pipe_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	pipelike=1,
	on_construct = function(pos)
	local meta = minetest.env:get_meta(pos)
	meta:set_int("pipelike",1)
	end,
})

minetest.register_node("pipeworks:storage_tank_z", {
	description = "Fluid Storage Tank (Z axis)... You hacker, you.",
	tiles = {
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_sides.png",
		"pipeworks_storage_tank_sides.png",
		"pipeworks_storage_tank_fittings.png",
		"pipeworks_storage_tank_fittings.png"
	},
	paramtype = "light",
	groups = {snappy=3, pipe=1, not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	stack_max = 99,
	drop = "pipeworks:storage_tank_x",
	after_place_node = function(pos)
		pipe_device_autorotate(pos, nil, "pipeworks:storage_tank")
		pipe_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
		pipe_scanforobjects(pos)
	end,
	pipelike=1,
	on_construct = function(pos)
	local meta = minetest.env:get_meta(pos)
	meta:set_int("pipelike",1)
	end,
})

-- various actions

local axes = { "x", "z" }

for a in ipairs(axes) do
	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:valve_on_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:valve_off_"..axes[a] })
			local meta = minetest.env:get_meta(pos)
			meta:set_int("pipelike",0)
		end
	end)

	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:valve_off_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:valve_on_"..axes[a] })
			local meta = minetest.env:get_meta(pos)
			meta:set_int("pipelike",1)
		end
	end)

	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:pump_on_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:pump_off_"..axes[a] })
		end
	end)

	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:pump_off_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:pump_on_"..axes[a] })
		end
	end)
end

print("Pipeworks loaded!")
