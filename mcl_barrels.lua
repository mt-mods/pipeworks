-- this bit of code modifies the mcl barrels to be compatible with
-- pipeworks.

-- Pipeworks Specific
local tube_entry = "^pipeworks_tube_connection_wooden.png"

-- Original Definitions
local old_barrel = table.copy(minetest.registered_items["mcl_barrels:barrel_closed"])

local groups = old_barrel.groups
groups["tubedevice"] = 1
groups["tubedevice_receiver"] = 1
local groups_open = table.copy(groups)
groups_open["not_in_creative_inventory"] = 1


-- Override Construction
local override_barrel = {}

override_barrel.tiles = {
   "mcl_barrels_barrel_top.png^[transformR270",
   "mcl_barrels_barrel_bottom.png"..tube_entry,
   "mcl_barrels_barrel_side.png"..tube_entry
}

override_barrel.after_place_node = function(pos, placer, itemstack, pointed_thing)
   old_barrel.after_place_node(pos, placer, itemstack, pointed_thing)
   pipeworks.after_place(pos, placer, itemstack, pointed_thing)
end

override_barrel.tube = {
   insert_object = function(pos, node, stack, direction)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      return inv:add_item("main", stack)
   end,
   can_insert = function(pos, node, stack, direction)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      if meta:get_int("splitstacks") == 1 then
	 stack = stack:peek_item(1)
      end
      return inv:room_for_item("main", stack)
   end,
   input_inventory = "main",
   connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1}
}

override_barrel.after_dig_node = function(pos, oldnode, oldmetadata, digger)
   old_barrel.after_dig_node(pos, oldnode, oldmetadata, digger)
   pipeworks.after_dig(pos)
end

override_barrel.groups = table.copy(old_barrel.groups)

override_barrel.on_rotate = pipeworks.on_rotate


local override_barrel_open = table.copy(override_barrel)

override_barrel_open.tiles = {
   "mcl_barrels_barrel_top_open.png",
   "mcl_barrels_barrel_bottom.png"..tube_entry,
   "mcl_barrels_barrel_side.png"..tube_entry
}

override_barrel_open.groups = groups_open


-- Override with the new modifications.
minetest.override_item("mcl_barrels:barrel_closed", override_barrel)
minetest.override_item("mcl_barrels:barrel_open", override_barrel_open)
