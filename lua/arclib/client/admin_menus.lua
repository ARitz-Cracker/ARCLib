-- admin_menus.lua -- for addons that want to take advantage of the admin gui

net.Receive( "arclib_comm_client_settings", function(length)
	local addon = net.ReadString()
	local len = net.ReadUInt(32)
	if _G[addon] && _G[addon].Settings then
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
	elseif typ == TYPE_STRING then
		val = net.ReadString()
	elseif typ == TYPE_BOOL then
		val = tobool(net.ReadBit())
	elseif typ == TYPE_TABLE then
		net.ReadTable()
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
	local SettingBool = vgui.Create( "DCheckBoxLabel", SettingsContainer )
	SettingBool:SetPos( 12, 92 )
	SettingBool:SetText( "Enable" )
	SettingBool:SetValue( 1 )
	SettingBool:SizeToContents()
	SettingBool:SetVisible(false)
	SettingBool:SetDark( 1 )
	local SettingNum = vgui.Create( "DNumberWang", SettingsContainer )
	SettingNum:SetPos( 10, 92 )
	SettingNum:SetSize( 265, 20 )
	SettingNum:SetValue( 1 )
	SettingNum:SetVisible(false)
	SettingNum:SetMinMax( 0 , 1000000 )
	SettingNum:SetDecimals(4)
	local SettingStr = vgui.Create( "DTextEntry", SettingsContainer )
	SettingStr:SetPos( 12,92 )
	SettingStr:SetTall( 20 )
	SettingStr:SetWide( 265 )
	SettingStr:SetVisible(false)
	SettingStr:SetEnterAllowed( true )
	local SettingsTabContainer = vgui.Create( "DPanel",SettingsContainer)
	SettingsTabContainer:SetPos(10,92)
	SettingsTabContainer:SetSize( 265, 50 )
	SettingsTabContainer:SetVisible(false)
	local SettingTab = vgui.Create( "DComboBox", SettingsTabContainer )
	SettingTab:SetPos( 0,0 )
	SettingTab:SetSize( 210, 20 )
	function SettingTab:OnSelect(index,value,data)
		SettingTab.Selection = value
	end
	local SettingTaba = vgui.Create( "DTextEntry", SettingsTabContainer )
	SettingTaba:SetPos( 0,30 )
	SettingTaba:SetTall( 20 )
	SettingTaba:SetWide( 210 )
	--SettingTaba:SetVisible(false)
	SettingTaba:SetEnterAllowed( true )

	local SettingRemove = vgui.Create( "DButton", SettingsTabContainer )
	SettingRemove:SetText( "Remove" )
	SettingRemove:SetPos( 210, 0 )
	SettingRemove:SetSize( 55, 20 )
	local SettingAdd = vgui.Create( "DButton", SettingsTabContainer )
	SettingAdd:SetText( "Add" )
	SettingAdd:SetPos( 210, 30)
	SettingAdd:SetSize( 55, 20 )

	function AList1:OnSelect(index,value,data)
		SettingDesc:SetText("Description:\n"..tostring(_G[addon].SettingsDesc[value]));
		--SettingDesc:SizeToContents();
			SettingBool.OnChange = function( pan, val ) end
			SettingStr.OnValueChanged = function( pan, val ) end
			SettingStr.OnEnter = function() end
			SettingNum.OnValueChanged = function( pan, val ) end
		if isnumber(settings[value]) then
			SettingBool:SetVisible(false)
			SettingNum:SetVisible(true)
			SettingStr:SetVisible(false)
			SettingsTabContainer:SetVisible(false)
			SettingNum:SetValue( settings[value] )
			SettingNum.OnValueChanged = function( pan, val )
				RunConsoleCommand( cmd,"settings",value,tostring(val))
			end
		elseif istable(settings[value]) then
			SettingNum:SetVisible(false)
			SettingBool:SetVisible(false)
			SettingStr:SetVisible(false)
			SettingsTabContainer:SetVisible(true)
			SettingTab:Clear()
			SettingTab.Selection = ""
			for k,v in pairs(settings[value]) do
				SettingTab:AddChoice(v)
			end
			SettingAdd.DoClick = function()
				
				table.insert( settings[value], SettingTaba:GetValue() )
				string.Replace(SettingTaba:GetValue(), ",", "_")
				local s = ""
				for o,p in pairs(settings[value]) do
					if o > 1 then
						s = s..","..p
					else
						s = p
					end
				end
				RunConsoleCommand( cmd,"settings",value,s)
				SettingTab:AddChoice(SettingTaba:GetValue())
				SettingTaba:SetValue("")
			end	
			SettingRemove.DoClick = function()
				table.RemoveByValue( settings[value], SettingTab.Selection )
				local s = ""
				for o,p in pairs(settings[value]) do
					if o > 1 then
						s = s..","..p
					else
						s = p
					end
				end
				SettingTab:Clear()
				for k,v in pairs(settings[value]) do
					SettingTab:AddChoice(v)
				end
				RunConsoleCommand( cmd,"settings",value,s)
			end
		elseif isstring(settings[value]) then
			SettingNum:SetVisible(false)
			SettingBool:SetVisible(false)
			SettingStr:SetVisible(true)
			SettingsTabContainer:SetVisible(false)
			SettingStr:SetValue( settings[value] )
			SettingStr.OnValueChange = function( pan, val )
				RunConsoleCommand( cmd,"settings",value,tostring(val))
			end
			SettingStr.OnEnter = function()
				RunConsoleCommand( cmd, "settings",value,SettingStr:GetValue())
			end
		elseif isbool(settings[value]) then
			SettingNum:SetVisible(false)
			SettingBool:SetVisible(true)
			SettingStr:SetVisible(false)
			SettingsTabContainer:SetVisible(false)
			SettingBool:SetValue( ARCLib.BoolToNumber(settings[value]) )
			SettingBool.OnChange = function( pan, val )
				RunConsoleCommand( cmd, "settings",value,tostring(val))
			end
		end
	end
end

