
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
    SpecializationUtil.registerFunction(vehicleType, "getLastMousePosition", ClickToSwitch.getLastMousePosition)
    SpecializationUtil.registerFunction(vehicleType, "isClickToSwitchAllowed", ClickToSwitch.isClickToSwitchAllowed)
    SpecializationUtil.registerFunction(vehicleType, "isChangingMouseStateAllowed", ClickToSwitch.isChangingMouseStateAllowed)
    SpecializationUtil.registerFunction(vehicleType, "isMouseActive", ClickToSwitch.isMouseActive)
    SpecializationUtil.registerFunction(vehicleType, "enterVehicleRaycast", ClickToSwitch.enterVehicleRaycast)
    SpecializationUtil.registerFunction(vehicleType, "enterVehicleRaycastCallback", ClickToSwitch.enterVehicleRaycastCallback)
end

---Register toggle mouse state and clickToSwitch action events
---@param bool isActiveForInput
---@param bool isActiveForInputIgnoreSelection
function ClickToSwitch:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and not g_courseplay and not self.spec_courseplay then
        local spec = self.spec_clickToSwitch
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            ---Toggle mouse action event
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE, self, ClickToSwitch.actionEventToggleMouse, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleMouse)
            ---ClickToSwitch (enter vehicle by mouse button) action event
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE, self, ClickToSwitch.actionEventEnterVehicle, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.enterVehicle)

            ClickToSwitch.updateActionEventState(self)
        end
    end
end;

---Updates toggle mouse state and clickToSwitch action events visibility and usability 
---@param class self 
function ClickToSwitch.updateActionEventState(self)
    ---Activate/deactivate the clickToSwitch action event 
    local spec = self.spec_clickToSwitch
    local actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:isClickToSwitchAllowed())
    
    ---If changing mouse is not allowed, for example by a extern mod, then deactivate the action event  
    if not self:isChangingMouseStateAllowed() then
        local actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE]
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
    end
end

---Action event for turning the mouse on/off
---@param class self 
---@param class actionName 
---@param class inputValue 
---@param class callbackState 
---@param class isAnalog 
function ClickToSwitch.actionEventToggleMouse(self, actionName, inputValue, callbackState, isAnalog)
    if self:isChangingMouseStateAllowed() then
        local spec = self.spec_clickToSwitch
        self:setShowMouseCursor(not self:isMouseActive())
    end
end

---Action event for entering a vehicle by mouse click
---@param class self 
---@param class actionName 
---@param class inputValue 
---@param class callbackState 
---@param class isAnalog 
function ClickToSwitch.actionEventEnterVehicle(self, actionName, inputValue, callbackState, isAnalog)
    if self:isClickToSwitchAllowed() then
        local x,y = self:getLastMousePosition()
        self:enterVehicleRaycast(x,y)
    end
end

function ClickToSwitch:onLoad(savegame)
	---Register the spec: spec_clickToSwitch
    local specName = ClickToSwitch.MOD_NAME .. ".clickToSwitch"
    self.spec_clickToSwitch = self["spec_" .. specName]
    local spec = self.spec_clickToSwitch
    
    spec.texts = {}
    spec.texts.toggleMouse = g_i18n:getText("CLICK_TO_SWITCH_TOGGLE_MOUSE")
    spec.texts.enterVehicle = g_i18n:getText("CLICK_TO_SWITCH_ENTER_VEHICLE")
    spec.mouseActive = false
    ---Creating a backup table of all camera and if they are rotatable
    spec.camerasBackup = {}
    for camIndex, camera in pairs(self.spec_enterable.cameras) do
		if camera.isRotatable then
			spec.camerasBackup[camIndex] = camera.isRotatable
		end
	end
end

---Is the mouse visible/active
function ClickToSwitch:isMouseActive()
    local spec = self.spec_clickToSwitch
    return spec.mouseActive
end

---Is entering vehicle by mouse click allowed
function ClickToSwitch:isClickToSwitchAllowed()
    return self:isMouseActive()
end

---Is changing mouse visibly (g_inputBinding:setShowMouseCursor) allowed
function ClickToSwitch:isChangingMouseStateAllowed()
    return true
end

---Active/disable the mouse cursor
function ClickToSwitch:setShowMouseCursor(show)
    local spec = self.spec_clickToSwitch
	g_inputBinding:setShowMouseCursor(show)
    spec.mouseActive = show
    ---Update the action events
    ClickToSwitch.updateActionEventState(self)
    ---While mouse cursor is active, disable the camera rotations
	for camIndex,_ in pairs(spec.camerasBackup) do
		self.spec_enterable.cameras[camIndex].isRotatable = not show
	end
end

---Gets the last mouse cursor screen positions
---@return float posX,posY
function ClickToSwitch:getLastMousePosition()
    return g_inputBinding.mousePosXLast,g_inputBinding.mousePosYLast 
end

---Creates a raycast relative to the current camera and the mouse click 
---@param float mouseX,mouseY
function ClickToSwitch:enterVehicleRaycast(posX, posY)
    local activeCam = getCamera()
    if activeCam ~= nil then
        local hx, hy, hz, px, py, pz = RaycastUtil.getCameraPickingRay(posX, posY, activeCam)
        raycastClosest(hx, hy, hz, px, py, pz, "enterVehicleRaycastCallback", 1000, self, 371)
    end
end

---@param int hitObjectId, scenegraph object id
---@param float x, world x hit position
---@param float	y, world y hit position
---@param float	z, world z hit position
---@param float	distance, distance at which the cast hit the object
---@return bool was the correct object hit
function ClickToSwitch:enterVehicleRaycastCallback(hitObjectId, x, y, z, distance)
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
