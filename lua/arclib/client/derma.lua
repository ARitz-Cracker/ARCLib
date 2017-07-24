local PANEL = {}

AccessorFunc( PANEL, "m_fFraction", "Fraction" )

Derma_Hook( PANEL, "Paint", "Paint", "Progress" )

function PANEL:Init()
	self:SetMouseInputEnabled( false )
	self:SetFraction( 0 )
end
local oldPaint = PANEL.Paint
function PANEL:Paint(w,h)
	if (self.endStart) then
	
		self.m_fFraction = self.endProgress + (ARCLib.BetweenNumberScale(self.endStart,SysTime(),self.endEnd)^2)*self.endMul
		if (SysTime() > self.endEnd) then
			self.m_fFraction = 1
			self.t = nil
			self.endProgress = nil
			self.endMul = nil
			self.endStart = nil
			self.endEnd = nil
			if isfunction(self.callback) then
				self.callback()
			end
		end
	elseif (self.t) then
		--print(SysTime()-self.t)
		self.m_fFraction = self:ProgressFunc(SysTime()-self.t)
		--print(self.m_fFraction)
	end
	oldPaint(self,w,h)
end
function PANEL:StartProgress()
	self.t = SysTime()
	self.endStart = nil
end
function PANEL:StopProgress(t,cb)
	self.callback = cb
	self.endProgress = self.m_fFraction
	self.endMul = 1 - self.endProgress
	self.endStart = SysTime()
	self.endEnd = self.endStart + (tonumber(t) or 1)
end

-- Found by playing with a graphing calculator
function PANEL:ProgressFunc(x)
	return (((x+100)^2)-10000)/((x+100)^2)
end
-- Derivative of above function
function PANEL:ProgressFuncDeriv(x)
	return 20000/((x+100)^3)
end

derma.DefineControl( "DProgressFake", "", PANEL, "Panel" )

--[[]
local p
function ARCLib.Derma_Progress()
	local Window = vgui.Create( "DFrame" )
	Window:SetTitle( "aa" )
	Window:SetDraggable( true )
	Window:ShowCloseButton( true )
	Window:SetSize( 200, 20 + 25 + 75 + 10 )
	Window:Center()
	Window:MakePopup()
	p = vgui.Create( "DProgressFake", Window )
	p:StretchToParent( 5, nil, 5, nil )
	p:AlignBottom( 5 )
	p:StartProgress()
end

function ARCLib.Derma_ProgressStop(t)
	p:StopProgress(t,function()
		print("done!")
	end)
end
--]]


function ARCLib.Derma_NumberRequest( strTitle, strText, numMin, numMax, numDefault, fnEnter, fnCancel, strButtonText, strButtonCancelText )
	numMin = numMin or 0
	numMax = numMax or 100
	local Window = vgui.Create( "DFrame" )
		Window:SetTitle( strTitle or "Message Title (First Parameter)" )
		Window:SetDraggable( false )
		Window:ShowCloseButton( false )
		Window:SetBackgroundBlur( true )
		Window:SetDrawOnTop( true )
		
	local InnerPanel = vgui.Create( "DPanel", Window )
		InnerPanel:SetDrawBackground( false )
	
	local Text = vgui.Create( "DLabel", InnerPanel )
		Text:SetText( strText or "Message Text (Second Parameter)" )
		Text:SizeToContents()
		Text:SetContentAlignment( 5 )
		Text:SetTextColor( color_white )
		
	local TextEntry = vgui.Create( "Slider", InnerPanel )
		TextEntry:SetMin(numMin)
		TextEntry:SetMax(numMax)
		TextEntry:SetDecimals( 0 )
		TextEntry:SetValue( numDefault or ((numMin+numMax)/2) )
	local ButtonPanel = vgui.Create( "DPanel", Window )
		ButtonPanel:SetTall( 30 )
		ButtonPanel:SetDrawBackground( false )
		
	local Button = vgui.Create( "DButton", ButtonPanel )
		Button:SetText( strButtonText or "OK" )
		Button:SizeToContents()
		Button:SetTall( 20 )
		Button:SetWide( Button:GetWide() + 20 )
		Button:SetPos( 5, 5 )
		Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
		
	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
		ButtonCancel:SetText( strButtonCancelText or "Cancel" )
		ButtonCancel:SizeToContents()
		ButtonCancel:SetTall( 20 )
		ButtonCancel:SetWide( Button:GetWide() + 20 )
		ButtonCancel:SetPos( 5, 5 )
		ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
		ButtonCancel:MoveRightOf( Button, 5 )
		
	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
	
	local w, h = Text:GetSize()
	w = math.max( w, 400 ) 
	
	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()
	
	InnerPanel:StretchToParent( 5, 25, 5, 45 )
	
	Text:StretchToParent( 5, 5, 5, 35 )	
	
	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )
	
	--TextEntry:RequestFocus()
	--TextEntry:SelectAllText( true )
	
	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )
	
	Window:MakePopup()
	Window:DoModal()
	return Window

