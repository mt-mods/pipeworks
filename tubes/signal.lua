-- luacheck: globals DIR_DELIM

local S = core.get_translator("pipeworks")

if core.get_modpath("mesecons") and pipeworks.enable_detector_tube then
	local detector_tube_step = 5 * (tonumber(core.settings:get("dedicated_server_step")) or 0.09)

	-- this table stores ad-hoc timers (not node timers) for every detector tube
	-- { [position_hash] = time }
	local detector_timers = {}

	-- Persistency: load/save pending timers from/into a file across game restarts
	-- this is basically a copypaste from mesecons code
	local wpath = core.get_worldpath()
	local filename = "detector_timers"

	local f = io.open(wpath..DIR_DELIM..filename, "r")
	if f then
		local t = f:read("*all")
		f:close()
		if t and t ~= "" then
			detector_timers = core.deserialize(t)
		end
	end

	core.register_on_shutdown(function()
		local f = io.open(wpath..DIR_DELIM..filename, "w")
		f:write(core.serialize(detector_timers))
		f:close()
	end)

	local function detector_set_timer(pos)
		-- refresh timer if already set
		detector_timers[core.hash_node_position(pos)] = detector_tube_step
	end

	core.register_globalstep(function(dtime)
		for hash,time in pairs(detector_timers) do
			time = time - dtime
			if time <= 0 then
				local pos = core.get_position_from_hash(hash)
				local node = core.get_node_or_nil(pos)
				if node then
					detector_timers[hash] = nil
					if string.find(node.name, "pipeworks:detector_tube_on", 1, true) then
						node.name = string.gsub(node.name, "on", "off")
						core.swap_node(pos, node)
						mesecon.receptor_off(pos, pipeworks.mesecons_rules)
					end
				end
				-- in case the area wasn't loaded, do not remove the timer
			else
				detector_timers[hash] = time
			end
		end
	end)

	-- cleanup metadata from previous versions
	local function detector_cleanup_metadata(pos)
		local meta = core.get_meta(pos)
		if not meta then return end
		-- an empty string deletes the key even if the previous value wasn't a string
		meta:set_string("nitems", "")
	end

	pipeworks.register_tube("pipeworks:detector_tube_on", {
			description = S("Detecting Pneumatic Tube Segment on"),
			inventory_image = "pipeworks_detector_tube_inv.png",
			plain = { "pipeworks_detector_tube_plain.png" },
			node_def = {
				tube = {
					can_go = function(pos, node, velocity, stack)
						detector_cleanup_metadata(pos)
						detector_set_timer(pos)
						return pipeworks.notvel(pipeworks.meseadjlist, velocity)
					end,
				},
				groups = {mesecon = 2, not_in_creative_inventory = 1},
				drop = "pipeworks:detector_tube_off_1",
				mesecons = {receptor = {state = "on", rules = pipeworks.mesecons_rules}},
			},
	})

	pipeworks.register_tube("pipeworks:detector_tube_off", {
		description = S("Detecting Pneumatic Tube Segment"),
		inventory_image = "pipeworks_detector_tube_inv.png",
		plain = {"pipeworks_detector_tube_plain.png"},
		node_def = {
			tube = {
				can_go = function(pos, node, velocity, stack)
					detector_cleanup_metadata(pos)
					node.name = string.gsub(node.name, "off", "on")
					core.swap_node(pos, node)
					mesecon.receptor_on(pos, pipeworks.mesecons_rules)
					detector_set_timer(pos)
					return pipeworks.notvel(pipeworks.meseadjlist, velocity)
				end,
			},
			groups = {mesecon = 2},
			mesecons = {receptor = {state = "off", rules = pipeworks.mesecons_rules}},
		},
	})

	core.register_craft( {
		output = "pipeworks:detector_tube_off_1 2",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ "mesecons:mesecon", "mesecons_materials:silicon", "mesecons:mesecon" },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})
end

