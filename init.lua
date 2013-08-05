-- Pipeworks mod by Vanessa Ezekowitz - 2013-07-13
--
-- This mod supplies various steel pipes and plastic pneumatic tubes
-- and devices that they can connect to.
--
-- License: WTFPL
--

-- Read (and if necessary, copy) the config file

local worldpath = minetest.get_worldpath()
local modpath = minetest.get_modpath("pipeworks")

dofile(modpath.."/default_settings.txt")

if io.open(worldpath.."/pipeworks_settings.txt","r") == nil then

	io.input(modpath.."/default_settings.txt")
	io.output(worldpath.."/pipeworks_settings.txt")

	local size = 2^13      -- good buffer size (8K)
	while true do
		local block = io.read(size)
		if not block then
			io.close()
			break
		end
		io.write(block)
	end

else
	dofile(worldpath.."/pipeworks_settings.txt")
end

-- Helper functions

if minetest.get_modpath("unified_inventory") or not minetest.setting_getbool("creative_mode") then
	pipeworks_expect_infinite_stacks = false
else
	pipeworks_expect_infinite_stacks = true
end

function pipeworks_fix_image_names(table, replacement)
	outtable={}
	for i in ipairs(table) do
		outtable[i]=string.gsub(table[i], "_XXXXX", replacement)
	end

	return outtable
end

function pipeworks_add_pipebox(t, b)
	for i in ipairs(b)
		do table.insert(t, b[i])
	end
end

function pipeworks_node_is_owned(pos, placer)
	local ownername = false
	if type(IsPlayerNodeOwner) == "function" then					-- node_ownership mod
		if HasOwner(pos, placer) then						-- returns true if the node is owned
			if not IsPlayerNodeOwner(pos, placer:get_player_name()) then
				if type(getLastOwner) == "function" then		-- ...is an old version
					ownername = getLastOwner(pos)
				elseif type(GetNodeOwnerName) == "function" then	-- ...is a recent version
					ownername = GetNodeOwnerName(pos)
				else
					ownername = S("someone")
				end
			end
		end

	elseif type(isprotect)=="function" then 					-- glomie's protection mod
		if not isprotect(5, pos, placer) then
			ownername = S("someone")
		end
	elseif type(protector)=="table" and type(protector.can_dig)=="function" then 	-- Zeg9's protection mod
		if not protector.can_dig(5, pos, placer) then
			ownername = S("someone")
		end
	end

	if ownername ~= false then
		minetest.chat_send_player( placer:get_player_name(), S("Sorry, %s owns that spot."):format(ownername) )
		return true
	else
		return false
	end
end

function pipeworks_replace_name(tbl,tr,name)
	local ntbl={}
	for key,i in pairs(tbl) do
		if type(i)=="string" then
			ntbl[key]=string.gsub(i,tr,name)
		elseif type(i)=="table" then
			ntbl[key]=pipeworks_replace_name(i,tr,name)
		else
			ntbl[key]=i
		end
	end
	return ntbl
end

-- Load the various parts of the mod

dofile(modpath.."/autoplace.lua")
dofile(modpath.."/item_transport.lua")
dofile(modpath.."/flowing_logic.lua")
dofile(modpath.."/crafts.lua")

dofile(modpath.."/tubes.lua")

if enable_pipes then dofile(modpath.."/pipes.lua") end
if enable_teleport_tube then dofile(modpath.."/teleport_tube.lua") end
if enable_pipe_devices then dofile(modpath.."/devices.lua") end
if enable_redefines then dofile(modpath.."/compat.lua") end
if enable_autocrafter then dofile(modpath.."/autocrafter.lua") end
if enable_deployer then dofile(modpath.."/deployer.lua") end
if enable_node_breaker then dofile(modpath.."/node_breaker.lua") end

minetest.register_alias("pipeworks:pipe", "pipeworks:pipe_110000_empty")
local DEBUG = false
local CYCLIC = true

print("Pipeworks loaded!")
