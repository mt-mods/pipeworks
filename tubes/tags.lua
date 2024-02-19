local S = minetest.get_translator("pipeworks")
local fs_helpers = pipeworks.fs_helpers

if not pipeworks.enable_tags_tube then return end

local notag_name = "<<notag>>"
local tube_name = "pipeworks:tags_tube"
local tube_description = S("Tags Sorting Pneumatic Tube Segment")

local safe_tags = function(tags)
	local length_limit = tonumber(minetest.settings:get("pipeworks_item_tag_name_limit") or "30")
	return tags:sub(1, length_limit * 6)
end

local update_formspec = function(pos)
	local meta = minetest.get_meta(pos)
	local buttons_formspec = ""
	for i = 0, 5 do
		buttons_formspec = buttons_formspec .. fs_helpers.cycling_button(meta,
			"image_button[9," .. (i + (i * 0.25) + 1.5) .. ";1,0.6", "l" .. (i + 1) .. "s",
			{
				pipeworks.button_off,
				pipeworks.button_on
			}
		)
	end
	local size = "10.2,10"
	meta:set_string("formspec",
		"formspec_version[2]" ..
		"size[" .. size .. "]" ..
		"item_image[0.2,0.2;1,1;  " .. tube_name .. "]" ..
		"label[1.5,0.75;" .. minetest.formspec_escape(tube_description) .. "]" ..
		pipeworks.fs_helpers.get_prepends(size) ..
		"field[1.5,1.25;7.25,1;tags1;;${tags1}]" ..
		"field[1.5,2.5;7.25,1;tags2;;${tags2}]" ..
		"field[1.5,3.75;7.25,1;tags3;;${tags3}]" ..
		"field[1.5,5.0;7.25,1;tags4;;${tags4}]" ..
		"field[1.5,6.25;7.25,1;tags5;;${tags5}]" ..
		"field[1.5,7.5;7.25,1;tags6;;${tags6}]" ..

		"image[0.22,1.25;1,1;pipeworks_white.png]" ..
		"image[0.22,2.50;1,1;pipeworks_black.png]" ..
		"image[0.22,3.75;1,1;pipeworks_green.png]" ..
		"image[0.22,5.00;1,1;pipeworks_yellow.png]" ..
		"image[0.22,6.25;1,1;pipeworks_blue.png]" ..
		"image[0.22,7.50;1,1;pipeworks_red.png]" ..
		buttons_formspec ..
		"button[6,8.75;1.5,1;set_items_tags;" .. S("Set") .. "]" ..
		"button_exit[7.75,8.75;2,1;close;" .. S("Close") .. "]"
	)
end

pipeworks.register_tube(tube_name, {
	description = tube_description,
	inventory_image = "pipeworks_tag_tube_inv.png",
	noctr = { "pipeworks_tag_tube_noctr_1.png", "pipeworks_tag_tube_noctr_2.png", "pipeworks_tag_tube_noctr_3.png",
		"pipeworks_tag_tube_noctr_4.png", "pipeworks_tag_tube_noctr_5.png", "pipeworks_tag_tube_noctr_6.png" },
	plain = { "pipeworks_tag_tube_plain_1.png", "pipeworks_tag_tube_plain_2.png", "pipeworks_tag_tube_plain_3.png",
		"pipeworks_tag_tube_plain_4.png", "pipeworks_tag_tube_plain_5.png", "pipeworks_tag_tube_plain_6.png" },
	ends = { "pipeworks_tag_tube_end.png" },
	short = "pipeworks_tag_tube_short.png",
	no_facedir = true, -- Must use old tubes, since the textures are rotated with 6d ones
	node_def = {
		tube = {
			can_go = function(pos, node, velocity, stack)
				local tbl, tbln = {}, 0
				local found, foundn = {}, 0
				local meta = minetest.get_meta(pos)
				local stack_tag = pipeworks.get_item_tag(stack)
				if not stack_tag or stack_tag == "" then
					stack_tag = notag_name
				end
				stack_tag = pipeworks.safe_tag(stack_tag)
				for i, vect in ipairs(pipeworks.meseadjlist) do
					local npos = vector.add(pos, vect)
					local node = minetest.get_node(npos)
					local reg_node = minetest.registered_nodes[node.name]
					if meta:get_int("l" .. i .. "s") == 1 and reg_node then
						local tube_def = reg_node.tube
						if not tube_def or not tube_def.can_insert or
							tube_def.can_insert(npos, node, stack, vect) then
							local tags_name = "tags" .. i
							local tags = meta:get_string(tags_name)
							local is_empty = tags == nil or tags == ""
							if not is_empty then
								for tag in string.gmatch(tags, "[^,]+") do
									tag = pipeworks.safe_tag(tag)
									if tag and tag == stack_tag then
										foundn = foundn + 1
										found[foundn] = vect
									end
								end
							end
							if is_empty then
								tbln = tbln + 1
								tbl[tbln] = vect
							end
						end
					end
				end
				return (foundn > 0) and found or tbl
			end
		},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			for i = 1, 6 do
				meta:set_int("l" .. tostring(i) .. "s", 1)
				inv:set_size("line" .. tostring(i), 6 * 1)
			end
			update_formspec(pos)
			meta:set_string("infotext", S("Tags Sorting pneumatic tube"))
		end,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if placer and placer:is_player() and placer:get_player_control().aux1 then
				local meta = minetest.get_meta(pos)
				for i = 1, 6 do
					meta:set_int("l" .. tostring(i) .. "s", 0)
				end
				update_formspec(pos)
			end
			return pipeworks.after_place(pos, placer, itemstack, pointed_thing)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			if (fields.quit and not fields.key_enter_field)
				or not pipeworks.may_configure(pos, sender) then
				return
			end

			local meta = minetest.get_meta(pos)
			for i = 1, 6 do
				local field_name = "tags" .. tostring(i)
				if fields[field_name] then
					local safe_tags = safe_tags(fields[field_name])
					meta:set_string(field_name, safe_tags)
				end
			end

			fs_helpers.on_receive_fields(pos, fields)
			update_formspec(pos)
		end,
		can_dig = function(pos, player)
			return true
		end,
	},
})
