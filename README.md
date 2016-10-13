# ARCLib
A library used by my Garry's Mod addons.
## This will be released on workshop soon!
I will be releasing this on workshop so you can easily integrate this into your addons
## How to use the ARCLib settings menu
There are some prerequisits to using the ARCLib settings menu (as it was intended to work with my addons)
* ```_G.YourAddon.Dir``` Must exist and must be a name of a folder that exists (the settings will be saved in this folder as "_saved_settings.txt") (Server)
* ```_G.YourAddon.Settings``` Must exist and contain your default settings (Shared)
* ```_G.YourAddon.Settings.admins``` Must be an array of all the usergroups that can access the admin GUI.
* ```_G.YourAddon.SettingsDesc``` Must exist and contain descriptions of your settings (Shared)
* ```_G.YourAddon.Loaded``` Must be a boolean that is true (unless your addon is not loaded, of course) (Server)
* [All this stuff must exist](https://gist.github.com/ARitz-Cracker/19a3ff9db727e80c0e8343c4495b7916) (Shared)
* ```_G.YourAddon.MsgCL``` must be a function [that works like this](https://gist.github.com/ARitz-Cracker/a71cb16b00751aec9873448b127447dd) (Server)
* ```_G.YourAddon.Commands``` must be a table.

### The ARCLib command structure (It's really cool!)
Actually using my command structure is optional. It can be an empty table if you'd like.
```
YourAddon.Commands = {
	["about"] = {
		command = function(ply,args) -- This function is called when you would enter "theawesomeaddon about" in console
			if !ARCBank.Loaded then ARCBank.MsgCL(ply,ARCBank.Msgs.CommandOutput.SysReset) return end
			ARCBank.MsgCL(ply,"This is the awesome addon, your addon! :)" )
		end, 
		usage = "", -- What arguments this command accepts use <> for requeired arguments and [] for optional ones.
		description = "About The Awesome addon",
		adminonly = false, -- If it should check your 
		hidden = false
	},
	["test"] = {
		command = function(ply,args) 
			local str = "Arguments:"
			for _,arg in ipairs(args) do
				str = str.." | "..arg
			end
			YourAddon.MsgCL(ply,str)
		end, 
		usage = " [argument(any)] [argument(any)] [argument(any)]",
		description = "[Debug] Tests arguments",
		adminonly = false,
		hidden = true
	},
  -- More command here
}

ARCLib.AddSettingConsoleCommands("YourAddon") -- Adds the commands the admin GUI uses to change the settings
ARCLib.AddAddonConcommand("YourAddon","theawesomeaddon") -- Actually makes the command usable
```
Now that all the commands are defined, you can FINALLY define your settings!
```
YourAddon.Settings["is_awesome"] = true
YourAddon.Settings["irony_level"] = 5
```
Then add your descriptions...
```
YourAddon.SettingsDesc["is_awesome"] = "Is this addon awesome?"
YourAddon.SettingsDesc["irony_level"] = "How many levels or irony are you on, bro?"
```
And call this function on the server to start the networking magic! This function will also read the config file if it exists.
```
ARCLib.AddonLoadSettings("YourAddon",{old_setting_name = "new_setting_name"}) -- As you can see, this also supports the renaming of settings!
```
Now at any moment, call ```ARCLib.AddonConfigMenu("YourAddon","theawesomeaddon")``` on the client.

## The auto-loader (With dependency managment!!!)
I've created the auto loader for 2 reasons.

1. I wanted to make my addons load as soon as ARCLib was done loading without having to wait for the next game tick
2. I wanted to make sure my DLC was loading AFTER the main addon

Here's how to use it!
* Create a file called lua/arclib_addons/theawesomeaddon.lua
* Make it look at this
```
YourAddon = YourAddon or {}
-- Return Name of the table, Name of addon, and the list of dependencies
return "YourAddon","The Awesome Addon",{"arclib"} -- Dependencies aren't defined by their table, but by file name (without .lua) so if I made an addon that depended on this one, I would add "theawesomeaddon" to the list.
```
* Next it will load all the files in lua/theawesomeaddon/shared/
* Then it will load all the files in lua/theawesomeaddon/server/
* Then it will load all the files in lua/theawesomeaddon/client/
* Then after all ARCLib dependent addons are loaded, it will do the same as above for all addons, except it will use a "_plugins" suffix to the name of the folder.
* Afer that, if YourAddon.Load is a function, it will call that.

## Other cool functions that you should totally be using.
This isn't a complete list, but I wanted to showcase some things I think everyone should use!!
* ```ARCLib.GetIcon(type,name)``` (Client) This is intended to be used with ```surface.SetMaterial```. It will return an IMaterial of any [FatCow icon](http://www.fatcow.com/free-icons) 

type can be either ARCLib.ICON_16, ARCLib.ICON_32, ARCLib.ICON_16_GRAY or ARCLib.ICON_32_GRAY. This will allow you to select 16x16 icons or 32x32 icons in colour or grayscale. name is the name of the icon without the .png There's also ```ARCLib.GetWebIcon16(name)```, ```ARCLib.GetWebIcon32(name)```, ```ARCLib.GetWebIcon16Gray(name)```, and ```ARCLib.GetWebIcon32Gray(name)``` if you like that kind of thing.
* ```ARCLib.PlayCachedURL(url,flags,callback)``` (Client) This is exactly like ```sound.PlayURL``` except that it caches the file until the game ends.
* ```ENT:ARCLib_SetAnimation(animation)``` (Shared) this makes the entity's model play an animation!
* ```ARCLib.DeleteAll(dir)``` (Shared) deletes a folder and everything in it
* Everything in the shared/maths.lua !!!
* ```ARCLib.IsVersion(version,addon)``` Compares version to _G[addon].Version with syntaxes like "1.3.4". For example, if I wanted ARCBank v1.3.4, and v1.3.6 was installed, ```ARCLib.IsVersion("1.3.4","ARCBank")``` would return true.
