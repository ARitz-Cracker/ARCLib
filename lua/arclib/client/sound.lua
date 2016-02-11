--sounds
file.CreateDir("arclib_cache")
file.CreateDir("arclib_cache/sound")
function ARCLib.PlayCachedURL(url,flags,callback)
	local path
	for i=1,#url do
		if url[i] == ":" && url[i+1] == "/" && url[i+2] == "/" then
			path = string.Explode("/",string.sub( url, i+3))
			--MsgN(string.sub( url, i+3))
			break;
		end
	end
	path[1] = "arclib_cache/sound/"..path[1]
	for i=2,#path do
		path[i] = path[i-1].."/"..path[i]
	end
	path[#path]=path[#path]..".dat"
	for i=1,#path-1 do
		file.CreateDir(path[i])
	end
	if file.Exists(path[#path],"DATA") then
		sound.PlayFile( path[#path], flags, callback )
	else
		http.Fetch( url,
			function( body, len, headers, code )
				-- The first argument is the HTML we asked for.
				if code >= 400 then
					callback(nil,-2,"URL Returned: "..code)
				else
					file.Write(path[#path],body)
					sound.PlayFile( path[#path], flags, callback )
				end
			end,
			function( err )
				callback(nil,-3,"HTTP Error: "..err)
			end
		)
	end
end

hook.Add( "ShutDown", "ARCLib CachedSounds", function()
	ARCLib.DeleteAll("arclib_cache/sound")
end)
