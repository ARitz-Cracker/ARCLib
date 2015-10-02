function ARCLib.AddAddonConcommand(addon,command) 
	concommand.Add( command, function( ply, cmd, args )
		local comm = args[1]
		table.remove( args, 1 )
		if _G[addon].Commands[comm] then
			if _G[addon].Commands[comm].adminonly && ply && ply:IsPlayer() && !ply:IsAdmin() && !ply:IsSuperAdmin() then
				_G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.admin)
			return end
			if _G[addon].Commands[comm].adminonly && _G[addon].Settings["superadmin_only"] && ply && ply:IsPlayer() && !ply:IsSuperAdmin() then
				_G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.superadmin)
			return end
			if _G[addon].Commands[comm].adminonly && _G[addon].Settings["owner_only"] && ply && ply:IsPlayer() && string.lower(ply:GetUserGroup()) != "owner" then
				_G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.superadmin)
			return end
			
			if ply && ply:IsPlayer() then
				local shitstring = ply:Nick().." ("..ply:SteamID()..") used the command: "..comm
				for i=1,#args do
					shitstring = shitstring.." "..args[i]
				end
				_G[addon].Msg(shitstring)
			end
			_G[addon].Commands[comm].command(ply,args)
		elseif !comm then
			_G[addon].MsgCL(ply,"No command. Type '"..addon.." help' for help.")
		else
			_G[addon].MsgCL(ply,"Invalid command '"..tostring(comm).."' Type '"..addon.." help' for help.")
		end
	end)
end

function ARCLib.SetAddonLanguage(addon)
	local lang = _G[addon].Settings.language
	local lanstr = file.Read(_G[addon].Dir.."/languages/"..lang..".txt","DATA")
	if lanstr && lanstr != "" then
		local tab = util.JSONToTable(lanstr)
		if tab then
			_G[string.upper(addon).."_ERRORSTRINGS"] = ARCLib.RecursiveTableMerge(_G[string.upper(addon).."_ERRORSTRINGS"],tab.errmsgs)
			_G[addon].Msgs = ARCLib.RecursiveTableMerge(_G[addon].Msgs,tab.msgs)
			_G[addon].SettingsDesc = ARCLib.RecursiveTableMerge(_G[addon].SettingsDesc,tab.settingsdesc)
			
			--[[
			local translations = {}
			translations.errmsgs = ARCBANK_ERRORSTRINGS
			translations.msgs = ARCBank.Msgs
			translations.settingsdesc = ARCBank.SettingsDesc
			]]
			//local compressedstir
			_G[addon].JSON_Lang = ARCLib.SplitString(util.Compress(lanstr),49152) -- Splitting the string every 48 kb just in case
			for k,v in pairs(player.GetHumans()) do
				ARCLib.SendAddonLanguage(addon,v)
			end
		else
			_G[addon].Msg("WARNING! The language file '"..tostring(lang).."' is not a valid JSON file!")
		end
	else
		_G[addon].Msg("WARNING! The language file '"..tostring(lang).."' wasn't found!")
	end
end

function ARCLib.SendAddonLanguage(addon,v)
	if !v.["_"..addon.."_Lang_Place"] then
		net.Start("arcbank_comm_lang")
		net.WriteInt(0,ARCBANK_ERRORBITRATE)
		v.["_"..addon.."_Lang_Place"] = 0
		net.WriteUInt(0,32)
		net.WriteUInt(#_G[addon].JSON_Lang,32)
		net.WriteUInt(0,32)
		net.Send(v)
	end
end

util.AddNetworkString( "arclib_comm_lang" )
net.Receive( "arclib_comm_lang", function(length,ply)
	local addon = net.ReadString()
	local part = net.ReadUInt(32)
	local whole  = net.ReadUInt(32)
	if whole == #_G[addon].JSON_Lang then
		if part == ply["_"..addon.."_Lang_Place"] then
			ply.["_"..addon.."_Lang_Place"] = ply.["_"..addon.."_Lang_Place"] + 1
			net.Start("arclib_comm_lang")
			net.WriteInt(0,8)
			net.WriteUInt(ply.["_"..addon.."_Lang_Place"],32)
			net.WriteUInt(#_G[addon].JSON_Lang,32)
			local str = tostring(_G[addon].JSON_Lang[ply.["_"..addon.."_Lang_Place"]])
			net.WriteUInt(#str,32)
			net.WriteData(str,#str)
			net.Send(ply)
		else
			net.Start("arclib_comm_lang")
			net.WriteInt(1,0)
			net.Send(ply)
		end
	elseif part == 0 && whole == 0 then
		ply.["_"..addon.."_Lang_Place"] = nil
	else
		net.Start("arclib_comm_lang")
		net.WriteInt(2,0)
		net.Send(ply)
	end
end)
