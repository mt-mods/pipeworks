-- This file supplies pneumatic tubes and a 'test' device

minetest.register_node("pipeworks:testobject", {
	description = "Pneumatic tube test object",
	tiles = {
		"pipeworks_testobject.png",
	},
	paramtype = "light",
	groups = {snappy=3, tubedevice=1},
	sounds = default.node_sound_wood_defaults(),
	walkable = true,
	after_place_node = function(pos)
			tube_scanforobjects(pos)
	end,
	after_dig_node = function(pos)
			tube_scanforobjects(pos)
	end,
})

function replace_name(tbl,tr,name)
	local ntbl={}
	for key,i in pairs(tbl) do
		if type(i)=="string" then
			ntbl[key]=string.gsub(i,tr,name)
		elseif type(i)=="table" then
			ntbl[key]=replace_name(i,tr,name)
		else
			ntbl[key]=i
		end
	end
	return ntbl
end

tubenodes={}

-- tables

minetest.register_alias("pipeworks:tube", "pipeworks:tube_000000")

tube_leftstub = {
	{ -32/64, -9/64, -9/64, 9/64, 9/64, 9/64 },	-- tube segment against -X face
}

tube_rightstub = {
	{ -9/64, -9/64, -9/64,  32/64, 9/64, 9/64 },	-- tube segment against +X face
}

tube_bottomstub = {
	{ -9/64, -32/64, -9/64,   9/64, 9/64, 9/64 },	-- tube segment against -Y face
}


tube_topstub = {
	{ -9/64, -9/64, -9/64,   9/64, 32/64, 9/64 },	-- tube segment against +Y face
}

tube_frontstub = {
	{ -9/64, -9/64, -32/64,   9/64, 9/64, 9/64 },	-- tube segment against -Z face
}

tube_backstub = {
	{ -9/64, -9/64, -9/64,   9/64, 9/64, 32/64 },	-- tube segment against -Z face
} 

tube_selectboxes = {
	{ -32/64,  -10/64,  -10/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64, 32/64,  10/64,  10/64 },
	{ -10/64 , -32/64,  -10/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64,  10/64, 32/64,  10/64 },
	{ -10/64 ,  -10/64, -32/64,  10/64,  10/64,  10/64 },
	{ -10/64 ,  -10/64,  -10/64,  10/64,  10/64, 32/64 }
}

--  Functions

function tube_addbox(t, b)
	for i in ipairs(b)
		do table.insert(t, b[i])
	end
end

