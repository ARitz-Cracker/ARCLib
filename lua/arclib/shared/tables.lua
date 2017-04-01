-- Table stuffs


local CachedTables = {}
if timer.Exists( "ARCLib_DumpCachedTables" ) then
	timer.Destroy( "ARCLib_DumpCachedTables" )
end
timer.Create( "ARCLib_DumpCachedStrings", 30, 0, function() 
	table.Empty(CachedTables)
end)
function ARCLib.TableHasValueCached(tab,val)
	if (!CachedTables[tab]) then
		CachedTables[tab] = {}
		for k,v in pairs(tab) do
			CachedTables[tab][v] = true
		end	
	end
	return CachedTables[tab][val] == true
end
function ARCLib.TableFillGapInsert(tab,val)
	local i = 1
	while tab[i] ~= nil do
		i = i + 1
	end
	tab[i] = val
	return i
end

function ARCLib.TableMergeOptimized( dest, source ) -- Slightly more optimized version of table.Marge (except it makes both tables equal to each other...)
	for k, v in pairs( dest ) do
		if source[k] == nil then
			source[k] = v
		end
	end
	dest = source
	
	return dest
end


function ARCLib.RecursiveTableMerge(overwrite,tab)
	if !overwrite then overwrite = {} end
	for k,v in pairs(tab) do
		if istable(v) && istable(overwrite[k]) then
			overwrite[k] = ARCLib.RecursiveTableMerge(overwrite[k],v)
		else
			overwrite[k] = v
		end
	end
	return overwrite
end

-- Checks how many items are in a table
function ARCLib.TableAmount(tab)
	error("Use table.Count instead")
	local am = 0
	for k,v in pairs(tab) do
		am = am + 1
	end
	return am
end

function ARCLib.RecursiveHasValue(tab,value)
	local result = false
	for k,v in pairs(tab) do
		if istable(v) then
			result = result or ARCLib.RecursiveHasValue(v,value)
		end
		result = result or (v == value)
	end
	return result
end

function ARCLib.TableToSequential(tab)
	local result = {}
	local i = 0
	for k,v in pairs(tab) do
		i = i + 1
		result[i] = v
	end
	return result
end


function ARCLib.JSONSafe( t, done )
	local done = done or {}
	local tbl = {}
	for k, v in pairs ( t ) do
		if ( istable( v ) and !done[ v ] ) then
			done[ v ] = true
			tbl[ k ] = table.Sanitise( v, done )
		else
			if ( type( v ) == "Vector" ) then
				local x, y, z = v.x, v.y, v.z
				if y == 0 then y = nil end
				if z == 0 then z = nil end
				tbl[ k ] = { __type = "Vector", x = x, y = y, z = z }
			elseif ( type( v ) == "Angle" ) then
				local p, y, r = v.pitch, v.yaw, v.roll
				if p == 0 then p = nil end
				if y == 0 then y = nil end
				if r == 0 then r = nil end
				tbl[ k ] = { __type = "Angle", p = p, y = y, r = r }
			elseif ( type( v ) == "boolean" ) then
				tbl[ k ] = { __type = "Bool", tostring( v ) }
			elseif ( type( v ) == "number" ) then
				--tbl[ k ] = { __type = "Number", tostring( v ) }
				tbl[ k ] = v
			elseif ( IsColor(v) ) then
				tbl[ k ] = { __type = "Color", r = v.r, g = v.g, b = v.b, a= v.a }
			else
				tbl[ k ] = tostring( v )
			end
		end
	end
	return tbl
end

function ARCLib.UnJSONSafe( t, done )
	local done = done or {}
	local tbl = {}
	for k, v in pairs ( t ) do
		if ( istable( v ) and !done[ v ] ) then
			done[ v ] = true
			if ( v.__type ) then
				if ( v.__type == "Vector" ) then
					tbl[ k ] = Vector( v.x, v.y, v.z )
				elseif ( v.__type == "Angle" ) then
					tbl[ k ] = Angle( v.p, v.y, v.r )
				elseif ( v.__type == "Bool" ) then
					tbl[ k ] = ( v[ 1 ] == "true" )
				--elseif ( v.__type == "Number" ) then
					--tbl[ k ] = tonumber( v[ 1 ] )
				elseif ( IsColor(v) ) then
					tbl[ k ] = Color( v.r, v.g, v.b , v.a )
				end
			else
				tbl[ k ] = table.DeSanitise( v, done )
			end
		else
			tbl[ k ] = v
		end
	end
	return tbl
end

function ARCLib.RemoveAllByValue(tab,val)
	if table.IsSequential(tab) then
		local i = #tab
		while i > 0 do
			if tab[i] == val then
				table.remove(tab,i)
			end
			i = i - 1
		end
	else
		for k,v in pairs(tab) do
			if v == val then
				table.remove(tab,k)
			end
		end
	end
end
