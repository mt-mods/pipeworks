-- this bit of code modifies the default chests and furnaces to be compatible
-- with pipeworks.

function pipeworks.clone_node(name)
	local node2 = {}
	local node = minetest.registered_nodes[name]
	for k, v in pairs(node) do
		node2[k] = v
	end
	return node2
end

local furnace = pipeworks.clone_node("default:furnace")
	furnace.tiles[1] = "default_furnace_top.png^pipeworks_tube_connection_stony.png"
	furnace.tiles[2] = "default_furnace_bottom.png^pipeworks_tube_connection_stony.png"
	furnace.tiles[3] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	furnace.tiles[4] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	furnace.tiles[5] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	-- note we don't redefine entry 6 ( front)
	furnace.groups.tubedevice = 1
	furnace.groups.tubedevice_receiver = 1
	furnace.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:add_item("fuel",stack)
			else
				return inv:add_item("src",stack)
			end
		end,
		can_insert = function(pos,node,stack,direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:room_for_item("fuel", stack)
			else
				return inv:room_for_item("src", stack)
			end
		end,
		input_inventory = "dst",
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	}
	furnace.after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end
	furnace.after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end

minetest.register_node(":default:furnace", furnace)

local furnace_active = pipeworks.clone_node("default:furnace_active")
	furnace_active.tiles[1] = "default_furnace_top.png^pipeworks_tube_connection_stony.png"
	furnace_active.tiles[2] = "default_furnace_bottom.png^pipeworks_tube_connection_stony.png"
	furnace_active.tiles[3] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	furnace_active.tiles[4] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	furnace_active.tiles[5] = "default_furnace_side.png^pipeworks_tube_connection_stony.png"
	-- note we don't redefine entry 6 (front)
	furnace_active.groups.tubedevice = 1
	furnace_active.groups.tubedevice_receiver = 1
	furnace_active.tube = {
		insert_object = function(pos,node,stack,direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:add_item("fuel", stack)
			else
				return inv:add_item("src", stack)
			end
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if direction.y == 1 then
				return inv:room_for_item("fuel", stack)
			else
				return inv:room_for_item("src", stack)
			end
		end,
		input_inventory = "dst",
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	}
	furnace_active.after_place_node= function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end
	furnace_active.after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end

minetest.register_node(":default:furnace_active", furnace_active)


local chest = pipeworks.clone_node("default:chest")
	chest.tiles[1] = "default_chest_top.png^pipeworks_tube_connection_wooden.png"
	chest.tiles[2] = "default_chest_top.png^pipeworks_tube_connection_wooden.png"
	chest.tiles[3] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	chest.tiles[4] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	chest.tiles[5] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	-- note we don't redefine entry 6 (front).
	chest.groups.tubedevice = 1
	chest.groups.tubedevice_receiver = 1
	chest.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	}
	chest.after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end
	chest.after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end

minetest.register_node(":default:chest", chest)


local chest_locked = pipeworks.clone_node("default:chest_locked")
	chest_locked.tiles[1] = "default_chest_top.png^pipeworks_tube_connection_wooden.png"
	chest_locked.tiles[2] = "default_chest_top.png^pipeworks_tube_connection_wooden.png"
	chest_locked.tiles[3] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	chest_locked.tiles[4] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	chest_locked.tiles[5] = "default_chest_side.png^pipeworks_tube_connection_wooden.png"
	-- note we don't redefine entry 6 (front).
	chest_locked.groups.tubedevice = 1
	chest_locked.groups.tubedevice_receiver = 1
	chest_locked.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.env:get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.env:get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("main", stack)
		end,
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	}
	local old_after_place = minetest.registered_nodes["default:chest_locked"].after_place_node
	chest_locked.after_place_node = function(pos, placer)
		pipeworks.scan_for_tube_objects(pos)
		old_after_place(pos, placer)
	end
	chest_locked.after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end

minetest.register_node(":default:chest_locked", chest_locked)
