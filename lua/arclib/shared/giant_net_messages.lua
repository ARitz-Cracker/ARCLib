
ARCLib.NET_COMPLETE = 0
ARCLib.NET_DOWNLOADING = 1 -- RECIEVER
ARCLib.NET_DOWNLOADING_ERROR = 3
ARCLib.NET_DOWNLOADING_ERROR_MISMATCH = 4
ARCLib.NET_DOWNLOADING_ERROR_LENGTH = 5
ARCLib.NET_DOWNLOADING_ERROR_LENGTH_MISMATCH = 6
ARCLib.NET_DOWNLOADING_ACK = 7

ARCLib.NET_UPLOADING = 9 -- SENDER
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
			ply.ARCLib_NetTab[identifier].dlPlace = 0
			ply.ARCLib_NetTab[identifier].dlLength = 0
			ply.ARCLib_NetTab[identifier].upMsgs = {}
			ply.ARCLib_NetTab[identifier].upCallbacks = {}
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
		for k,v in pairs(bigMessageNames) do
			net.Start("arclib_big_messages_register")
			net.WriteString(k)
			net.WriteUInt(v.id,8)
			net.WriteUInt(v.chunksize,16)
			net.WriteUInt(v.chunklimit,8)
			net.Send(ply)
		end
	end)
	function ARCLib.RegisterBigMessage(name,chunksize,chunklimit,serverToClientOnly)
		if identifiers > 255 then
			error("ARCLib.RegisterBigMessage: There can't be more than 256 big messages registered. If this happens, ask ARitz Cracker to use 16 bit identifiers. ")
		end
		if not isnumber(chunksize) then
			chunksize = 8192
		end
		if not isnumber(chunklimit) then
			chunklimit = 64
		end
		if chunksize < 256 or chunksize > 49152 then
			error("ARCLib.RegisterBigMessage: Argument #2 must be between 256 and 49152")
		end
		if chunklimit < 4 or chunklimit > 255 then
			error("ARCLib.RegisterBigMessage: Argument #2 must be between 4 and 255")
		end
		if bigMessageNames[name] then return end
		bigMessageNames[name] = {}
		bigMessageNames[name].serveronly = serverToClientOnly
		bigMessageNames[name].id = identifiers
		bigMessageNames[name].chunksize = chunksize
		bigMessageNames[name].chunklimit = chunklimit
		
		net.Start("arclib_big_messages_register")
		net.WriteString(name)
		net.WriteUInt(identifiers,8)
		net.WriteUInt(chunksize,16)
		net.WriteUInt(chunklimit,8)
		net.Broadcast()
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
			tab[identifier].upCallbacks = {}
			tab[identifier].upPlace = -1
			tab[identifier].upLength = -1
			tab[identifier].upMsg = -1
		end
		return tab[identifier]
	end
	net.Receive("arclib_big_messages_register",function(msglen,ply)
		local a = {}
		local name = net.ReadString()
		if not bigMessageNames[name] then
			bigMessageNames[name] = {}
		end
		a.id = net.ReadUInt(8)
		a.chunksize = net.ReadUInt(16)
		a.chunklimit = net.ReadUInt(8)
		table.Merge( bigMessageNames[name], a )
	end)
end
function ARCLib.ReceiveBigMessage(name,func)
	if not bigMessageNames[name] then
		bigMessageNames[name] = {}
	end
	bigMessageNames[name].func = func
end
local pendingUploads = {}
local pendingUpload = 0
timer.Simple(0,function()
ARCLib.AddThinkFunc("ARCLib PendingBigUploads",function()
	if pendingUpload > 0 then
		local name = pendingUploads[pendingUpload].name
		local data = pendingUploads[pendingUpload].data
		local ply = pendingUploads[pendingUpload].ply
		local callback = pendingUploads[pendingUpload].callback
		
		local m = bigMessageNames[name]
		if m then
			if not callback then
				callback = NULLFUNC
			end
			local tab = GetMessageTable(ply,m.id)
			local stuffs = ARCLib.SplitString(data,m.chunksize,true)
			if #stuffs > m.chunklimit then
				callback(ARCLib.NET_UPLOADING_ERROR_LENGTH,0)
				return
			end
			local i = #tab.upMsgs + 1
			tab.upMsgs[i] = stuffs
			tab.upCallbacks[i] = callback
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
				callback(ARCLib.NET_UPLOADING,0)
				tab.upPlace = 1
			end
		end
		pendingUpload = pendingUpload + 1
		if not pendingUploads[pendingUpload] then
			pendingUpload = 0
			pendingUploads = {}
		end
	end
end)
end)

