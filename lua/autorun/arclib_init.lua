ARCLib = ARCLib or {}
local ver = 1.6
if !ARCLib.Version || ARCLib.Version < ver then
	ARCLib.Version = ver
	ARCLib.Update = "November 3rd 2015"
	MsgN("ARCLib v"..ARCLib.Version)
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
end