local digiline_enabled = core.get_modpath("digilines") ~= nil
if digiline_enabled and pipeworks.enable_digiline_detector_tube then
	pipeworks.register_tube("pipeworks:digiline_detector_tube", {
			description = S("Digiline Detecting Pneumatic Tube Segment"),
			inventory_image = "pipeworks_digiline_detector_tube_inv.png",
			plain = { "pipeworks_digiline_detector_tube_plain.png" },
			node_def = {
				tube = {can_go = function(pos, node, velocity, stack)
						local meta = core.get_meta(pos)

						local setchan = meta:get_string("channel")

						digilines.receptor_send(pos, digilines.rules.default, setchan, stack:to_table())

						return pipeworks.notvel(pipeworks.meseadjlist, velocity)
					end},
				on_construct = function(pos)
					local meta = core.get_meta(pos)
					meta:set_string("formspec",
						"size[8.5,2.2]"..
						"image[0.2,0;1,1;pipeworks_digiline_detector_tube_inv.png]"..
						"label[1.2,0.2;"..S("Digiline Detecting Tube").."]"..
						"field[0.5,1.6;4.6,1;channel;"..S("Channel")..";${channel}]"..
						"button[4.8,1.3;1.5,1;set_channel;"..S("Set").."]"..
						"button_exit[6.3,1.3;2,1;close;"..S("Close").."]"
					)
				end,
				on_receive_fields = function(pos, formname, fields, sender)
					if (fields.quit and not fields.key_enter_field)
					or (fields.key_enter_field ~= "channel" and not fields.set_channel)
					or not pipeworks.may_configure(pos, sender) then
						return
					end
					if fields.channel then
						core.get_meta(pos):set_string("channel", fields.channel)
					end
				end,
				groups = {},
				digilines = {
					receptor = {},
					effector = {
						action = function(pos,node,channel,msg) end
					},
					wire = {
						rules = pipeworks.digilines_rules
					},
				},
			},
	})

	core.register_craft( {
		output = "pipeworks:digiline_detector_tube_1 2",
		recipe = {
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" },
			{ "digilines:wire_std_00000000", "mesecons_materials:silicon", "digilines:wire_std_00000000" },
			{ "basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet" }
		},
	})
end

if core.get_modpath("mesecons") and pipeworks.enable_conductor_tube then
	pipeworks.register_tube("pipeworks:conductor_tube_off", {
			description = S("Conducting Pneumatic Tube Segment"),
			inventory_image = "pipeworks_conductor_tube_inv.png",
			short = "pipeworks_conductor_tube_short.png",
			plain = { "pipeworks_conductor_tube_plain.png" },
			noctr = { "pipeworks_conductor_tube_noctr.png" },
			ends = { "pipeworks_conductor_tube_end.png" },
			node_def = {
				groups = {mesecon = 2},
				mesecons = {conductor = {state = "off",
							  rules = pipeworks.mesecons_rules,
							  onstate = "pipeworks:conductor_tube_on_#id"}}
			},
	})
	pipeworks.register_tube("pipeworks:conductor_tube_on", {
			description = S("Conducting Pneumatic Tube Segment on"),
			inventory_image = "pipeworks_conductor_tube_inv.png",
			short = "pipeworks_conductor_tube_short.png",
			plain = { "pipeworks_conductor_tube_on_plain.png" },
			noctr = { "pipeworks_conductor_tube_on_noctr.png" },
			ends = { "pipeworks_conductor_tube_on_end.png" },
			node_def = {
				groups = {mesecon = 2, not_in_creative_inventory = 1},
				drop = "pipeworks:conductor_tube_off_1",
				mesecons = {conductor = {state = "on",
							  rules = pipeworks.mesecons_rules,
							  offstate = "pipeworks:conductor_tube_off_#id"}}
			},
	})

	core.register_craft({
		type = "shapeless",
		output = "pipeworks:conductor_tube_off_1",
		recipe = {"pipeworks:tube_1", "mesecons:mesecon"}
	})
end

