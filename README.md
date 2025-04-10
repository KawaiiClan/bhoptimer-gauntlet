# bhoptimer-gauntlet
### Requires <a href="https://github.com/shavitush/bhoptimer">bhoptimer</a>, tested on SM1.12
Single player bhop tournament using bhoptimer, made by me for aimer
<br>Configure a maplist, then go to the first map with `!startgauntlet`. When you beat a map, the next map will be loaded until you complete the last map
<br>Times and all info is logged to `/logs/gauntlet/YYYY-MM-DD.txt`

# Installation
<br>Upload plugin to your server (mostly used on private LAN servers, not advised for public servers)
<br>Configure a "gauntlet" entry in `sourcemod/configs/maplists.cfg`, as seen below:

```
"gauntlet"
{
  "file"		"addons/sourcemod/configs/gauntlet_maplist.ini"
}
```

<br>Create `addons/sourcemod/configs/gauntlet_maplist.ini` and add maps to it, each on its own line and all lowercase
<br>Start the server and either change the map to the first map, or type !gauntletstart

# Commands
### !gauntlet
>See information about the currently configured gauntlet
### !startgauntlet/!restartgauntlet
>Go to the first map in the gauntlet (starting a new gauntlet)
