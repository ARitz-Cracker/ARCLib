-- String stuffs

function ARCLib.TimeString(sec,tab) -- Converts seconds to a human-readable form. Also, string.NiceTime is terrible.
	if(!tab || tab == {}) then -- I don't really like this, but it's for the sake of making it translatable!
		tab = {}
		tab.nd = "and"
		tab.second = "second"
		tab.seconds = "seconds"
		tab.minute = "minute"
		tab.minutes = "minutes"
		tab.hour = "hour"
		tab.hours = "hours"
		tab.day = "day"
		tab.days = "days"
		tab.forever = "forever"
		tab.now = "now"
	end
	if !sec || !isnumber(sec) || sec == math.huge then
		return tab.forever
	end
	sec = math.Round(sec)
	local min = math.floor(sec/60)
	local hour = math.floor(sec/3600)
	local day = math.floor(sec/86400)
	if sec <= 0 then
		return tab.now
	end
	if sec == 1 then
		return "1 "..tab.second
	end
	if sec < 60 then
		return ""..sec.." "..tab.seconds
	else
		if min < 60 then
			if min == 1 then
				if (sec%60) == 1 then
					return "1 "..tab.minute.." "..tab.nd.." 1 "..tab.second
				else
					return "1 "..tab.minute.." "..tab.nd.." "..(sec%60).." "..tab.seconds
				end
			else
				if (sec%60) == 1 then
					return ""..min.." "..tab.minutes.." "..tab.nd.." 1 "..tab.second
				else
					return ""..min.." "..tab.minutes.." "..tab.nd.." "..(sec%60).." "..tab.seconds
				end
			end
		else
			if hour < 24 then
				if hour == 1 then
					if (min%60) == 1 then
						return "1 "..tab.hour.." "..tab.nd.." 1 "..tab.minute
					else
						return "1 "..tab.hour.." "..tab.nd.." "..(min%60).." "..tab.minutes
					end
				else
					if (min%60) == 1 then
						return ""..hour.." "..tab.hours.." "..tab.nd.." 1 "..tab.minute
					else
						return ""..hour.." "..tab.hours.." "..tab.nd.." "..(min%60).." "..tab.minutes
					end
					
				end
			else
				if day == 1 then
					if (hour%24) == 1 then
						return "1 "..tab.day.." "..tab.nd.." 1 "..tab.hour
					else
						return "1 "..tab.day.." "..tab.nd.." "..(hour%24).." "..tab.hours
					end
				else
					if (hour%24) == 1 then
						return ""..day.." "..tab.days.." "..tab.nd.." 1 "..tab.hour
					else
						return ""..day.." "..tab.days.." "..tab.nd.." "..(hour%24).." "..tab.hours
					end
				end
			end
		end
	end
	return tab.forever
end


function ARCLib.SplitString(str,num) -- Splits a string at every num characters
	if !str then return {"nil"} end
	local length = string.len(str)
	if length <= num then return {str} end
	local curtab = 1
	local result = {}
	result[curtab] = ""
	for i=1,length do
		result[curtab] = result[curtab]..str[i]
		if i >= curtab*num then
			curtab = curtab + 1;
			result[curtab] = ""
		end
	end
	return result
end

if !CLIENT then return end -- The following code only functions on the client side since only the client has those surface. functions

if timer.Exists( "ARCLib_DumpCachedStrings" ) then
	timer.Destroy( "ARCLib_DumpCachedStrings" )
end
timer.Create( "ARCLib_DumpCachedStrings", 300, 0, function() 
	ARCLib.CachedStrings = {}
	ARCLib.CachedStringsCut = {}
end )
ARCLib.CachedStrings = {}
ARCLib.CachedStringsCut = {}


