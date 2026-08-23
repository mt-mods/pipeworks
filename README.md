# Pipeworks

[![ContentDB](https://content.luanti.org/packages/mt-mods/pipeworks/shields/downloads/)](https://content.luanti.org/packages/mt-mods/pipeworks/)
[![Translation status](https://translate.luanti.ch/widget/mt-mods/pipeworks/svg-badge.svg)](https://translate.luanti.ch/engage/mt-mods/)
[![Luacheck](https://github.com/mt-mods/pipeworks/actions/workflows/luacheck.yml/badge.svg)](https://github.com/mt-mods/pipeworks/actions/workflows/luacheck.yml)

This mod uses nodeboxes to supply a complete set of 3D pipes and tubes,
along devices that work with them.

See [the wiki](https://github.com/mt-mods/pipeworks/wiki/) for detailed
information about usage of this mod.

Unlike the previous version of this mod, these pipes are rounded, and when
placed, they'll automatically join together as needed. Pipes can go vertically
or horizontally, and there are enough nodes defined to allow for all possible
connections. Valves and pumps can only be placed horizontally, and will
automatically rotate and join with neighboring pipes as objects are added, as
well as joining with each other under certain circumstances.

Pipes come in two variants: one type bears one or more dark windows on each
pipe, suggesting they're empty, while the other type bears green-tinted
windows, as if full (the two colors should also be easy to select if you want
to change them in a paint program). These windows only appear on straight
lengths and on certain junctions.

Please note that owing to the nature of this mod, I have opted to use 64px
textures. Anything less just looks terrible.

The teleport tube database used to be kept in a file named 'teleport_tubes'.
The database is now kept in mod storage. The migration from 'teleport_tubes' is
automatic. The old file is then kept around but is not used at all.

## Dependencies

- Luanti/Minetest v5.10+
- [`basic_materials`](https://github.com/mt-mods/basic_materials)
- [`xcompat`](github.com/mt-mods/xcompat)
- [`fakelib`](https://github.com/OgelGames/fakelib)

### Optional

- MTG mods `default` and `screwdriver`
- Hades mods `hades_core`, `hades_furnaces`, and `hades_chests`
- Mineclone mods `mcl_mapgen_core`, `mcl_barrels`, `mcl_furnaces`, `mcl_experience`
- `mesecons`
- `mesecons_mvps`
- `digilines`
- `signs_lib`
- `unified_inventory`
- `fl_mapgen`
- `sound_api`
- `i3`
- `vizlib`
- `mapgen`