function ARCLib.SendBigMessage(name,data,ply,callback)
	local m = bigMessageNames[name]
	if not m then
		error("ARCLib.SendBigMessage: tried to use an unregistered name!")
	end
	local tab = {}
	tab.name = name
	tab.data = data
	tab.ply = ply
	tab.callback = callback
	pendingUploads[#pendingUploads + 1] = tab
	if pendingUpload == 0 then
		pendingUpload = 1
	end
end
local function CallCallback(id,code,progress,data,ply)
	local notFound = true
	for k,v in pairs(bigMessageNames) do
		if v.id == id then
			notFound = false
			if isfunction(v.func) then
				v.func(code,progress,data,ply)
			else
				ARCLib.Msg("Big net message "..k.." has no receive function!")
			end
			break
		end
	end
	if notFound then
		ARCLib.Msg("Got a big net message with ID "..tostring(id).." but it hasn't been registered??")
	end
end
local function NextUpload(ply,id,tab)
	tab.upMsg = tab.upMsg + 1
	tab.upPlace = -1
	tab.upLength = -1
	if tab.upMsgs[tab.upMsg] then
		tab.upLength = #tab.upMsgs[tab.upMsg]
		tab.upPlace = 0
		net.Start("arclib_big_messages")
		net.WriteUInt(ARCLib.NET_UPLOADING,4)
		net.WriteUInt(id,8)
		net.WriteUInt(tab.upPlace,8)
		net.WriteUInt(tab.upLength,8)
		net.WriteUInt(0,16)
		net_Send(ply)
		tab.upCallbacks[tab.upMsg](ARCLib.NET_UPLOADING,0)
		tab.upPlace = 1
	else
		tab.upMsg = -1
		tab.upMsgs = {}
		tab.upCallbacks = {}
	end
end
net.Receive("arclib_big_messages",function(msglen,ply)
	local status = net.ReadUInt(4)
	local id = net.ReadUInt(8)
	local place = net.ReadUInt(8)
	local whole = net.ReadUInt(8)
	local tab = GetMessageTable(ply,id)
	
	if status == ARCLib.NET_UPLOADING then
		if place == tab.dlPlace then
			local propertyTab
			for k,v in pairs(bigMessageNames) do
				if v.id == id then
					propertyTab = v
					break
				end
			end
			if not propertyTab then
				net.Start("arclib_big_messages")
				net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR,4)
				net.WriteUInt(id,8)
				net.WriteUInt(0,8)
				net.WriteUInt(0,8)
				net_Send(ply)
				return
			end
			if whole > propertyTab.chunklimit then
				net.Start("arclib_big_messages")
				net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR_LENGTH,4)
				net.WriteUInt(id,8)
				net.WriteUInt(0,8)
				net.WriteUInt(0,8)
				net_Send(ply)
				CallCallback(id,ARCLib.NET_DOWNLOADING_ERROR_LENGTH,0,nil,ply)
				return
			end
			if SERVER and propertyTab.serveronly then
				net.Start("arclib_big_messages")
				net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR,4)
				net.WriteUInt(id,8)
				net.WriteUInt(0,8)
				net.WriteUInt(0,8)
				net_Send(ply)
				return
			end
			if place == 0 then
				tab.dlLength = whole
				tab.dlMsg = ""
				tab.dlPlace = 1
				net.Start("arclib_big_messages")
				net.WriteUInt(ARCLib.NET_DOWNLOADING,4)
				net.WriteUInt(id,8)
				net.WriteUInt(tab.dlPlace,8)
				net.WriteUInt(tab.dlLength,8)
				net_Send(ply)
				CallCallback(id,ARCLib.NET_DOWNLOADING,0,nil,ply)
			elseif tab.dlLength != whole then
				net.Start("arclib_big_messages")
				net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR_LENGTH_MISMATCH,4)
				net.WriteUInt(id,8)
				net.WriteUInt(0,8)
				net.WriteUInt(0,8)
				net_Send(ply)
				CallCallback(id,ARCLib.NET_DOWNLOADING_ERROR_LENGTH_MISMATCH,0,nil,ply)
			else
				local msglen = net.ReadUInt(16)
				local msg = ""
				if msglen > propertyTab.chunksize then
					net.Start("arclib_big_messages")
					net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR,4)
					net.WriteUInt(id,8)
					net.WriteUInt(0,8)
					net.WriteUInt(0,8)
					net_Send(ply)
					CallCallback(id,ARCLib.NET_DOWNLOADING_ERROR,0,nil,ply)
				elseif msglen > 0 then
					msg = net.ReadData(msglen)
				end
				tab.dlMsg = tab.dlMsg .. msg
				if tab.dlPlace == tab.dlLength then
					net.Start("arclib_big_messages")
					net.WriteUInt(ARCLib.NET_DOWNLOADING_ACK,4)
					net.WriteUInt(id,8)
					net.WriteUInt(0,8)
					net.WriteUInt(0,8)
					net_Send(ply)
					tab.dlMsg = ""
					tab.dlPlace = 0
					tab.dlLength = 0
					CallCallback(id,ARCLib.NET_COMPLETE,1,tab.dlMsg,ply)
				else
					tab.dlPlace = tab.dlPlace + 1
					net.Start("arclib_big_messages")
					net.WriteUInt(ARCLib.NET_DOWNLOADING,4)
					net.WriteUInt(id,8)
					net.WriteUInt(tab.dlPlace,8)
					net.WriteUInt(tab.dlLength,8)
					net_Send(ply)
					CallCallback(id,ARCLib.NET_DOWNLOADING,tab.dlPlace/tab.dlLength,nil,ply)
				end
			end
		else
			net.Start("arclib_big_messages")
			net.WriteUInt(ARCLib.NET_DOWNLOADING_ERROR_MISMATCH,4)
			net.WriteUInt(id,8)
			net.WriteUInt(0,8)
			net.WriteUInt(0,8)
			net_Send(ply)
		end
	elseif status > ARCLib.NET_UPLOADING then
		--Sender is reporting an error
		CallCallback(id,status,0,nil,ply)
	elseif status == ARCLib.NET_DOWNLOADING then
		if whole != tab.upLength then
			net.Start("arclib_big_messages")
			net.WriteUInt(ARCLib.NET_UPLOADING_ERROR_LENGTH_MISMATCH,4)
			net.WriteUInt(id,8)
			net.WriteUInt(0,8)
			net.WriteUInt(0,8)
			net_Send(ply)
			local func = tab.upCallbacks[tab.upMsg]
			timer.Simple(0,function() func(ARCLib.NET_UPLOADING_ERROR_LENGTH_MISMATCH,0) end)
			NextUpload(ply,id,tab)
			
		elseif place == tab.upPlace then
			net.Start("arclib_big_messages")
			net.WriteUInt(ARCLib.NET_UPLOADING,4)
			net.WriteUInt(id,8)
			net.WriteUInt(tab.upPlace,8)
			net.WriteUInt(tab.upLength,8)
			local msg = tab.upMsgs[tab.upMsg][tab.upPlace]
			local msglen = #msg
			net.WriteUInt(msglen,16)
			net.WriteData(msg,msglen)
			net_Send(ply)
			tab.upPlace = tab.upPlace + 1
			tab.upCallbacks[tab.upMsg](ARCLib.NET_UPLOADING,(tab.upPlace-1)/tab.upLength)
		else
			net.Start("arclib_big_messages")
			net.WriteUInt(ARCLib.NET_UPLOADING_ERROR_MISMATCH,4)
			net.WriteUInt(id,8)
			net.WriteUInt(0,8)
			net.WriteUInt(0,8)
			net_Send(ply)
			local func = tab.upCallbacks[tab.upMsg]
			timer.Simple(0,function() func(ARCLib.NET_UPLOADING_ERROR_MISMATCH,0) end)
			NextUpload(ply,id,tab)
			
		end
	elseif status == ARCLib.NET_DOWNLOADING_ACK then
		--Receiver is reporting dl is finished
		local func = tab.upCallbacks[tab.upMsg]
		timer.Simple(0,function() func(ARCLib.NET_COMPLETE,0) end)
		NextUpload(ply,id,tab)
		
	elseif status > ARCLib.NET_DOWNLOADING then
		--Receiver is reporting an error
		local func = tab.upCallbacks[tab.upMsg]
		timer.Simple(0,function() func(status,0) end)
		NextUpload(ply,id,tab)
	end
end)


