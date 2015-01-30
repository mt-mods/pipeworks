if pipeworks.enable_sand_tube then
	local sand_noctr_textures = {"pipeworks_sand_tube_noctr.png", "pipeworks_sand_tube_noctr.png", "pipeworks_sand_tube_noctr.png",
				     "pipeworks_sand_tube_noctr.png", "pipeworks_sand_tube_noctr.png", "pipeworks_sand_tube_noctr.png"}
	local sand_plain_textures = {"pipeworks_sand_tube_plain.png", "pipeworks_sand_tube_plain.png", "pipeworks_sand_tube_plain.png",
				     "pipeworks_sand_tube_plain.png", "pipeworks_sand_tube_plain.png", "pipeworks_sand_tube_plain.png"}
	local sand_end_textures = {"pipeworks_sand_tube_end.png", "pipeworks_sand_tube_end.png", "pipeworks_sand_tube_end.png",
				   "pipeworks_sand_tube_end.png", "pipeworks_sand_tube_end.png", "pipeworks_sand_tube_end.png"}
	local sand_short_texture = "pipeworks_sand_tube_short.png"
	local sand_inv_texture = "pipeworks_sand_tube_inv.png"

	pipeworks.register_tube("pipeworks:sand_tube", "Vacuuming Pneumatic Tube Segment", sand_plain_textures, sand_noctr_textures, sand_end_textures,
				sand_short_texture, sand_inv_texture,
				{groups = {vacuum_tube = 1}})

	minetest.register_craft( {
		output = "pipeworks:sand_tube_1 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "default:sand", "default:sand", "default:sand" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		output = "pipeworks:sand_tube_1 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "default:desert_sand", "default:desert_sand", "default:desert_sand" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		output = "pipeworks:sand_tube_1",
		recipe = {
			{ "default:desert_sand", "pipeworks:tube_1", "default:desert_sand" },
		},
	})
end

if pipeworks.enable_mese_sand_tube then
	local mese_sand_noctr_textures = {"pipeworks_mese_sand_tube_noctr.png", "pipeworks_mese_sand_tube_noctr.png", "pipeworks_mese_sand_tube_noctr.png",
					  "pipeworks_mese_sand_tube_noctr.png", "pipeworks_mese_sand_tube_noctr.png", "pipeworks_mese_sand_tube_noctr.png"}
	local mese_sand_plain_textures = {"pipeworks_mese_sand_tube_plain.png", "pipeworks_mese_sand_tube_plain.png", "pipeworks_mese_sand_tube_plain.png",
					  "pipeworks_mese_sand_tube_plain.png", "pipeworks_mese_sand_tube_plain.png", "pipeworks_mese_sand_tube_plain.png"}
	local mese_sand_end_textures = {"pipeworks_mese_sand_tube_end.png", "pipeworks_mese_sand_tube_end.png", "pipeworks_mese_sand_tube_end.png",
					"pipeworks_mese_sand_tube_end.png", "pipeworks_mese_sand_tube_end.png", "pipeworks_mese_sand_tube_end.png"}
	local mese_sand_short_texture = "pipeworks_mese_sand_tube_short.png"
	local mese_sand_inv_texture = "pipeworks_mese_sand_tube_inv.png"

	pipeworks.register_tube("pipeworks:mese_sand_tube", "Adjustable Vacuuming Pneumatic Tube Segment", mese_sand_plain_textures, mese_sand_noctr_textures,
				mese_sand_end_textures, mese_sand_short_texture,mese_sand_inv_texture,
				{groups = {vacuum_tube = 1},
				on_construct = function(pos)
					local meta = minetest.get_meta(pos)
					meta:set_int("dist", 0)
					meta:set_string("formspec", "size[2.1,0.8]"..
							"image[0,0;1,1;pipeworks_mese_sand_tube_inv.png]"..
							"field[1.3,0.4;1,1;dist;distance;${dist}]"..
							default.gui_bg..
							default.gui_bg_img)
					meta:set_string("infotext", "Adjustable Vacuuming Pneumatic Tube Segment")
				end,
				on_receive_fields = function(pos,formname,fields,sender)
					local meta = minetest.get_meta(pos)
					local dist = tonumber(fields.dist)
					if dist and 0 <= dist and dist <= 8 then
						meta:set_int("dist", dist)
						meta:set_string("infotext", ("Adjustable Vacuuming Pneumatic Tube Segment (%dm)"):format(dist))
					end
				end,
	})

	minetest.register_craft( {
		output = "pipeworks:mese_sand_tube_1 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "default:sand", "default:mese_crystal", "default:sand" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		output = "pipeworks:mese_sand_tube_1 2",
		recipe = {
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" },
			{ "default:desert_sand", "default:mese_crystal", "default:desert_sand" },
			{ "homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting" }
		},
	})

	minetest.register_craft( {
		type = "shapeless",
		output = "pipeworks:mese_sand_tube_1",
		recipe = {
			"pipeworks:sand_tube_1",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment",
			"default:mese_crystal_fragment"
		},
	})
end

local function vacuum(pos, radius)
	radius = radius + 0.5
	for _, object in pairs(minetest.get_objects_inside_radius(pos, math.sqrt(2) * radius)) do
		local lua_entity = object:get_luaentity()
		if not object:is_player() and lua_entity and lua_entity.name == "__builtin:item" then
			local obj_pos = object:getpos()
			if pos.x - radius <= obj_pos.x and obj_pos.x <= pos.x + radius
			and pos.y - radius <= obj_pos.y and obj_pos.y <= pos.y + radius
			and pos.z - radius <= obj_pos.z and obj_pos.z <= pos.z + radius then
				if lua_entity.itemstring ~= "" then
					pipeworks.tube_inject_item(pos, pos, vector.new(0, 0, 0), lua_entity.itemstring)
					lua_entity.itemstring = ""
				end
				object:remove()
			end
		end
	end
end

minetest.register_abm({nodenames = {"group:vacuum_tube"},
			interval = 1,
			chance = 1,
			action = function(pos, node, active_object_count, active_object_count_wider)
				if node.name == "pipeworks:sand_tube" then
					vacuum(pos, 2)
				else
					local radius = minetest.get_meta(pos):get_int("dist")
					vacuum(pos, radius)
				end
			end
})