function ARCLib.CutOutText(text,font,length) -- Makes the trailing "..." if the text is too wide
	if !isstring(text) then return type(text) end
	if ARCLib.CachedStringsCut[util.CRC(text..font..length)] then -- I wonder if this will actually save performance...
		return ARCLib.CachedStringsCut[util.CRC(text..font..length)]
	end
	surface.SetFont( font )
	local dotslen, _ = surface.GetTextSize("...")
	if dotslen > length then
		return "."
	end
	local txtlen,_ = surface.GetTextSize(text)
	if txtlen <= length then
		return text
	end
	local charplace = 0
	local result = ""
	local curlen,_ = surface.GetTextSize(result)
	while curlen + dotslen < length do
		charplace = charplace + 1
		result = result..text[charplace]
		curlen,_ = surface.GetTextSize(result)
	end
	return string.Left( result, #result-1 ).."..."
end

-- The following 2 functions do the same thing, they are mostly used by my 3D2D displays when I want to fit something in a box. One tries to do it all within the same frame, the other one does it in chunks so the game doesn't freeze.
-- I honestly want to try re-coding these functions some time as they are pretty... hack-ish


function ARCLib.FitText(text,font,length) -- Splits strings for text boxes. (length) is in pix. Supports "\n"
-- TODO: Support UTF-8 characters
if !isstring(text) then return {type(text)} end
--Note: This is a pretty messy thing. DON'T USE EVERY FRAME FOR LOADSA TEXT!
	if ARCLib.CachedStrings[util.CRC(text..font..length)] then -- I wonder if this will actually save performence...
		return ARCLib.CachedStrings[util.CRC(text..font..length)]
	end

	text = string.Replace(text,"\r","") -- What if we're reading a file with \r\n?
	text = string.Replace(text,"\n"," \n")
	surface.SetFont( font )
	local badword = ""
	local OKToGo = true
	local strings = string.Explode(" ",text)
	for k, v in pairs(strings) do -- Quick n' dirty fix TODO: Make it so that strings bigger than length get split at the vowel or something
		strings[k] = v.." "
		local badstring , _ = surface.GetTextSize(strings[k])
		if badstring > length then
			OKToGo = false
			badword = tostring(strings[k])
		end
	end
	
	if OKToGo then
		local tempstring = ""
		local fittedstrings = {}
		local i = 1
		while #strings > 0 do
			--MsgN(#strings)
			local tempstringlen , _ = surface.GetTextSize(tempstring)
			local string1len , _ = surface.GetTextSize(strings[1])
			--MsgN(tempstringlen.."+"..string1len.." <= "..length.." && "..strings[1])
			while (tempstringlen+string1len <= length) && strings[1] do
				
				tempstring = tempstring .. table.remove( strings, 1 )
				tempstringlen , _ = surface.GetTextSize(tempstring)
				if strings[1] then
					string1len , _ = surface.GetTextSize(strings[1])
				else
					string1len = 0
				end
			end
			fittedstrings[i] = tempstring
			tempstring = ""
			i = i + 1
		end
		i = #fittedstrings
		while i > 0 do
			local newlinecheck = string.Explode("\n",fittedstrings[i])
			table.remove(fittedstrings,i)
			local ii = #newlinecheck
			while ii > 0 do
				table.insert(fittedstrings,i,newlinecheck[ii])
				ii = ii - 1
			end
			i = i - 1
		end
		while table.HasValue(fittedstrings,"") do -- Some checks to make sure everything is right
			table.RemoveByValue(fittedstrings,"")
		end
		while table.HasValue(fittedstrings," ") do
			table.RemoveByValue(fittedstrings," ")
		end
		--if #text < 2097152 then
			
			ARCLib.CachedStrings[util.CRC(text..font..length) ] = fittedstrings
		--end
		return fittedstrings
	else
		return {"Word too long.","("..badword..")"}
	end
end

ARCLib.StringThinkPhase = 0
ARCLib.StringThink_Strings = {}
ARCLib.StringThink_i = 1
ARCLib.StringThink_fittedstrings = {}
ARCLib.StringThink_callback = nil
ARCLib.StringThink_Percent = 0
ARCLib.StringThink_tempstring = ""
ARCLib.StringThink_length = 0
ARCLib.StringThink_tempstringlen = nil
ARCLib.StringThink_string1len = nil
ARCLib.StringThink_font = ""
function ARCLib.FitTextRealtime(text,font,length,callback) -- Splits strings for text boxes. (length) is in pix. Supports "\n"
	-- Realtime version, this was made so that your computer doesn't freeze while processing massive amounts of text.
	-- TODO: Support UTF-8 characters
	if !isstring(text) then 
		callback(1,{type(text)})
		return
	end
	if ARCLib.StringThinkPhase > 0 then
		callback(1,{"Busy"})
		return
	end
	text = string.Replace(text,"\r","")
	text = string.Replace(text,"\n"," \n")
	surface.SetFont( font )
	ARCLib.StringThink_font = font
	local badword = ""
	local OKToGo = true
	ARCLib.StringThink_Strings = string.Explode(" ",text)
	for k, v in pairs(ARCLib.StringThink_Strings) do -- Quick n' dirty fix TODO: Make it so that strings bigger than length get split at the vowel or something
		ARCLib.StringThink_Strings[k] = v.." "
		local badstring , _ = surface.GetTextSize(ARCLib.StringThink_Strings[k])
		if badstring > length then
			OKToGo = false
			badword = tostring(ARCLib.StringThink_Strings[k])
		end
	end
	
	if OKToGo then
		ARCLib.StringThink_callback = callback
		ARCLib.StringThinkPhase = 1
		ARCLib.StringThink_length = length
	else
		callback(1,{"Word too long.","("..badword..")"})
	end
end
hook.Add( "Think", "ARCLib Stringthink", function()
	if ARCLib.StringThinkPhase == 1 then
		--MsgN("ARCLib.StringThinkPhase 1")
		ARCLib.StringThink_tempstring = ""
		ARCLib.StringThink_fittedstrings = {}
		ARCLib.StringThink_i = 1
		ARCLib.StringThinkPhase = 2
		ARCLib.LoadPerBase = #ARCLib.StringThink_Strings
	elseif ARCLib.StringThinkPhase == 2 then---
		--MsgN("ARCLib.StringThinkPhase 2")
		local stime = SysTime()
		while SysTime() - stime < 0.01 do
			if #ARCLib.StringThink_Strings > 0 then
				--MsgN(#ARCLib.StringThink_Strings)
				surface.SetFont( ARCLib.StringThink_font )
				ARCLib.StringThink_tempstringlen , _ = surface.GetTextSize(ARCLib.StringThink_tempstring)
				ARCLib.StringThink_string1len , _ = surface.GetTextSize(ARCLib.StringThink_Strings[1])
				while (ARCLib.StringThink_tempstringlen+ARCLib.StringThink_string1len <= ARCLib.StringThink_length) && ARCLib.StringThink_Strings[1] do
					ARCLib.StringThink_tempstring = ARCLib.StringThink_tempstring .. table.remove( ARCLib.StringThink_Strings, 1 )
					ARCLib.StringThink_tempstringlen , _ = surface.GetTextSize(ARCLib.StringThink_tempstring)
					if ARCLib.StringThink_Strings[1] then
						ARCLib.StringThink_string1len , _ = surface.GetTextSize(ARCLib.StringThink_Strings[1])
					else
						ARCLib.StringThink_string1len = 0
					end
				end
				
				ARCLib.StringThink_fittedstrings[ARCLib.StringThink_i] = ARCLib.StringThink_tempstring
				ARCLib.StringThink_tempstring = ""
				ARCLib.StringThink_i = ARCLib.StringThink_i + 1
			else
				ARCLib.StringThinkPhase = 3
			end
		end
		local per = (#ARCLib.StringThink_Strings/ARCLib.LoadPerBase - 1)*-1
		ARCLib.StringThink_callback(per*0.5,"Loading... ("..math.floor(per * 50).."%)")
	elseif ARCLib.StringThinkPhase == 3 then
		--MsgN("ARCLib.StringThinkPhase 3")
		ARCLib.LoadPerBase = #ARCLib.StringThink_fittedstrings
		ARCLib.StringThink_i = #ARCLib.StringThink_fittedstrings
		ARCLib.StringThinkPhase = 4
	elseif ARCLib.StringThinkPhase == 4 then
		--MsgN("ARCLib.StringThinkPhase 4")
		local stime = SysTime()
		while SysTime() - stime < 0.01 do
			if ARCLib.StringThink_i > 0 then
				--MsgN(ARCLib.StringThink_i)
				local newlinecheck = string.Explode("\n",ARCLib.StringThink_fittedstrings[ARCLib.StringThink_i])
				table.remove(ARCLib.StringThink_fittedstrings,ARCLib.StringThink_i)
				local ii = #newlinecheck
				while ii > 0 do
					table.insert(ARCLib.StringThink_fittedstrings,ARCLib.StringThink_i,newlinecheck[ii])
					ii = ii - 1
				end
				ARCLib.StringThink_i = ARCLib.StringThink_i - 1
			else
				ARCLib.StringThinkPhase = 5
			end
		end
		local per = (ARCLib.StringThink_i/ARCLib.LoadPerBase - 1)*-1
		ARCLib.StringThink_callback(0.5 + per*0.5,"Loading... ("..math.floor(50 + per * 50).."%)")
	elseif ARCLib.StringThinkPhase == 5 then
		--MsgN("ARCLib.StringThinkPhase 5")
		while table.HasValue(ARCLib.StringThink_fittedstrings,"") do -- Some checks to make sure everything is right
			table.RemoveByValue(ARCLib.StringThink_fittedstrings,"")
		end
		while table.HasValue(ARCLib.StringThink_fittedstrings," ") do
			table.RemoveByValue(ARCLib.StringThink_fittedstrings," ")
		end
		ARCLib.StringThink_callback(1,ARCLib.StringThink_fittedstrings)
		ARCLib.StringThinkPhase = 0
		ARCLib.StringThink_Strings = {}
		ARCLib.StringThink_i = 1
		ARCLib.StringThink_fittedstrings = {}
		ARCLib.StringThink_callback = nil
		ARCLib.StringThink_Percent = 0
		ARCLib.StringThink_tempstring = ""
		ARCLib.StringThink_length = 0
	end
end)

