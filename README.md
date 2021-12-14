# ShowHidden (ShowClips & ShowTriggers)

Module for Garry's mod Bunnyhop gamemode that shows invisible obstacles.

* Invisible brushes (walls):
  * Player-clip and Invisible
  * Invisible ladders
  * NoDraw and SkyBox
* Triggers (map created invisible zones)
  * Teleports and teleports with filters (reset zones)
  * Boosters: push, [gravity](https://gamebanana.com/prefabs/6677) and [base-velocity](https://gamebanana.com/prefabs/7118)
  * BunnyHop platforms (standing prevention)
  * PreSpeed prevention triggers ([gravity](https://gamebanana.com/prefabs/6760))
  * And other triggers...
* Static props collision models
* You can select default, solid-color or wireframe texture for every brush/trigger type and change it's color.

Tested on FLOW gamemodes: [v8.42 (by czarchasm)](https://czarchasm.club/bhop.html), [v8.50 (pG)](https://github.com/GMSpeedruns/GM-BunnyHop) and [v7.26](https://github.com/GMSpeedruns/Flow-Release/tree/master/Gamemodes/Flow%20Network%20-%20All%20gamemodes/Flow%20Network%20-%20Bunny%20Hop/Gamemode), but should work on any gamemode

## Installation

1. Place folder into Garry's mod `addons` folder
2. Restart the server (if it was running)

## Usage

You can toggle and configure everything from GUI (config menu).

### Chat commands

| Action              | Chat command    | Console command/variable   |
| ------------------- | --------------- | -------------------------- |
| Open config menu    | `!showhidden`   | `showhidden`               |
| Toggle ShowClips    | `!showclips`    | `showclips 1/0`            |
| Toggle ShowTriggers | `!showtriggers` | `showtriggers_enabled 1/0` |
| Toggle ShowProps    | `!showprops`    | `showprops 1/0`            |

There are also "on" and "off" commands for ShowClips and ShwoTriggers...
Chat commands can be changed in `lua/showclips/sv_init.lua` file.

### Console commands and variables

**MaterialTypes:** 0 - wireframe, 1 - default, 2 - solid color
**BrushTypes:** 1 - player-clip, 2 - invisible, 3 - ladder, 4 - nodraw, 5 - skybox
**TriggerTypes:** 1 - other, 2 - teleport, 3 - tele with filter, 4 - push, 5 - basevel, 6 - gravity, 7 - anti-pre, 8 - platform

| Command | Description |
| ------- | ----------- |
| `showhidden` | Open settings window |
| `showclips 0-31` | Set bit-mask with enabled brush types |
| `showclips_material 1-5 0-2 "R G B A"` | Set material and color for brush type |
| `showprops 0/1` | Toggle static props collision models |
| `showprops_material 0-2 "R G B A"` | Set material and color for props |
| `showtriggers_enabled 0/1` | Toggle ShowTriggers |
| `showtriggers_types 0-255` | Set bit-mask with enabled trigger types |
| `showtriggers_material 1-8 0-2 "R G B A"` | Set material and color for trigger type |
| `showtriggers_trace` | Show triggers information (you looking at), use `developer 1` to see text and lines on screen |

## Internationalization support

You can change language strings in file `lua/showclips/cl_lang.lua`.

## TODO
* [ ] Show triggers info (name, filter, destination, outputs)
* [ ] Select some brushes/triggers/props and show/hide only them
* [ ] Add "custom" material type (generate with color, text and font size)
* [ ] Do not render entity brushes (at world center)
* [ ] Show SOLID_BBOX static props collision model
* [ ] Render triggers fully on client side (optionally?)
* [ ] Refactor: split into files and use DRY

## Credits

* Made by [CLazStudio](https://steamcommunity.com/id/CLazStudio/) 
* ShowClips part initially was sponsored by [rq](https://steamcommunity.com/id/relrq/)
* ShowTriggers part based on __Meeno__ version
* Trigger types inspired by [ improved-showtriggers](https://github.com/blankbhop/improved-showtriggers) by __Eric__ and __Blank__
* This addon uses [luabsp-gmod](https://github.com/h3xcat/gmod-luabsp) library by __h3xcat__ licensed under GPL-3.0
