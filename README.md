# ShowHidden (ShowClips & ShowTriggers)

Module for Garry's mod Bunnyhop gamemode that shows invisible obstacles.

* Player-clip brushes (invisible walls)
* Triggers (map created invisible zones)
  * Teleports and teleports with filters (reset zones)
  * Boosters: push, [gravity](https://gamebanana.com/prefabs/6677) and [base-velocity](https://gamebanana.com/prefabs/7118)
  * BunnyHop platforms (standing prevention)
  * PreSpeed prevention triggers ([gravity](https://gamebanana.com/prefabs/6760))
  * And other triggers...
* You can select default, solid color or wireframe texture for brushes and change it's color.

Tested on FLOW gamemodes: [v8.42 (by czarchasm)](https://czarchasm.club/bhop.html), [v8.50 (pG)](https://github.com/GMSpeedruns/GM-BunnyHop) and [v7.26](https://github.com/GMSpeedruns/Flow-Release/tree/master/Gamemodes/Flow%20Network%20-%20All%20gamemodes/Flow%20Network%20-%20Bunny%20Hop/Gamemode)

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

There are also "on" and "off" commands for ShowClips and ShwoTriggers...
Chat commands can be changed in `lua/showclips/sv_init.lua` file.

### Console commands and variables

| Command                     | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| `showhidden`                | Open settings window                                         |
| `showclips 0/1`             | Toggle ShowClips                                             |
| `showclips_material 0-2`    | Set material for clip brushes (0 - wireframe, 1 - default, 2 - solid color) |
| `showclips_color "R G B A"` | Set color for player-clip brushes                            |
| `showtriggers_enabled 0/1` | Toggle ShowTriggers |
| `showtriggers_types 0-255` | Set bit-mask with enabled trigger types |
| `showtriggers_material 1-8 0-2 "R G B A"` | Set material and color for trigger type |
| `showtriggers_trace` | Show triggers information (you looking at), use `developer 1` to see text and lines on screen |

## Internationalization support

You can change language strings at the bottom of the `lua/showclips/cl_init.lua` file.

## TODO
* [ ] Show (static) props collision model
* [ ] Other brushes and geometry (invisible, ladder, no-draw, ...)
* [ ] Select some brushes and show/hide only them
* [ ] Show triggers info (name, filter, destination, outputs)

## Credits

* Made by [CLazStudio](https://steamcommunity.com/id/CLazStudio/) 
* ShowClips part initially was sponsored by [rq](https://steamcommunity.com/id/relrq/)
* ShowTriggers part based on __Meeno__ version
* Trigger types inspired by [ improved-showtriggers](https://github.com/blankbhop/improved-showtriggers) by __Eric__ and __Blank__
* This addon uses [luabsp-gmod](https://github.com/h3xcat/gmod-luabsp) library by __h3xcat__ licensed under GPL-3.0
