dofile(pipeworks.modpath.."/compat.lua")

--and an extra function for getting the right-facing vector
local function facedir_to_right_dir(facedir)
	
	--find the other directions
	local backdir = minetest.facedir_to_dir(facedir)
	local topdir = ({[0]={x=0, y=1, z=0},
									{x=0, y=0, z=1},
									{x=0, y=0, z=-1},
									{x=1, y=0, z=0},
									{x=-1, y=0, z=0},
									{x=0, y=-1, z=0}})[math.floor(facedir/4)]
	
	--return a cross product
		return {x=topdir.y*backdir.z - backdir.y*topdir.z,
						y=topdir.z*backdir.x - backdir.z*topdir.x,
						z=topdir.x*backdir.y - backdir.x*topdir.y}
end

minetest.register_craftitem("pipeworks:filter", {
	description = "Filter",
	stack_max = 99,
})

local fakePlayer = {
    get_player_name = function() return ":pipeworks" end,
    -- any other player functions called by allow_metadata_inventory_take anywhere...
    -- perhaps a custom metaclass that errors specially when fakePlayer.<property> is not found?
}

function pipeworks.tube_item(pos, item)
	-- Take item in any format
	local stack = ItemStack(item)
	local obj = minetest.add_entity(pos, "pipeworks:tubed_item")
	obj:get_luaentity():set_item(stack:to_string())
	return obj
end

-- adding two tube functions
-- can_remove(pos,node,stack,dir) returns the maximum number of items of that stack that can be removed
-- remove_items(pos,node,stack,dir,count) removes count items and returns them
-- both optional w/ sensible defaults and fallback to normal allow_* function
-- XXX: possibly change insert_object to insert_item

-- sname = the current name to allow for, or nil if it allows anything

local function grabAndFire(frominv,frominvname,frompos,fromnode,sname,tube,idef,dir,all)
	for spos,stack in ipairs(frominv:get_list(frominvname)) do
		if (sname == nil and stack:get_name() ~= "") or stack:get_name() == sname then
			local doRemove = stack:get_count()
			if tube.can_remove then
				doRemove = tube.can_remove(frompos, fromnode, stack, dir)
			elseif idef.allow_metadata_inventory_take then
				doRemove = idef.allow_metadata_inventory_take(frompos, frominvname,spos, stack, fakePlayer)
			end
			-- stupid lack of continue statements grumble
			if doRemove > 0 then
				local item
				local count
				if all then
					count = math.min(stack:get_count(), doRemove)
				else
					count = 1
				end
				if tube.remove_items then
					-- it could be the entire stack...
					item = tube.remove_items(frompos, fromnode, stack, dir, count)
				else
					item = stack:take_item(count)
					frominv:set_stack(frominvname, spos, stack)
					if idef.on_metadata_inventory_take then
						idef.on_metadata_inventory_take(frompos, frominvname, spos, item, fakePlayer)
					end
				end
				local item1 = pipeworks.tube_item(vector.add(frompos, vector.multiply(dir, 1.4)), item)
				item1:get_luaentity().start_pos = vector.add(frompos, dir)
				item1:setvelocity(dir)
				item1:setacceleration({x=0, y=0, z=0})
				return true-- only fire one item, please
			end
		end
	end
	return false
end

