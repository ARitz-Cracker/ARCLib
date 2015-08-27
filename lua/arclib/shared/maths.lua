
function ARCLib.DistanceLinePoints(x0,y0,x1,y1,x2,y2)
	-- https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
	return math.abs((y2-y1)*x0 - (x2-x1)*y0 + x2*y1 - y2*x1)/math.sqrt((y2-y1)^2 + (x2-x1)^2)
end
function ARCLib.BetweenNumberScaleReverse(min,inp,max)
	assert(isnumber(min),"ARCLib.BetweenNumberScaleReverse: Bad argument #1. I wanted a number, but I got a goddamn "..type(min))
	assert(isnumber(inp),"ARCLib.BetweenNumberScaleReverse: Bad argument #2. I wanted a number, but I got a goddamn "..type(inp))
	assert(isnumber(max),"ARCLib.BetweenNumberScaleReverse: Bad argument #3. I wanted a number, but I got a goddamn "..type(max))
	return (ARCLib.BetweenNumberScale(min,inp,max)-1)*-1
end
function ARCLib.BetweenNumberScale(min,inp,max) --Like Lerp except different.
	assert(isnumber(min),"ARCLib.BetweenNumberScale: Bad argument #1. I wanted a number, but I got a goddamn "..type(min))
	assert(isnumber(inp),"ARCLib.BetweenNumberScale: Bad argument #2. I wanted a number, but I got a goddamn "..type(inp))
	assert(isnumber(max),"ARCLib.BetweenNumberScale: Bad argument #3. I wanted a number, but I got a goddamn "..type(max))
	if inp <= min then
		return 0
	end
	if inp >= max then
		return 1
	end

	return (inp - min) / (max - min)
end

function ARCLib.InBetween(min,inp,max) -- Inclusive between
	return min <= inp && inp <= max
end
function ARCLib.ExBetween(min,inp,max) -- Exclusive between
	return min < inp && inp < max
end
function ARCLib.InBox(b1x1,b1x2,b1y1,b1y2,b2x1,b2x2,b2y1,b2y2) -- Check if box 1 is inside box 2.
	return ARCLib.InBetween(b2x1,b1x1,b2x2) && ARCLib.InBetween(b2x1,b1x2,b2x2) && ARCLib.InBetween(b2y1,b1y1,b2y2) && ARCLib.InBetween(b2y1,b1y2,b2y2)
end
function ARCLib.TouchingBox(b1x1,b1x2,b1y1,b1y2,b2x1,b2x2,b2y1,b2y2) -- Check if box 1 is touching box 2.
	return (ARCLib.InBetween(b2x1,b1x1,b2x2)||ARCLib.InBetween(b2x1,b1x2,b2x2) || ARCLib.InBetween(b1x1,b2x1,b1x2)||ARCLib.InBetween(b1x1,b2x2,b1x2) ) && (ARCLib.InBetween(b2y1,b1y1,b2y2)||ARCLib.InBetween(b2y1,b1y2,b2y2)||ARCLib.InBetween(b1y1,b2y1,b1y2)||ARCLib.InBetween(b1y1,b2y2,b1y2))
end

function ARCLib.ExpTransition(min,inp,max) -- Like BetweenNumberScale except exponential-curve-like
	min = min - 1
	local relativemax = max - min
	local relativein = inp - min
	local result = math.Round(2^(relativein/(relativemax*0.30102999566398119521373889472449))*(relativemax/10))
	if result < 1 then
		result = 1
	end
	return result + min
end

