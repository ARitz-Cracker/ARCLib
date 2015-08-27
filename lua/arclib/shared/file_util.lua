-- Utilities regarding file I/O

-- Makes a string "safe" for file names.
function ARCLib.FileSafe(name)
	return string.lower(string.gsub(name, "[^_%w]", "_"))
end

-- Returns a material based on a file in the /data folder. TODO: Is the typ paramitar required?
function ARCLib.MaterialFromTxt(mat,typ,param)
	typ = string.lower(typ)
	assert(typ == "png" || typ == "jpg","ARCLib.MaterialFromTxt: Second argument is not \"png\" or \"jpg\"")
	local ret = Material("../data/" .. mat .. "\n."..typ, param)
	LocalPlayer():ConCommand("mat_reloadmaterial ../data/" .. mat .. "*")
	return ret
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