minetest.register_node("pipeworks:filter", {
	description = "Filter",
	tiles = {"pipeworks_filter_top.png", "pipeworks_filter_top.png", "pipeworks_filter_output.png",
		"pipeworks_filter_input.png", "pipeworks_filter_side.png", "pipeworks_filter_top.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,6.5;]"..
				"list[current_name;main;0,0;8,2;]"..
				"list[current_player;main;0,2.5;8,4;]")
		meta:set_string("infotext", "Filter")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*2)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end,
	after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end,
	mesecons={effector={action_on=function(pos,node)
					minetest.registered_nodes[node.name].on_punch(pos,node,nil)
				end}},
	tube={connect_sides={right=1}},
	on_punch = function (pos, node, puncher)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		local dir = facedir_to_right_dir(node.param2)
		local frompos = {x=pos.x - dir.x, y=pos.y - dir.y, z=pos.z - dir.z}
		local fromnode=minetest.get_node(frompos)
		if not fromnode then return end
		local idef = minetest.registered_nodes[fromnode.name]
		-- assert(idef)
		local tube = idef.tube
		if not (tube and tube.input_inventory) then
			return
		end
		if tube.before_filter then
			tube.before_filter(frompos)
		end
		local frommeta = minetest.get_meta(frompos)
		local frominv = frommeta:get_inventory()
		
		local function from_inventory(frominvname)
			local sname
			for _,filter in ipairs(inv:get_list("main")) do
				sname = filter:get_name()
				if sname ~= "" then
					-- XXX: that's a lot of parameters
					if grabAndFire(frominv, frominvname, frompos, fromnode, sname, tube, idef, dir) then
						return true
					end
				end
			end
			if inv:is_empty("main") then
				grabAndFire(frominv, frominvname, frompos, fromnode, nil, tube, idef, dir)
				return true
			end
			return false
		end
		
		if type(tube.input_inventory) == "table" then
			for _, i in ipairs(tube.input_inventory) do
				if from_inventory(i) then -- fired an item
					break
				end
			end
		else
			from_inventory(tube.input_inventory)
		end
		
		if tube.after_filter then
			tube.after_filter(frompos)
		end
	end,
})

minetest.register_craftitem("pipeworks:mese_filter", {
	description = "Mese filter",
	stack_max = 99,
})

minetest.register_node("pipeworks:mese_filter", {
	description = "Mese filter",
	tiles = {"pipeworks_mese_filter_top.png", "pipeworks_mese_filter_top.png", "pipeworks_mese_filter_output.png",
		"pipeworks_mese_filter_input.png", "pipeworks_mese_filter_side.png", "pipeworks_mese_filter_top.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,6.5;]"..
				"list[current_name;main;0,0;8,2;]"..
				"list[current_player;main;0,2.5;8,4;]")
		meta:set_string("infotext", "Mese filter")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*2)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_place_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end,
	after_dig_node = function(pos)
		pipeworks.scan_for_tube_objects(pos)
	end,
	mesecons={effector={action_on=function(pos,node)
					minetest.registered_nodes[node.name].on_punch(pos,node,nil)
				end}},
	tube={connect_sides={right=1}},
	on_punch = function (pos, node, puncher)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		local dir = facedir_to_right_dir(node.param2)
		local frompos = {x=pos.x - dir.x, y=pos.y - dir.y, z=pos.z - dir.z}
		local fromnode=minetest.get_node(frompos)
		local idef = minetest.registered_nodes[fromnode.name]
		-- assert(idef)
		local tube = idef.tube
		if not (tube and tube.input_inventory) then
			return
		end
		
		if tube.before_filter then
			tube.before_filter(frompos)
		end
		local frommeta = minetest.get_meta(frompos)
		local frominv = frommeta:get_inventory()
		
		local function from_inventory(frominvname)
			local sname
			for _,filter in ipairs(inv:get_list("main")) do
				sname = filter:get_name()
				if sname ~= "" then
					-- XXX: that's a lot of parameters
					if grabAndFire(frominv, frominvname, frompos, fromnode, sname, tube, idef, dir, true) then
						return true
					end
				end
			end
			if inv:is_empty("main") then
				grabAndFire(frominv, frominvname, frompos, fromnode, nil, tube, idef, dir, true)
				return true
			end
			return false
		end
		
		if type(tube.input_inventory) == "table" then
			for _, i in ipairs(tube.input_inventory) do
				if from_inventory(i) then -- fired an item
					break
				end
			end
		else
			from_inventory(tube.input_inventory)
		end
		
		if tube.after_filter then
			tube.after_filter(frompos)
		end
	end,
})

local function roundpos(pos)
	return {x=math.floor(pos.x+0.5),y=math.floor(pos.y+0.5),z=math.floor(pos.z+0.5)}
end

local function addVect(pos,vect)
	return {x=pos.x+vect.x,y=pos.y+vect.y,z=pos.z+vect.z}
end

local adjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

function pipeworks.notvel(tbl, vel)
	local tbl2={}
	for _,val in ipairs(tbl) do
		if val.x ~= -vel.x or val.y ~= -vel.y or val.z ~= -vel.z then table.insert(tbl2, val) end
	end
	return tbl2
end

