local UpdateLang_Progress = {}
local UpdateLang_Chunks = {}
net.Receive( "arclib_comm_lang", function(length)
	local addon = net.ReadString()
	if !UpdateLang_Progress[addon] then UpdateLang_Progress[addon] = 0 end
	if !UpdateLang_Chunks[addon] then UpdateLang_Chunks[addon] = "" end
	local succ = net.ReadInt(ARCBANK_ERRORBITRATE)
	local part = net.ReadUInt(32)
	if part == 0 then
		UpdateLang_Progress[addon] = 0
		UpdateLang_Chunks[addon] = ""
	end
	local whole = net.ReadUInt(32)
	local chunklen = net.ReadUInt(32)
	local str = ""
	if (chunklen > 0) then
		str = net.ReadData(chunklen)
	end
	if succ == 0 then
		if part != UpdateLang_Progress[addon] then
			MsgN(addon..": Chuck Mismatch Error while loading language. Possibly due to lag.")
		else
			UpdateLang_Chunks[addon] = UpdateLang_Chunks[addon] .. str
			if part == whole then
				local tab = util.JSONToTable(util.Decompress(UpdateLang_Chunks[addon]))
				if tab then
					_G[string.upper(addon).."_ERRORSTRINGS"] = ARCLib.RecursiveTableMerge(_G[string.upper(addon).."_ERRORSTRINGS"],tab.errmsgs)
					_G[addon].Msgs = ARCLib.RecursiveTableMerge(_G[addon].Msgs,tab.msgs)
					_G[addon].SettingsDesc = ARCLib.RecursiveTableMerge(_G[addon].SettingsDesc,tab.settingsdesc)
				end
				UpdateLang_Chunks[addon] = ""
				UpdateLang_Progress[addon] = 0
				net.Start("arclib_comm_lang")
				net.WriteString(addon)
				net.WriteUInt(0,32)
				net.WriteUInt(0,32)
				net.SendToServer()
			else
				net.Start("arclib_comm_lang")
				net.WriteString(addon)
				net.WriteUInt(part,32)
				net.WriteUInt(whole,32)
				net.SendToServer()
				UpdateLang_Progress[addon] = UpdateLang_Progress[addon] + 1
			end
		end
	else
		MsgN(addon..": Server said you errored or something ("..succ..")")
	end
end)

