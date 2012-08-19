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

	if s == "off" then
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
			tilez,
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
			pipe_device_autorotate(pos, states[s], "pipeworks:pump_")
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
			tilex,
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
			pipe_device_autorotate(pos, states[s], "pipeworks:pump_")
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
			pipe_device_autorotate(pos, states[s], "pipeworks:valve_")
			pipe_scanforobjects(pos)
		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:valve_off_x"
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
			pipe_device_autorotate(pos, states[s], "pipeworks:valve_")
			pipe_scanforobjects(pos)

		end,
		after_dig_node = function(pos)
			pipe_scanforobjects(pos)
		end,
		drop = "pipeworks:valve_off_x"
	})
end

local axes = { "x", "z" }

for a in ipairs(axes) do
	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:valve_on_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:valve_off_"..axes[a] })
		end
	end)

	minetest.register_on_punchnode(function (pos, node)
		if node.name=="pipeworks:valve_off_"..axes[a] then 
			minetest.env:add_node(pos, { name = "pipeworks:valve_on_"..axes[a] })
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
