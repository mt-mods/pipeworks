-- chest -> filter-injector -> tube -> chest, running along the x-axis
mtt.register_with_area("chest -> injector -> tube -> chest", {
	size = { x = 5, y = 3, z = 3 },
	emerged = true
}, function(pos1, _, callback)
	local chest = "default:chest"

	local y, z = pos1.y + 1, pos1.z + 1
	local chest_in = { x = pos1.x, y = y, z = z }
	local injector = { x = pos1.x + 1, y = y, z = z }
	local tube = { x = pos1.x + 2, y = y, z = z }
	local chest_out = { x = pos1.x + 3, y = y, z = z }

	core.set_node(chest_in, { name = chest, param2 = 0 })
	core.set_node(injector, { name = "pipeworks:filter", param2 = 0 })
	core.set_node(tube, { name = "pipeworks:tube_1" })
	core.set_node(chest_out, { name = chest, param2 = 0 })
	pipeworks.scan_for_tube_objects(tube)

	core.get_meta(injector):set_string("owner", "singleplayer")
	core.get_meta(chest_in):get_inventory():add_item("main", "default:dirt 3")

	local node = core.get_node(injector)
	core.registered_nodes["pipeworks:filter"].on_punch(injector, node, nil)

	-- itemwise injector, the item travels through the tube asynchronously
	local inv_out = core.get_meta(chest_out):get_inventory()
	local function check()
		if inv_out:contains_item("main", "default:dirt") then
			-- exactly one item moved per punch
			assert(core.get_meta(chest_in):get_inventory():contains_item("main", "default:dirt 2"))
			assert(not inv_out:contains_item("main", "default:dirt 2"))
			callback()
		else
			core.after(0.2, check)
		end
	end
	check()
end)
