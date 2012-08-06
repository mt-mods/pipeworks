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
	"crossing_xyz",
	"cap_center",
	"cap_neg_x",
	"cap_pos_x",
	"cap_neg_y",
	"cap_pos_y",
	"cap_neg_z",
	"cap_pos_z"
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
	"6-way crossing",
	"capped, center only",
	"capped, negative X half only",
	"capped, positive X half only",
	"capped, negative Y half only",
	"capped, positive Y half only",
	"capped, negative Z half only",
	"capped, positive Z half only"
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
	 "pipeworks_pipe_end.png"},

	{"pipeworks_plain.png",		-- center segment
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_plain.png",		-- capped, anchored at -X
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_plain.png",		-- capped, anchored at +X
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_plain.png",	-- capped, anchored at -Y
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_pipe_end.png",	-- capped, anchored at +Y
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png"},

	{"pipeworks_plain.png",	-- capped, anchored at -Z
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png"},

	{"pipeworks_plain.png",	-- capped, anchored at +Z
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_plain.png",
	 "pipeworks_pipe_end.png",
	 "pipeworks_plain.png"},
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
	{ -0.3, -0.15, -0.15, 0.3, 0.15, 0.15 },	-- capped, center only
	{ -0.5, -0.15, -0.15, 0, 0.15, 0.15 },		-- capped, negative X half only
	{ 0, -0.15, -0.15, 0.5, 0.15, 0.15 },		-- capped, positive X half only
	{ -0.15, -0.5, -0.15, 0.15, 0, 0.15 },		-- capped, negative Y half only
	{ -0.15, 0, -0.15, 0.15, 0.5, 0.15 },		-- capped, positive Y half only
	{ -0.15, -0.15, -0.5, 0.15, 0.15, 0 },		-- capped, negative Z half only
	{ -0.15, -0.15, 0, 0.15, 0.15, 0.5 },		-- capped, positive Z half only
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

	{{ -0.3 , -0.15, -0.15, -0.25, 0.15, 0.15 },	-- centered
	 { -0.25, -0.1 , -0.1 ,  0.25, 0.1 , 0.1  },
	 {  0.25, -0.15, -0.15,  0.3 , 0.15, 0.15 }},

	{{ -0.5,  -0.15, -0.15, -0.45, 0.15, 0.15 },	-- anchored at -X
	 { -0.45, -0.1,  -0.1,  -0.2,  0.1,  0.1  },
	 { -0.2,  -0.15, -0.15, -0.15, 0.15, 0.15 },
	 { -0.15, -0.12, -0.12, -0.1,  0.12, 0.12 },
	 { -0.1,  -0.08, -0.08, -0.05, 0.08, 0.08 },
	 { -0.05, -0.04, -0.04,  0,    0.04, 0.04 }},

	{{  0.45, -0.15, -0.15, 0.5,  0.15, 0.15 },	-- anchored at +X
	 {  0.2,  -0.1,  -0.1,  0.45, 0.1,  0.1  },
	 {  0.15, -0.15, -0.15, 0.2,  0.15, 0.15 },
	 {  0.1,  -0.12, -0.12, 0.15, 0.12, 0.12 },
	 {  0.05, -0.08, -0.08, 0.1,  0.08, 0.08 },
	 {  0,    -0.04, -0.04, 0.05, 0.04, 0.04 }},

	{{ -0.15,  -0.5, -0.15,  0.15, -0.45, 0.15 },	-- anchored at -Y
	 { -0.1,  -0.45, -0.1,   0.1,  -0.2,  0.1  },
	 { -0.15,  -0.2, -0.15,  0.15, -0.15, 0.15 },
	 { -0.12, -0.15, -0.12,  0.12, -0.1,  0.12 },
	 { -0.08, -0.1,  -0.08,  0.08, -0.05, 0.08 },
	 { -0.04, -0.05, -0.04,  0.04,  0,    0.04 }},

	{{ -0.15,  0.45, -0.15, 0.15, 0.5,  0.15 },	-- anchored at +Y
	 { -0.1,   0.2,  -0.1,  0.1,  0.45, 0.1  },
	 { -0.15,  0.15, -0.15, 0.15, 0.2,  0.15 },
	 { -0.12,  0.1,  -0.12, 0.12, 0.15, 0.12 },
	 { -0.08,  0.05, -0.08, 0.08, 0.1,  0.08 } ,
	 { -0.04,  0,    -0.04, 0.04, 0.05, 0.04 }},

	{{ -0.15, -0.15, -0.5,  0.15, 0.15, -0.45 },	-- anchored at -Z
	 { -0.1,  -0.1,  -0.45, 0.1,  0.1,  -0.2  },
	 { -0.15, -0.15, -0.2,  0.15, 0.15, -0.15 },
	 { -0.12, -0.12, -0.15, 0.12, 0.12, -0.1  },
	 { -0.08, -0.08, -0.1,  0.08, 0.08, -0.05 },
	 { -0.04, -0.04, -0.05, 0.04, 0.04,  0    }},

	{{ -0.15, -0.15,  0.45, 0.15, 0.15, 0.5  },	-- anchored at +Z
	 { -0.1,  -0.1,   0.2,  0.1,  0.1,  0.45 },
	 { -0.15, -0.15,  0.15, 0.15, 0.15, 0.2  },
	 { -0.12, -0.12,  0.1,  0.12, 0.12, 0.15 },
	 { -0.08, -0.08,  0.05, 0.08, 0.08, 0.1  },
	 { -0.04, -0.04,  0,    0.04, 0.04, 0.05 }},
}

function fix_image_names(node, replacement)
	outtable={}
	for i in ipairs(nodeimages[node]) do
		outtable[i]=string.gsub(nodeimages[node][i], "_XXXXX", replacement)
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
		selection_box = {
              		type = "fixed",
			fixed = selectionboxes[node],
		},
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
		selection_box = {
              		type = "fixed",
			fixed = selectionboxes[node],
		},	
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
