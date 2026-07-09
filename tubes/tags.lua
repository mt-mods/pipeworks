local S = core.get_translator("pipeworks")
local fs_helpers = pipeworks.fs_helpers
local insert = table.insert

if not pipeworks.enable_item_tags or not pipeworks.enable_tag_tube then return end

local help_text = core.formspec_escape(
	S("Separate multiple tags using commas.").."\n"..
	S("Use \"<none>\" to match items without tags.")
)

local formspec = {
	fs_helpers.prepends(8.5, 7.5),
	"label[0.3,6.5;"..help_text.."]",
	"image_button[7.25,6.25;1,1;pipeworks_checkmark.png;set_item_tags;]",
}
for i, color in ipairs({"ffffff", "000000", "41de3b", "ffeb10", "3866ea", "e53e11"}) do
	local height = 0.25 + (i - 1)
	insert(formspec, "box[0.25,"..height..";0.75,0.75;#"..color.."ff]")
	insert(formspec, "field[1.25,"..height..";5.75,0.75;tags"..i..";;${tags"..i.."}]")
end
formspec = table.concat(formspec)

local update_formspec = function(pos)
	local meta = core.get_meta(pos)
	local fs = {formspec}
	for i=1, 6 do
		local height = 0.3 + (i - 1)
		insert(fs, fs_helpers.toggle_button(7.25, height, meta, "l"..i.."s"))
	end
	meta:set_string("formspec", table.concat(fs))
end

pipeworks.register_tube("pipeworks:tag_tube", {
	description = S("Tag Sorting Pneumatic Tube Segment"),
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
			can_go = function(pos, node, velocity, stack, tags)
				local tbl, tbln = {}, 0
				local found, foundn = {}, 0
				local meta = core.get_meta(pos)
				local tag_hash = {}
				if #tags > 0 then
					for _,tag in ipairs(tags) do
						tag_hash[tag] = true
					end
				else
					tag_hash["<none>"] = true  -- Matches items without tags
				end
				for i, vect in ipairs(pipeworks.meseadjlist) do
					local npos = vector.add(pos, vect)
					local node = core.get_node(npos)
					local reg_node = core.registered_nodes[node.name]
					if meta:get_int("l" .. i .. "s") == 1 and reg_node then
						local tube_def = reg_node.tube
						if not tube_def or not tube_def.can_insert or
							tube_def.can_insert(npos, node, stack, vect) then
							local side_tags = meta:get_string("tags" .. i)
							if side_tags ~= "" then
								side_tags = pipeworks.sanitize_tags(side_tags)
								for _,tag in ipairs(side_tags) do
									if tag_hash[tag] then
										foundn = foundn + 1
										found[foundn] = vect
										break
									end
								end
							else
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
			local meta = core.get_meta(pos)
			for i = 1, 6 do
				meta:set_int("l" .. tostring(i) .. "s", 1)
			end
			update_formspec(pos)
			meta:set_string("infotext", S("Tag sorting pneumatic tube"))
		end,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if placer and placer:is_player() and placer:get_player_control().aux1 then
				local meta = core.get_meta(pos)
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
			local meta = core.get_meta(pos)
			for i = 1, 6 do
				local field_name = "tags" .. tostring(i)
				if fields[field_name] then
					local tags = pipeworks.sanitize_tags(fields[field_name])
					meta:set_string(field_name, table.concat(tags, ","))
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
