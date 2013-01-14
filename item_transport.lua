modpath=minetest.get_modpath("pipeworks")

dofile(modpath.."/compat.lua")

minetest.register_craftitem("pipeworks:filter", {
	description = "Filter",
	stack_max = 99,
})

minetest.register_node("pipeworks:filter", {
	description = "filter",
	tiles = {"filter_top.png", "filter_top.png", "filter_output.png",
		"filter_input.png", "filter_side.png", "filter_top.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,tubedevice=1,mesecon=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",
				"invsize[9,9;]"..
				"list[current_name;main;0,2;8,2;]"..
				"list[current_player;main;0,5;8,4;]")
		meta:set_string("infotext", "Filter")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	mesecons={effector={action_on=function(pos,node)
					minetest.registered_nodes[node.name].on_punch(pos,node,nil)
				end}},
	on_punch = function (pos, node, puncher)
	local meta = minetest.env:get_meta(pos);
	local inv = meta:get_inventory()
	local frompos
	local dir
	if node.param2==0 then
		frompos={x=pos.x-1,y=pos.y,z=pos.z}
		dir={x=1,y=0,z=0}
	elseif node.param2==1 then
		frompos={x=pos.x,y=pos.y,z=pos.z+1}
		dir={x=0,y=0,z=-1}
	elseif node.param2==2 then
		frompos={x=pos.x+1,y=pos.y,z=pos.z}
		dir={x=-1,y=0,z=0}
	else
		frompos={x=pos.x,y=pos.y,z=pos.z-1}
		dir={x=0,y=0,z=1}
	end
	local fromnode=minetest.env:get_node(frompos)
	local frominv
	if not (minetest.registered_nodes[fromnode.name].tube and 
		minetest.registered_nodes[fromnode.name].tube.input_inventory) then
			return
	end
	local frommeta=minetest.env:get_meta(frompos)
	local frominvname=minetest.registered_nodes[fromnode.name].tube.input_inventory
	local frominv=frommeta:get_inventory()
	for _,filter in ipairs(inv:get_list("main")) do
		local sname=filter:get_name()
		if sname ~="" then
			for spos,stack in ipairs(frominv:get_list(frominvname)) do
				if stack:get_name()==sname then
					item=stack:take_item()
					frominv:set_stack(frominvname,spos,stack)
					pos1=pos
					item1=tube_item({x=pos1.x,y=pos1.y,z=pos1.z},item)
					item1:get_luaentity().start_pos = {x=pos1.x,y=pos1.y,z=pos1.z}
					item1:setvelocity(dir)
					item1:setacceleration({x=0, y=0, z=0})
					return
				end
			end
		end
	end
	if inv:is_empty("main") then
		for spos,stack in ipairs(frominv:get_list(frominvname)) do
			if stack:get_name()~="" then
				item=stack:take_item()
				frominv:set_stack(frominvname,spos,stack)
				pos1=pos
				item1=tube_item({x=pos1.x,y=pos1.y,z=pos1.z},item)
				item1:get_luaentity().start_pos = {x=pos1.x,y=pos1.y,z=pos1.z}
				item1:setvelocity(dir)
				item1:setacceleration({x=0, y=0, z=0})
				return
			end
		end
	end
end,
})


function tube_item(pos, item)
	-- Take item in any format
	local stack = ItemStack(item)
	local obj = minetest.env:add_entity(pos, "pipeworks:tubed_item")
	obj:get_luaentity():set_item(stack:to_string())
	return obj
end

