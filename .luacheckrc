unused_args = false
max_line_length= 240
redefined = false

globals = {
	"pipeworks",
	"luaentity"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "minetest",
	"VoxelManip", "VoxelArea",

	-- mods
	"default", "mesecon", "digiline",
	"screwdriver"

}
