-- admin_menus.lua -- for addons that want to take advantage of the admin gui

net.Receive( "arclib_comm_client_settings", function(length)
	local addon = net.ReadString()
	if _G[addon] && _G[addon].Settings then
		_G[addon].SettingType = net.ReadTable()
		local len = net.ReadUInt(32)
		_G[addon].SettingMultichoices = util.JSONToTable(util.Decompress(net.ReadData(len)))
		len = net.ReadUInt(32)
		_G[addon].Settings = util.JSONToTable(util.Decompress(net.ReadData(len)))
		if _G[addon].OnSettingChanged then
			for k,v in pairs(_G[addon].Settings) do
				_G[addon].OnSettingChanged(k,v)
			end
		end
	end
end)

net.Receive( "arclib_comm_client_settings_changed", function(length)
	local addon = net.ReadString()
	local typ = net.ReadUInt(16)
	local stn = net.ReadString()
	local val
	if typ == TYPE_NUMBER then
		val = net.ReadDouble()
	elseif typ == TYPE_STRING || typ == TYPE_ARCLIB_MULTICHOICE then
		val = net.ReadString()
	elseif typ == TYPE_BOOL then
		val = tobool(net.ReadBit())
	elseif typ == TYPE_TABLE then
		val = net.ReadTable()
	else
		error("Server attempted to send unknown setting type. (wat)")
	end
	if _G[addon] && _G[addon].Settings then
		_G[addon].Settings[stn] = val
	end
	if _G[addon].OnSettingChanged then
		_G[addon].OnSettingChanged(stn,val)
	end
end)

function ARCLib.AddonConfigMenu(addon,cmd)
	local SettingsWindow = vgui.Create( "DFrame" )
	SettingsWindow:SetSize( 295,215 )
	SettingsWindow:Center()
	SettingsWindow:SetTitle( _G[addon].Msgs.AdminMenu.Settings )
	SettingsWindow:SetVisible( true )
	SettingsWindow:SetDraggable( true )
	SettingsWindow:ShowCloseButton( true )
	SettingsWindow:MakePopup()




	
	local settings = _G[addon].Settings
	local SettingsContainer = vgui.Create( "DPanel",SettingsWindow)
	SettingsContainer:SetPos( 5, 30 )
	SettingsContainer:SetSize( 285, 180 )
	local AList1= vgui.Create( "DComboBox",SettingsContainer)
	AList1:SetPos(10,10)
	AList1:SetSize( 265, 20 )
	AList1:SetText( _G[addon].Msgs.AdminMenu.ChooseSetting..":" )
	for k,v in SortedPairs(settings) do
		AList1:AddChoice(k)
	end

	local SettingSave = vgui.Create( "DButton", SettingsContainer )
	SettingSave:SetText( _G[addon].Msgs.AdminMenu.SaveSettings )
	SettingSave:SetPos( 10, 152 )
	SettingSave:SetSize( 265, 20 )
	SettingSave.DoClick = function()
		RunConsoleCommand( cmd,"settings_save")
	end
	local SettingDesc = vgui.Create( "DLabel", SettingsContainer )
	SettingDesc:SetPos( 12, 35 ) -- Set the position of the label
	SettingDesc:SetText( _G[addon].Msgs.AdminMenu.ChooseSetting ) --  Set the text of the label
	SettingDesc:SetWrap(true)
	SettingDesc:SetSize( 265, 50 )