if digiline_enabled and pipeworks.enable_digiline_conductor_tube then
	pipeworks.register_tube("pipeworks:digiline_conductor_tube", {
		description = S("Digiline Conducting Pneumatic Tube Segment"),
		inventory_image = "pipeworks_tube_inv.png^pipeworks_digiline_conductor_tube_inv.png",
		short = "pipeworks_tube_short.png^pipeworks_digiline_conductor_tube_short.png",
		plain = {"pipeworks_tube_plain.png^pipeworks_digiline_conductor_tube_plain.png"},
		noctr = {"pipeworks_tube_noctr.png^pipeworks_digiline_conductor_tube_noctr.png"},
		ends = {"pipeworks_tube_end.png^pipeworks_digiline_conductor_tube_end.png"},
		node_def = {digilines = {wire = {rules = pipeworks.digilines_rules}}},
	})
	core.register_craft({
		type = "shapeless",
		output = "pipeworks:digiline_conductor_tube_1",
		recipe = {"pipeworks:tube_1", "digilines:wire_std_00000000"}
	})
end

if digiline_enabled and pipeworks.enable_digiline_conductor_tube and
		pipeworks.enable_conductor_tube then
	pipeworks.register_tube("pipeworks:mesecon_and_digiline_conductor_tube_off", {
		description = S("Mesecon and Digiline Conducting Pneumatic Tube Segment"),
		inventory_image = "pipeworks_conductor_tube_inv.png^pipeworks_digiline_conductor_tube_inv.png",
		short = "pipeworks_conductor_tube_short.png^pipeworks_digiline_conductor_tube_short.png",
		plain = {"pipeworks_conductor_tube_plain.png^pipeworks_digiline_conductor_tube_plain.png"},
		noctr = {"pipeworks_conductor_tube_noctr.png^pipeworks_digiline_conductor_tube_noctr.png"},
		ends = {"pipeworks_conductor_tube_end.png^pipeworks_digiline_conductor_tube_end.png"},
		node_def = {
			digilines = {wire = {rules = pipeworks.digilines_rules}},
			groups = {mesecon = 2},
			mesecons = {conductor = {
				state = "off",
				rules = pipeworks.mesecons_rules,
				onstate = "pipeworks:mesecon_and_digiline_conductor_tube_on_#id"
			}},
		},
	})
	pipeworks.register_tube("pipeworks:mesecon_and_digiline_conductor_tube_on", {
		description = S("Mesecon and Digiline Conducting Pneumatic Tube Segment on"),
		inventory_image = "pipeworks_conductor_tube_inv.png^pipeworks_digiline_conductor_tube_inv.png",
		short = "pipeworks_conductor_tube_short.png^pipeworks_digiline_conductor_tube_short.png",
		plain = {"pipeworks_conductor_tube_on_plain.png^pipeworks_digiline_conductor_tube_plain.png"},
		noctr = {"pipeworks_conductor_tube_on_noctr.png^pipeworks_digiline_conductor_tube_noctr.png"},
		ends = {"pipeworks_conductor_tube_on_end.png^pipeworks_digiline_conductor_tube_end.png"},
		node_def = {
			digilines = {wire = {rules = pipeworks.digilines_rules}},
			groups = {mesecon = 2, not_in_creative_inventory = 1},
			drop = "pipeworks:mesecon_and_digiline_conductor_tube_off_1",
			mesecons = {conductor = {
				state = "on",
				rules = pipeworks.mesecons_rules,
				offstate = "pipeworks:mesecon_and_digiline_conductor_tube_off_#id"}
			},
		},
	})
	core.register_craft({
		type = "shapeless",
		output = "pipeworks:mesecon_and_digiline_conductor_tube_off_1",
		recipe = {"pipeworks:tube_1", "mesecons:mesecon", "digilines:wire_std_00000000"}
	})
	core.register_craft({
		type = "shapeless",
		output = "pipeworks:mesecon_and_digiline_conductor_tube_off_1",
		recipe = {"pipeworks:conductor_tube_off_1", "digilines:wire_std_00000000"}
	})
	core.register_craft({
		type = "shapeless",
		output = "pipeworks:mesecon_and_digiline_conductor_tube_off_1",
		recipe = {"pipeworks:digiline_conductor_tube_1", "mesecons:mesecon"}
	})
end