-- now define the nodes!
function register_tube(name,desc,plain_textures,noctr_textures,end_textures,short_texture,inv_texture,special)
for xm = 0, 1 do
for xp = 0, 1 do
for ym = 0, 1 do
for yp = 0, 1 do
for zm = 0, 1 do
for zp = 0, 1 do
	local outboxes = {}
	local outsel = {}
	local outimgs = {}

	if yp==1 then
		tube_addbox(outboxes, tube_topstub)
		table.insert(outsel, tube_selectboxes[4])
		table.insert(outimgs, noctr_textures[4])
	else
		table.insert(outimgs, plain_textures[4])
	end
	if ym==1 then
		tube_addbox(outboxes, tube_bottomstub)
		table.insert(outsel, tube_selectboxes[3])
		table.insert(outimgs, noctr_textures[3])
	else
		table.insert(outimgs, plain_textures[3])
	end
	if xp==1 then
		tube_addbox(outboxes, tube_rightstub)
		table.insert(outsel, tube_selectboxes[2])
		table.insert(outimgs, noctr_textures[2])
	else
		table.insert(outimgs, plain_textures[2])
	end
	if xm==1 then
		tube_addbox(outboxes, tube_leftstub)
		table.insert(outsel, tube_selectboxes[1])
		table.insert(outimgs, noctr_textures[1])
	else
		table.insert(outimgs, plain_textures[1])
	end
	if zp==1 then
		tube_addbox(outboxes, tube_backstub)
		table.insert(outsel, tube_selectboxes[6])
		table.insert(outimgs, noctr_textures[6])
	else
		table.insert(outimgs, plain_textures[6])
	end
	if zm==1 then
		tube_addbox(outboxes, tube_frontstub)
		table.insert(outsel, tube_selectboxes[5])
		table.insert(outimgs, noctr_textures[5])
	else
		table.insert(outimgs, plain_textures[5])
	end

	local jx = xp+xm
	local jy = yp+ym
	local jz = zp+zm

	if (jx+jy+jz) == 1 then
		if xm == 1 then 
			table.remove(outimgs, 3)
			table.insert(outimgs, 3, end_textures[3])
		end
		if xp == 1 then 
			table.remove(outimgs, 4)
			table.insert(outimgs, 4, end_textures[4])
		end
		if ym == 1 then 
			table.remove(outimgs, 1)
			table.insert(outimgs, 1, end_textures[1])
		end
		if xp == 1 then 
			table.remove(outimgs, 2)
			table.insert(outimgs, 2, end_textures[2])
		end
		if zm == 1 then 
			table.remove(outimgs, 5)
			table.insert(outimgs, 5, end_textures[5])
		end
		if zp == 1 then 
			table.remove(outimgs, 6)
			table.insert(outimgs, 6, end_textures[6])
		end
	end

	local tname = xm..xp..ym..yp..zm..zp
	local tgroups = ""

	if tname ~= "000000" then
		tgroups = {snappy=3, tube=1, not_in_creative_inventory=1}
		tubedesc = desc.." ("..tname..")... You hacker, you."
		iimg=plain_textures[1]
		wscale = {x=1,y=1,z=1}
	else
		tgroups = {snappy=3, tube=1}
		tubedesc = desc
		iimg=inv_texture
		outimgs = {
			short_texture,short_texture,
			end_textures[3],end_textures[4],
			short_texture,short_texture
		}
		outboxes = { -24/64, -9/64, -9/64, 24/64, 9/64, 9/64 }
		outsel = { -24/64, -10/64, -10/64, 24/64, 10/64, 10/64 }
		wscale = {x=1,y=1,z=0.01}
	end
	
	table.insert(tubenodes,name.."_"..tname)
	
	nodedef={
		description = tubedesc,
		drawtype = "nodebox",
		tiles = outimgs,
		inventory_image=iimg,
		wield_image=iimg,
		wield_scale=wscale,
		paramtype = "light",
		selection_box = {
	             	type = "fixed",
			fixed = outsel
		},
		node_box = {
			type = "fixed",
			fixed = outboxes
		},
		groups = tgroups,
		sounds = default.node_sound_wood_defaults(),
		walkable = true,
		stack_max = 99,
		drop = name.."_000000",
		tubelike=1,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("tubelike",1)
			if minetest.registered_nodes[name.."_"..tname].on_construct_ then
				minetest.registered_nodes[name.."_"..tname].on_construct_(pos)
			end
		end,
		after_place_node = function(pos)
			tube_scanforobjects(pos)
			if minetest.registered_nodes[name.."_"..tname].after_place_node_ then
				minetest.registered_nodes[name.."_"..tname].after_place_node_(pos)
			end
		end,
		after_dig_node = function(pos)
			tube_scanforobjects(pos)
			if minetest.registered_nodes[name.."_"..tname].after_dig_node_ then
				minetest.registered_nodes[name.."_"..tname].after_dig_node_(pos)
			end
		end
	}
	
	if special==nil then special={} end

	for key,value in pairs(special) do
		if key=="on_construct" or key=="after_dig_node" or key=="after_place_node" then
			nodedef[key.."_"]=value
		elseif key=="groups" then
			for group,val in pairs(value) do
				nodedef.groups[group]=val
			end
		elseif type(value)=="table" then
			nodedef[key]=replace_name(value,"#id",tname)
		elseif type(value)=="string" then
			nodedef[key]=string.gsub(value,"#id",tname)
		else
			nodedef[key]=value
		end
	end

	local prefix=":"
	if string.find(name, "pipeworks:") then prefix = "" end

	minetest.register_node(prefix..name.."_"..tname, nodedef)

