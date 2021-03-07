
ClickToSwitch = {}

ClickToSwitch.MOD_NAME = g_currentModName

function ClickToSwitch.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Drivable, specializations) 
end

function ClickToSwitch.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ClickToSwitch)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ClickToSwitch)
end

function ClickToSwitch.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setShowMouseCursor", ClickToSwitch.setShowMouseCursor)
    SpecializationUtil.registerFunction(vehicleType, "tryToEnterVehicle", ClickToSwitch.tryToEnterVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getLastMousePosition", ClickToSwitch.getLastMousePosition)
    SpecializationUtil.registerFunction(vehicleType, "raycastCallback", ClickToSwitch.raycastCallback)
end

function ClickToSwitch:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and not g_courseplay and not self.spec_courseplay then
        local spec = self.spec_clickToSwitch
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            --toggle mouse
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE, self, ClickToSwitch.actionEventToggleMouse, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleMouse)
            --enter vehicle
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE, self, ClickToSwitch.actionEventEnterVehicle, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.enterVehicle)

            ClickToSwitch.updateActionEventState(self)
        end
    end
end;

function ClickToSwitch.updateActionEventState(self)
    local spec = self.spec_clickToSwitch
    local actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.mouseActive)
end

function ClickToSwitch.actionEventToggleMouse(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_clickToSwitch
    self:setShowMouseCursor(not spec.mouseActive)
end

function ClickToSwitch.actionEventEnterVehicle(self, actionName, inputValue, callbackState, isAnalog)
    local x,y = self:getLastMousePosition()
    self:tryToEnterVehicle(x,y)
end

function ClickToSwitch:onLoad(savegame)
	local specName = ClickToSwitch.MOD_NAME .. ".clickToSwitch"
    self.spec_clickToSwitch = self["spec_" .. specName]
    local spec = self.spec_clickToSwitch

    spec.texts = {}
    spec.texts.toggleMouse = g_i18n:getText("CLICK_TO_SWITCH_TOGGLE_MOUSE")
    spec.texts.enterVehicle = g_i18n:getText("CLICK_TO_SWITCH_ENTER_VEHICLE")
    spec.mouseActive = false
    spec.camerasBackup = {}
    for camIndex, camera in pairs(self.spec_enterable.cameras) do
		if camera.isRotatable then
			spec.camerasBackup[camIndex] = camera.isRotatable
		end
	end
end

function ClickToSwitch:isMouseActive()
    return self.mouseActive
end

function ClickToSwitch:isAllowed()
	return true --not (self.spec_attachable and self.spec_attachable.attacherVehicle)
end

function ClickToSwitch:setShowMouseCursor(show)
    local spec = self.spec_clickToSwitch
	g_inputBinding:setShowMouseCursor(show)
    spec.mouseActive = show
  --  g_currentMission.isPlayerFrozen = show
    ClickToSwitch.updateActionEventState(self)
    --Cameras: deactivate/reactivate zoom function in order to allow CP mouse wheel
	for camIndex,_ in pairs(spec.camerasBackup) do
		self.spec_enterable.cameras[camIndex].isRotatable = not show
	--	print(string.format("%s: right mouse key (mouse cursor=%s): camera %d allowTranslation=%s", tostring(self:getName()), tostring(show), camIndex, tostring(self.spec_enterable.cameras[camIndex].isRotatable)));
	end

end

function ClickToSwitch:getLastMousePosition()
    return g_inputBinding.mousePosXLast,g_inputBinding.mousePosYLast 
end


-- let's find out if a vehicle is under the cursor by casting a ray in that direction
function ClickToSwitch:tryToEnterVehicle(posX, posY)
    local activeCam = getCamera()
    if activeCam ~= nil then
        local hx, hy, hz, px, py, pz = RaycastUtil.getCameraPickingRay(posX, posY, activeCam)
        raycastClosest(hx, hy, hz, px, py, pz, "raycastCallback", 1000, self, 371)
    end
end

-- this is called when the ray hits something
function ClickToSwitch:raycastCallback(hitObjectId, x, y, z, distance)
    if hitObjectId ~= nil then
        local object = g_currentMission:getNodeObject(hitObjectId)    
        if object ~= nil then
            -- check if the object is a implement or trailer then get the rootVehicle 
            local rootVehicle = object.getRootVehicle and object:getRootVehicle()
            local enterableSpec = object.spec_enterable or rootVehicle and rootVehicle.spec_enterable
            local targetObject = object.spec_enterable and object or rootVehicle 
            if enterableSpec then 
                -- this is a valid vehicle, so enter it
                g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(targetObject, g_currentMission.missionInfo.playerStyle, g_currentMission.player.ownerFarmId));
                self:setShowMouseCursor(false)
                return false
            end                
        end
    end
    return true
end
