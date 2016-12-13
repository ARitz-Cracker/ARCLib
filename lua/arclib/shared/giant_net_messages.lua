
ARCLib.NET_COMPLETE = 0
ARCLib.NET_DOWNLOADING = 1
ARCLib.NET_UPLOADING = 2
ARCLib.NET_DOWNLOADING_ERROR = 3
ARCLib.NET_UPLOADING_ERROR = 4

local GetMessageTable
local bigMessageNames = {}
if SERVER then
	GetMessageTable = function(ply,identifier)
		if not ply.ARCLib_NetTab then
			ply.ARCLib_NetTab = {}
		end
	end
	util.AddNetworkString( "arclib_big_messages" )
	util.AddNetworkString( "arclib_big_messages_register" )
	local identifiers = 0
	hook.Add( "PlayerInitialSpawn", "ARCLib RegisterBigMessages", function(ply)
		net.Start("arclib_big_messages_register")
		net.WriteBool(true)
		net.WriteTable(bigMessageNames)
		net.Send(ply)
		--bigMessageNames
	end)
	function ARCLib.RegisterBigMessage(name,chunksize,chunklimit)
		if identifiers > 255 then
			error("There can't be more than 256 big messages registered. If this happens, ask ARitz Cracker to use 16 bit instead of 8 bit identifiers")
		end
		if not isnumber(chunksize) then
			chunksize = 8192
		end
		if not isnumber(chunklimit) then
			chunklimit = 32
		end
		if chunksize < 256 or chunksize > 49152 then
			error("ARCLib.RegisterBigMessage: Argument #2 must be between 256 and 49152")
		end
		if chunklimit < 4 or chunklimit > 255 then
			error("ARCLib.RegisterBigMessage: Argument #2 must be between 4 and 255")
		end
		if bigMessageNames[name] then return end
		bigMessageNames[name] = {}
		bigMessageNames[name].id = identifiers
		bigMessageNames[name].chunksize = chunksize
		bigMessageNames[name].chunklimit = chunklimit
		
		net.Start("arclib_big_messages_register")
		net.WriteBool(false)
		net.WriteString(name)
		net.WriteUInt(identifiers,8)
		net.WriteUInt(chunksize,16)
		net.WriteUInt(chunklimit,8)
		net.Send(ply)
		identifiers = identifiers + 1
	end
elseif CLIENT then
	local tab = {}
	GetMessageTable = function(ply,identifier)
		if not tab[identifier] then
			tab[identifier] = {}
			tab[identifier].msg = ""
			tab[identifier].place = -1
			tab[identifier].length = -1
		end
	end
end