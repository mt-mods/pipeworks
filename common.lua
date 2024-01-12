local S = minetest.get_translator("pipeworks")

-- Random variables

pipeworks.expect_infinite_stacks = true
if minetest.get_modpath("unified_inventory") or not minetest.settings:get_bool("creative_mode") then
	pipeworks.expect_infinite_stacks = false
end

pipeworks.meseadjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

pipeworks.rules_all = {{x=0, y=0, z=1},{x=0, y=0, z=-1},{x=1, y=0, z=0},{x=-1, y=0, z=0},
		{x=0, y=1, z=1},{x=0, y=1, z=-1},{x=1, y=1, z=0},{x=-1, y=1, z=0},
		{x=0, y=-1, z=1},{x=0, y=-1, z=-1},{x=1, y=-1, z=0},{x=-1, y=-1, z=0},
		{x=0, y=1, z=0}, {x=0, y=-1, z=0}}

pipeworks.mesecons_rules={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=1,y=0,z=0},{x=-1,y=0,z=0},{x=0,y=1,z=0},{x=0,y=-1,z=0}}
pipeworks.digilines_rules={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=1,y=0,z=0},{x=-1,y=0,z=0},{x=0,y=1,z=0},{x=0,y=-1,z=0}}

pipeworks.liquid_texture = minetest.registered_nodes[pipeworks.liquids.water.flowing].tiles[1]
if type(pipeworks.liquid_texture) == "table" then pipeworks.liquid_texture = pipeworks.liquid_texture.name end

pipeworks.button_off   = {text="", texture="pipeworks_button_off.png", addopts="false;false;pipeworks_button_interm.png"}
pipeworks.button_on    = {text="", texture="pipeworks_button_on.png",  addopts="false;false;pipeworks_button_interm.png"}
pipeworks.button_base  = "image_button[0,4.3;1,0.6"
pipeworks.button_label = "label[0.9,4.31;"..S("Allow splitting incoming stacks from tubes").."]"

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
			tile.name = tile.name .. "^[multiply:" .. minetest.colorspec_to_colorstring(tile.color)
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
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner ~= "" and owner == name then -- wielders and filters
		return true
	end
	return not minetest.is_protected(pos, name)
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

----------------------
-- Vector functions --
----------------------

function pipeworks.vector_cross(a, b)
	return {
		x = a.y * b.z - a.z * b.y,
		y = a.z * b.x - a.x * b.z,
		z = a.x * b.y - a.y * b.x
	}
end

function pipeworks.vector_dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

-----------------------
-- Facedir functions --
-----------------------

function pipeworks.facedir_to_top_dir(facedir)
	return 	({[0] = {x =  0, y =  1, z =  0},
	                {x =  0, y =  0, z =  1},
	                {x =  0, y =  0, z = -1},
	                {x =  1, y =  0, z =  0},
	                {x = -1, y =  0, z =  0},
	                {x =  0, y = -1, z =  0}})
		[math.floor(facedir / 4)]
end

