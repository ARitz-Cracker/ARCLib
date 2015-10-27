-- Utilities regarding file I/O

-- Makes a string "safe" for file names.
function ARCLib.FileSafe(name)
	return string.lower(string.gsub(name, "[^_%w]", "_"))
end


function ARCLib.DeleteAll(dir) --Exactly like doing "rm -rf [dir]" on linux
	if file.IsDir(dir) then
		local files, directories = file.Find( dir.."/*", "DATA" )
		for k,v in pairs(files) do
			file.Delete(dir.."/"..v)
		end
		for k,v in pairs(directories) do
			ARCLib.DeleteAll(dir.."/"..v)
		end
		file.Delete(dir)
	end
end

function ARCLib.DeleteOldFiles(time,dir,recur,delfol)
	local dtime = os.time()-time
	local files, directories = file.Find( dir.."/*", "DATA" )
	for i=1,#files do
		if file.Time( dir.."/"..files[i], "DATA") < dtime then
			file.Delete(dir.."/"..files[i])
		end
	end
	if recur then
		for i=1,#directories do
			ARCLib.DeleteOldFiles(time,dir.."/"..directories[i],true,delfol)
		end
		if delfol then
			file.Delete(dir)
		end
	end
end
