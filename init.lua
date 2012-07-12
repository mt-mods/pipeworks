-- Pipes mod by VanessaE
-- 2012-06-12
--

-- Entirely my own code.  This mod merely supplies enough nodes to build 
-- a bunch of pipes in all directions and with all types of junctions.
--
-- License: WTFPL
--

local DEBUG = 1

-- Local Functions

local dbg = function(s)
	if DEBUG == 1 then
		print('[PIPES] ' .. s)
	end
end

-- Nodes (empty)

minetest.register_node("pipes:vertical", {
        description = "Pipe (vertical)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_plain.png",
			"pipes_windowed_empty.png",
			"pipes_windowed_empty.png"
			},
        paramtype = "light",
--	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15,  0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },	
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:horizontal", {
        description = "Pipe (horizontal)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_empty.png",
			"pipes_windowed_empty.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_plain.png"
			},
        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.15, 0.5, 0.15, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:junction_xy", {
        description = "Pipe (junction between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_empty.png",
			"pipes_windowed_empty.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {			
			{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 ,  0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15,  0.15,  0.5 , 0.15 },	
			{  0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:junction_xz", {
        description = "Pipe (junction between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_empty.png",
			"pipes_windowed_empty.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.15, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },
			{ -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xy_down", {
        description = "Pipe (downward bend between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_empty.png",
			"pipes_windowed_empty.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.5, 0.15, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 ,  0.1 ,  0.1 , 0.1  },
			{ -0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xy_up", {
        description = "Pipe (upward bend between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_empty.png",
			"pipes_windowed_empty.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.15, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, 0.45 , -0.15, 0.15,  0.5, 0.15 },
			{ -0.1 , -0.1 , -0.1 , 0.1 , 0.45, 0.1  },
			{ -0.1 , -0.1 , -0.1 , 0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15, 0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xz", {
        description = "Pipe (bend between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_empty.png",
			"pipes_windowed_empty.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_plain.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.15, -0.15, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },
			{ -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
			{ -0.1 , -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xz", {
        description = "Pipe (4-way crossing between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_empty.png",
			"pipes_windowed_empty.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png"
			},

        paramtype = "light",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.5, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {

			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },

			{ -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
			{ -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
			{ -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xy", {
        description = "Pipe (4-way crossing between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_windowed_empty.png",
			"pipes_windowed_empty.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.5, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },
	
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },	

		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xyz", {
        description = "Pipe (6-way crossing between X/Y/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png"
			},

        paramtype = "light",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {

			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },

			{ -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
			{ -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
			{ -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  },

			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },	

		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})


-- Nodes (full/loaded)

minetest.register_node("pipes:vertical_loaded", {
        description = "Pipe (vertical)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_plain.png",
			"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png"
			},
        paramtype = "light",
--	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.15,  0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },	
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:horizontal_loaded", {
        description = "Pipe (horizontal)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_plain.png"
			},
        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.15, 0.5, 0.15, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:junction_xy_loaded", {
        description = "Pipe (junction between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {			
			{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 ,  0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15,  0.15,  0.5 , 0.15 },	
			{  0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:junction_xz_loaded", {
        description = "Pipe (junction between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.15, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },
			{ -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xy_down_loaded", {
        description = "Pipe (downward bend between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.5, -0.15, 0.5, 0.15, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 ,  0.1 ,  0.1 , 0.1  },
			{ -0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xy_up_loaded", {
        description = "Pipe (upward bend between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.15, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, 0.45 , -0.15, 0.15,  0.5, 0.15 },
			{ -0.1 , -0.1 , -0.1 , 0.1 , 0.45, 0.1  },
			{ -0.1 , -0.1 , -0.1 , 0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15, 0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:bend_xz_loaded", {
        description = "Pipe (bend between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png",
			"pipes_pipe_end.png",
			"pipes_plain.png",
			"pipes_pipe_end.png",
			"pipes_plain.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.15, -0.15, -0.15, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },
			{ -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
			{ -0.1 , -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xz_loaded", {
        description = "Pipe (4-way crossing between X/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png"
			},

        paramtype = "light",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.15, -0.5, 0.5, 0.15, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {

			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },

			{ -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
			{ -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
			{ -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  },
		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xy_loaded", {
        description = "Pipe (4-way crossing between X/Y axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_windowed_loaded.png",
			"pipes_windowed_loaded.png"
			},

        paramtype = "light",
	paramtype2 = "facedir",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.5, -0.15, 0.5, 0.5, 0.15 },
        },
	node_box = {
		type = "fixed",
                fixed = {
			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },
	
			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },	

		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

minetest.register_node("pipes:crossing_xyz_loaded", {
        description = "Pipe (6-way crossing between X/Y/Z axes)",
        drawtype = "nodebox",
        tile_images = {	"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png",
			"pipes_pipe_end.png"
			},

        paramtype = "light",
        selection_box = {
                type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        },
	node_box = {
		type = "fixed",
                fixed = {

			{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
			{ -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
			{  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },

			{ -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
			{ -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
			{ -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  },

			{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
			{ -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
			{ -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },	

		}
	},
        groups = {snappy=3},
        sounds = default.node_sound_wood_defaults(),
	walkable = true,
})

print("[Pipes] Loaded!")