minetest.register_entity("pipeworks:tubed_item", {
	initial_properties = {
		hp_max = 1,
		physical = false,
		collisionbox = {0,0,0,0,0,0},
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
			
			return	minetest.serialize({
				itemstring=self.itemstring,
				velocity=self.object:getvelocity(),
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
	if self.start_pos then
	local pos = self.object:getpos()
	local node = minetest.env:get_node(pos)
	local meta = minetest.env:get_meta(pos)
	tubelike=meta:get_int("tubelike")
	local stack = ItemStack(self.itemstring)
	local drop_pos=nil
		
	local velocity=self.object:getvelocity()
	
	if velocity==nil then return end
	
	local velocitycopy={x=velocity.x,y=velocity.y,z=velocity.z}
	
	local moved=false
	
	if math.abs(velocity.x)==1 then
		local next_node=math.abs(pos.x-self.start_pos.x)
		if next_node >= 1 then 
			self.start_pos.x=self.start_pos.x+velocity.x
			moved=true
		end
	elseif math.abs(velocity.y)==1 then
		local next_node=math.abs(pos.y-self.start_pos.y)
		if next_node >= 1 then 
			self.start_pos.y=self.start_pos.y+velocity.y
			moved=true
		end	
	elseif math.abs(velocity.z)==1 then
		local next_node=math.abs(pos.z-self.start_pos.z)
		if next_node >= 1 then 
			self.start_pos.z=self.start_pos.z+velocity.z
			moved=true
		end
	end
	
	node = minetest.env:get_node(self.start_pos)
	if moved and minetest.get_item_group(node.name,"tubedevice_receiver")==1 then
		if minetest.registered_nodes[node.name].tube and minetest.registered_nodes[node.name].tube.insert_object then
			leftover = minetest.registered_nodes[node.name].tube.insert_object(self.start_pos,node,stack,velocity)
		else
			leftover = stack
		end
		--drop_pos=minetest.env:find_node_near(self.start_pos,1,"air")
		--if drop_pos and not leftover:is_empty() then minetest.item_drop(leftover,"",drop_pos) end
		--self.object:remove()
		if leftover:is_empty() then
			self.object:remove()
			return
		end
		velocity.x=-velocity.x
		velocity.y=-velocity.y
		velocity.z=-velocity.z
		self.object:setvelocity(velocity)
		self:set_item(leftover:to_string())
		return
	end
	
	if moved then
		if go_next (self.start_pos, velocity, stack)==0 then
			drop_pos=minetest.env:find_node_near({x=self.start_pos.x+velocity.x,y=self.start_pos.y+velocity.y,z=self.start_pos.z+velocity.z}, 1, "air")
			if drop_pos then 
				minetest.item_drop(stack, "", drop_pos)
				self.object:remove()
			end
		end
	end
	
	if velocity.x~=velocitycopy.x or velocity.y~=velocitycopy.y or velocity.z~=velocitycopy.z then
		self.object:setpos(self.start_pos)
		self.object:setvelocity(velocity)
	end

	end
end
})


function addVect(pos,vect)
return {x=pos.x+vect.x,y=pos.y+vect.y,z=pos.z+vect.z}
end

adjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

function go_next(pos,velocity,stack)
	--print(dump(pos))
	local chests={}
	local tubes={}
	local cmeta=minetest.env:get_meta(pos)
	local node
	local meta
	local tubelike
	local tube_receiver
	local len=1
	local n
	for _,vect in ipairs(adjlist) do
		if vect.x~=-velocity.x or vect.y~=-velocity.y or vect.z~=-velocity.z then
			npos=addVect(pos,vect)
			node=minetest.env:get_node(npos)
			tube_receiver=minetest.get_item_group(node.name,"tubedevice_receiver")
			--tubelike=minetest.get_item_group(node.name,"tubelike")
			meta=minetest.env:get_meta(npos)
			tubelike=meta:get_int("tubelike")
			if tube_receiver==1 then
				if minetest.registered_nodes[node.name].tube and
					minetest.registered_nodes[node.name].tube.can_insert and
					minetest.registered_nodes[node.name].tube.can_insert(npos,node,stack,vect) then
					local i=1
					repeat
						if chests[i]==nil then break end
						i=i+1
					until false
					chests[i]={}
					chests[i].pos=npos
					chests[i].vect=vect
				end
			elseif tubelike==1 then
				local i=1
				repeat
					if tubes[i]==nil then break end
					i=i+1
				until false
				tubes[i]={}
				tubes[i].pos=npos
				tubes[i].vect=vect
			end
		end
	end
	if chests[1]==nil then--no chests found
		if tubes[1]==nil then
			return 0
		else
			local i=1
			repeat
				if tubes[i]==nil then break end
				i=i+1
			until false
			n=meta:get_int("tubedir")+1
			repeat
				if n>=i then
					n=n-i+1
				else
					break
				end
			until false
			meta:set_int("tubedir",n)
			velocity.x=tubes[n].vect.x
			velocity.y=tubes[n].vect.y
			velocity.z=tubes[n].vect.z
		end
	else
		local i=1
		repeat
			if chests[i]==nil then break end
			i=i+1
		until false
		n=meta:get_int("tubedir")+1
		repeat
			if n>=i then
				n=n-i+1
			else
				break
			end
		until false
		velocity.x=chests[n].vect.x
		velocity.y=chests[n].vect.y
		velocity.z=chests[n].vect.z
	end
	return 1
end