end
end
end
end
end
end
end

noctr_textures={"pipeworks_tube_noctr.png","pipeworks_tube_noctr.png","pipeworks_tube_noctr.png",
		"pipeworks_tube_noctr.png","pipeworks_tube_noctr.png","pipeworks_tube_noctr.png"}
plain_textures={"pipeworks_tube_plain.png","pipeworks_tube_plain.png","pipeworks_tube_plain.png",
		"pipeworks_tube_plain.png","pipeworks_tube_plain.png","pipeworks_tube_plain.png"}
end_textures={"pipeworks_tube_end.png","pipeworks_tube_end.png","pipeworks_tube_end.png",
		"pipeworks_tube_end.png","pipeworks_tube_end.png","pipeworks_tube_end.png"}
short_texture="pipeworks_tube_short.png"
inv_texture="pipeworks_tube_inv.png"

register_tube("pipeworks:tube","Pneumatic tube segment",plain_textures,noctr_textures,end_textures,short_texture,inv_texture)

mese_noctr_textures={"pipeworks_mese_tube_noctr_1.png","pipeworks_mese_tube_noctr_2.png","pipeworks_mese_tube_noctr_3.png",
		"pipeworks_mese_tube_noctr_4.png","pipeworks_mese_tube_noctr_5.png","pipeworks_mese_tube_noctr_6.png"}

mese_plain_textures={"pipeworks_mese_tube_plain_1.png","pipeworks_mese_tube_plain_2.png","pipeworks_mese_tube_plain_3.png",
		"pipeworks_mese_tube_plain_4.png","pipeworks_mese_tube_plain_5.png","pipeworks_mese_tube_plain_6.png"}
mese_end_textures={"pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png",
		"pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png","pipeworks_mese_tube_end.png"}
mese_short_texture="pipeworks_mese_tube_short.png"
mese_inv_texture="pipeworks_mese_tube_inv.png"

detector_plain_textures={"pipeworks_detector_tube_plain.png","pipeworks_detector_tube_plain.png","pipeworks_detector_tube_plain.png",
		"pipeworks_detector_tube_plain.png","pipeworks_detector_tube_plain.png","pipeworks_detector_tube_plain.png"}
detector_inv_texture="pipeworks_detector_tube_inv.png"

meseadjlist={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=0,y=1,z=0},{x=0,y=-1,z=0},{x=1,y=0,z=0},{x=-1,y=0,z=0}}

