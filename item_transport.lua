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

local function set_filter_infotext(data, meta)
	local infotext = data.wise_desc.." Filter-Injector"
	if meta:get_int("slotseq_mode") == 2 then
		infotext = infotext .. " (slot #"..meta:get_int("slotseq_index").." next)"
	end
	meta:set_string("infotext", infotext)
end

local function set_filter_formspec(data, meta)
	local itemname = data.wise_desc.." Filter-Injector"
	local formspec = "size[8,8.5]"..
			"item_image[0,0;1,1;pipeworks:"..data.name.."]"..
			"label[1,0;"..minetest.formspec_escape(itemname).."]"..
			"label[0,1;Prefer item types:]"..
			"list[current_name;main;0,1.5;8,2;]"
	local slotseq_mode = meta:get_int("slotseq_mode")
	if slotseq_mode == 1 then
		formspec = formspec .. "button[0,3.5;4,1;slotseq_mode2;Sequence slots Randomly]"
	elseif slotseq_mode == 2 then
		formspec = formspec .. "button[0,3.5;4,1;slotseq_mode0;Sequence slots by Rotation]"
	else
		formspec = formspec .. "button[0,3.5;4,1;slotseq_mode1;Sequence slots by Priority]"
	end
	formspec = formspec .. "list[current_player;main;0,4.5;8,4;]"
	meta:set_string("formspec", formspec)
end

local function grabAndFire(data,slotseq_mode,filtmeta,frominv,frominvname,frompos,fromnode,filtername,fromtube,fromdef,dir,all)
	local sposes = {}
	for spos,stack in ipairs(frominv:get_list(frominvname)) do
		local matches
		if filtername == "" then
			matches = stack:get_name() ~= ""
		else
			matches = stack:get_name() == filtername
		end
		if matches then table.insert(sposes, spos) end
	end
	if #sposes == 0 then return false end
	if slotseq_mode == 1 then
		for i = #sposes, 2, -1 do
			local j = math.random(i)
			local t = sposes[j]
			sposes[j] = sposes[i]
			sposes[i] = t
		end
	elseif slotseq_mode == 2 then
		local headpos = filtmeta:get_int("slotseq_index")
		table.sort(sposes, function (a, b)
			if a >= headpos then
				if b < headpos then return true end
			else
				if b >= headpos then return false end
			end
			return a < b
		end)
	end
	for _, spos in ipairs(sposes) do
			local stack = frominv:get_stack(frominvname, spos)
			local doRemove = stack:get_count()
			if fromtube.can_remove then
				doRemove = fromtube.can_remove(frompos, fromnode, stack, dir)
			elseif fromdef.allow_metadata_inventory_take then
				doRemove = fromdef.allow_metadata_inventory_take(frompos, frominvname,spos, stack, fakePlayer)
			end
			-- stupid lack of continue statements grumble
			if doRemove > 0 then
				if slotseq_mode == 2 then
					local nextpos = spos + 1
					if nextpos > frominv:get_size(frominvname) then
						nextpos = 1
					end
					filtmeta:set_int("slotseq_index", nextpos)
					set_filter_infotext(data, filtmeta)
				end
				local item
				local count
				if all then
					count = math.min(stack:get_count(), doRemove)
				else
					count = 1
				end
				if fromtube.remove_items then
					-- it could be the entire stack...
					item = fromtube.remove_items(frompos, fromnode, stack, dir, count)
				else
					item = stack:take_item(count)
					frominv:set_stack(frominvname, spos, stack)
					if fromdef.on_metadata_inventory_take then
						fromdef.on_metadata_inventory_take(frompos, frominvname, spos, item, fakePlayer)
					end
				end
				local item1 = pipeworks.tube_item(vector.add(frompos, vector.multiply(dir, 1.4)), item)
				item1:get_luaentity().start_pos = vector.add(frompos, dir)
				item1:setvelocity(dir)
				item1:setacceleration({x=0, y=0, z=0})
				return true-- only fire one item, please
			end
	end
	return false
end

local function punch_filter(data, filtpos, filtnode)
	local filtmeta = minetest.get_meta(filtpos)
	local filtinv = filtmeta:get_inventory()
	local dir = facedir_to_right_dir(filtnode.param2)
	local frompos = {x=filtpos.x - dir.x, y=filtpos.y - dir.y, z=filtpos.z - dir.z}
	local fromnode = minetest.get_node(frompos)
	if not fromnode then return end
	local fromdef = minetest.registered_nodes[fromnode.name]
	if not fromdef then return end
	local fromtube = fromdef.tube
	if not (fromtube and fromtube.input_inventory) then return end
	local filters = {}
	for _, filterstack in ipairs(filtinv:get_list("main")) do
		local filtername = filterstack:get_name()
		if filtername ~= "" then table.insert(filters, filtername) end
	end
	if #filters == 0 then table.insert(filters, "") end
	local slotseq_mode = filtmeta:get_int("slotseq_mode")
	local frommeta = minetest.get_meta(frompos)
	local frominv = frommeta:get_inventory()
	if fromtube.before_filter then fromtube.before_filter(frompos) end
	for _, frominvname in ipairs(type(fromtube.input_inventory) == "table" and fromtube.input_inventory or {fromtube.input_inventory}) do
		local done = false
		for _, filtername in ipairs(filters) do
			if grabAndFire(data, slotseq_mode, filtmeta, frominv, frominvname, frompos, fromnode, filtername, fromtube, fromdef, dir, data.stackwise) then
				done = true
				break
			end
		end
		if done then break end
	end
	if fromtube.after_filter then fromtube.after_filter(frompos) end
