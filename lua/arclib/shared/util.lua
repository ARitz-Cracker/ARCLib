--Random utilities

function ARCLib.TableMergeOptimized( dest, source ) -- Slightly more optimized version of table.Marge (except it makes both tables equal to each other...)
	for k, v in pairs( dest ) do
		if source[k] == nil then
			source[k] = v
		end
	end
	dest = source
	return dest
end


function ARCLib.RecursiveTableMerge(overwrite,tab)
	if !overwrite then overwrite = {} end
	for k,v in pairs(tab) do
		if istable(v) && istable(overwrite[k]) then
			overwrite[k] = ARCLib.RecursiveTableMerge(overwrite[k],v)
		else
			overwrite[k] = v
		end
	end
	return overwrite
end

-- Gets the IP of the server
function ARCLib.GetIP()

	local hostip = GetConVarString( "hostip" ) -- GetConVarNumber is inaccurate
	hostip = tonumber( hostip )
	if (!hostip) then return "127.0.0.1" end -- Single Player game!
	local ip = {}
	ip[ 1 ] = bit.rshift( bit.band( hostip, 0xFF000000 ), 24 )
	ip[ 2 ] = bit.rshift( bit.band( hostip, 0x00FF0000 ), 16 )
	ip[ 3 ] = bit.rshift( bit.band( hostip, 0x0000FF00 ), 8 )
	ip[ 4 ] = bit.band( hostip, 0x000000FF )

	return table.concat( ip, "." )
end


function ARCLib.RecursiveHasValue(tab,value)
	local result = false
	for k,v in pairs(tab) do
		if istable(v) then
			result = result or ARCLib.RecursiveHasValue(v,value)
		end
		result = result or (v == value)
	end
	return result
end

function ARCLib.ConvertColor(col)
	assert( ARCLib.IsColor(col), "ARCLib.ConvertColor: I wanted a color, but I got some sort of wierd "..type( col ).." thing..." )
	return col.r, col.g, col.b, col.a
end

-- Checks how many items are in a table
function ARCLib.TableAmount(tab)
	error("Use table.Count instead")
	local am = 0
	for k,v in pairs(tab) do
		am = am + 1
	end
	return am
end

function ARCLib.AddDir(dir) -- recursively adds everything in a directory to be downloaded by client. (Taken from old GMod wiki, Fixed by ARitz Cracker)
	if SERVER then
		local files, directories = file.Find( dir.."/*", "GAME" )
		if !files then return end
		for _,v in pairs(files) do
			resource.AddFile(dir.."/"..v)
		end
		for _, fdir in pairs(directories) do
			if fdir != ".svn" && fdir != "_svn" then -- Don't spam people with useless .svn folders
				ARCLib.AddDir(dir.."/"..fdir) -- Recursion ho!
			end
		end
	else
		MsgN("Did you really try to add resources on the client, you dolt?")
	end
end

function ARCLib.TableToSequential(tab)
	local result = {}
	local i = 0
	for k,v in pairs(tab) do
		i = i + 1
		result[i] = v
	end
	return result
end

function ARCLib.RGBToCMY(col)
	return {c = (1 - col.r / 255)*255,m = (1 - col.g / 255)*255,y = (1 - col.b / 255)*255,a = col.a}
end

function ARCLib.ColorNegative(col)
	local tab = ARCLib.RGBToCMY(col)
	return Color(tab.c,tab.m,tab.y,tab.a)
end

function ARCLib.IsColor(col) -- Colors can be tables and util.JSONToTable doesn't return colours so AAAAAAAAAAH
	if !istable(col) then return false end
	return table.Count(col) == 4 && col.r && col.g && col.b && col.a
end