function ARCLib.FloorDec(num,decimal) -- Floors a number nearest to the specified decimal (Doesn't lua already have something like this?)
	return math.floor(num*(10^decimal))/(10^decimal)
end

function ARCLib.DigiNumber(num,zeros) -- Puts zeros in front of a number. Useful for "retro" displays
	if num == 0 then
		return string.rep( "0", zeros ).."0"
	end
	return string.rep( "0", zeros-math.floor(math.log10(num)) )..tostring(math.floor(num))
end


function ARCLib.RandomRound(number) -- Randomly rounds things.
	if tobool(math.Round(math.random())) then
		return math.Round(number)
	else
		if tobool(math.Round(math.random())) then
			return math.floor(number)
		else	
			return math.ceil(number)
		end
	end
end

function ARCLib.RandomExp(min,max) -- Biased random towards lower values, I love exponential curves.
	min = min - 1
	local relativemax = max - min
	local result = ARCLib.RandomRound(2^(math.Rand(1,relativemax)/(relativemax*0.30102999566398119521373889472449))*(relativemax/10))
	if result < 1 then
		result = 1
	end
	return result + min
end
function ARCLib.MoneyLimit(num) -- Used for ARCBank. This is actually the limit where you can accurately count whole numbers using these floats.
	if !num || !isnumber(num) then return "Invalid" end
	if num < 1e14 then
		return string.Comma(num)
	else
		return "A wasted life"
	end
end

function ARCLib.ShortScale(num,dec) -- Formats a number to a string using the short number scale
		-- https://en.wikipedia.org/wiki/Names_of_large_numbers
		if !num || !isnumber(num) then return "Invalid" end
		if !dec then dec = 2 end
		if num < 1e6 then
			return string.Comma(num)
		elseif num < 1e9 then
			return tostring(ARCLib.FloorDec( num/1e6, dec )).." Million"
		elseif num < 1e12 then
			return tostring(ARCLib.FloorDec( num/1e9, dec )).." Billion"
		elseif num < 1e15 then
			return tostring(ARCLib.FloorDec( num/1e12, dec )).." Trillion"
		elseif num < 1e18 then
			return tostring(ARCLib.FloorDec( num/1e15, dec )).." Quadrillion"
		elseif num < 1e21 then
			return tostring(ARCLib.FloorDec( num/1e18, dec )).." Quintillion"
		elseif num < 1e24 then
			return tostring(ARCLib.FloorDec( num/1e21, dec )).." Sextillion"
		elseif num < 1e27 then
			return tostring(ARCLib.FloorDec( num/1e24, dec )).." Septillion"
		elseif num < 1e30 then
			return tostring(ARCLib.FloorDec( num/1e27, dec )).." Octillion"
		elseif num < 1e33 then
			return tostring(ARCLib.FloorDec( num/1e30, dec )).." Nonillion"
		elseif num < 1e36 then
			return tostring(ARCLib.FloorDec( num/1e33, dec )).." Decillion"
		elseif num < 1e39 then
			return tostring(ARCLib.FloorDec( num/1e36, dec )).." Undecillion"
		elseif num < 1e42 then
			return tostring(ARCLib.FloorDec( num/1e39, dec )).." Duodecillion"
		elseif num < 1e45 then
			return tostring(ARCLib.FloorDec( num/1e42, dec )).." Tredecillion"
		elseif num < 1e48 then
			return tostring(ARCLib.FloorDec( num/1e45, dec )).." Quattuordecillion"
		elseif num < 1e51 then
			return tostring(ARCLib.FloorDec( num/1e48, dec )).." Quindecillion"
		elseif num < 1e54 then
			return tostring(ARCLib.FloorDec( num/1e51, dec )).." Sexdecillion"
		elseif num < 1e57 then
			return tostring(ARCLib.FloorDec( num/1e54, dec )).." Septendecillion"
		elseif num < 1e60 then
			return tostring(ARCLib.FloorDec( num/1e57, dec )).." Octodecillion"
		elseif num < 1e63 then
			return tostring(ARCLib.FloorDec( num/1e60, dec )).." Novemdecillion"
		elseif num < 1e66 then
			return tostring(ARCLib.FloorDec( num/1e63, dec )).." Vigintillion"
		else
			return "A huge number"
		end
end

function ARCLib.BoolToNumber(bool) -- Turns a boolean into a 0 or 1. Useful for math operations.
	if bool then
		return 1
	else
		return 0
	end
end
