-- Big shoutout to bobbleheadbob and JamesXx for helping me with this

local RTs = {}
local DRAWING_RT = false
local UPDATING_RT = false
ARCLib.TrackRT = false
local unique = 0
local function generateUniqueName()
	local result = "__arclib"..unique.."arclib__"
	while RTs[result] do
		if unique > 127 then -- Let's just hope that there aren't more than 128 RTs
			unique = 0
		else
			unique = unique + 1
		end
		result = "__arclib"..unique.."arclib__"
	end
	return result
end

hook.Add( "RenderScene", "ARCLib RenderRTs", function( wat, skybox )

	if ( not LocalPlayer() ) then return end
	if ( not skybox ) then return end
	
	if ( not DRAWING_RT ) then
		UPDATING_RT = false
		DRAWING_RT = true

		for k, v in pairs( RTs ) do
			if v.Update then
				render.PushRenderTarget( v.RenderTarget, 0, 0, v.renderInformation.w, v.renderInformation.h ) 
				render.Clear( 0, 0, 0, 255, true, true )
					if v.Func then
						v.Func()
					else
						UPDATING_RT = true
						render.RenderView(v.renderInformation)
					end
					if v.Func3D then
						cam.Start3D()
							v.Func3D()
						cam.End3D()
					end
					if v.Func2D then
						cam.Start2D()
							v.Func2D()
						cam.End2D()
					end
					render.UpdateScreenEffectTexture()
					if v.Screenie then
						v.Screenie(render.Capture({
							format = v.ScreenieFormat,
							quality = v.ScreenieQuality,
							h = v.renderInformation.h,
							w = v.renderInformation.w,
							x = v.renderInformation.x,
							y = v.renderInformation.y,
						}))
						v.Screenie = nil
						v.ScreenieFormat = nil
						v.ScreenieQuality = nil
					end
				render.PopRenderTarget()

			end
		end

		DRAWING_RT = false
	end

end)
local color_nothing = Color( 0, 0, 0, 0 )
hook.Add("PreDrawHalos", "ARCLib HorribleWorkaroundIHateDoingThis", function()
	if UPDATING_RT then
		halo.Add({LocalPlayer()}, color_nothing,0,0,0)
	end
end)

hook.Add( "ShouldDrawLocalPlayer", "ARCLib PlayerRTs", function( ply )
	if ( DRAWING_RT ) then
		return true
	end
	--return false
end)

hook.Add( "GetMotionBlurValues", "ARCLib PlayerRTs GetMotionBlurValues", function( x, y, fwd, spin )
	if ( DRAWING_RT ) then
		return 0, 0, 0, 0
	end
end )
 
hook.Add( "PostProcessPermitted", "ARCLib PlayerRTs PostProcessPermitted", function( element )
	if ( DRAWING_RT and element == "bloom" ) then
		return false
	end
end )

local RT_OBJECT = {}
function RT_OBJECT:Disable()
	ARCLib.DisableRenderTarget(self.name)
end
function RT_OBJECT:Enable()
	ARCLib.EnableRenderTarget(self.name)
end
function RT_OBJECT:SetFunc(func)
	ARCLib.SetRenderTargetFunc(self.name,func)
end
function RT_OBJECT:SetFunc2D(func)
	ARCLib.SetRenderTargetFunc2D(self.name,func)
end
function RT_OBJECT:SetFunc3D(func)
	ARCLib.SetRenderTargetFunc(self.name,func)
end
function RT_OBJECT:SetPos(pos)
	ARCLib.SetRenderTargetPos(self.name,pos)
end
function RT_OBJECT:SetAngles(ang)
	ARCLib.SetRenderTargetAngles(self.name,ang)
end
function RT_OBJECT:SetFov(ang)
	ARCLib.SetRenderTargetFov(self.name,ang)
end
function RT_OBJECT:Capture(format,quality,callback)
	ARCLib.CaptureRenderTarget(self.name,format,quality,callback)
end
function RT_OBJECT:Destroy()
	ARCLib.DestroyRenderTarget(self.name)
end
function RT_OBJECT:GetTexture()
	return ARCLib.GetRenderTargetTexture(self.name)
end
function RT_OBJECT:GetMaterial()
	return ARCLib.GetRenderTargetMaterial(self.name)
end
function RT_OBJECT:IsValid()
	return RTs[self.name] != nil
end
function ARCLib.PrintRT()
	PrintTable(RTs)
end
function ARCLib.CreateRenderTarget(name,w,h,pos,angles,fov)
	local rt = {}
	if !isstring(name) then
		name = generateUniqueName()
	end
	assert(isnumber(w) and w > 16,"ARCLib.CreateRenderTarget: Width must be greater than 16")
	assert(isnumber(h) and h > 16,"ARCLib.CreateRenderTarget: Height must be greater than 16")
	pos = pos or vector_origin
	angles = angles or angle_zero
	fov = fov or 75
	
	
	rt.RenderTarget = GetRenderTarget( name, w, h, false )
	rt.renderInformation = {
		origin = pos,
		angles = angles,
		x = 0,
		y = 0,
		w = w,
		h = h,
		fov = fov,
		dopostprocess = false,
		drawhud = false,
		drawmonitors = false,
		drawviewmodel = true,
		ortho = false
	}
	RTs[name] = rt
	local tab = table.Copy(RT_OBJECT)
	tab.name = name
	return tab
end

function ARCLib.DisableRenderTarget(name)
	RTs[name].Update = false
end

function ARCLib.EnableRenderTarget(name)
	RTs[name].Update = true
end

function ARCLib.SetRenderTargetFunc(name,func)
	RTs[name].Func = func
end

function ARCLib.SetRenderTargetFunc3D(name,func)
	RTs[name].Func3D = func
end
function ARCLib.SetRenderTargetFunc2D(name,func)
	RTs[name].Func2D = func
end

function ARCLib.SetRenderTargetPos(name,pos)
	RTs[name].renderInformation.origin = pos or vector_origin
end
function ARCLib.SetRenderTargetAngles(name,ang)
	RTs[name].renderInformation.angles = ang or angle_zero
end
function ARCLib.SetRenderTargetFov(name,pos)
	RTs[name].renderInformation.fov = pos or 75
end

function ARCLib.CaptureRenderTarget(name,format,quality,callback)
	timer.Simple(0.01,function()
		if RTs[name] then
			RTs[name].Screenie = callback
			RTs[name].ScreenieFormat = format
			RTs[name].ScreenieQuality = quality
		end
	end)
end

function ARCLib.DestroyRenderTarget(name)
	RTs[name] = nil --TODO: There's a GetRenderTarget, but there is no KillRenderTarget??
end

function ARCLib.GetRenderTargetTexture(name)
	return RTs[name].RenderTarget
end

function ARCLib.GetRenderTargetMaterial(name)
	if !RTs[name].material then
		local params = {}
		params[ "$basetexture" ] = RTs[name].RenderTarget:GetName()
		params[ "$vertexcolor" ] = 1
		params[ "$vertexalpha" ] = 0
		-- params[ "$model" ] = 1 -- TODO: Is this required?
		RTs[name].material = CreateMaterial( "arclib_rt_"..name, "UnlitGeneric", params )
	end
	return RTs[name].material
end
