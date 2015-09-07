-- Utilities regarding file I/O

-- Makes a string "safe" for file names.
function ARCLib.FileSafe(name)
	return string.lower(string.gsub(name, "[^_%w]", "_"))
end


function ARCLib.DeleteAll(dir) --Exactly like doing "rm -rf [dir]" on linux
	local files, directories = file.Find( dir.."/*", "DATA" )
	for k,v in pairs(files) do
		file.Delete(dir.."/"..v)
	end
	for k,v in pairs(directories) do
		ARCLib.DeleteAll(dir.."/"..v)
	end
	file.Delete(dir)
end