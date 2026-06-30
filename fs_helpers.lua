local S = core.get_translator("pipeworks")
local insert = table.insert

local fs_helpers = {}
pipeworks.fs_helpers = fs_helpers

-- Pipeworks formspec standard:
-- - Margins and minimum spacing between elements: 0.25
-- - Minimum spacing between inventories: 0.5
-- - Spacing between elements and player inventory: 0.5
-- - Minimum button with text width: 2
-- - Field and button height: 0.75

local splitstacks_text = S("Allow splitting incoming stacks from tubes")

function fs_helpers.standard_formspec(height)
	return fs_helpers.prepends(10.25, height)..fs_helpers.player_inv(0.25, height - 5)
end

function fs_helpers.node_label(name, desc)
	local s = "item_image[0.25,0.25;1,1;%s]label[1.35,0.75;%s]"
	return s:format(name, desc or core.registered_nodes[name].description)
end

function fs_helpers.field(x, y, width, name, label, exit)
	width = width - 0.75  -- Subtract button width
	local s = "field[%f,%f;%f,0.75;%s;%s;${%s}]"..
		"image_button%s[%f,%f;0.75,0.75;pipeworks_checkmark.png;set_%s;]"
	return s:format(x, y, width, name, label, name, exit and "_exit" or "", x + width, y, name)
end

function fs_helpers.toggle_button(x, y, meta, name, on_off)
	local state = meta:get_int(name) == 1 and "on" or "off"
	local s = "image_button[%f,%f;1,0.6;pipeworks_button_%s.png;%s;;;false;pipeworks_button_interm.png]"
	return s:format(x, y, state, on_off and state or "fs_helpers_toggle:"..name)
end

function fs_helpers.splitstacks_button(x, y, meta)
	local button = fs_helpers.toggle_button(x, y, meta, "splitstacks")
	local label = ("label[%f,%f;%s]"):format(x + 1.1, y, splitstacks_text)
	return button..label
end

function fs_helpers.cycling_button(meta, base, key, values)
	local current_value = meta:get_int(key)
	local next_value = (current_value + 1) % #values
	local v = values[current_value + 1]
	local texture, addopts, text = "", ""
	if type(v) == "table" then
		-- Caller wants an image button
		texture = v.texture and (v.texture..";") or ""
		addopts = v.addopts and (";"..v.addopts) or ""
		text = core.formspec_escape(v.text or "")
	else
		text = core.formspec_escape(v or "")
	end
	local s = "%s;%sfs_helpers_cycling:%d:%s;%s%s]"
	return s:format(base, texture, next_value, key, text, addopts)
end

function fs_helpers.on_receive_fields(pos, fields)
	local meta = core.get_meta(pos)
	for field in pairs(fields) do
		if field:sub(1, 19) == "fs_helpers_cycling:" then
			local split = field:split(":")
			meta:set_int(split[3], tonumber(split[2]))
		elseif field:sub(1, 18) == "fs_helpers_toggle:" then
			local key = field:sub(19)
			meta:set_int(key, meta:get_int(key) == 1 and 0 or 1)
		end
	end
end

function fs_helpers.player_inv(x, y)
	local w, size, space
	if core.get_modpath("i3") then
		y = i3.settings.legacy_inventory and y or y + 0.4275
		w = i3.settings.legacy_inventory and 8 or 9
		size = w * 4
		space = i3.settings.legacy_inventory and 0.25 or 0.09375
	elseif core.get_modpath("mcl_formspec") then
		y = y + 0.4275
		w = 9
		size = 36
		space = 0.09375
	else
		return "list[current_player;main;"..x..","..y..";8,4;]"
	end
	local fs = {}
	-- Hotbar
	insert(fs, "style_type[box;colors=#77777710,#77777710,#777,#777]")
	for i = 0, w - 1 do
		insert(fs, "box["..(i + x + i * space)..","..y..";1,1;]")
	end
	insert(fs, "style_type[list;size=1;spacing="..space.."]")
	insert(fs, "list[current_player;main;"..x..","..y..";"..w..",1;]")
	-- Rest of main inventory
	insert(fs, "style_type[box;colors=#666]")
	for i=0, 2 do
		for j=0, w - 1 do
			insert(fs, "box["..(x + j * space + j)..","..(y + 1.15 + i * space + i)..";1,1;]")
		end
	end
	insert(fs, ("list[current_player;main;"..x..",%f;%f,%f;%f]"):format(y + 1.15, w, size / w, w))
	return table.concat(fs)
end

function fs_helpers.prepends(w, h)
	local prepends = "formspec_version[2]size["..w..","..h.."]"
	if core.get_modpath("i3") then
		prepends = table.concat({prepends,
			"no_prepend[]",
			"bgcolor[black;neither]",
			"background9[0,0;"..w..","..h..";i3_bg_full.png;false;10]",
			"style_type[button;border=false;bgimg=[combine:16x16^[noalpha^[colorize:#6b6b6b]",
			"listcolors[#0000;#ffffff20]",
		})
	end
	return prepends
end

function fs_helpers.inv_list(x, y, w, h, list, desc)
	local fs = {}
	if core.get_modpath("i3") or core.get_modpath("mcl_formspec") then
		insert(fs, "style_type[box;colors=#666]")
		for i = 0, w-1 do
			for j = 0, h-1 do
				insert(fs, "box["..x + (i * 1.25)..","..y + (j * 1.25)..";1,1;]")
			end
		end
	end
	insert(fs, ("list[context;%s;%f,%f;%f,%f;]"):format(list, x, y, w, h))
	insert(fs, "listring[current_player;main]listring[context;"..list.."]")
	if desc then
		insert(fs, ("tooltip[%f,%f;%f,%f;%s]"):format(x, y, w * 1.25 - 0.25, h * 1.25 - 0.25, desc))
	end
	return table.concat(fs)
end

-- Deprecated, but kept for compatibility
pipeworks.button_off = {
	text = "",
	texture = "pipeworks_button_off.png",
	addopts = "false;false;pipeworks_button_interm.png",
}
pipeworks.button_on = {
	text = "",
	texture = "pipeworks_button_on.png",
	addopts = "false;false;pipeworks_button_interm.png",
}
pipeworks.button_base = "image_button[0,4.3;1,0.6"
pipeworks.button_label = "label[0.9,4.31;"..splitstacks_text.."]"
