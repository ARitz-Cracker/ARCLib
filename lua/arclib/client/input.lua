
function ARCLib.IsCTRLDown()
	if system.IsOSX() then -- OSX is special with their COMMAND key
		return input.IsKeyDown( KEY_LWIN ) || input.IsKeyDown( KEY_RWIN ) 
	else
		return input.IsKeyDown( KEY_LCONTROL ) || input.IsKeyDown( KEY_RCONTROL ) 
	end
end