end

function ARCLib.Derma_ChoiceRequest( strTitle, strText, choiceNames, choiceValues, default, fnEnter, fnCancel, strButtonText, strButtonCancelText )
	local choiceLen = #choiceNames
	if choiceLen != #choiceValues then
		error("ARCLib.Derma_NumberRequest: choiceNames and choiceValues are not the same length")
	end
	default = default or 1
	if default <= 0 or default > choiceLen then
		error("ARCLib.Derma_NumberRequest: default choice is out of range!")
	end
	
	local choice = choiceValues[default]
	local Window = vgui.Create( "DFrame" )
		Window:SetTitle( strTitle or "Message Title (First Parameter)" )
		Window:SetDraggable( false )
		Window:ShowCloseButton( false )
		Window:SetBackgroundBlur( true )
		Window:SetDrawOnTop( true )
		
	local InnerPanel = vgui.Create( "DPanel", Window )
		InnerPanel:SetDrawBackground( false )
	
	local Text = vgui.Create( "DLabel", InnerPanel )
		Text:SetText( strText or "Message Text (Second Parameter)" )
		Text:SizeToContents()
		Text:SetContentAlignment( 5 )
		Text:SetTextColor( color_white )
		
	local TextEntry = vgui.Create( "DComboBox", InnerPanel )
		TextEntry:SetValue(choiceNames[default])
		for i=1,choiceLen do
			TextEntry:AddChoice(choiceNames[i])
		end
		TextEntry.OnSelect = function( panel, index, value )
			choice = choiceValues[index]
		end
		
	local ButtonPanel = vgui.Create( "DPanel", Window )
		ButtonPanel:SetTall( 30 )
		ButtonPanel:SetDrawBackground( false )
		
	local Button = vgui.Create( "DButton", ButtonPanel )
		Button:SetText( strButtonText or "OK" )
		Button:SizeToContents()
		Button:SetTall( 20 )
		Button:SetWide( Button:GetWide() + 20 )
		Button:SetPos( 5, 5 )
		Button.DoClick = function() Window:Close() fnEnter( choice) end
		
	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
		ButtonCancel:SetText( strButtonCancelText or "Cancel" )
		ButtonCancel:SizeToContents()
		ButtonCancel:SetTall( 20 )
		ButtonCancel:SetWide( Button:GetWide() + 20 )
		ButtonCancel:SetPos( 5, 5 )
		ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( choice ) end end
		ButtonCancel:MoveRightOf( Button, 5 )
		
	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
	
	local w, h = Text:GetSize()
	w = math.max( w, 400 ) 
	
	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()
	
	InnerPanel:StretchToParent( 5, 25, 5, 45 )
	
	Text:StretchToParent( 5, 5, 5, 35 )	
	
	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )
	
	--TextEntry:RequestFocus()
	--TextEntry:SelectAllText( true )
	
	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )
	
	Window:MakePopup()
	--Window:DoModal()
	return Window

end

