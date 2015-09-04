-- String stuffs

local langtab = {}
langtab.nd = "and"
langtab.second = "second"
langtab.seconds = "seconds"
langtab.minute = "minute"
langtab.minutes = "minutes"
langtab.hour = "hour"
langtab.hours = "hours"
langtab.day = "day"
langtab.days = "days"
langtab.forever = "forever"
langtab.now = "now"

function ARCLib.TimeString(sec,tab) -- Converts seconds to a human-readable form. Also, string.NiceTime is terrible.
	if(!istable(tab) || #tab == 0 )then -- I don't really like this, but it's for the sake of making it translatable!
		tab = langtab
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


function ARCLib.JamesHash(str)
	local hash = 1
	for i=1, #str do
		hash = (2 * hash) + string.byte(str, i)
		hash = hash % 2147483647
	end
	return tostring(hash)
end


if !CLIENT then return end -- The following code only functions on the client side since only the client has those surface.* functions

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


local function ARCLib_CorrectStringTooLargeForTable(word,tab,place,font,length)
	local temptables = {}
	local tempstr = ""
	local tempstrsize = 0
	local charsize = 0
	for i=1,#word do
		charsize = surface.GetTextSize(word[i])
		if (charsize+tempstrsize <= length) then
			tempstr = tempstr..word[i]
			tempstrsize = charsize+tempstrsize
		else
			temptables[#temptables + 1] = tempstr
			tempstr = word[i]
			tempstrsize = charsize
		end
	end
	for i=1,#temptables do
		place = place + 1
		tab[place] = temptables[i]
	end
	place = place + 1
	tab[place] = tempstr
	return place
end

function ARCLib.FitText(text,font,length,incoroutine)
	if !isstring(text) then return {type(text)} end
	local hash
	if !incoroutine then
		hash = util.CRC(text..font..length)
		if ARCLib.CachedStrings[hash] then -- I wonder if this will actually save performence...
			return ARCLib.CachedStrings[hash]
		end
	end
	text = string.Replace(text,"\r","") -- What if we're reading a file with \r\n?
	local textlen = #text
	if text[textlen] != " " || text[textlen] != "\n" then
		textlen = textlen + 1
		text = text.." " -- This is here so that the last word doesn't get left behind :)
	end
	
	local textprogress = 0
	
	local resulttab = {""}
	local curplace = 1
	local currentword = ""
	local currentwordsize = 0
	local currentlinesize = 0
	surface.SetFont( font )
	local spacelen = surface.GetTextSize( " " )
	for k,v in utf8.codes(text) do
		if (v == " ") then
			--MsgN("curplace = "..curplace)
			--PrintTable(resulttab)
			currentlinesize = surface.GetTextSize( resulttab[curplace] )
			currentwordsize = surface.GetTextSize( currentword )
			if (currentwordsize > length) then -- WORD IS LONGER THAN THE LENGTH OF THE SCREEN AAAAAAAAAAAAAAAAH
				curplace = ARCLib_CorrectStringTooLargeForTable(currentword,resulttab,curplace,font,length)
			elseif (currentlinesize == 0) then
				resulttab[curplace] = currentword
			elseif (currentlinesize+currentwordsize+spacelen <= length) then
				resulttab[curplace] = resulttab[curplace].." "..currentword
			else
				curplace = curplace + 1
				resulttab[curplace] = currentword
			end
			currentword = ""
		elseif (v == "\n") then
			currentlinesize = surface.GetTextSize( resulttab[curplace] )
			currentwordsize = surface.GetTextSize( currentword )
			if (currentwordsize > length) then -- WORD IS LONGER THAN THE LENGTH OF THE SCREEN AAAAAAAAAAAAAAAAH
				curplace = ARCLib_CorrectStringTooLargeForTable(currentword,resulttab,curplace,font,length)
			elseif (currentlinesize == 0) then
				resulttab[curplace] = currentword
			elseif (currentlinesize+currentwordsize+spacelen <= length) then
				resulttab[curplace] = resulttab[curplace].." "..currentword
			else
				curplace = curplace + 1
				resulttab[curplace] = currentword
			end
			curplace = curplace + 1
			resulttab[curplace] = ""
			currentword = ""
		else
			currentword = currentword..v
		end
		if incoroutine then
			textprogress = textprogress + #v
			ARCLib.CR.Progress = textprogress/textlen
			coroutine.yield()
		end
	end
	if !incoroutine then
		ARCLib.CachedStrings[hash] = resulttab
	end
	return resulttab
end

local NULLTABLE = {}

ARCLib.CR = {}
ARCLib.CR.Progress = -1
ARCLib.CR.Callback = nil
ARCLib.CR.Text = ""
ARCLib.CR.Font = ""
ARCLib.CR.Length = 0
ARCLib.CR.Thread = nil
local function ARCLib_CRFunc()
	ARCLib.CR.Progress = 0
	ARCLib.CR.Table = ARCLib.FitText(ARCLib.CR.Text,ARCLib.CR.Font,ARCLib.CR.Length,true)
	ARCLib.CR.Text = ""
	ARCLib.CR.Font = ""
	ARCLib.CR.Length = 0
	ARCLib.CR.Progress = 1
end

function ARCLib.FitTextRealtime(text,font,length,callback) -- Splits strings for text boxes. (length) is in pix. Supports "\n"
	-- Realtime version, this was made so that your computer doesn't freeze while processing massive amounts of text.
	if (ARCLib.CR.Callback) then
		return ARCLib.CR.Callback(1,{"BUSY"})
	end
	ARCLib.CR.Text = text
	ARCLib.CR.Font = font
	ARCLib.CR.Length = length
	ARCLib.CR.Callback = callback
end
hook.Add( "Think", "ARCLib Stringthink", function()
	if ARCLib.CR.Callback then
		local done = false
		if ARCLib.CR.Progress == -1 then
			ARCLib.CR.Thread = coroutine.create(ARCLib_CRFunc) 
			ARCLib.CR.Progress = 0
			ARCLib.CR.Callback(0,NULLTABLE)
		else
			local stime = SysTime()
			while SysTime() - stime < 0.01 do
				if (coroutine.status(ARCLib.CR.Thread) == "dead") then
					ARCLib.CR.Callback(1,ARCLib.CR.Table)
					ARCLib.CR.Progress = -1
					ARCLib.CR.Callback = nil
					ARCLib.CR.Text = ""
					ARCLib.CR.Font = ""
					ARCLib.CR.Length = 0
					ARCLib.CR.Thread = nil
					done = true
					break
				else
					local succ,err = coroutine.resume(ARCLib.CR.Thread)
					if !succ then
						error("ARCLib.FitTextRealtime coroutine failed: "..err)
					end
				end
			end
			if (!done) then
				ARCLib.CR.Callback(ARCLib.CR.Progress,NULLTABLE)
			end
		end
	end
end)

