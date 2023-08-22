-- this bit of code modifies the mcl barrels to be compatible with
-- pipeworks.

-- Pipeworks Specific
local tube_entry = "^pipeworks_tube_connection_wooden.png"

-- Original Definitions
local old_barrel_closed_def = table.copy(minetest.registered_items["mcl_barrels:barrel_closed"])
local old_barrel_open_def = table.copy(minetest.registered_items["mcl_barrels:barrel_open"])


-- Override Construction
local override_mcl_barrel_closed = {
   tiles = {"mcl_barrels_barrel_top.png^[transformR270",
	    "mcl_barrels_barrel_bottom.png"..tube_entry,
	    "mcl_barrels_barrel_side.png"..tube_entry},
   after_place_node = function(pos, placer, itemstack, pointed_thing)
      old_barrel_closed_def.after_place_node(pos, placer, itemstack, pointed_thing)
      pipeworks.after_place(pos, placer, itemstack, pointed_thing)
   end,
   tube = {
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
   },
   after_dig_node = function(pos)
      old_barrel_closed_def.after_dig_node(pos)
      pipeworks.after_dig(pos)
   end,
   groups = table.copy(old_barrel_closed_def.groups),
   --on_rotate = pipeworks.on_rotate
}

override_mcl_barrel_open = table.copy(override_mcl_barrel_closed)

override_mcl_barrel_open.tiles = {
   "mcl_barrels_barrel_top_open.png",
   "mcl_barrels_barrel_bottom.png"..tube_entry,
   "mcl_barrels_barrel_side.png"..tube_entry
}


-- Add the extra groups
for _,v in ipairs({override_mcl_barrel_closed, override_mcl_barrel_open}) do
   v.groups.tubedevice = 1
   v.groups.tubedevice_receiver = 1
end

-- Override with the new modifications.
minetest.override_item("mcl_barrels:barrel_closed", override_mcl_barrel_closed)
minetest.override_item("mcl_barrels:barrel_open", override_mcl_barrel_open)