register_tube("pipeworks:mese_tube","Mese pneumatic tube segment",mese_plain_textures,mese_noctr_textures,
	mese_end_textures,mese_short_texture,mese_inv_texture,
	{tube={can_go=function(pos,node,velocity,stack)
		tbl={}
		local meta=minetest.get_meta(pos)
		local inv=meta:get_inventory()
		local found=false
		local name=stack:get_name()
		for i,vect in ipairs(meseadjlist) do
			if meta:get_int("l"..tostring(i).."s")==1 then
				for _,st in ipairs(inv:get_list("line"..tostring(i))) do
					if st:get_name()==name then
						found=true
						table.insert(tbl,vect)
					end
				end
			end
		end
		if found==false then
			for i,vect in ipairs(meseadjlist) do
				if meta:get_int("l"..tostring(i).."s")==1 then
					if inv:is_empty("line"..tostring(i)) then
						table.insert(tbl,vect)
					end
				end
			end
		end
		return tbl
	end},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		for i=1,6 do
			meta:set_int("l"..tostring(i).."s",1)
			inv:set_size("line"..tostring(i), 6*1)
		end
		meta:set_string("formspec",
				"size[8,11]"..
				"list[current_name;line1;1,0;6,1;]"..
				"list[current_name;line2;1,1;6,1;]"..
				"list[current_name;line3;1,2;6,1;]"..
				"list[current_name;line4;1,3;6,1;]"..
				"list[current_name;line5;1,4;6,1;]"..
				"list[current_name;line6;1,5;6,1;]"..
				"image[0,0;1,1;pipeworks_white.png]"..
				"image[0,1;1,1;pipeworks_black.png]"..
				"image[0,2;1,1;pipeworks_green.png]"..
				"image[0,3;1,1;pipeworks_yellow.png]"..
				"image[0,4;1,1;pipeworks_blue.png]"..
				"image[0,5;1,1;pipeworks_red.png]"..
				"button[7,0;1,1;button1;On]"..
				"button[7,1;1,1;button2;On]"..
				"button[7,2;1,1;button3;On]"..
				"button[7,3;1,1;button4;On]"..
				"button[7,4;1,1;button5;On]"..
				"button[7,5;1,1;button6;On]"..
				"list[current_player;main;0,7;8,4;]")
		meta:set_string("infotext", "Mese pneumatic tube")
	end,
	on_receive_fields=function(pos,formname,fields,sender)
		local meta=minetest.get_meta(pos)
		local i
		for key,_ in pairs(fields) do i=key end
		if i==nil then return end
		i=string.sub(i,-1)
		newstate=1-meta:get_int("l"..i.."s")
		meta:set_int("l"..i.."s",newstate)
		local frm="size[8,11]"..
				"list[current_name;line1;1,0;6,1;]"..
				"list[current_name;line2;1,1;6,1;]"..
				"list[current_name;line3;1,2;6,1;]"..
				"list[current_name;line4;1,3;6,1;]"..
				"list[current_name;line5;1,4;6,1;]"..
				"list[current_name;line6;1,5;6,1;]"..
				"image[0,0;1,1;pipeworks_white.png]"..
				"image[0,1;1,1;pipeworks_black.png]"..
				"image[0,2;1,1;pipeworks_green.png]"..
				"image[0,3;1,1;pipeworks_yellow.png]"..
				"image[0,4;1,1;pipeworks_blue.png]"..
				"image[0,5;1,1;pipeworks_red.png]"
		for i=1,6 do
			local st=meta:get_int("l"..tostring(i).."s")
			if st==0 then
				frm=frm.."button[7,"..tostring(i-1)..";1,1;button"..tostring(i)..";Off]"
			else
				frm=frm.."button[7,"..tostring(i-1)..";1,1;button"..tostring(i)..";On]"
			end
		end
		frm=frm.."list[current_player;main;0,7;8,4;]"
		meta:set_string("formspec",frm)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return (inv:is_empty("line1") and inv:is_empty("line2") and inv:is_empty("line3") and
			inv:is_empty("line4") and inv:is_empty("line5") and inv:is_empty("line6"))
	end})


mesecons_rules={{x=0,y=0,z=1},{x=0,y=0,z=-1},{x=1,y=0,z=0},{x=-1,y=0,z=0},{x=0,y=1,z=0},{x=0,y=-1,z=0}}

register_tube("pipeworks:detector_tube_on","Detector tube segment on (you hacker you)",detector_plain_textures,noctr_textures,
	end_textures,short_texture,detector_inv_texture,
	{tube={can_go=function(pos,node,velocity,stack)
		local meta = minetest.get_meta(pos)
		local name = minetest.get_node(pos).name
		local nitems=meta:get_int("nitems")+1
		meta:set_int("nitems", nitems)
		minetest.after(0.1,minetest.registered_nodes[name].item_exit,pos)
		return notvel(meseadjlist,velocity)
	end},
	groups={mesecon=2,not_in_creative_inventory=1},
	drop="pipeworks:detector_tube_off_000000",
	mesecons={receptor={state="on",
				rules=mesecons_rules}},
	item_exit = function(pos)
		local meta = minetest.get_meta(pos)
		local nitems=meta:get_int("nitems")-1
		local name = minetest.get_node(pos).name
		if nitems==0 then
			minetest.set_node(pos,{name=string.gsub(name,"on","off")})
			mesecon:receptor_off(pos,mesecons_rules)
		else
			meta:set_int("nitems", nitems)
		end
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("nitems", 1)
		local name = minetest.get_node(pos).name
		minetest.after(0.1,minetest.registered_nodes[name].item_exit,pos)
	end})

