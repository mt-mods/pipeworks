
pipeworks.fluid_recipes = {
	trie = {}
}

--[[def = {items = {
	<strictly width 3 or shapeless>
},
output = out|{outs}, -- Itemstacks
fluid = {
	type = <type>,
	amount = <float amount>
}}
]]
pipeworks.fluid_recipes.register = function(self, def)
	if def.output == nil then return end
	if def.items == nil then return end
	local newdef = {
		items = {},
		fluid = def.fluid,
		shaped = def.shaped
	}
	local path = self.trie

	for _,v in ipairs(def.items) do
		if type(v) == "table" then
			for _,w in ipairs(v) do
				newdef.items[#newdef.items + 1] = w
				local child = {}
				if path[w] then
					child = path[w]
				end
				path[w] = child
				path = child
			end
		else
			newdef.items[#newdef.items + 1] = v
			local child = {}
			if path[v] then
				child = path[v]
			end
			path[v] = child
			path = child
		end
	end

	if core.get_modpath("unified_inventory") then
		unified_inventory.register_craft({
			output = def.output,
			type = "fluidshaped",
			items = table.copy(newdef.items),
			fluid = newdef.fluid,
			width = 3,
		})
	end

	if type(def.output) == "table" then
		newdef.output = def.output
	else
		newdef.output = {item = def.output}
	end

	if not path.fluid then path.fluid = {} end
	if not path.output then path.output = {} end

	path.fluid[newdef.fluid.type] = newdef.fluid
	path.output[newdef.fluid.type] = newdef.output
	path.tail = true
	self[#self + 1] = newdef
end

local check_fluid_sufficiency = function(input, req)
	if not req then return true end
	if req.amount <= 0 then return true end
	if not input then return false end
	return input.type == req.type and input.amount >= req.amount
end

--[[
input = {items = <ItemStack list>},
fluid = <fluid>
]]
pipeworks.fluid_recipes.get = function(self, input, fluid)
	local path = self.trie
	local empty = {item = ItemStack("")}
	local emptyfluid = {type = "", amount = 0}
	local dec_input = {
		items = table.copy(input.items)
	}
	for k,v in ipairs(dec_input.items) do
		path = path[v:get_name()]
		if path == nil then return empty, input, emptyfluid, fluid end
		dec_input.items[k] = ItemStack(v)
		dec_input.items[k]:set_count(v:get_count()-1)
		if path == nil then return empty, input, emptyfluid, fluid end
		if path.tail then
			local fluid_type = fluid.type
			if path.output[fluid_type] then
				local fluidcost = path.fluid[fluid_type]
				if not check_fluid_sufficiency(fluid, fluidcost) then return empty, input, emptyfluid, fluid, true end
				return path.output[fluid_type], dec_input, fluidcost, {type = fluid_type, amount = fluid.amount - fluidcost.amount}
			else
				return empty, input, emptyfluid, fluid
			end
		end
	end
	return empty, input, emptyfluid, fluid
end

-- name = <string>
-- fluid_type = <string>
pipeworks.fluid_recipes.get_all_with = function(self, name, fluid_type)
	local out = {}
	local n = 0
	for _,v in ipairs(self) do
		if v.fluid.type == fluid_type and v.output.item:get_name() == name then
			n = n + 1
			out[n] = v
		end
	end
	return out
end

-- name = <string>
pipeworks.fluid_recipes.get_all = function(self, name)
	local out = {}
	local n = 0
	for _,v in ipairs(self) do
		if v.output.item:get_name() == name then
			n = n + 1
			out[n] = v
		end
	end
	return out
end

local format_fluid_amount = function(amount)
	return (amount * 1000) .. "L"
end

if core.get_modpath("unified_inventory") then
	unified_inventory.register_craft_type("fluidshaped", {
		description = S("Shaped Fluid Craft"),
		icon = "pipeworks_autocrafter.png",
		width = 3,
		height = 4,
	})

	local reqstack = ItemStack("air")
	local meta = reqstack:get_meta()
	meta:set_string("count_meta","FLUID\nREQ:")
	meta:set_int("count_alignment",10)
	meta:set_string("inventory_image","blank.png")

	unified_inventory.register_on_craft_registered(function (_, options)
		if options.type ~= "fluidshaped" then return end
		options.items[10] = reqstack:to_string()
		local fluidstack = ItemStack(pipeworks.liquids[options.fluid.type].source)
		fluidstack:get_meta():set_string("count_meta", format_fluid_amount(options.fluid.amount))
		options.items[11] = fluidstack:to_string()
	end)
end
