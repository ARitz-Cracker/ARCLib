--sounds
file.CreateDir("arclib_cache")
file.CreateDir("arclib_cache/sound")
local cachingSounds = {}
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
		sound.PlayFile( "data/"..path[#path], flags, callback )
	else
		if cachingSounds[url] then -- Don't download the same file again
			table.insert(cachingSounds[url],{"data/"..path[#path], flags, callback})
			return
		end
		cachingSounds[url] = {} -- Subsequent requests for the same URL will wait until the file has downloaded. The same file doesn't have to be downloaded more than twice.
		sound.PlayURL(url,flags,callback) -- Stream the first time, allowing for faster playback.
		http.Fetch( url,
			function( body, len, headers, code )
				-- The first argument is the HTML we asked for.
				if code >= 400 then
					for k,v in ipairs(cachingSounds[url]) do
						sound.PlayFile(nil,-2,"URL Returned: "..code)
					end
					cachingSounds[url] = nil
				else
					file.Write(path[#path],body)
					for k,v in ipairs(cachingSounds[url]) do
						sound.PlayFile(unpack(v))
					end
					cachingSounds[url] = nil
				end
			end,
			function( err )
				for k,v in ipairs(cachingSounds[url]) do
					sound.PlayFile(nil,-3,"HTTP Error: "..err)
				end
				cachingSounds[url] = nil
			end
		)
	end
end

hook.Add( "ShutDown", "ARCLib CachedSounds", function()
	ARCLib.DeleteAll("arclib_cache/sound")
end)
