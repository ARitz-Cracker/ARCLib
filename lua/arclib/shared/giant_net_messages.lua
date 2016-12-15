
ARCLib.NET_COMPLETE = 0
ARCLib.NET_DOWNLOADING = 1 -- REQUESTER
ARCLib.NET_DOWNLOADING_ERROR = 3
ARCLib.NET_DOWNLOADING_ERROR_MISMATCH = 4
ARCLib.NET_DOWNLOADING_ERROR_LENGTH = 5
ARCLib.NET_DOWNLOADING_ERROR_LENGTH_MISMATCH = 6
ARCLib.NET_DOWNLOADING_ACK = 7

ARCLib.NET_UPLOADING = 9 -- RESPONDER
ARCLib.NET_UPLOADING_ERROR = 10
ARCLib.NET_UPLOADING_ERROR_MISMATCH = 11
ARCLib.NET_UPLOADING_ERROR_LENGTH = 12
ARCLib.NET_UPLOADING_ERROR_LENGTH_MISMATCH = 13
ARCLib.NET_UPLOADING_ACK = 14


local net_Send
local GetMessageTable
local bigMessageNames = {}
if SERVER then
	net_Send = net.Send
	GetMessageTable = function(ply,identifier)
		if not ply.ARCLib_NetTab then
			ply.ARCLib_NetTab = {}
		end
		if not ply.ARCLib_NetTab[identifier] then
			ply.ARCLib_NetTab[identifier] = {}
			ply.ARCLib_NetTab[identifier].dlMsg = ""
			ply.ARCLib_NetTab[identifier].dlPlace = -1
			ply.ARCLib_NetTab[identifier].dlLength = -1
			ply.ARCLib_NetTab[identifier].upMsgs = {}
			ply.ARCLib_NetTab[identifier].upPlace = -1
			ply.ARCLib_NetTab[identifier].upLength = -1
			ply.ARCLib_NetTab[identifier].upMsg = -1
		end
		return ply.ARCLib_NetTab[identifier]
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
	net_Send = net.SendToServer
	local tab = {}
	GetMessageTable = function(ply,identifier)
		if not tab[identifier] then
			tab[identifier] = {}
			tab[identifier].dlMsg = ""
			tab[identifier].dlPlace = 0
			tab[identifier].dlLength = 0
			tab[identifier].upMsgs = {}
			tab[identifier].upPlace = -1
			tab[identifier].upLength = -1
			tab[identifier].upMsg = -1
		end
		return tab[identifier]
	end
	net.Receive("arclib_big_messages_register",function(msglen,ply)
		local entireThing = net.ReadBool()
		if entireThing then
			bigMessageNames = net.ReadTable()
		else
			local a = {}
			local name = net.ReadString()
			a.id = net.ReadUInt(8)
			a.chunksize = net.ReadUInt(16)
			a.chunklimit = net.ReadUInt(8)
			bigMessageNames[name] = a
		end
	end)
end

function ARCLib.SendBigMessage(name,data,ply,callback)
	local m = bigMessageNames[name]
	if not m then
		error("ARCLib.SendBigMessage: tried to use an unregistered name!")
	end
	local tab = GetMessageTable(ply,m.id)
	local stuffs = ARCLib.SplitString(str,m.chunksize)
	if #stuffs > chunklimit then
		callback(ARCLib.NET_UPLOADING_ERROR_LENGTH_MISMATCH,0)
		return
	end
	tab.upMsgs[#tab.upMsgs + 1] = stuffs
	if tab.upMsg == -1 then -- There's only one pending message (this one) that must mean no others are going right now
		tab.upLength = #stuffs
		tab.upMsg = 1
		tab.upPlace = 0
		net.Start("arclib_big_messages")
		net.WriteUInt(ARCLib.NET_UPLOADING,4)
		net.WriteUInt(m.id,8)
		net.WriteUInt(tab.upPlace,8)
		net.WriteUInt(tab.upLength,8)
		net.WriteUInt(0,16)
		net_Send(ply)
	end
end