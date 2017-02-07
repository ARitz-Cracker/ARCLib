ARCLib = ARCLib or {}
NULLFUNC = function(...) end
function ARCLib.Msg(msg)
	Msg("ARCLib: "..tostring(msg).."\n")
end
ARCLib.Version = "1.7.0"
ARCLib.Update = "January 17th 2016"
ARCLib.Msg("ARitz Cracker's Libraries")
ARCLib.Msg(table.Random({"My pile-o-spaghetti-code","This library assumes a lot about the addon it loads, doesn't it?","Maybe other people will find this useful.","[Insert witty message here]","These little messages are tradition!"}))
ARCLib.Msg("Version: "..ARCLib.Version)
ARCLib.Msg("Updated on: "..ARCLib.Update)
if SERVER then
	AddCSLuaFile()
	
	local sharedfiles, _ = file.Find( "arclib/shared/*.lua", "LUA" )
	for i, v in ipairs( sharedfiles ) do
		AddCSLuaFile( "arclib/shared/"..v )
		include( "arclib/shared/"..v )
	end
	local serverfiles, _ = file.Find( "arclib/server/*.lua", "LUA" )
	for i, v in ipairs( serverfiles ) do
		include( "arclib/server/"..v )
	end
	local clientfiles, _ = file.Find( "arclib/client/*.lua", "LUA" )
	for i, v in ipairs( clientfiles ) do
		AddCSLuaFile( "arclib/client/"..v )
	end
else
	local sharedfiles, _ = file.Find( "arclib/shared/*.lua", "LUA" )
	for i, v in pairs( sharedfiles ) do
		include( "arclib/shared/"..v )
	end
	local clientfiles, _ = file.Find( "arclib/client/*.lua", "LUA" )
	for i, v in pairs( clientfiles ) do
		include( "arclib/client/"..v )
	end
end

ARCLib.Msg("Looking for any addons that depend on ARCLib...")

ARCLib.Addons = {}

local len = 1

ARCLib.Addons[len] = {}
ARCLib.Addons[len].tabname = "ARCLib"
ARCLib.Addons[len].filename = "arclib"
ARCLib.Addons[len].name = "ARCLib"
ARCLib.Addons[len].depends = {}

local arcloadfiles, _ = file.Find( "arclib_addons/*.lua", "LUA" )
for k, v in pairs( arcloadfiles ) do
	local addon = {}
	addon.filename = string.sub(v,1,-5)
	addon.tabname,addon.name,addon.depends = include( "arclib_addons/"..v )
	AddCSLuaFile("arclib_addons/"..v )
	len = len + 1
	ARCLib.Addons[len] = addon
end

local installedAddons = {}

for i=1,len do
	installedAddons[ARCLib.Addons[i].filename] = true
end
local loadedaddons = {}
local i = 1
while i<=len do
	local valid = true
	for ii=1,#ARCLib.Addons[i].depends do
		if !installedAddons[ARCLib.Addons[i].depends[ii]] then
			ARCLib.Msg("WARNING! "..ARCLib.Addons[i].name.." has an unmet dependency! ("..ARCLib.Addons[i].depends[ii]..") This addon will not be loaded!")
			table.remove( ARCLib.Addons ,i )
			i = i - 1
			len = len - 1
			valid = false
			break
		end
		if !loadedaddons[ARCLib.Addons[i].depends[ii]] then
			local addon = table.remove( ARCLib.Addons ,i)
			i = i - 1
			ARCLib.Addons[len] = addon
			valid = false
			break
		end
	end
	if valid then
		loadedaddons[ARCLib.Addons[i].filename] = true
	end
	i = i + 1
end

for i=2,len do
	local addon = ARCLib.Addons[i]
	ARCLib.Msg(">> Loading "..addon.name.."...")
	if SERVER then
		local sharedfiles, _ = file.Find( addon.filename.."/shared/*.lua", "LUA" )
		for i, v in ipairs( sharedfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."/shared/"..v )
			AddCSLuaFile( addon.filename.."/shared/"..v )
			include( addon.filename.."/shared/"..v )
		end
		local serverfiles, _ = file.Find( addon.filename.."/server/*.lua", "LUA" )
		for i, v in ipairs( serverfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."/server/"..v )
			include( addon.filename.."/server/"..v )
		end
		local clientfiles, _ = file.Find( addon.filename.."/client/*.lua", "LUA" )
		for i, v in ipairs( clientfiles ) do
			AddCSLuaFile( addon.filename.."/client/"..v )
		end
	else
		local sharedfiles, _ = file.Find( addon.filename.."/shared/*.lua", "LUA" )
		for i, v in pairs( sharedfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."/shared/"..v )
			include( addon.filename.."/shared/"..v )
		end
		local clientfiles, _ = file.Find( addon.filename.."/client/*.lua", "LUA" )
		for i, v in pairs( clientfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."/client/"..v )
			include( addon.filename.."/client/"..v )
		end
	end
end
for i=2,len do
	local addon = ARCLib.Addons[i]
	ARCLib.Msg("Loading plugins for "..addon.name.."...")
	if SERVER then
		local sharedfiles, _ = file.Find( addon.filename.."_plugins/shared/*.lua", "LUA" )
		for i, v in ipairs( sharedfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."_plugins/shared/"..v )
			AddCSLuaFile( addon.filename.."_plugins/shared/"..v )
			include( addon.filename.."_plugins/shared/"..v )
		end
		local serverfiles, _ = file.Find( addon.filename.."_plugins/server/*.lua", "LUA" )
		for i, v in ipairs( serverfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."_plugins/server/"..v )
			include( addon.filename.."_plugins/server/"..v )
		end
		local clientfiles, _ = file.Find( addon.filename.."_plugins/client/*.lua", "LUA" )
		for i, v in ipairs( clientfiles ) do
			AddCSLuaFile( addon.filename.."_plugins/client/"..v )
		end
	else
		local sharedfiles, _ = file.Find( addon.filename.."_plugins/shared/*.lua", "LUA" )
		for i, v in pairs( sharedfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."_plugins/shared/"..v )
			include( addon.filename.."_plugins/shared/"..v )
		end
		local clientfiles, _ = file.Find( addon.filename.."_plugins/client/*.lua", "LUA" )
		for i, v in pairs( clientfiles ) do
			ARCLib.Msg( "lua/"..addon.filename.."_plugins/client/"..v )
			include( addon.filename.."_plugins/client/"..v )
		end
	end
end

for i=2,len do
	local addon = ARCLib.Addons[i]
	if type(_G[addon.tabname]) == "table" and type(_G[addon.tabname].Load) == "function" then
		_G[addon.tabname].Load()
	end
end