local function go_next(pos, velocity, stack)
	local chests = {}
	local tubes = {}
	local cnode = minetest.get_node(pos)
	local cmeta = minetest.get_meta(pos)
	local n
	local can_go
	local speed = math.abs(velocity.x + velocity.y + velocity.z)
	local vel = {x = velocity.x/speed, y = velocity.y/speed, z = velocity.z/speed,speed=speed}
	if speed >= 4.1 then
		speed = 4
	elseif speed >= 1.1 then
		speed = speed-0.1
	else
		speed = 1
	end
	vel.speed = speed
	if minetest.registered_nodes[cnode.name] and minetest.registered_nodes[cnode.name].tube and minetest.registered_nodes[cnode.name].tube.can_go then
		can_go = minetest.registered_nodes[cnode.name].tube.can_go(pos, cnode, vel, stack)
	else
		can_go = pipeworks.notvel(adjlist, vel)
	end
	local meta = nil
	for _,vect in ipairs(can_go) do
		local npos = addVect(pos,vect)
		local node = minetest.get_node(npos)
		local tube_receiver = minetest.get_item_group(node.name,"tubedevice_receiver")
		meta = minetest.get_meta(npos)
		local tubelike = meta:get_int("tubelike")
		if tube_receiver == 1 then
			if minetest.registered_nodes[node.name].tube and
				minetest.registered_nodes[node.name].tube.can_insert and
				minetest.registered_nodes[node.name].tube.can_insert(npos, node, stack, vect) then
				local i = #chests + 1
				chests[i] = {}
				chests[i].pos = npos
				chests[i].vect = vect
			end
		elseif tubelike == 1 then
			local i = #tubes + 1
			tubes[i] = {}
			tubes[i].pos = npos
			tubes[i].vect = vect
		end
	end
	if chests[1] == nil then--no chests found
		if tubes[1] == nil then
			return 0
		else
			n = (cmeta:get_int("tubedir")%(#tubes)) + 1
			if pipeworks.enable_cyclic_mode then
				cmeta:set_int("tubedir",n)
			end
			velocity.x = tubes[n].vect.x*vel.speed
			velocity.y = tubes[n].vect.y*vel.speed
			velocity.z = tubes[n].vect.z*vel.speed
		end
	else
		n = (cmeta:get_int("tubedir")%(#chests))+1
		if pipeworks.enable_cyclic_mode then
			cmeta:set_int("tubedir",n)
		end
		velocity.x = chests[n].vect.x*speed
		velocity.y = chests[n].vect.y*speed
		velocity.z = chests[n].vect.z*speed
	end
	return 1
end

minetest.register_entity("pipeworks:tubed_item", {
	initial_properties = {
		hp_max = 1,
		physical = false,
--		collisionbox = {0,0,0,0,0,0},
		collisionbox = {0.1,0.1,0.1,0.1,0.1,0.1},
		visual = "sprite",
		visual_size = {x=0.5, y=0.5},
		textures = {""},
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = false,
		start_pos={},
		route={}
	},
	
	itemstring = '',
	physical_state = false,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		if minetest.registered_items[itemname] then
			item_texture = minetest.registered_items[itemname].inventory_image
			item_type = minetest.registered_items[itemname].type
		end
		prop = {
			is_visible = true,
			visual = "sprite",
			textures = {"unknown_item.png"}
		}
		if item_texture and item_texture ~= "" then
			prop.visual = "sprite"
			prop.textures = {item_texture}
			prop.visual_size = {x=0.3, y=0.3}
		else
			prop.visual = "wielditem"
			prop.textures = {itemname}
			prop.visual_size = {x=0.15, y=0.15}
		end
		self.object:set_properties(prop)
	end,

	get_staticdata = function(self)
		if self.start_pos==nil then return end
		local velocity=self.object:getvelocity()
		self.object:setpos(self.start_pos)
		return	minetest.serialize({
			itemstring=self.itemstring,
			velocity=velocity,
			start_pos=self.start_pos
		})
	end,

	on_activate = function(self, staticdata)
		if  staticdata=="" or staticdata==nil then return end
		local item = minetest.deserialize(staticdata)
		local stack = ItemStack(item.itemstring)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		
		if itemname then 
		self.start_pos=item.start_pos
		self.object:setvelocity(item.velocity)
		self.object:setacceleration({x=0, y=0, z=0})
		self.object:setpos(item.start_pos)
		end
		self:set_item(item.itemstring)
	end,

	on_step = function(self, dtime)
		if self.start_pos==nil then
			local pos = self.object:getpos()
			self.start_pos=roundpos(pos)
		end
		local pos = self.object:getpos()
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local tubelike = meta:get_int("tubelike")
		local stack = ItemStack(self.itemstring)
		local drop_pos = nil
		
		local velocity=self.object:getvelocity()
	
		if velocity == nil then return end
	
		local velocitycopy = {x = velocity.x, y = velocity.y, z = velocity.z}
		
		local moved = false
		local speed = math.abs(velocity.x+velocity.y+velocity.z)
		local vel = {x = velocity.x/speed, y = velocity.y/speed, z = velocity.z/speed, speed = speed}
		
		if math.abs(vel.x) == 1 then
			local next_node = math.abs(pos.x-self.start_pos.x)
			if next_node >= 1 then 
				self.start_pos.x = self.start_pos.x+vel.x
				moved = true
			end
		elseif math.abs(vel.y) == 1 then
		local next_node = math.abs(pos.y-self.start_pos.y)
		if next_node >= 1 then 
			self.start_pos.y = self.start_pos.y+vel.y
			moved = true
		end	
		elseif math.abs(vel.z) == 1 then
			local next_node = math.abs(pos.z-self.start_pos.z)
			if next_node >= 1 then 
				self.start_pos.z = self.start_pos.z+vel.z
				moved = true
			end
		end
		
		local sposcopy = {x = self.start_pos.x, y = self.start_pos.y, z = self.start_pos.z}
		
		node = minetest.get_node(self.start_pos)
		if moved and minetest.get_item_group(node.name, "tubedevice_receiver") == 1 then
			local leftover = nil
			if minetest.registered_nodes[node.name].tube and minetest.registered_nodes[node.name].tube.insert_object then
				leftover = minetest.registered_nodes[node.name].tube.insert_object(self.start_pos, node, stack, vel)
			else
				leftover = stack
			end
			if leftover:is_empty() then
				self.object:remove()
				return
			end
			velocity.x = -velocity.x
			velocity.y = -velocity.y
			velocity.z = -velocity.z
			self.object:setvelocity(velocity)
			self:set_item(leftover:to_string())
			return
		end
		
		if moved then
			if go_next (self.start_pos, velocity, stack) == 0 then
				drop_pos = minetest.find_node_near(vector.add(self.start_pos, velocity), 1, "air")
				if drop_pos then 
					minetest.item_drop(stack, "", drop_pos)
					self.object:remove()
				end
			end
		end
		
		if velocity.x~=velocitycopy.x or velocity.y~=velocitycopy.y or velocity.z~=velocitycopy.z or 
				self.start_pos.x~=sposcopy.x or self.start_pos.y~=sposcopy.y or self.start_pos.z~=sposcopy.z then
			self.object:setpos(self.start_pos)
			self.object:setvelocity(velocity)
		end
	end
})

if minetest.get_modpath("mesecons_mvps") ~= nil then
	local function add_table(table,toadd)
		local i = 1
		while true do
			o = table[i]
			if o == toadd then return end
			if o == nil then break end
			i = i+1
		end
		table[i] = toadd
	end
	mesecon:register_mvps_unmov("pipeworks:tubed_item")
	mesecon:register_on_mvps_move(function(moved_nodes)
		local objects_to_move = {}
		for _, n in ipairs(moved_nodes) do
			local objects = minetest.get_objects_inside_radius(n.oldpos, 1)
			for _, obj in ipairs(objects) do
				local entity = obj:get_luaentity()
				if entity and entity.name == "pipeworks:tubed_item" then
					--objects_to_move[#objects_to_move+1] = obj
					add_table(objects_to_move, obj)
				end
			end
		end
		if #objects_to_move > 0 then
			local dir = vector.subtract(moved_nodes[1].pos, moved_nodes[1].oldpos)
			for _, obj in ipairs(objects_to_move) do
				local entity = obj:get_luaentity()
				obj:setpos(vector.add(obj:getpos(), dir))
				entity.start_pos = vector.add(entity.start_pos, dir)
			end
		end
	end)
end
