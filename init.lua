-- Pipeworks mod by Vanessa Ezekowitz - 2012-08-05
--
-- Entirely my own code.  This mod merely supplies enough nodes to build 
-- a bunch of pipes in all directions and with all types of junctions
--
-- License: WTFPL
--

local DEBUG = 0

-- Local Functions

local dbg = function(s)
	if DEBUG == 1 then
		print('[PIPEWORKS] ' .. s)
	end
end

local nodenames = {
	"vertical",
	"horizontal",
	"junction_xy",
	"junction_xz",
	"bend_xy_down",
	"bend_xy_up",
	"bend_xz",
	"crossing_xz",
	"crossing_xy",
	"crossing_xyz"
}

local descriptions = {
	"vertical",
	"horizontal",
	"junction between X and Y axes",
	"junction between X and Z axes",
	"downward bend between X and Y axes",
	"upward bend between X and Y axes",
	"bend between X/Z axes",
	"4-way crossing between X and Z axes",
	"4-way crossing between X/Z and Y axes",
	"6-way crossing"
}

local nodeimages = {
	{"pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png"},

	{"pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png"},

	{"pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png"},

	{"pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png"},

	{"pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png"},

	{"pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png"},

	{"pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png"},

	{"pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_windowed_XXXXX.png",
	 "pipeworks_windowed_XXXXX.png"},

	{"pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png"}
}

local selectionboxes = {
	{ -0.15, -0.5, -0.15, 0.15,  0.5, 0.15 },	-- vertical
	{ -0.5, -0.15, -0.15, 0.5, 0.15, 0.15 },	-- horizontal
	{ -0.15, -0.5, -0.15, 0.5, 0.5, 0.15 },		-- vertical with X/Z junction
	{ -0.5, -0.15, -0.15, 0.5, 0.15, 0.5 },		-- horizontal with X/Z junction
	{ -0.15, -0.5, -0.15, 0.5, 0.15, 0.15 },	-- bend down from X/Z to Y axis
	{ -0.15, -0.15, -0.15, 0.5, 0.5, 0.15 },	-- bend up from X/Z to Y axis
	{ -0.15, -0.15, -0.15, 0.5, 0.15, 0.5 },	-- bend between X and Z axes
	{ -0.5, -0.15, -0.5, 0.5, 0.15, 0.5 },		-- 4-way crossing between X and Z axes
	{ -0.5, -0.5, -0.15, 0.5, 0.5, 0.15 },		-- 4-way crossing between X/Z and Y axes
	{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },		-- 6-way crossing (all 3 axes)
}

local nodeboxes = {
	{{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },	-- vertical
	 { -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
	 { -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 }},

	{{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },	-- horizontal
	 { -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 }},

	{{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },	-- vertical with X/Z junction
	 { -0.1 , -0.45, -0.1 ,  0.1 ,  0.45, 0.1  },
	 { -0.15,  0.45, -0.15,  0.15,  0.5 , 0.15 },	
	 {  0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 }},

	{{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },	-- horizontal with X/Z junction
	 { -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
	 { -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
	 { -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 }},

	{{ -0.15, -0.5 , -0.15,  0.15, -0.45, 0.15 },	-- bend down from X/Z to Y axis
	 { -0.1 , -0.45, -0.1 ,  0.1 ,  0.1 , 0.1  },
	 { -0.1 , -0.1 , -0.1 ,  0.45,  0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 ,  0.15, 0.15 }},

	{{ -0.15, 0.45 , -0.15, 0.15,  0.5, 0.15 },	-- bend up from X/Z to Y axis
	 { -0.1 , -0.1 , -0.1 , 0.1 , 0.45, 0.1  },
	 { -0.1 , -0.1 , -0.1 , 0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15, 0.5 , 0.15, 0.15 }},

	{{ -0.15, -0.15,  0.45,  0.15, 0.15, 0.5  },	-- bend between X and Z axes
	 { -0.1 , -0.1 ,  0.1 ,  0.1 , 0.1 , 0.45 },
	 { -0.1 , -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 }},

	{{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },	-- 4-way crossing between X and Z axes
	 { -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
	 { -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
	 { -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
	 { -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  }},

	{{ -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },	-- 4-way crossing between X/Z and Y axes
	 { -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
	 { -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 },
	 { -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },
	 { -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 }},

	{{ -0.5 , -0.15, -0.15, -0.45, 0.15, 0.15 },	-- 6-way crossing (all 3 axes)
	 { -0.45, -0.1 , -0.1 ,  0.45, 0.1 , 0.1  },
	 {  0.45, -0.15, -0.15,  0.5 , 0.15, 0.15 },
	 { -0.15, -0.15, -0.5 ,  0.15, 0.15, -0.45 },
	 { -0.1 , -0.1 , -0.45,  0.1 , 0.1 ,  0.45 },
	 { -0.15, -0.15,  0.45,  0.15, 0.15,  0.5  },
	 { -0.15, -0.5 , -0.15, 0.15, -0.45, 0.15 },
	 { -0.1 , -0.45, -0.1 , 0.1 ,  0.45, 0.1  },
	 { -0.15,  0.45, -0.15, 0.15,  0.5 , 0.15 }},
}

function fix_image_names(node, replacement)
	outtable={}
	for i in ipairs(nodeimages[node]) do
	print(nodeimages[node][i])
		outtable[i]=string.gsub(nodeimages[node][i], "_XXXXX", replacement)
	print(outtable[i])
	end

	return outtable
end

-- Now define the actual nodes

for node in ipairs(nodenames) do
	minetest.register_node("pipeworks:"..nodenames[node], {
		description = "Empty Pipe ("..descriptions[node]..")",
		drawtype = "nodebox",
		tiles = fix_image_names(node, "_empty"),
		paramtype = "light",
		paramtype2 = "facedir",
		selection_box = selectionboxes[node],
		node_box = {
			type = "fixed",
			fixed = nodeboxes[node]
		},
		groups = {snappy=3, pipe=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = "pipeworks:horizontal"
	})

	minetest.register_node("pipeworks:"..nodenames[node].."_loaded", {
		description = "Loaded Pipe ("..descriptions[node]..")",
		drawtype = "nodebox",
		tiles = fix_image_names(node, "_loaded"),
		paramtype = "light",
		paramtype2 = "facedir",
		selection_box = selectionboxes[node],
		node_box = {
			type = "fixed",
			fixed = nodeboxes[node]
		},
		groups = {snappy=3, pipe=1},
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = "pipeworks:horizontal"
	})
end

print("Pipeworks loaded!")
