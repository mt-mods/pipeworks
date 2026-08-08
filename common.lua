-- Random variables

pipeworks.expect_infinite_stacks = true
if core.get_modpath("unified_inventory") or not core.settings:get_bool("creative_mode") then
	pipeworks.expect_infinite_stacks = false
end

pipeworks.meseadjlist = {
	vector.new( 0, 0, 1),
	vector.new( 0, 0,-1),
	vector.new( 0, 1, 0),
	vector.new( 0,-1, 0),
	vector.new( 1, 0, 0),
	vector.new(-1, 0, 0),
}

pipeworks.rules_all = {
	vector.new( 0, 0, 1),
	vector.new( 0, 0,-1),
	vector.new( 1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new( 0, 1, 1),
	vector.new( 0, 1,-1),
	vector.new( 1, 1, 0),
	vector.new(-1, 1, 0),
	vector.new( 0,-1, 1),
	vector.new( 0,-1,-1),
	vector.new( 1,-1, 0),
	vector.new(-1,-1, 0),
	vector.new( 0, 1, 0),
	vector.new( 0,-1, 0),
}

pipeworks.mesecons_rules = {
	vector.new( 0, 0, 1),
	vector.new( 0, 0,-1),
	vector.new( 1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new( 0, 1, 0),
	vector.new( 0,-1, 0),
}

local digilines_enabled = core.get_modpath("digilines") ~= nil
if digilines_enabled and pipeworks.enable_vertical_digilines_connectivity then
	pipeworks.digilines_rules=digilines.rules.default
else
	-- These rules break vertical connectivity to deployers, node breakers, dispensers, and digiline filter injectors
	-- via digiline conducting tubes. Changing them may break some builds on some servers, so the setting was added
	-- for server admins to be able to revert to the old "broken" behavior as some builds may use it as a "feature".
	-- See https://github.com/mt-mods/pipeworks/issues/64
	pipeworks.digilines_rules = {
		vector.new( 0, 0, 1),
		vector.new( 0, 0,-1),
		vector.new( 1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new( 0, 1, 0),
		vector.new( 0,-1, 0),
	}
end

pipeworks.liquid_texture = core.registered_nodes[pipeworks.liquids.water.flowing].tiles[1]
if type(pipeworks.liquid_texture) == "table" then pipeworks.liquid_texture = pipeworks.liquid_texture.name end

-- Helper functions

function pipeworks.fix_image_names(table, replacement)
	local outtable={}
	for i in ipairs(table) do
		outtable[i]=string.gsub(table[i], "_XXXXX", replacement)
	end

	return outtable
end

local function overlay_tube_texture(texture)
	-- The texture appears the first time to be colorized as the opaque background.
	return ("(%s)^[noalpha^[colorize:#dadada^(%s)"):format(texture, texture)
end

function pipeworks.make_tube_tile(tile)
	if pipeworks.use_real_entities then
		return tile
	elseif type(tile) == "string" then
		return overlay_tube_texture(tile)
	else
		tile = table.copy(tile)
		if tile.color then
			-- Won't work 100% of the time, but good enough.
			tile.name = tile.name .. "^[multiply:" .. core.colorspec_to_colorstring(tile.color)
			tile.color = nil
		end
		tile.name = overlay_tube_texture(tile.name)
		tile.backface_culling = nil -- The texture is opaque
		return tile
	end
end

function pipeworks.add_node_box(t, b)
	if not t or not b then return end
	for i in ipairs(b)
		do table.insert(t, b[i])
	end
end

function pipeworks.may_configure(pos, player)
	local name = player:get_player_name()
	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner ~= "" and owner == name then -- wielders and filters
		return true
	end
	return not core.is_protected(pos, name)
end

function pipeworks.replace_name(tbl,tr,name)
	local ntbl={}
	for key,i in pairs(tbl) do
		if type(i)=="string" then
			ntbl[key]=string.gsub(i,tr,name)
		elseif type(i)=="table" then
			ntbl[key]=pipeworks.replace_name(i,tr,name)
		else
			ntbl[key]=i
		end
	end
	return ntbl
end

-----------------------
-- Facedir functions --
-----------------------

function pipeworks.facedir_to_top_dir(facedir)
	return 	({[0] = vector.new( 0, 1, 0),
	                vector.new( 0, 0, 1),
	                vector.new( 0, 0,-1),
	                vector.new( 1, 0, 0),
	                vector.new(-1, 0, 0),
	                vector.new( 0,-1, 0)})
		[math.floor(facedir / 4)]
end

function pipeworks.facedir_to_right_dir(facedir)
	return vector.cross(
		pipeworks.facedir_to_top_dir(facedir),
		core.facedir_to_dir(facedir)
	)
end

local directions = {}
pipeworks.directions = directions
function directions.side_to_dir(side)
	return ({[0] = vector.new(),
		vector.new( 0,  1,  0),
		vector.new( 0, -1,  0),
		vector.new( 1,  0,  0),
		vector.new(-1,  0,  0),
		vector.new( 0,  0,  1),
		vector.new( 0,  0, -1)
	})[side]
end

function directions.dir_to_side(dir)
	local c = vector.dot(dir, vector.new(1, 2, 3)) + 4
	return ({6, 2, 4, 0, 3, 1, 5})[c]
end

---------------------
-- Table functions --
---------------------

function pipeworks.table_contains(tbl, element)
	for _, elt in pairs(tbl) do
		if elt == element then
			return true
		end
	end
	return false
end

function pipeworks.table_extend(tbl, tbl2)
	local oldlength = #tbl
	for i = 1,#tbl2 do
		tbl[oldlength + i] = tbl2[i]
	end
end

function pipeworks.table_recursive_replace(tbl, pattern, replace_with)
	if type(tbl) == "table" then
		local tbl2 = {}
		for key, value in pairs(tbl) do
			tbl2[key] = pipeworks.table_recursive_replace(value, pattern, replace_with)
		end
		return tbl2
	elseif type(tbl) == "string" then
		return tbl:gsub(pattern, replace_with)
	else
		return tbl
	end
end

---------
-- Env --
---------

function pipeworks.load_position(pos)
	if pos.x < -30912 or pos.y < -30912 or pos.z < -30912 or
	   pos.x >  30927 or pos.y >  30927 or pos.z >  30927 then return end
	if core.get_node_or_nil(pos) then
		return
	end
	local vm = core.get_voxel_manip()
	vm:read_from_map(pos, pos)
end

-- Kept for compatibility with old mods
pipeworks.create_fake_player = fakelib.create_player
