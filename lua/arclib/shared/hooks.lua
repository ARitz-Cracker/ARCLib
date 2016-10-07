-- Some custom event hooks I call

-- The following code calls a hook on both the client and the server. No built-in hooks seem to be called right when the Sending Client Info process is complete.
if CLIENT then
	hook.Add( "Think", "ARCLib_FullyLoadedConfirm", function()
		if IsValid(LocalPlayer()) then
			net.Start("ARCLib_FullyLoaded")
			net.SendToServer()
			hook.Remove( "Think", "ARCLib_FullyLoadedConfirm") 
		end
	end)
	net.Receive( "ARCLib_FullyLoaded", function(length)
		local ply = net.ReadEntity()
		if IsValid(ply) && ply:IsPlayer() then
			MsgN(ply:Nick().." is now fully loaded!")
			hook.Call( "ARCLib_OnPlayerFullyLoaded",GM,ply)
		end
	end)
else
	util.AddNetworkString("ARCLib_FullyLoaded")
	net.Receive( "ARCLib_FullyLoaded", function(length,ply)
		if IsValid(ply) && !ply.ARCLib_FullyLoaded then
			MsgN(ply:Nick().." is now fully loaded!")
			net.Start("ARCLib_FullyLoaded")
			net.WriteEntity(ply)
			net.Broadcast()
			hook.Call( "ARCLib_OnPlayerFullyLoaded",GM,ply)
			ply.ARCLib_FullyLoaded = true
		end
	end)
	
	hook.Add( "PlayerInitialSpawn", "ARCLib SendSettings", function(ply)
		for k,v in pairs(ARCLib.AddonsUsingSettings) do
			ARCLib.SendAddonSettings(k,ply)
		end
		for k,v in pairs(ARCLib.AddonsUsingLanguages) do
			ARCLib.SendAddonLanguage(k,ply)
		end
	end)
end