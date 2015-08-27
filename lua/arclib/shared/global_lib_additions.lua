--I literally don't know who made this function so I can't give proper credit to it.
--All I know is that someone at facepunch will give you this function if you ask for it.
function util.Base64Decode( data ) -- Y WE NO HAVE "util.Base64Decode"? >:( -- I don't know where this originally came from
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	if !data then return end
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 && '1' || '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' && 2^(8-i) || 0) end
		return string.char(c)
	end))
end

-- This is taken from Swep Contruction Kit
-- Works like table.Copy except that any tables within the tables will also get copied instead of just their pointers.
-- Don't use this for a table that contains itself down the line or you'll get an infinit loop
function table.FullCopy( tab )

	if (!tab) then return nil end
	
	local res = {}
	for k, v in pairs( tab ) do
		if (type(v) == "table") then
			res[k] = table.FullCopy(v) // recursion ho!
		elseif (type(v) == "Vector") then
			res[k] = Vector(v.x, v.y, v.z)
		elseif (type(v) == "Angle") then
			res[k] = Angle(v.p, v.y, v.r)
		else
			res[k] = v
		end
	end
	
	return res
	
end