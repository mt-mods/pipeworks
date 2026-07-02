local S = core.get_translator("pipeworks")
local fs_helpers = pipeworks.fs_helpers
local insert = table.insert

if pipeworks.enable_mese_tube then
	local formspec = {
		fs_helpers.prepends(10.25, 13),
		"listring[current_player;main]",  -- Blocks shift-clicking into slots
	}
	for i, color in ipairs({"ffffff", "000000", "41de3b", "ffeb10", "3866ea", "e53e11"}) do
		local height = 0.25 + (i - 1) * 1.25
		insert(formspec, "box[0.25,"..height..";1,1;#"..color.."ff]")
		insert(formspec, fs_helpers.inv_list(1.5, height, 6, 1, "line"..i))
	end
	insert(formspec, fs_helpers.player_inv(0.25, 8))
	formspec = table.concat(formspec)

	local function update_formspec(pos)
		local meta = core.get_meta(pos)
		local fs = {formspec}
		for i=1, 6 do
			local height = 0.45 + (i - 1) * 1.25
			insert(fs, fs_helpers.toggle_button(9, height, meta, "l"..i.."s"))
		end
		meta:set_string("formspec", table.concat(fs))
	end

	pipeworks.register_tube("pipeworks:mese_tube", {
			description = S("Sorting Pneumatic Tube Segment"),
			inventory_image = "pipeworks_mese_tube_inv.png",
			noctr = {"pipeworks_mese_tube_noctr_1.png", "pipeworks_mese_tube_noctr_2.png", "pipeworks_mese_tube_noctr_3.png",
				"pipeworks_mese_tube_noctr_4.png", "pipeworks_mese_tube_noctr_5.png", "pipeworks_mese_tube_noctr_6.png"},
			plain = {"pipeworks_mese_tube_plain_1.png", "pipeworks_mese_tube_plain_2.png", "pipeworks_mese_tube_plain_3.png",
				"pipeworks_mese_tube_plain_4.png", "pipeworks_mese_tube_plain_5.png", "pipeworks_mese_tube_plain_6.png"},
			ends = { "pipeworks_mese_tube_end.png" },
			short = "pipeworks_mese_tube_short.png",
			no_facedir = true,  -- Must use old tubes, since the textures are rotated with 6d ones
			node_def = {
				tube = {can_go = function(pos, node, velocity, stack)
						 local tbl, tbln = {}, 0
						 local found, foundn = {}, 0
						 local meta = core.get_meta(pos)
						 local inv = meta:get_inventory()
						 local name = stack:get_name()
						 for i, vect in ipairs(pipeworks.meseadjlist) do
							local npos = vector.add(pos, vect)
							local node = core.get_node(npos)
							local reg_node = core.registered_nodes[node.name]
							if meta:get_int("l"..i.."s") == 1 and reg_node then
								local tube_def = reg_node.tube
								if not tube_def or not tube_def.can_insert or
								tube_def.can_insert(npos, node, stack, vect) then
									local invname = "line"..i
									local is_empty = true
									for _, st in ipairs(inv:get_list(invname)) do
										if not st:is_empty() then
											is_empty = false
											if st:get_name() == name then
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
					end},
				on_construct = function(pos)
					local meta = core.get_meta(pos)
					local inv = meta:get_inventory()
					for i = 1, 6 do
						meta:set_int("l"..tostring(i).."s", 1)
						inv:set_size("line"..tostring(i), 6*1)
					end
					update_formspec(pos)
					meta:set_string("infotext", S("Sorting pneumatic tube"))
				end,
				after_place_node = function(pos, placer, itemstack, pointed_thing)
					if placer and placer:is_player() and placer:get_player_control().aux1 then
						local meta = core.get_meta(pos)
						for i = 1, 6 do
							meta:set_int("l"..tostring(i).."s", 0)
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
					fs_helpers.on_receive_fields(pos, fields)
					update_formspec(pos)
				end,
				allow_metadata_inventory_put = function(pos, listname, index, stack, player)
					if not pipeworks.may_configure(pos, player) then return 0 end
					update_formspec(pos) -- For old tubes
					local inv = core.get_meta(pos):get_inventory()
					local stack_copy = ItemStack(stack)
					stack_copy:set_count(1)
					inv:set_stack(listname, index, stack_copy)
					return 0
				end,
				allow_metadata_inventory_take = function(pos, listname, index, stack, player)
					if not pipeworks.may_configure(pos, player) then return 0 end
					local inv = core.get_meta(pos):get_inventory()
					inv:set_stack(listname, index, ItemStack(""))
					return 0
				end,
				allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
					if not pipeworks.may_configure(pos, player) then return 0 end
					local inv = core.get_meta(pos):get_inventory()

					if from_list:match("line%d") and to_list:match("line%d") then
						return count
					else
						inv:set_stack(from_list, from_index, ItemStack(""))
						return 0
					end
				end,
			},
	})
end