function ARCLib.JSONSafe( t, done )
	local done = done or {}
	local tbl = {}
	for k, v in pairs ( t ) do
		if ( istable( v ) and !done[ v ] ) then
			done[ v ] = true
			tbl[ k ] = table.Sanitise( v, done )
		else
			if ( type( v ) == "Vector" ) then
				local x, y, z = v.x, v.y, v.z
				if y == 0 then y = nil end
				if z == 0 then z = nil end
				tbl[ k ] = { __type = "Vector", x = x, y = y, z = z }
			elseif ( type( v ) == "Angle" ) then
				local p, y, r = v.pitch, v.yaw, v.roll
				if p == 0 then p = nil end
				if y == 0 then y = nil end
				if r == 0 then r = nil end
				tbl[ k ] = { __type = "Angle", p = p, y = y, r = r }
			elseif ( type( v ) == "boolean" ) then
				tbl[ k ] = { __type = "Bool", tostring( v ) }
			elseif ( type( v ) == "number" ) then
				--tbl[ k ] = { __type = "Number", tostring( v ) }
				tbl[ k ] = v
			elseif ( IsColor(v) ) then
				tbl[ k ] = { __type = "Color", r = v.r, g = v.g, b = v.b, a= v.a }
			else
				tbl[ k ] = tostring( v )
			end
		end
	end
	return tbl
end

function ARCLib.UnJSONSafe( t, done )
	local done = done or {}
	local tbl = {}
	for k, v in pairs ( t ) do
		if ( istable( v ) and !done[ v ] ) then
			done[ v ] = true
			if ( v.__type ) then
				if ( v.__type == "Vector" ) then
					tbl[ k ] = Vector( v.x, v.y, v.z )
				elseif ( v.__type == "Angle" ) then
					tbl[ k ] = Angle( v.p, v.y, v.r )
				elseif ( v.__type == "Bool" ) then
					tbl[ k ] = ( v[ 1 ] == "true" )
				--elseif ( v.__type == "Number" ) then
					--tbl[ k ] = tonumber( v[ 1 ] )
				elseif ( IsColor(v) ) then
					tbl[ k ] = Color( v.r, v.g, v.b , v.a )
				end
			else
				tbl[ k ] = table.DeSanitise( v, done )
			end
		else
			tbl[ k ] = v
		end
	end
	return tbl
end


if CLIENT then
	net.Receive( "ARCLib_Notify", function(length)
		local msg = net.ReadString() 
		local typ = net.ReadUInt(4)
		local time = net.ReadUInt(16)
		local sound = tobool(net.ReadBit())
		notification.AddLegacy(msg,typ,time) 
		if snd then
			if typ == NOTIFY_ERROR then
				 
				LocalPlayer():EmitSound("buttons/button8.wav" )
			else
				LocalPlayer():EmitSound("ambient/water/drip"..math.random(1, 4)..".wav" )
			end
		end
	end)

else
	NOTIFY_GENERIC = 0 --These constants are only pre-defined on the client. So if we're using NotifyPlayer, then better to do it here!
	NOTIFY_ERROR = 1
	NOTIFY_UNDO = 2
	NOTIFY_HINT = 3
	NOTIFY_CLEANUP = 4
	util.AddNetworkString( "ARCLib_Notify" )
	-- Player, Message, Type (NOTIFY_), time (seconds), Should we play a sound or not?
	function ARCLib.NotifyPlayer(ply,str,typ,time,snd)
		net.Start("ARCLib_Notify")
		net.WriteString(str)
		net.WriteUInt(typ,4)
		net.WriteUInt(time,16)
		net.WriteBit(snd)
		net.Send(ply)
	
	end
	-- Message, Type (NOTIFY_), time (seconds), Should we play a sound or not?
	function ARCLib.NotifyBroadcast(str,typ,time,snd)
		net.Start("ARCLib_Notify")
		net.WriteString(str)
		net.WriteUInt(typ,4)
		net.WriteUInt(time,16)
		net.WriteBit(snd)
		net.Broadcast()
	
	end

end

