
util.AddNetworkString("arclib_thankyou")
ARCLib.AddonsUsingLanguages = {}

function ARCLib.AddAddonConcommand(addon,command) 
	concommand.Add( command, function( ply, cmd, args )
		local comm = args[1]
		table.remove( args, 1 )
		if _G[addon].Commands[comm] then
			if _G[addon].Commands[comm].adminonly && IsValid(ply) && !table.HasValue(_G[addon].Settings.admins,string.lower(ply:GetUserGroup())) then
				_G[addon].MsgCL(ply,ARCLib.PlaceholderReplace(_G[addon].Msgs.CommandOutput.AdminCommand,{RANKS=table.concat( _G[addon].Settings.admins, ", " )}))
			return end
			if IsValid(ply) then
				local shitstring = ply:Nick().." ("..ply:SteamID()..") used the command: "..comm
				for i=1,#args do
					shitstring = shitstring.." "..args[i]
				end
				_G[addon].Msg(shitstring)
			end
			_G[addon].Commands[comm].command(ply,args)
		elseif !comm then
			_G[addon].MsgCL(ply,"No command. Type '"..command.." help' for help.")
		else
			_G[addon].MsgCL(ply,"Invalid command '"..tostring(comm).."' Type '"..command.." help' for help.")
		end
	end)
end

function ARCLib.SetAddonLanguage(addon)
	ARCLib.AddonsUsingLanguages[addon] = true
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
function ARCLib.LoadDefaultLanguages(addon,url,callback,retries)
	retries = tonumber(retries) or 0
	local dir = _G[addon].Dir.."/languages"
	local langs = {}
	if !file.IsDir( dir,"DATA" ) then
		ARCLib.Msg("Created Folder: "..dir)
		file.CreateDir(dir)
	end
	local files, _ = file.Find( dir.."/*.txt", "DATA" )
	for i=1,#files do
		local fname = string.sub( files[i], 1, #files[i]-4 )
		langs[fname] = fname
	end
	http.Fetch( url,
		function( body, len, headers, code )
			if code == 200 then
				
				local tab = util.JSONToTable(body)
				if !istable(tab) then
					ARCLib.Msg(url.." is not valid JSON")
					callback()
					return
				end
				ARCLib.ForEachAsync(tab,function(k,v,callback)
					http.Fetch( v,
						function( body, len, headers, code )
							if code == 200 then
								local parts = string.Explode( "/", v )
								local filename = parts[#parts]
								local langname = string.sub( filename, 1, #filename-4 )
								local key = table.KeyFromValue( langs, langname )
								if (key) then
									langs[key] = nil
								end
								
								langs[k] = langname
								file.Write(dir.."/"..filename,body)
							else
								ARCLib.Msg(v.." returned HTTP status "..code)
							end
							callback()
						end,
						function( err )
							ARCLib.Msg("Failed to connect to "..url)
							callback()
						end
					)
				end,
				function()
					callback(langs)
				end)
			else
				if (retries > 5) then
					ARCLib.Msg(url.." returned HTTP status "..code)
					callback(langs)
					return
				end
				
				retries = retries + 1
				ARCLib.LoadDefaultLanguages(addon,url,callback,retries)
			end
		end,
		function( err )
			if (retries > 5) then
				ARCLib.Msg("Failed to connect to "..url.." after 10 retries. ("..err..")")
				callback(langs)
				return
			end
			retries = retries + 1
			ARCLib.LoadDefaultLanguages(addon,url,callback,retries)
		end
	)
	
end

util.AddNetworkString( "arclib_comm_lang" )
function ARCLib.SendAddonLanguage(addon,v)
	if istable(_G[addon].JSON_Lang) then
		net.Start("arclib_comm_lang")
		net.WriteString(addon)
		net.WriteInt(0,8)
		v["_"..addon.."_Lang_Place"] = 0
		net.WriteUInt(0,32)
		net.WriteUInt(#_G[addon].JSON_Lang,32)
		net.WriteUInt(0,32)
		net.Send(v)
	end
end


net.Receive( "arclib_comm_lang", function(length,ply)
	local addon = net.ReadString()
	local part = net.ReadUInt(32)
	local whole  = net.ReadUInt(32)
	if whole == #_G[addon].JSON_Lang then
		if part == ply["_"..addon.."_Lang_Place"] then
			ply["_"..addon.."_Lang_Place"] = ply["_"..addon.."_Lang_Place"] + 1
			net.Start("arclib_comm_lang")
			net.WriteString(addon)
			net.WriteInt(0,8)
			net.WriteUInt(ply["_"..addon.."_Lang_Place"],32)
			net.WriteUInt(#_G[addon].JSON_Lang,32)
			local str = tostring(_G[addon].JSON_Lang[ply["_"..addon.."_Lang_Place"]])
			net.WriteUInt(#str,32)
			net.WriteData(str,#str)
			net.Send(ply)
		else
			net.Start("arclib_comm_lang")
			net.WriteString(addon)
			net.WriteInt(1,8)
			net.Send(ply)
		end
	elseif part == 0 && whole == 0 then
		ply["_"..addon.."_Lang_Place"] = nil
	else
		net.Start("arclib_comm_lang")
		net.WriteString(addon)
		net.WriteInt(2,8)
		net.Send(ply)
	end
end)
