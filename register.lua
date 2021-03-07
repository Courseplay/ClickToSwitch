local modName = g_currentModName
local modDirectory = g_currentModDirectory

local ClickToSwitchRegister = {}

function init()
	VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, validateVehicleTypes)
end


function validateVehicleTypes(vehicleTypeManager)
	ClickToSwitchRegister.installSpecializations(vehicleTypeManager, modDirectory, modName)
end

function ClickToSwitchRegister.installSpecializations(vehicleTypeManager, modDirectory, modName)	
	for typeName, typeEntry in pairs(vehicleTypeManager:getVehicleTypes()) do
		if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
			vehicleTypeManager:addSpecialization(typeName, modName .. ".clickToSwitch")	
		end
    end

end

init()