-- Now this code allows clients to play sound on other clients. The reasoning behind this is that I want a sound to be played on one client, but a different sound to be played on other clients.
-- The sound must be validated with ARCLib.AddToSoundWhitelist before being sent by the client, though.

if SERVER then
	if timer.Exists( "ARCLib_SoundCheck" ) then
		timer.Destroy( "ARCLib_SoundCheck" )
	end
	timer.Create( "ARCLib_SoundCheck", 1, 0, function() 
		for k,v in pairs(player.GetAll()) do
			v.ARCLIB_SOUND_COUNT = 0;
		end
	end )
	timer.Start( "ARCLib_SoundCheck" ) 
	util.AddNetworkString( "ARCLib_Sound" )
	ARCLib.SoundWhitelist = ARCLib.SoundWhitelist or {}

	function ARCLib.AddToSoundWhitelist(_ent,_snd,_lvl,_ptch)
		local alreadyexists = false
		for k,v in ipairs(ARCLib.SoundWhitelist) do
			alreadyexists = (alreadyexists || (v.ent == _ent && v.snd == _snd && v.lvl == _lvl && v.ptch == _ptch))
		end
		if !alreadyexists then
			table.insert(ARCLib.SoundWhitelist,{ent = _ent,snd = _snd,lvl = _lvl,ptch = _ptch})
		end
	end
	
	net.Receive( "ARCLib_Sound", function(length,ply)
		if ply.ARCLIB_SOUND_COUNT && ply.ARCLIB_SOUND_COUNT > 5 then -- Can't blame a guy for trying. Every 0.2 seconds may still be annoying... 
			ply:Kick("Spamming Sound")
		end
		
		local ent = net.ReadEntity() 
		local snd = net.ReadString() 
		local lvl = net.ReadUInt(8)
		local ptch = net.ReadUInt(8)
		if !IsValid(ent) || ent:IsWorld() then return end
		local validsound = false
		
		for k,v in pairs(ARCLib.SoundWhitelist) do
			validsound = validsound or (v.ent == ent:GetClass() && v.snd == snd && v.lvl == lvl && v.ptch == ptch)
		end
		
		if validsound then
			net.Start("ARCLib_Sound")
			net.WriteEntity(ent)
			net.WriteString(snd)
			net.WriteUInt(lvl,8)
			net.WriteUInt(ptch,8)
			net.SendOmit(ply)
			if !ply.ARCLIB_SOUND_COUNT then
				ply.ARCLIB_SOUND_COUNT = 0
			end
			ply.ARCLIB_SOUND_COUNT = ply.ARCLIB_SOUND_COUNT + 1
		else
			ARCLib.MsgCL(ply,"ARCLib: Invalid sound. (Not on sound whitelist)")
		end
	end)

else
	local soundspam = 0
	timer.Create( "ARCLib_SoundCheck", 1.1, 0, function() 
		soundspam = 0
	end )
	timer.Start( "ARCLib_SoundCheck" ) 
	
	function ARCLib.PlaySoundOnOtherPlayers(snd,ent,lvl,ptch) -- Plays a sound on people's clients.
		if soundspam && soundspam < 4 then
			if !lvl then lvl = 75 end
			if !ptch then ptch = 100 end
			net.Start("ARCLib_Sound") -- Now I know any client can just do lua_run_cl with this, BUT IT'S SO USEFUL...
			net.WriteEntity(ent)
			net.WriteString(snd)
			net.WriteUInt(lvl,8)
			net.WriteUInt(ptch,8)
			net.SendToServer()
			MsgN(soundspam)
		end
		soundspam = soundspam + 1
	end
	net.Receive( "ARCLib_Sound", function(length)
		local ent = net.ReadEntity() 
		local snd = net.ReadString() 
		local lvl = net.ReadUInt(8)
		local ptch = net.ReadUInt(8)
		if IsValid(ent) then
			sound.Play(snd, ent:GetPos(), lvl, ptch ) 
		end
	end)
end