end

for _, data in ipairs({
	{
		name = "filter",
		wise_desc = "Itemwise",
		stackwise = false,
	},
	{
		name = "mese_filter",
		wise_desc = "Stackwise",
		stackwise = true,
	},
}) do
	minetest.register_node("pipeworks:"..data.name, {
		description = data.wise_desc.." Filter-Injector",
		tiles = {
			"pipeworks_"..data.name.."_top.png",
			"pipeworks_"..data.name.."_top.png",
			"pipeworks_"..data.name.."_output.png",
			"pipeworks_"..data.name.."_input.png",
			"pipeworks_"..data.name.."_side.png",
			"pipeworks_"..data.name.."_top.png",
		},
		paramtype2 = "facedir",
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
		legacy_facedir_simple = true,
		sounds = default.node_sound_wood_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			set_filter_formspec(data, meta)
			set_filter_infotext(data, meta)
			local inv = meta:get_inventory()
			inv:set_size("main", 8*2)
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local meta = minetest.get_meta(pos)
			for k, _ in pairs(fields) do
				if k:sub(1, 12) == "slotseq_mode" then
					local mode = tonumber(k:sub(13, 13))
					meta:set_int("slotseq_mode", mode)
					meta:set_int("slotseq_index", mode == 2 and 1 or 0)
				end
			end
			set_filter_formspec(data, meta)
			set_filter_infotext(data, meta)
		end,
		can_dig = function(pos,player)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:is_empty("main")
		end,
		after_place_node = function(pos)
			pipeworks.scan_for_tube_objects(pos)
		end,
		after_dig_node = function(pos)
			pipeworks.scan_for_tube_objects(pos)
		end,
		mesecons = {
			effector = {
				action_on = function(pos, node)
					punch_filter(data, pos, node)
				end,
			},
		},
		tube={connect_sides={right=1}},
		on_punch = function (pos, node, puncher)
			punch_filter(data, pos, node)
		end,
	})
end

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
		collisionbox = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		visual = "wielditem",
		visual_size = {x = 0.15, y = 0.15},
		textures = {""},
		spritediv = {x = 1, y = 1},
		initial_sprite_basepos = {x = 0, y = 0},
		is_visible = false,
		start_pos = {},
		route = {},
		removed = false
	},
	
	itemstring = '',
	physical_state = false,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		self.object:set_properties({
			is_visible = true,
			textures = { stack:get_name() },
		})
		local def = stack:get_definition()
		self.object:setyaw((def and def.type == "node") and 0 or math.pi * 0.25)
	end,

	get_staticdata = function(self)
		if self.start_pos == nil or self.removed then
			return
		end
		local velocity = self.object:getvelocity()
		self.object:setpos(self.start_pos)
		return	minetest.serialize({
			itemstring = self.itemstring,
			velocity = velocity,
			start_pos = self.start_pos
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
	
	remove = function(self)
		self.object:remove()
		self.removed = true
		self.itemstring = ''
	end,

	on_step = function(self, dtime)
		if self.removed then
			return
		end
		if self.start_pos == nil then
			local pos = self.object:getpos()
			self.start_pos = roundpos(pos)
		end
		local pos = self.object:getpos()
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local tubelike = meta:get_int("tubelike")
		local stack = ItemStack(self.itemstring)
		local drop_pos = nil
		
		local velocity = self.object:getvelocity()
	
		if velocity == nil then return end
	
		local velocitycopy = {x = velocity.x, y = velocity.y, z = velocity.z}
		
		local moved = false
		local speed = math.abs(velocity.x + velocity.y + velocity.z)
		local vel = {x = velocity.x / speed, y = velocity.y / speed, z = velocity.z / speed, speed = speed}
		
		if math.abs(vel.x) == 1 then
			local next_node = math.abs(pos.x - self.start_pos.x)
			if next_node >= 1 then 
				self.start_pos.x = self.start_pos.x + vel.x
				moved = true
			end
		elseif math.abs(vel.y) == 1 then
		local next_node = math.abs(pos.y - self.start_pos.y)
			if next_node >= 1 then 
				self.start_pos.y = self.start_pos.y + vel.y
				moved = true
			end	
		elseif math.abs(vel.z) == 1 then
			local next_node = math.abs(pos.z - self.start_pos.z)
			if next_node >= 1 then 
				self.start_pos.z = self.start_pos.z + vel.z
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
				self:remove()
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
					self:remove()
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
