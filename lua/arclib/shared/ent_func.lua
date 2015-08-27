-- Entity metafuncs.
local entity = FindMetaTable("Entity")
function entity:EmitSoundTable(soundName, soundLevel, pitchPercent, volume,channel)
	assert(istable(soundName)||isstring(soundName),"EmitSoundTable: Invalidized 1st argushizzle. string or table expected. Got a motherfuckin' "..type(soundName))
	soundLevel = soundLevel or 75
	pitchPercent = pitchPercent or 100 
	volume = volume or 1
	channel = channel or CHAN_AUTO
	if istable(soundName) then
		if #soundName > 0 then
			self:EmitSound(table.Random(soundName), soundLevel, pitchPercent, volume,channel)
		end
	else
		self:EmitSound(soundName, soundLevel, pitchPercent, volume,channel)
	end
end

--For some reason, I couldn't get any of the pre-built animations functions in GMod to work, SO I HACKED MY OWN!

if CLIENT then
	function entity:ARCLib_SetAnimationID(animid,time)
		self._ARCLib_Animation = true
		--MsgN("AnimID: "..animid)
		--MsgN("Time: "..time)
		if time > 0 then
			--MsgN()
			self._ARCLib_AnimScale = time
			self._ARCLib_AnimEndTime = CurTime() + self._ARCLib_AnimScale
			self:ResetSequenceInfo() 
			self:SetSequence(animid)
			self:SetCycle( 0 )
			self._ARCLib_AnimTime = math.Clamp((self._ARCLib_AnimEndTime - CurTime())/self._ARCLib_AnimScale,0,1)
		else
			self._ARCLib_AnimEndTime = self._ARCLib_AnimEndTime or 1
			self._ARCLib_AnimScale = self._ARCLib_AnimScale or 1
			self._ARCLib_AnimTime = self._ARCLib_AnimTime or 1
			self:SetSequence(animid)
		end
	end
	function entity:ARCLib_SetAnimation(anim)
		self:ARCLib_SetAnimationID(self:LookupSequence(anim))
	end
	function entity:ARCLib_SetAnimationTime(anim,time)
		local animid = self:LookupSequence(anim)
		self:ARCLib_SetAnimationID(animid,time)
	end
	net.Receive( "ARCLib_ModelAnimation", function(length)
		net.ReadEntity():ARCLib_SetAnimationID(net.ReadInt(32),net.ReadDouble(32))
	end)
	hook.Add("Think","ARCLib_ModelAnimations",function()
		for k,v in pairs(ents.GetAll()) do
			if v._ARCLib_Animation then
				v._ARCLib_AnimTime = math.Clamp((v._ARCLib_AnimEndTime - CurTime())/v._ARCLib_AnimScale,0,1)
				--MsgN(v._ARCLib_AnimTime)
				v:SetCycle( v._ARCLib_AnimTime  )
			end
		end
	end)
else
	util.AddNetworkString( "ARCLib_ModelAnimation" )
	function entity:ARCLib_SetAnimationID(animid,time)
		--MsgN("AnimID: "..animid)
		--MsgN("Time: "..time)
		net.Start("ARCLib_ModelAnimation")
		net.WriteEntity(self)
		net.WriteInt(animid,32)
		net.WriteDouble(time)
		net.Broadcast()
	end
	function entity:ARCLib_SetAnimation(anim)
		local animid, time = self:LookupSequence(anim)
		self:ARCLib_SetAnimationID(animid,time)
	end
	function entity:ARCLib_SetAnimationTime(anim,time)
		local animid = self:LookupSequence(anim)
		self:ARCLib_SetAnimationID(animid,time)
	end
end