-- Things that involve searching for entities in the world

function ARCLib.IsPlayer(ent)
	return isentity(ent) && ent:IsPlayer()
end
-- Used by some of my addons...
function ARCLib.GetUserID(ply)
	return ply._ARCFakeUserID or ply:SteamID()
end

function ARCLib.GetPlayerBySteamID(steamid) -- Gets a player by their SteamID
	local ply = {}
	if !isstring(steamid) then return NULL end
	for _, v in pairs( player.GetHumans() ) do
		if v:SteamID() == steamid then
			ply = v
		end
	end
	if !IsValid(ply) then
		function ply:SteamID() return steamid end
		function ply:Nick() return "[Player Offline]" end
		function ply:IsPlayer() return false end
		function ply:IsValid() return false end
	end
	return ply
end

function ARCLib.GetPlayerByUserID(steamid) -- Gets a player by their "ARCLib.UserID"
	local ply = {}
	if !isstring(steamid) then return {} end
	for _, v in pairs( player.GetHumans() ) do
		if ARCLib.GetUserID(v) == steamid then
			ply = v;
		end
	end
	if !IsValid(ply) then
		function ply:SteamID() return "STEAM_0:0:0" end
		ply._ARCFakeUserID = steamid
		function ply:Nick() return "[Player Offline]" end
		function ply:IsPlayer() return false end
		function ply:IsValid() return false end
	end
	return ply
end

function ARCLib.GetNearestPlayer(pos,plyex) -- Gets the nearest player relative to pos. plyex is the player or list of players to exclude.
	local dist = math.huge
	local ply = NULL
	assert(isvector(pos),"ARCLib.GetNearestPlayer: Bad argument #1. I wanted a vector, but I got a goddamn "..type(pos))
	for _, v in pairs( player.GetAll() ) do
		local newdist = pos:DistToSqr( v:GetPos() )
		if istable(plyex) then
			if newdist < dist && !table.HasValue(plyex,v) then
				ply = v
				dist = newdist
			end
		else
			if newdist < dist && v != plyex then
				ply = v
				dist = newdist
			end
		end
	end
	return ply
end
function ARCLib.GetNearestEntity(pos,class) -- Gets the nearest entity relative to pos. Defined by classname
	if !isstring(class) then return NULL end
	local dist = math.huge
	local ply = NULL
	for _, v in pairs( ents.FindByClass(class) ) do
		local newdist = pos:DistToSqr( v:GetPos() )
		if newdist < dist then
			ply = v
			dist = newdist
		end
	end
	return ply
end