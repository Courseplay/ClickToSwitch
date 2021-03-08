local modName = g_currentModName
local modDirectory = g_currentModDirectory

---Register the spec_clickToSwitch in all drivable vehicle,horses ...
function validateVehicleTypes(vehicleTypeManager)
	for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
		if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
			vehicleTypeManager:addSpecialization(typeName, modName .. ".clickToSwitch")	
		end
    end
end
VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)