register_tube("pipeworks:detector_tube_off","Detector tube segment",detector_plain_textures,noctr_textures,
	end_textures,short_texture,detector_inv_texture,
	{tube={can_go=function(pos,node,velocity,stack)
		local name = minetest.get_node(pos).name
		minetest.set_node(pos,{name=string.gsub(name,"off","on")})
		mesecon:receptor_on(pos,mesecons_rules)
		return notvel(meseadjlist,velocity)
	end},
	groups={mesecon=2},
	mesecons={receptor={state="off",
				rules=mesecons_rules}}})

conductor_plain_textures={"pipeworks_conductor_tube_plain.png","pipeworks_conductor_tube_plain.png","pipeworks_conductor_tube_plain.png",
		"pipeworks_conductor_tube_plain.png","pipeworks_conductor_tube_plain.png","pipeworks_conductor_tube_plain.png"}
conductor_noctr_textures={"pipeworks_conductor_tube_noctr.png","pipeworks_conductor_tube_noctr.png","pipeworks_conductor_tube_noctr.png",
		"pipeworks_conductor_tube_noctr.png","pipeworks_conductor_tube_noctr.png","pipeworks_conductor_tube_noctr.png"}
conductor_end_textures={"pipeworks_conductor_tube_end.png","pipeworks_conductor_tube_end.png","pipeworks_conductor_tube_end.png",
		"pipeworks_conductor_tube_end.png","pipeworks_conductor_tube_end.png","pipeworks_conductor_tube_end.png"}
conductor_short_texture="pipeworks_conductor_tube_short.png"
conductor_inv_texture="pipeworks_conductor_tube_inv.png"

register_tube("pipeworks:conductor_tube_off","Conductor tube segment",conductor_plain_textures,conductor_noctr_textures,
	conductor_end_textures,conductor_short_texture,conductor_inv_texture,
	{groups={mesecon=2},
	mesecons={conductor={state="off",
				rules=mesecons_rules,
				onstate="pipeworks:conductor_tube_on_#id"}}})

conductor_on_plain_textures={"pipeworks_conductor_tube_on_plain.png","pipeworks_conductor_tube_on_plain.png","pipeworks_conductor_tube_on_plain.png",
		"pipeworks_conductor_tube_on_plain.png","pipeworks_conductor_tube_on_plain.png","pipeworks_conductor_tube_on_plain.png"}
conductor_on_noctr_textures={"pipeworks_conductor_tube_on_noctr.png","pipeworks_conductor_tube_on_noctr.png","pipeworks_conductor_tube_on_noctr.png",
		"pipeworks_conductor_tube_on_noctr.png","pipeworks_conductor_tube_on_noctr.png","pipeworks_conductor_tube_on_noctr.png"}
conductor_on_end_textures={"pipeworks_conductor_tube_on_end.png","pipeworks_conductor_tube_on_end.png","pipeworks_conductor_tube_on_end.png",
		"pipeworks_conductor_tube_on_end.png","pipeworks_conductor_tube_on_end.png","pipeworks_conductor_tube_on_end.png"}

register_tube("pipeworks:conductor_tube_on","Conductor tube segment on (you hacker you)",conductor_on_plain_textures,conductor_on_noctr_textures,
	conductor_on_end_textures,conductor_short_texture,conductor_inv_texture,
	{groups={mesecon=2,not_in_creative_inventory=1},
	drop="pipeworks:conductor_tube_off_000000",
	mesecons={conductor={state="on",
				rules=mesecons_rules,
				offstate="pipeworks:conductor_tube_off_#id"}}})

