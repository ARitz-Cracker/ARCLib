ARCLib.Icons16 = {}
for k, v in pairs(file.Find( "materials/icon16/*.png", "GAME" )) do
	ARCLib.Icons16[string.sub(v,1,-5)] = Material ("icon16/"..v, "nocull")
end

ARCLib.FlatIcons64 = {} -- Some of my addons use falticons! :D
for k, v in pairs(file.Find( "materials/arc_flaticons/*.vmt", "GAME" )) do
	ARCLib.FlatIcons64[string.sub(v,1,-5)] = surface.GetTextureID("arc_flaticons/"..string.sub(v,1,-5))
end

-- Returns a material based on a file in the /data folder. TODO: Is the typ paramitar required?
function ARCLib.MaterialFromTxt(mat,typ,param)
	ErrorNoHalt( "ARCLib.MaterialFromTxt is depreciated as GMod now allows for images to be written in the data folder." )
	typ = string.lower(typ)
	assert(typ == "png" || typ == "jpg","ARCLib.MaterialFromTxt: Second argument is not \"png\" or \"jpg\"")
	local ret = Material("../data/" .. mat .. "\n."..typ, param)
	LocalPlayer():ConCommand("mat_reloadmaterial ../data/" .. mat .. "*")
	return ret
end

file.CreateDir("arclib_cache")
file.CreateDir("arclib_cache/icons")
file.CreateDir("arclib_cache/icons/16")
file.CreateDir("arclib_cache/icons/32")
file.CreateDir("arclib_cache/icons/16g")
file.CreateDir("arclib_cache/icons/32g")

ARCLib._WebIcons16 = {}
for k, v in pairs(file.Find( "arclib_cache/icons/16/*.png", "DATA" )) do
	ARCLib._WebIcons16[string.sub( v, 1, #v-4 )] = Material ("../data/arclib_cache/icons/16/"..v, "nocull smooth")
end
ARCLib._WebIcons32 = {}
for k, v in pairs(file.Find( "arclib_cache/icons/32/*.png", "DATA" )) do
	MsgN("../data/arclib_cache/icons/32/"..v)
	ARCLib._WebIcons32[string.Replace(v,".png","")] = Material ("../data/arclib_cache/icons/32/"..v, "nocull smooth")
end

ARCLib._WebIcons16Gray = {}
for k, v in pairs(file.Find( "arclib_cache/icons/16g/*.png", "DATA" )) do
	ARCLib._WebIcons16Gray[string.sub( v, 1, #v-4 )] = Material ("../data/arclib_cache/icons/16g/"..v, "nocull smooth")
end
ARCLib._WebIcons32Gray = {}
for k, v in pairs(file.Find( "arclib_cache/icons/32g/*.png", "DATA" )) do
	ARCLib._WebIcons32Gray[string.Replace(v,".png","")] = Material ("../data/arclib_cache/icons/32g/"..v, "nocull smooth")
end

local function GetIconFromInterwebs(tab,dirname,urlname,iconname,retries)
	http.Fetch( urlname..iconname..".png",
		function( body, len, headers, code )
			-- The first argument is the HTML we asked for.
			
			if code >= 500 then
				if retries > 9 then
					tab[iconname] = ARCLib.Icons16["emotocon_unhappy"]
					MsgN("ARCLib: "..urlname..iconname..".png Returned: HTTP "..code.." failed after trying 10 times.")
				else
					timer.Simple(1,function()
						GetIconFromInterwebs(tab,dirname,urlname,iconname,retries+1)
					end)
				end
			elseif code >= 400 then
				MsgN("ARCLib: "..urlname..iconname..".png Returned: HTTP "..code)
				tab[iconname] = ARCLib.Icons16["emotocon_unhappy"]
			else
				file.Write(dirname..iconname..".png",body)
				MsgN("../data/"..dirname..iconname..".png")
				tab[iconname] = Material ("../data/"..dirname..iconname..".png", "nocull")
			end
		end,
		function( err )
			timer.Simple(1,function()
				if retries > 9 then
					tab[iconname] = ARCLib.Icons16["emotocon_unhappy"]
					MsgN("ARCLib: "..urlname..iconname..".png Returned: Lua HTTP "..err.." failed after trying 10 times.")
				else
					timer.Simple(1,function()
						GetIconFromInterwebs(tab,dirname,urlname,iconname,retries+1)
					end)
				end
			end)
		end
	)
end
ARCLib.ICON_16 = 1
ARCLib.ICON_32 = 2
ARCLib.ICON_16_GRAY = 3
ARCLib.ICON_32_GRAY = 4


function ARCLib.GetIcon(t,name)
	local tab 
	if t == ARCLib.ICON_16 then
		tab = ARCLib._WebIcons16
	elseif t == ARCLib.ICON_32 then
		tab = ARCLib._WebIcons32
	elseif t == ARCLib.ICON_16_GRAY then
		tab = ARCLib._WebIcons16Gray
	elseif t == ARCLib.ICON_32_GRAY then
		tab = ARCLib._WebIcons32Gray
	end
	if (!tab || !name) then return ARCLib.Icons16["emotocon_unhappy"] end
	if (tab[name]) then
		return tab[name]
	end
	if ARCLib.Icons16[name] then
		tab[name] = ARCLib.Icons16[name]
	else
		tab[name] = ARCLib.Icons16["bullet_blue"]
	end
	local dirname = "arclib_cache/icons/"
	local urlname = "https://elur1.bste.ca/fatcow_icons"
	if t == 1 then
		dirname = dirname .. "16/"
		urlname = urlname .. "/16/"
	elseif t == 2 then
		dirname = dirname .. "32/"
		urlname = urlname .. "/32/"
	elseif t == 3 then
		dirname = dirname .. "16g/"
		urlname = urlname .. "_gray/16/"
	elseif t == 4 then
		dirname = dirname .. "32g/"
		urlname = urlname .. "_gray/32/"
	end
	GetIconFromInterwebs(tab,dirname,urlname,name,0)
	return tab[name]
end

function ARCLib.GetWebIcon16(name)
	return ARCLib.GetIcon(1,name)
end
function ARCLib.GetWebIcon32(name)
	return ARCLib.GetIcon(2,name)
end
function ARCLib.GetWebIcon16Gray(name)
	return ARCLib.GetIcon(3,name)
end
function ARCLib.GetWebIcon32Gray(name)
	return ARCLib.GetIcon(4,name)
end


