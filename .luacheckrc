unused_args = false
max_line_length= 240
redefined = false
std = "minetest+max"

globals = {
	"pipeworks",
	"luaentity"
}

read_globals = {
	-- luanti (TODO: remove after lunarmodules/luacheck releases a version with proper luanti support)
	"core",
	-- mods
	"default", "mesecon", "digilines",
	"screwdriver", "unified_inventory",
	"i3", "mcl_experience", "awards",
	"xcompat", "fakelib", "vizlib"
}