accelerator_noctr_textures={"pipeworks_accelerator_tube_noctr.png","pipeworks_accelerator_tube_noctr.png","pipeworks_accelerator_tube_noctr.png",
		"pipeworks_accelerator_tube_noctr.png","pipeworks_accelerator_tube_noctr.png","pipeworks_accelerator_tube_noctr.png"}
accelerator_plain_textures={"pipeworks_accelerator_tube_plain.png","pipeworks_accelerator_tube_plain.png","pipeworks_accelerator_tube_plain.png",
		"pipeworks_accelerator_tube_plain.png","pipeworks_accelerator_tube_plain.png","pipeworks_accelerator_tube_plain.png"}
accelerator_end_textures={"pipeworks_accelerator_tube_end.png","pipeworks_accelerator_tube_end.png","pipeworks_accelerator_tube_end.png",
		"pipeworks_accelerator_tube_end.png","pipeworks_accelerator_tube_end.png","pipeworks_accelerator_tube_end.png"}
accelerator_short_texture="pipeworks_accelerator_tube_short.png"
accelerator_inv_texture="pipeworks_accelerator_tube_inv.png"

register_tube("pipeworks:accelerator_tube","Accelerator pneumatic tube segment",accelerator_plain_textures,
		accelerator_noctr_textures,accelerator_end_textures,accelerator_short_texture,accelerator_inv_texture,
		{tube={can_go=function(pos,node,velocity,stack)
			velocity.speed=velocity.speed+1
			return notvel(meseadjlist,velocity)
		end}})

register_tube("pipeworks:crossing_tube","Crossing tube segment",accelerator_plain_textures,
		accelerator_noctr_textures,accelerator_end_textures,accelerator_short_texture,accelerator_inv_texture,
		{tube={can_go=function(pos,node,velocity,stack)
			return velocity
		end}})

sand_noctr_textures={"pipeworks_sand_tube_noctr.png","pipeworks_sand_tube_noctr.png","pipeworks_sand_tube_noctr.png",
		"pipeworks_sand_tube_noctr.png","pipeworks_sand_tube_noctr.png","pipeworks_sand_tube_noctr.png"}
sand_plain_textures={"pipeworks_sand_tube_plain.png","pipeworks_sand_tube_plain.png","pipeworks_sand_tube_plain.png",
		"pipeworks_sand_tube_plain.png","pipeworks_sand_tube_plain.png","pipeworks_sand_tube_plain.png"}
sand_end_textures={"pipeworks_sand_tube_end.png","pipeworks_sand_tube_end.png","pipeworks_sand_tube_end.png",
		"pipeworks_sand_tube_end.png","pipeworks_sand_tube_end.png","pipeworks_sand_tube_end.png"}
sand_short_texture="pipeworks_sand_tube_short.png"
sand_inv_texture="pipeworks_sand_tube_inv.png"

register_tube("pipeworks:sand_tube","Sand pneumatic tube segment",sand_plain_textures,sand_noctr_textures,sand_end_textures,
		sand_short_texture,sand_inv_texture,
		{groups={sand_tube=1}})

minetest.register_abm({nodenames={"group:sand_tube"},interval=1,chance=1,
	action=function(pos, node, active_object_count, active_object_count_wider)
		for _,object in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
			if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
				if object:get_luaentity().itemstring ~= "" then
					local titem=tube_item(pos,object:get_luaentity().itemstring)
					titem:get_luaentity().start_pos = {x=pos.x,y=pos.y-1,z=pos.z}
					titem:setvelocity({x=0.01,y=1,z=-0.01})
					titem:setacceleration({x=0, y=0, z=0})
				end
				object:get_luaentity().itemstring = ""
				object:remove()
			end
		end
	end
})