function pipeworks.facedir_to_right_dir(facedir)
	return pipeworks.vector_cross(
		pipeworks.facedir_to_top_dir(facedir),
		minetest.facedir_to_dir(facedir)
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
	local c = pipeworks.vector_dot(dir, vector.new(1, 2, 3)) + 4
	return ({6, 2, 4, 0, 3, 1, 5})[c]
end

----------------------
-- String functions --
----------------------

--[[function pipeworks.string_split(str, sep)
	local fields = {}
	local index = 1
	local expr = "([^"..sep.."])+"
	string.gsub(str, expr, function(substring)
		fields[index] = substring
		index = index + 1
	end)
	return fields
end]]

function pipeworks.string_startswith(str, substr)
	return str:sub(1, substr:len()) == substr
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

------------------------
-- Formspec functions --
------------------------

local fs_helpers = {}
pipeworks.fs_helpers = fs_helpers
function fs_helpers.on_receive_fields(pos, fields)
	local meta = minetest.get_meta(pos)
	for field in pairs(fields) do
		if pipeworks.string_startswith(field, "fs_helpers_cycling:") then
			local l = field:split(":")
			local new_value = tonumber(l[2])
			local meta_name = l[3]
			meta:set_int(meta_name, new_value)
		end
	end
end

function fs_helpers.cycling_button(meta, base, meta_name, values)
	local current_value = meta:get_int(meta_name)
	local new_value = (current_value + 1) % (#values)
	local val = values[current_value + 1]
	local text
	local texture_name = nil
	local addopts = nil
	--when we get a table, we know the caller wants an image_button
	if type(val) == "table" then
		text = val["text"]
		texture_name = val["texture"]
		addopts = val["addopts"]
	else
		text = val
	end
	local field = "fs_helpers_cycling:"..new_value..":"..meta_name
	return base..";"..(texture_name and texture_name..";" or "")..field..";"..minetest.formspec_escape(text)..(addopts and ";"..addopts or "").."]"
end

function fs_helpers.get_inv(y)
	local fs = {}
	if minetest.get_modpath("i3") then
		local inv_x = i3.settings.legacy_inventory and 0.75 or 0.22
		local inv_y = (y + 0.4) or 6.9
		local size, spacing = 1, 0.1
		local hotbar_len = i3.settings.hotbar_len or (i3.settings.legacy_inventory and 8 or 9)
		local inv_size = i3.settings.inv_size or (hotbar_len * 4)

		table.insert(fs, "style_type[box;colors=#77777710,#77777710,#777,#777]")

		for i = 0, hotbar_len - 1 do
			table.insert(fs, "box["..(i * size + inv_x + (i * spacing))..","..inv_y..";"..size..","..size..";]")
		end

		table.insert(fs, "style_type[list;size="..size..";spacing="..spacing.."]")
		table.insert(fs, "list[current_player;main;"..inv_x..","..inv_y..";"..hotbar_len..",1;]")

		table.insert(fs, "style_type[box;colors=#666]")
		for i=0, 2 do
			for j=0, hotbar_len - 1 do
				table.insert(fs, "box["..0.2+(j*0.1)+(j*size)..","..(inv_y+size+spacing+0.05)+(i*0.1)+(i*size)..";"..size..","..size..";]")
			end
		end

		table.insert(fs, "style_type[list;size="..size..";spacing="..spacing.."]")
		table.insert(fs, "list[current_player;main;"..inv_x..","..(inv_y + 1.15)..";"..hotbar_len..","..(inv_size / hotbar_len)..";"..hotbar_len.."]")
	elseif minetest.get_modpath("mcl_formspec") then
		local inv_x = 0.22
		local inv_y = (y + 0.4) or 6.9
		local size, spacing = 1, 0.1
		local hotbar_len = 9
		local inv_size = hotbar_len * 4

		table.insert(fs, "style_type[box;colors=#77777710,#77777710,#777,#777]")

		for i = 0, hotbar_len - 1 do
			table.insert(fs, "box["..(i * size + inv_x + (i * spacing))..","..inv_y..";"..size..","..size..";]")
		end

		table.insert(fs, "style_type[list;size="..size..";spacing="..spacing.."]")
		table.insert(fs, "list[current_player;main;"..inv_x..","..inv_y..";"..hotbar_len..",1;]")

		table.insert(fs, "style_type[box;colors=#666]")
		for i=0, 2 do
			for j=0, hotbar_len - 1 do
				table.insert(fs, "box["..0.2+(j*0.1)+(j*size)..","..(inv_y+size+spacing+0.05)+(i*0.1)+(i*size)..";"..size..","..size..";]")
			end
		end

		table.insert(fs, "style_type[list;size="..size..";spacing="..spacing.."]")
		table.insert(fs, "list[current_player;main;"..inv_x..","..(inv_y + 1.15)..";"..hotbar_len..","..(inv_size / hotbar_len)..";"..hotbar_len.."]")
	else
		table.insert(fs, "list[current_player;main;0.22,"..y..";8,4;]")
	end

	return table.concat(fs, "")
end

function fs_helpers.get_prepends(size)
	local prepend = {}

	if minetest.get_modpath("i3") then
		prepend = {
			"no_prepend[]",
			"bgcolor[black;neither]",
			"background9[0,0;"..size..";i3_bg_full.png;false;10]",
			"style_type[button;border=false;bgimg=[combine:16x16^[noalpha^[colorize:#6b6b6b]",
			"listcolors[#0000;#ffffff20]"
		}
	end

	return table.concat(prepend, "")
end

---------
-- Env --
---------

function pipeworks.load_position(pos)
	if pos.x < -30912 or pos.y < -30912 or pos.z < -30912 or
	   pos.x >  30927 or pos.y >  30927 or pos.z >  30927 then return end
	if minetest.get_node_or_nil(pos) then
		return
	end
	local vm = minetest.get_voxel_manip()
	vm:read_from_map(pos, pos)
end

local function delay(...)
	local args = {...}
	return (function() return unpack(args) end)
end

local function get_set_wrap(name, is_dynamic)
	return (function(self)
		return self["_" .. name]
	end), (function(self, value)
		if is_dynamic then
			self["_" .. name] = type(value) == "table"
				and table.copy(value) or value
		end
	end)
end

local fake_player_metatable = {
	is_player = delay(true),
	is_fake_player = true,

	-- dummy implementation of the rest of the player API:
	add_player_velocity = delay(),  -- deprecated
	add_velocity = delay(),
	get_acceleration = delay(), -- no-op for players
	get_animation = delay({x = 0, y = 0}, 0, 0, false),
	get_armor_groups = delay({}),
	get_attach = delay(),
	get_attribute = delay(),  -- deprecated
	get_bone_position = delay(vector.zero(), vector.zero()),
	get_children = delay({}),
	get_clouds = delay({
		ambient = { r = 0, b = 0, g = 0, a = 0 },
		color = { r = 0, b = 0, g = 0, a = 0 },
		density = 0,
		height = 120,
		thickness = 10,
		speed = vector.zero(),
	}),
	get_day_night_ratio = delay(),
	get_entity_name = delay(),
	get_formspec_prepend = delay(""),
	get_fov = delay(0, false, 0),
	get_lighting = delay({
		exposure = {
			center_weight_power = 1,
			exposure_correction = 0,
			luminance_max = -3,
			luminance_min = -3,
			speed_bright_dark = 1000,
			speed_dark_bright = 1000,
		},
		saturation = 1,
		shadows = {
			intensity = .6212,
		},
	}),
	get_local_animation = delay({x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, 30),
	get_luaentity = delay(),
	get_meta = delay({
		contains = delay(false),
		get = delay(),
		set_string = delay(),
		get_string = delay(""),
		set_int = delay(),
		get_int = delay(0),
		set_float = delay(),
		get_float = delay(0),
		get_keys = delay({}),
		to_table = delay({fields = {}}),
		from_table = delay(false),
		equals = delay(false),
	}),
	get_moon = delay({
		scale = 1,
		texture = "",
		tonemap = "",
		visible = false,
	}),
	get_physics_override = delay({
		acceleration_air = 1,
		acceleration_default = 1,
		gravity = 1,
		jump = 1,
		liquid_fluidity = 1,
		liquid_fluidity_smooth = 1,
		liquid_sink = 1,
		new_move = true,
		sneak = true,
		sneak_glitch = false,
		speed = 1,
		speed_climb = 1,
		speed_crouch = 1,
	}),
	get_player_velocity = vector.zero,  -- deprecated
	get_rotation = delay(), -- no-op for players
	get_sky = delay({ r = 0, g = 0, b = 0, a = 0 }, "regular", {}, true),
	get_sky_color = delay({
		dawn_horizon = { r = 0, g = 0, b = 0, a = 0 },
		dawn_sky = { r = 0, g = 0, b = 0, a = 0 },
		day_horizon = { r = 0, g = 0, b = 0, a = 0 },
		day_sky = { r = 0, g = 0, b = 0, a = 0 },
		fog_moon_tint = { r = 0, g = 0, b = 0, a = 0 },
		fog_sun_tint = { r = 0, g = 0, b = 0, a = 0 },
		fog_tint_type = "default",
		indoors = { r = 0, g = 0, b = 0, a = 0 },
		night_horizon = { r = 0, g = 0, b = 0, a = 0 },
		night_sky = { r = 0, g = 0, b = 0, a = 0 },
	}),
	get_stars = delay({
		count = 1000,
		day_opacity = 0,
		scale = 1,
		star_color = { r = 0, g = 0, b = 0, a = 0 },
		visible = true,
	}),
	get_sun = delay({
		scale = 1,
		sunrise = "",
		sunrise_visible = true,
		texture = "",
		tonemap = "",
		visible = true,
	}),
	get_texture_mod = delay(), -- no-op for players
	get_velocity = vector.zero,
	get_yaw = delay(), -- no-op for players
	getacceleration = delay(), -- backward compatibility
	getvelocity = vector.zero, -- backward compatibility
	getyaw = delay(), -- backward compatibility
	hud_add = delay(),
	hud_change = delay(),
	hud_get = delay(),
	hud_get_flags = delay({
		basic_debug = false,
		breathbar = false,
		chat = false,
		crosshair = false,
		healthbar = false,
		hotbar = false,
		minimap = false,
		minimap_radar = false,
		wielditem = false,
	}),
	hud_get_hotbar_image = delay(""),
	hud_get_hotbar_itemcount = delay(1),
	hud_get_hotbar_selected_image = delay(""),
	hud_remove = delay(),
	hud_set_flags = delay(),
	hud_set_hotbar_image = delay(),
	hud_set_hotbar_itemcount = delay(),
	hud_set_hotbar_selected_image = delay(),
	override_day_night_ratio = delay(),
	punch = delay(),
	remove = delay(),
	respawn = delay(),
	right_click = delay(),
	send_mapblock = delay(),
	set_acceleration = delay(),
	set_animation = delay(),
	set_animation_frame_speed = delay(),
	set_armor_groups = delay(),
	set_attach = delay(),
	set_attribute = delay(), -- deprecated
	set_bone_position = delay(),
	set_clouds = delay(),
	set_detach = delay(),
	set_formspec_prepend = delay(),
	set_fov = delay(),
	set_lighting = delay(),
	set_local_animation = delay(),
	set_look_horizontal = delay(),
	set_look_pitch = delay(),
	set_look_vertical = delay(),
	set_look_yaw = delay(),
	set_minimap_modes = delay(),
	set_moon = delay(),
	set_nametag_attributes = delay(),
	set_physics_override = delay(),
	set_rotation = delay(), -- no-op for players
	set_sky = delay(),
	set_sprite = delay(), -- no-op for players
	set_stars = delay(),
	set_sun = delay(),
	set_texture_mod = delay(), -- no-op for players
	set_velocity = delay(), -- no-op for players
	set_yaw = delay(), -- no-op for players
	setacceleration = delay(), -- backward compatibility
	setsprite = delay(), -- backward compatibility
	settexturemod = delay(), -- backward compatibility
	setvelocity = delay(), -- backward compatibility
	setyaw = delay(), -- backward compatibility
}

function pipeworks.create_fake_player(def, is_dynamic)
	local wielded_item = ItemStack("")
	if def.inventory and def.wield_list then
		wielded_item = def.inventory:get_stack(def.wield_list, def.wield_index or 1)
	end
	local p = {
		get_player_name = delay(def.name),

		_formspec = def.formspec or "",
		_hp = def.hp or 20,
		_breath = 11,
		_pos = def.position and table.copy(def.position) or vector.new(),
		_properties = def.properties or { eye_height = def.eye_height or 1.47 },
		_inventory = def.inventory,
		_wield_index = def.wield_index or 1,
		_wielded_item = wielded_item,

		-- Model and view
		_eye_offset1 = vector.new(),
		_eye_offset3 = vector.new(),
		set_eye_offset = function(self, first, third)
			self._eye_offset1 = table.copy(first)
			self._eye_offset3 = table.copy(third)
		end,
		get_eye_offset = function(self)
			return self._eye_offset1, self._eye_offset3
		end,
		get_look_dir = delay(def.look_dir or vector.new()),
		get_look_pitch = delay(def.look_pitch or 0),
		get_look_yaw = delay(def.look_yaw or 0),
		get_look_horizontal = delay(def.look_yaw or 0),
		get_look_vertical = delay(-(def.look_pitch or 0)),

		-- Controls
		get_player_control = delay({
			jump=false, right=false, left=false, LMB=false, RMB=false,
			sneak=def.sneak, aux1=false, down=false, up=false
		}),
		get_player_control_bits = delay(def.sneak and 64 or 0),

		-- Inventory and ItemStacks
		get_inventory = delay(def.inventory),
		set_wielded_item = function(self, item)
			if self._inventory and def.wield_list then
				return self._inventory:set_stack(def.wield_list,
					self._wield_index, item)
			end
			self._wielded_item = ItemStack(item)
		end,
		get_wielded_item = function(self, item)
			if self._inventory and def.wield_list then
				return self._inventory:get_stack(def.wield_list,
					self._wield_index)
			end
			return ItemStack(self._wielded_item)
		end,
		get_wield_list = delay(def.wield_list),
		get_nametag_attributes = delay({
			bgcolor = false,
			color = { r = 0, g = 0, b = 0, a = 0 },
			text = def.name,
		}),
	}
	-- Getter & setter functions
	p.get_inventory_formspec, p.set_inventory_formspec
		= get_set_wrap("formspec", is_dynamic)
	p.get_breath, p.set_breath = get_set_wrap("breath", is_dynamic)
	p.get_hp, p.set_hp = get_set_wrap("hp", is_dynamic)
	p.get_pos, p.set_pos = get_set_wrap("pos", is_dynamic)
	p.get_wield_index, p.set_wield_index = get_set_wrap("wield_index", true)
	p.get_properties, p.set_properties = get_set_wrap("properties", false)

	-- For players, move_to and get_pos do the same
	p.move_to = p.get_pos

	-- Backwards compatibility
	p.getpos = p.get_pos
	p.setpos = p.set_pos
	p.moveto = p.move_to
	setmetatable(p, { __index = fake_player_metatable })
	return p
end
