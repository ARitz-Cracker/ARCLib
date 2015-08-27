-- Some serverside stuff

function ARCLib.MsgCL(ply,msg) -- Lazy way for me to send messages to players chat and not worry if it's Console-god or not.
	if isentity(ply) && ply:IsPlayer() then
		ply:PrintMessage( HUD_PRINTTALK, msg)
	else
		MsgN(msg)
	end
end