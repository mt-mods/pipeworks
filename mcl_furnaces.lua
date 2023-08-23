
local old_furnace = table.copy(minetest.registered_nodes["mcl_furnaces:furnace"])

local tube_entry = "^pipeworks_tube_connection_stony.png"

local groups = old_furnace.groups
groups["tubedevice"] = 1
groups["tubedevice_receiver"] = 1
local groups_active = table.copy(groups)
groups_active["not_in_creative_inventory"] = 1

-- a hack to give the exp to fake players it's be dropped instead added to (fake) player inv
local function give_xp(pos, player)
   local meta = minetest.get_meta(pos)
   local dir = vector.divide(minetest.facedir_to_dir(minetest.get_node(pos).param2),-1.95)
   local xp = meta:get_int("xp")
   if xp > 0 then
      mcl_experience.throw_xp(vector.add(pos, dir), xp)
      meta:set_int("xp", 0)
   end
end

local override = {}

override.tiles = {
   "default_furnace_top.png"..tube_entry,
   "default_furnace_bottom.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_front.png"
}

override.groups = groups

override.tube = {
   insert_object = function(pos, node, stack, direction)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if not timer:is_started() then
	 timer:start(1.0)
      end
      if direction.y == 1 then
	 return inv:add_item("fuel", stack)
      else
	 return inv:add_item("src", stack)
      end
   end,
   can_insert = function(pos,node,stack,direction)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      if direction.y == 1 then
	 return inv:room_for_item("fuel", stack)
      else
	 if meta:get_int("split_material_stacks") == 1 then
	    stack = stack:peek_item(1)
	 end
	 return inv:room_for_item("src", stack)
      end
   end,
   input_inventory = "dst",
   connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1}
}

override.after_place_node = function(pos, placer, itemstack, pointed_thing)
   pipeworks.after_place(pos, placer, itemstack, pointed_thing)
end

override.after_dig_node = function(pos, oldnode, oldmetadata, digger)
   old_furnace.after_dig_node(pos, oldnode, oldmetadata, digger)
   pipeworks.after_dig(pos)
end

override.on_metadata_inventory_take = function(pos, listname, index, stack, player)
   if listname == "dst" then
      if stack:get_name() == "mcl_core:iron_ingot" then
	 awards.unlock(player:get_player_name(), "mcl:acquireIron")
      elseif stack:get_name() == "mcl_fishing:fish_cooked" then
	 awards.unlock(player:get_player_name(), "mcl:cookFish")
      end
      give_xp(pos, player)
   end
end

override.on_rotate = pipeworks.on_rotate


local override_active = table.copy(override)

override_active.tiles = {
   "default_furnace_top.png"..tube_entry,
   "default_furnace_bottom.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_side.png"..tube_entry,
   "default_furnace_front_active.png",
}

override_active.groups = groups_active

override_active.tube = {
   insert_object = function(pos,node,stack,direction)
      local meta = minetest.get_meta(pos)
      local inv = meta:get_inventory()
      local timer = minetest.get_node_timer(pos)
      if not timer:is_started() then
	 timer:start(1.0)
      end
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
   connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1}
}


-- override
minetest.override_item("mcl_furnaces:furnace", override)
minetest.override_item("mcl_furnaces:furnace_active", override_active)
