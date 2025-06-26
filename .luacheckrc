unused_args = false
max_line_length= 240
redefined = false
std = "minetest+max"

globals = {
	"pipeworks",
	"luaentity"
}

read_globals = {
	-- remove after luacheck release: https://github.com/lunarmodules/luacheck/issues/121
	"core",
	-- mods
	"default", "mesecon", "digilines",
	"screwdriver", "unified_inventory",
	"i3", "mcl_experience", "awards",
	"xcompat", "fakelib", "vizlib"
}