--		SettingDesc:SizeToContents() -- Size the label to fit the text in it
	SettingDesc:SetDark( 1 ) -- Set the colour of the text inside the label to a darker one
	
	local SettingSelectors = {}
	
	SettingSelectors[TYPE_BOOL] = vgui.Create( "DCheckBoxLabel", SettingsContainer )
	SettingSelectors[TYPE_BOOL]:SetPos( 12, 92 )
	SettingSelectors[TYPE_BOOL]:SetText( _G[addon].Msgs.AdminMenu.Enable or "Enable" )
	SettingSelectors[TYPE_BOOL]:SetValue( 1 )
	SettingSelectors[TYPE_BOOL]:SizeToContents()
	SettingSelectors[TYPE_BOOL]:SetVisible(false)
	SettingSelectors[TYPE_BOOL]:SetDark( 1 )
	SettingSelectors[TYPE_NUMBER] = vgui.Create( "DNumberWang", SettingsContainer )
	SettingSelectors[TYPE_NUMBER]:SetPos( 10, 92 )
	SettingSelectors[TYPE_NUMBER]:SetSize( 265, 20 )
	SettingSelectors[TYPE_NUMBER]:SetValue( 1 )
	SettingSelectors[TYPE_NUMBER]:SetVisible(false)
	SettingSelectors[TYPE_NUMBER]:SetMinMax( 0 , 99999999999999 )
	SettingSelectors[TYPE_NUMBER]:SetDecimals(4)
	SettingSelectors[TYPE_STRING] = vgui.Create( "DTextEntry", SettingsContainer )
	SettingSelectors[TYPE_STRING]:SetPos( 12,92 )
	SettingSelectors[TYPE_STRING]:SetTall( 20 )
	SettingSelectors[TYPE_STRING]:SetWide( 265 )
	SettingSelectors[TYPE_STRING]:SetVisible(false)
	SettingSelectors[TYPE_STRING]:SetEnterAllowed( true )
	SettingSelectors[TYPE_TABLE] = vgui.Create( "DPanel",SettingsContainer)
	SettingSelectors[TYPE_TABLE]:SetPos(10,92)
	SettingSelectors[TYPE_TABLE]:SetSize( 265, 50 )
	SettingSelectors[TYPE_TABLE]:SetVisible(false)
	
	SettingSelectors[TYPE_ARCLIB_MULTICHOICE] = vgui.Create( "DComboBox", SettingsContainer )
	SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:SetPos( 12,92 )
	SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:SetTall( 20 )
	SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:SetWide( 265 )
	SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:SetVisible(false)
	
	local SettingTab = vgui.Create( "DComboBox", SettingSelectors[TYPE_TABLE] )
	SettingTab:SetPos( 0,0 )
	SettingTab:SetSize( 210, 20 )
	function SettingTab:OnSelect(index,value,data)
		SettingTab.Selection = value
	end
	local SettingTaba = vgui.Create( "DTextEntry", SettingSelectors[TYPE_TABLE] )
	SettingTaba:SetPos( 0,30 )
	SettingTaba:SetTall( 20 )
	SettingTaba:SetWide( 210 )
	--SettingTaba:SetVisible(false)
	SettingTaba:SetEnterAllowed( true )

	local SettingRemove = vgui.Create( "DButton", SettingSelectors[TYPE_TABLE] )
	SettingRemove:SetText( _G[addon].Msgs.AdminMenu.Remove or "Remove" )
	SettingRemove:SetPos( 210, 0 )
	SettingRemove:SetSize( 55, 20 )
	local SettingAdd = vgui.Create( "DButton", SettingSelectors[TYPE_TABLE] )
	SettingAdd:SetText( _G[addon].Msgs.AdminMenu.Add or "Add" )
	SettingAdd:SetPos( 210, 30)
	SettingAdd:SetSize( 55, 20 )

	function AList1:OnSelect(index,setting,data)
		local typ = _G[addon].SettingType[setting] || TypeID(settings[setting])
	
		SettingDesc:SetText(tostring(_G[addon].SettingsDesc[setting]))
		
		for k,v in pairs(SettingSelectors) do
			v:SetVisible(k == typ)
		end
		--SettingDesc:SizeToContents();
		SettingSelectors[TYPE_BOOL].OnChange = NULLFUNC
		SettingSelectors[TYPE_STRING].OnValueChanged = NULLFUNC
		SettingSelectors[TYPE_STRING].OnEnter = NULLFUNC
		SettingSelectors[TYPE_NUMBER].OnValueChanged = NULLFUNC
		SettingSelectors[TYPE_ARCLIB_MULTICHOICE].OnSelect = NULLFUNC
			
		if typ == TYPE_NUMBER then
			SettingSelectors[TYPE_NUMBER]:SetValue( settings[setting] )
			SettingSelectors[TYPE_NUMBER].OnValueChanged = function( pan, val )
				RunConsoleCommand( cmd,"settings",setting,tostring(val))
			end
		elseif typ == TYPE_ARCLIB_MULTICHOICE then
			SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:Clear()
			for k,v in pairs(_G[addon].SettingMultichoices[setting]) do
				SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:AddChoice( k, v )
			end
			SettingSelectors[TYPE_ARCLIB_MULTICHOICE]:SetText(settings[setting])
			SettingSelectors[TYPE_ARCLIB_MULTICHOICE].OnSelect = function( panel, index, value )
				print( RunConsoleCommand( cmd,"settings",setting , panel:GetOptionData( index )))
			end
		elseif typ == TYPE_TABLE then
			SettingTab:Clear()
			SettingTab.Selection = ""
			for k,v in pairs(settings[setting]) do
				SettingTab:AddChoice(v)
			end
			SettingAdd.DoClick = function()
				
				table.insert( settings[setting], SettingTaba:GetValue() )
				string.Replace(SettingTaba:GetValue(), ",", "_")
				local s = ""
				for o,p in pairs(settings[setting]) do
					if o > 1 then
						s = s..","..p
					else
						s = p
					end
				end
				RunConsoleCommand( cmd,"settings",setting,s)
				SettingTab:AddChoice(SettingTaba:GetValue())
				SettingTaba:SetValue("")
			end	
			SettingRemove.DoClick = function()
				table.RemoveByValue( settings[setting], SettingTab.Selection )
				local s = ""
				for o,p in pairs(settings[setting]) do
					if o > 1 then
						s = s..","..p
					else
						s = p
					end
				end
				SettingTab:Clear()
				for k,v in pairs(settings[setting]) do
					SettingTab:AddChoice(v)
				end
				RunConsoleCommand( cmd,"settings",setting,s)
			end
		elseif typ == TYPE_STRING then
			SettingSelectors[TYPE_STRING]:SetValue( settings[setting] )
			SettingSelectors[TYPE_STRING].OnKeyCodeTyped = function( pan, val )
				RunConsoleCommand( cmd,"settings",setting,SettingSelectors[TYPE_STRING]:GetValue())
			end
			SettingSelectors[TYPE_STRING].OnEnter = function()
				RunConsoleCommand( cmd, "settings",setting,SettingSelectors[TYPE_STRING]:GetValue())
			end
		elseif typ == TYPE_BOOL then
			SettingSelectors[TYPE_BOOL]:SetValue( ARCLib.BoolToNumber(settings[setting]) )
			SettingSelectors[TYPE_BOOL].OnChange = function( pan, val )
				RunConsoleCommand( cmd, "settings",setting,tostring(val))
			end
		end
	end
end

