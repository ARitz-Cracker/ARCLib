ARCLib.Icons16 = {}
for k, v in pairs(file.Find( "materials/icon16/*.png", "GAME" )) do
	ARCLib.Icons16[string.Replace(v,".png","")] = Material ("icon16/"..v, "nocull")
end
ARCLib.Icons32 = {}
for k, v in pairs(file.Find( "materials/icon32/*.png", "GAME" )) do
	ARCLib.Icons32[string.Replace(v,".png","")] = Material ("icon32/"..v, "nocull")
end

ARCLib.Icons32t = {} -- Some of my addons have vmt versions of the 32x32 icons
for k, v in pairs(file.Find( "materials/icon32_t/*.vmt", "GAME" )) do
	ARCLib.Icons32t[string.Replace(v,".vmt","")] = surface.GetTextureID("icon32_t/"..string.Replace(v,".vmt",""))
end

ARCLib.FlatIcons64 = {} -- Some of my addons use falticons! :D
for k, v in pairs(file.Find( "materials/arc_flaticons/*.vmt", "GAME" )) do
	ARCLib.FlatIcons64[string.Replace(v,".vmt","")] = surface.GetTextureID("arc_flaticons/"..string.Replace(v,".vmt",""))
end

-- Returns a material based on a file in the /data folder. TODO: Is the typ paramitar required?
function ARCLib.MaterialFromTxt(mat,typ,param)
	typ = string.lower(typ)
	assert(typ == "png" || typ == "jpg","ARCLib.MaterialFromTxt: Second argument is not \"png\" or \"jpg\"")
	local ret = Material("../data/" .. mat .. "\n."..typ, param)
	LocalPlayer():ConCommand("mat_reloadmaterial ../data/" .. mat .. "*")
	return ret
end