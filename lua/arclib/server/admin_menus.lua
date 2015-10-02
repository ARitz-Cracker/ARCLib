-- admin_menus.lua -- for addons that want to take advantage of the admin gui


util.AddNetworkString("arclib_comm_client_settings")

function ARCLib.SendAddonSettings(addon,ply) 

	if _G[addon] && _G[addon].Settings then
		local data = util.Compress(util.TableToJSON(_G[addon].Settings))
		net.Start("arclib_comm_client_settings")
		net.WriteString(addon)
		net.WriteUInt(#data,32)
		net.Send(ply)
	end
end

util.AddNetworkString("arclib_comm_client_settings_changed")
function ARCLib.UpdateAddonSetting(addon,setting,ply)
	if _G[addon] && _G[addon].Settings && _G[addon].Settings[setting] then
		local typ = TypeID(_G[addon].Settings[setting])
		net.Start("arclib_comm_client_settings_changed")
		net.WriteString("addon")
		net.WriteUInt(typ,16)
		net.WriteString(setting)
		if typ == TYPE_NUMBER then
			val = net.WriteDouble(_G[addon].Settings[setting])
		elseif typ == TYPE_STRING then
			val = net.WriteString(_G[addon].Settings[setting])
		elseif typ == TYPE_BOOL then
			val = net.WriteBit(_G[addon].Settings[setting])
		elseif typ == TYPE_TABLE then
			net.WriteTable(_G[addon].Settings[setting])
		else
			error("Server attempted to send unknown setting type. (wat)")
		end
		net.Send(ply)
	end
end

function ARCLib.AddSettingConsoleCommands(addon)

	local VarTypeExamples = {}
	VarTypeExamples["list"] = {"aritz,snow,cathy,kenzie,isaac,tasha,bubby","bob,joe,frank,bill","red,green,blue,yellow","lol,wtf,omg,rly"}
	VarTypeExamples["number"] = {"1337","15","27","9","69","19970415"}
	VarTypeExamples["boolean"] = {"true","false"}
	VarTypeExamples["string"] = {"word","helloworld","iloveyou","MONEY!","bob","aritz"}

	_G[addon].Commands["settings"] = {
		command = function(ply,args) 
			if !_G[addon].Loaded then _G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.SysReset) return end
			if !args[1] then _G[addon].MsgCL(ply,"You didn't enter a setting!") return end
			if _G[addon].Settings[args[1]] || isbool(_G[addon].Settings[args[1]]) then
				if isnumber(_G[addon].Settings[args[1]]) then
					if tonumber(args[2]) then
						_G[addon].Settings[args[1]] = tonumber(args[2])
						
						
						for k,v in pairs(player.GetAll()) do
							_G[addon].MsgCL(v,string.Replace( string.Replace( _G[addon].Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", tostring(tonumber(args[2])) ))
							
						end
					else
						_G[addon].MsgCL(ply,"You cannot set "..args[1].." to "..tostring(tonumber(args[2])))
					end
				elseif istable(_G[addon].Settings[args[1]]) then
					if args[2] == "" || args[2] == " " then
						_G[addon].Settings[args[1]] = {}
					else
						_G[addon].Settings[args[1]] = string.Explode( ",", args[2])
					end
					for k,v in pairs(player.GetAll()) do
						_G[addon].MsgCL(v,string.Replace( string.Replace( _G[addon].Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", args[2] ))
					end
				elseif isstring(_G[addon].Settings[args[1]]) then
					_G[addon].Settings[args[1]] = args[2]--string.gsub(args[2], "[^_%w]", "_")
					for k,v in pairs(player.GetAll()) do
						_G[addon].MsgCL(v,string.Replace( string.Replace( _G[addon].Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", args[2] ))
					end
				elseif isbool(_G[addon].Settings[args[1]]) then
					_G[addon].Settings[args[1]] = tobool(args[2])
					for k,v in pairs(player.GetAll()) do
						_G[addon].MsgCL(v,string.Replace( string.Replace( _G[addon].Msgs.CommandOutput.SysSetting, "%SETTING%",args[1]), "%VALUE%", tostring(tobool(args[2])) ))
					end
				end
				ARCLib.UpdateAddonSetting(addon,args[1],player.GetAll())
			else
				_G[addon].MsgCL(ply,"Invalid setting "..args[1])
			end
		end, 
		usage = " <setting(str)> <value(any)>",
		description = "Changes settings (see settings_help)",
		adminonly = true,
		hidden = false
	}
	_G[addon].Commands["settings"] = {
		command = function(ply,args) 
			if !_G[addon].Loaded then _G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.SysReset) return end
			if !args[1] then 
				for k,v in SortedPairs(_G[addon].Settings) do
					if istable(v) then
						local s = ""
						for o,p in pairs(v) do
							if o > 1 then
								s = s..","..p
							else
								s = p
							end
						end
						_G[addon].MsgCL(ply,tostring(k).." = "..s)
					else
						_G[addon].MsgCL(ply,tostring(k).." = "..tostring(v))
					end
				end
				_G[addon].MsgCL(ply,"Type 'settings_help (setting) for a more detailed description of a setting.")
				return
			end
			if _G[addon].Settings[args[1]] || isbool(_G[addon].Settings[args[1]]) then
				if isnumber(_G[addon].Settings[args[1]]) then
					_G[addon].MsgCL(ply,"Type: number")
					_G[addon].MsgCL(ply,"Example: "..args[1].." "..table.Random(VarTypeExamples["number"]))
					_G[addon].MsgCL(ply,"Description: "..tostring(_G[addon].SettingsDesc[args[1]]))
					_G[addon].MsgCL(ply,"Currently set to: "..tostring(_G[addon].Settings[args[1]]))
				elseif istable(_G[addon].Settings[args[1]]) then
					local s = ""
					for o,p in pairs(_G[addon].Settings[args[1]]) do
						if o > 1 then
							s = s..","..p
						else
							s = p
						end
					end
					_G[addon].MsgCL(ply,"Type: list")
					_G[addon].MsgCL(ply,"Example: "..args[1].." "..table.Random(VarTypeExamples["list"]))
					_G[addon].MsgCL(ply,"Description: "..tostring(_G[addon].SettingsDesc[args[1]]))
					_G[addon].MsgCL(ply,"Currently set to: "..s)
				elseif isstring(_G[addon].Settings[args[1]]) then
					_G[addon].MsgCL(ply,"Type: string")
					_G[addon].MsgCL(ply,"Example: "..args[1].." "..table.Random(VarTypeExamples["string"]))
					_G[addon].MsgCL(ply,"Description: "..tostring(_G[addon].SettingsDesc[args[1]]))
					_G[addon].MsgCL(ply,"Currently set to: ".._G[addon].Settings[args[1]])
				elseif isbool(_G[addon].Settings[args[1]]) then
					_G[addon].MsgCL(ply,"Type: boolean")
					_G[addon].MsgCL(ply,"Example: "..args[1].." "..table.Random(VarTypeExamples["boolean"]))
					_G[addon].MsgCL(ply,"Description: "..tostring(_G[addon].SettingsDesc[args[1]]))
					_G[addon].MsgCL(ply,"Currently set to: "..tostring(_G[addon].Settings[args[1]]))
				end
			else
				_G[addon].MsgCL(ply,"Invalid setting")
			end
		end, 
		usage = " [setting(str)]",
		description = "Shows you and gives you a description of all the settings",
		adminonly = false,
		hidden = false
	}
	_G[addon].Commands["settings_save"] = {
		command = function(ply,args) 
			if !_G[addon].Loaded then _G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.SysReset) return end
			file.Write(_G[addon].Dir.."/_saved_settings.txt",util.TableToJSON(_G[addon].Settings))
			if file.Exists(_G[addon].Dir.."/_saved_settings.txt","DATA") then
				_G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.SettingsSaved)
				_G[addon].Msg(_G[addon].Msgs.CommandOutput.SettingsSaved)
			else
				_G[addon].MsgCL(ply,_G[addon].Msgs.CommandOutput.SettingsError)
				_G[addon].Msg(_G[addon].Msgs.CommandOutput.SettingsError)
			end
		end, 
		usage = "",
		description = "Saves the current settings to the disk",
		adminonly = true,
		hidden = false
	}
end


function ARCLib.AddonLoadSettings(addon,backward)
	if file.Exists(_G[addon].Dir.."/_saved_settings.txt","DATA") then
		local disksettings = util.JSONToTable(file.Read(_G[addon].Dir.."/_saved_settings.txt","DATA"))
		if disksettings then
			for k,v in pairs(_G[addon].Settings) do
				if disksettings[k] == nil then
					_G[addon].Msg(""..k.." not found in disk settings. Possibly out of date. Using default.")				
				else
					_G[addon].Settings[k] = disksettings[k]
				end
			end
			if istable(backward) then
				for k,v in pairs(backward) do
					if disksettings[k] then
						_G[addon].Settings[v] = disksettings[k]
					end
				end
			end
			_G[addon].Msg("Settings succesfully set.")
		else
			_G[addon].Msg("Settings file is corrupt or something! Using defaults.")
		end
	else
		_G[addon].Msg("No settings file found! Using defaults.")
	end
end
