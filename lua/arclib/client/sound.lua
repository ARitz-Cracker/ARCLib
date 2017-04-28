--sounds
file.CreateDir("arclib_cache")
file.CreateDir("arclib_cache/sound")
local cachingSounds = {}
local function getPathTable(url)
	local place = select(2,string.find( url, "://", 1, true ))
	if not place then return nil end
	local path = string.Explode("/",string.sub( url, place+1))
	if (path[1] == "www.youtube.com") then
		local stuffs = string.Explode("?",path[2] or "")
		if stuffs[1] ~= "watch" then
			return nil
		end
		local prm = ARCLib.DecodeURI(stuffs[2])
		if prm["v"] then
			return getPathTable("http://youtu.be/"..prm["v"])
		end
		return nil
	end
	
	path[1] = "arclib_cache/sound/"..path[1]
	for i=2,#path do
		path[i] = path[i-1].."/"..path[i]
	end
	path[#path]=string.Explode("?",path[#path])[1]..".dat"
	for i=1,#path-1 do
		file.CreateDir(path[i])
	end
	return path
end
local specialPaths = {}
specialPaths["arclib_cache/sound/youtu.be"] = function(url,path)
	local filepath = path[#path]
	local paths = string.Explode("/",filepath)
	local ytid = string.sub(paths[#paths],1,-5)
	local function httperr( err )
		for k,v in ipairs(cachingSounds[filepath]) do
			v[3](nil,-3,"HTTP Error: "..err)
		end
		cachingSounds[filepath] = nil
	end
	
	http.Fetch( "http://www.youtubeinmp3.com/fetch/?format=JSON&start=0&video=http://www.youtube.com/watch?v="..ytid,function( body, len, headers, code )
		if code >= 400 then
			for k,v in ipairs(cachingSounds[filepath]) do
				v[3](nil,-2,"URL Returned: "..code)
			end
			cachingSounds[filepath] = nil
		else
			local meta = util.JSONToTable( body ) or {}
			if not meta["link"] then
				print("No download link: "..body)
				for k,v in ipairs(cachingSounds[filepath]) do
					v[3](nil,-5,"Failed to convert YouTube URL to MP3.")
				end
				cachingSounds[filepath] = nil
				return
			end
			http.Fetch( meta["link"],function( body, len, headers, code )
				if code >= 400 then
					for k,v in ipairs(cachingSounds[filepath]) do
						v[3](nil,-2,"URL Returned: "..code)
					end
					cachingSounds[filepath] = nil
				else
					file.Write(filepath,body)
					for k,v in ipairs(cachingSounds[filepath]) do
						sound.PlayFile(unpack(v))
					end
					cachingSounds[filepath] = nil
				end
			end,httperr)
		end
	end,httperr)
end

function ARCLib.PreCacheSoundURL(url)
	local path = getPathTable(url)
	if not path then return end
	local filepath = path[#path]
	cachingSounds[filepath] = cachingSounds[filepath] or {}
	if specialPaths[path[1]] then
		specialPaths[path[1]](url,path)
	else
		http.Fetch( url,
			function( body, len, headers, code )
				-- The first argument is the HTML we asked for.
				if code >= 400 then
					for k,v in ipairs(cachingSounds[filepath]) do
						v[3](nil,-2,"URL Returned: "..code)
					end
					cachingSounds[filepath] = nil
				else
					
					file.Write(filepath,body)
					for k,v in ipairs(cachingSounds[filepath]) do
						sound.PlayFile(unpack(v))
					end
					cachingSounds[filepath] = nil
				end
			end,
			function( err )
				for k,v in ipairs(cachingSounds[filepath]) do
					v[3](nil,-3,"HTTP Error: "..err)
				end
				cachingSounds[filepath] = nil
			end
		)
	end
end

function ARCLib.PlayCachedURL(url,flags,callback)
	local path = getPathTable(url)
	if not path then
		callback(nil,20,"URL is invalid") -- 20 is BASS_ERROR_ILLPARAM for bass.
		return
	end
	local filepath = path[#path]
	if file.Exists(filepath,"DATA") then
		sound.PlayFile( "data/"..filepath, flags, callback )
	else
		if cachingSounds[filepath] then -- Don't download the same file again
			table.insert(cachingSounds[filepath],{"data/"..filepath, flags, callback})
			return
		end
		ARCLib.PreCacheSoundURL(url) -- Subsequent requests for the same URL will wait until the file has downloaded. The same file doesn't have to be downloaded more than twice.
		PrintTable(specialPaths)
		if specialPaths[path[1]] then
			table.insert(cachingSounds[filepath],{"data/"..filepath, flags, callback})
		else
			sound.PlayURL(url,flags,callback) -- Stream the first time, allowing for faster playback.
		end
	end
end

hook.Add( "ShutDown", "ARCLib CachedSounds", function()
	ARCLib.DeleteAll("arclib_cache/sound")
end)
