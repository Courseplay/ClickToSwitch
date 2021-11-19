local modName = g_currentModName
local modDirectory = g_currentModDirectory

---Register the spec_clickToSwitch in all drivable vehicle,horses ...
function validateVehicleTypes(typeManager)
	for typeName, typeEntry in pairs(typeManager.types) do
		if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
			typeManager:addSpecialization(typeName, modName .. ".clickToSwitch")	
		end
    end
end
TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, validateVehicleTypes)

function restartSaveGame(saveGameNumber)
	if g_server then
		restartApplication(" -autoStartSavegameId " .. saveGameNumber)
	end
end
addConsoleCommand( 'cpRestartSaveGame', 'Load and start a savegame', 'restartSaveGame')
