--[[
    This mod enables the possibility to enter vehicles by clicking with the mouse onto them.

    Interface for other mods: 
    
    - vehicle:isClickToSwitchToggleMouseAllowed() : 
        This function can be overwritten to disable the mouse visibility action event.
    - vehicle:isClickToSwitchAllowed() : 
        This function can be overwritten to enable the click to switch raycast, if the mouse is active.
]]


---@class ClickToSwitch
ClickToSwitch = {}

ClickToSwitch.MOD_NAME = g_currentModName
ClickToSwitch.DEFAULT_ASSIGNMENT = 0
ClickToSwitch.ADVANCED_ASSIGNMENT = 1

function ClickToSwitch.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations) 
end

function ClickToSwitch.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ClickToSwitch)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ClickToSwitch)
end

function ClickToSwitch.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "isClickToSwitchMouseActive", ClickToSwitch.isClickToSwitchMouseActive)
    SpecializationUtil.registerFunction(vehicleType, "onClickToSwitchToggleMouse", ClickToSwitch.onClickToSwitchToggleMouse)
    SpecializationUtil.registerFunction(vehicleType, "setClickToSwitchShowMouseCursor", ClickToSwitch.setClickToSwitchShowMouseCursor)
    SpecializationUtil.registerFunction(vehicleType, "getClickToSwitchLastMousePosition", ClickToSwitch.getClickToSwitchLastMousePosition)
    SpecializationUtil.registerFunction(vehicleType, "enterVehicleRaycastClickToSwitch", ClickToSwitch.enterVehicleRaycastClickToSwitch)
    SpecializationUtil.registerFunction(vehicleType, "enterVehicleRaycastCallbackClickToSwitch", ClickToSwitch.enterVehicleRaycastCallbackClickToSwitch)
end

function ClickToSwitch:onLoad(savegame)
	--- Register the spec: spec_clickToSwitch
    local specName = ClickToSwitch.MOD_NAME .. ".clickToSwitch"
    self.spec_clickToSwitch = self["spec_" .. specName]
    local spec = self.spec_clickToSwitch
    
    spec.texts = {}
    spec.texts.toggleMouse = g_i18n:getText("input_CLICK_TO_SWITCH_TOGGLE_MOUSE")
    spec.texts.toggleMouseAlternative = g_i18n:getText("input_CLICK_TO_SWITCH_TOGGLE_MOUSE_ALTERNATIVE")
    spec.texts.changesAssignments = g_i18n:getText("input_CLICK_TO_SWITCH_CHANGES_ASSIGNMENTS")
    spec.texts.enterVehicle = g_i18n:getText("input_CLICK_TO_SWITCH_ENTER_VEHICLE")

    spec.mouseActive = false
    spec.assignmentMode = ClickToSwitch.DEFAULT_ASSIGNMENT
    --- Creating a backup table of all camera and if they are rotatable
    spec.camerasBackup = {}
    for camIndex, camera in pairs(self.spec_enterable.cameras) do
		if camera.isRotatable then
			spec.camerasBackup[camIndex] = camera.isRotatable
		end
	end
end

--- Register toggle mouse state and clickToSwitch action events
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function ClickToSwitch:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
        local spec = self.spec_clickToSwitch
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            --- Toggle mouse action event
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE, self, ClickToSwitch.actionEventToggleMouse, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleMouse)
            --- ClickToSwitch (enter vehicle by mouse button) action event
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE_ALTERNATIVE, self, ClickToSwitch.actionEventToggleMouse, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleMouseAlternative)

            --- ClickToSwitch (enter vehicle by mouse button) action event
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_CHANGES_ASSIGNMENTS, self, ClickToSwitch.actionEventChangeAssignments, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.changesAssignments)

            --- ClickToSwitch (enter vehicle by mouse button) action event
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE, self, ClickToSwitch.actionEventEnterVehicle, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.enterVehicle)

            ClickToSwitch.updateActionEventState(self)
        end
    end
end;

--- Updates toggle mouse state and clickToSwitch action events visibility and usability 
---@param self table vehicle
function ClickToSwitch.updateActionEventState(self)
    --- Activate/deactivate the clickToSwitch action event 
    local spec = self.spec_clickToSwitch

    local actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_ENTER_VEHICLE]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:isClickToSwitchMouseActive())

    actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_CHANGES_ASSIGNMENTS]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, not self:isClickToSwitchMouseActive())

    actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.assignmentMode == ClickToSwitch.DEFAULT_ASSIGNMENT)

    actionEvent = spec.actionEvents[InputAction.CLICK_TO_SWITCH_TOGGLE_MOUSE_ALTERNATIVE]
    g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.assignmentMode == ClickToSwitch.ADVANCED_ASSIGNMENT)
end

--- Action event for turning the mouse on/off
---@param self table vehicle
---@param actionName string
---@param inputValue number
---@param callbackState number
---@param isAnalog boolean
function ClickToSwitch.actionEventToggleMouse(self, actionName, inputValue, callbackState, isAnalog)
    self:setClickToSwitchShowMouseCursor(not self:isClickToSwitchMouseActive())
end

--- Action event for entering a vehicle by mouse click
---@param self table vehicle
---@param actionName string
---@param inputValue number
---@param callbackState number
---@param isAnalog boolean
function ClickToSwitch.actionEventEnterVehicle(self, actionName, inputValue, callbackState, isAnalog)
    if self:isClickToSwitchMouseActive() then
        local x,y = self:getClickToSwitchLastMousePosition()
        self:enterVehicleRaycastClickToSwitch(x,y)
    end
end

function ClickToSwitch.actionEventChangeAssignments(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_clickToSwitch
    spec.assignmentMode = ClickToSwitch.DEFAULT_ASSIGNMENT and ClickToSwitch.ADVANCED_ASSIGNMENT or ClickToSwitch.DEFAULT_ASSIGNMENT
    ClickToSwitch.updateActionEventState(self)
end

function ClickToSwitch:onClickToSwitchToggleMouse()
    local spec = self.spec_clickToSwitch
    spec.mouseActive = not spec.mouseActive
    ClickToSwitch.updateActionEventState(self)
end

--- Is the mouse visible/active
function ClickToSwitch:isClickToSwitchMouseActive()
    local spec = self.spec_clickToSwitch
    return spec.mouseActive
end

--- Active/disable the mouse cursor
---@param show boolean
function ClickToSwitch:setClickToSwitchShowMouseCursor(show)
    local spec = self.spec_clickToSwitch
	g_inputBinding:setShowMouseCursor(show)
    self:onClickToSwitchToggleMouse()
    ---While mouse cursor is active, disable the camera rotations
	for camIndex,_ in pairs(spec.camerasBackup) do
		self.spec_enterable.cameras[camIndex].isRotatable = not show
	end
end

--- Gets the last mouse cursor screen positions
---@return number posX
---@return number posY
function ClickToSwitch:getClickToSwitchLastMousePosition()
    return g_inputBinding.mousePosXLast,g_inputBinding.mousePosYLast 
end

--- Creates a raycast relative to the current camera and the mouse click 
---@param mouseX number
---@param mouseY number
function ClickToSwitch:enterVehicleRaycastClickToSwitch(posX, posY)
    local activeCam = getCamera()
    if activeCam ~= nil then
        local hx, hy, hz, px, py, pz = RaycastUtil.getCameraPickingRay(posX, posY, activeCam)
        raycastClosest(hx, hy, hz, px, py, pz, "enterVehicleRaycastCallbackClickToSwitch", 1000, self, 371)
    end
end

--- Check and enters a vehicle.
---@param hitObjectId number
---@param x number world x hit position
---@param y number world y hit position
---@param z number world z hit position
---@param distance number distance at which the cast hit the object
---@return bool was the correct object hit?
function ClickToSwitch:enterVehicleRaycastCallbackClickToSwitch(hitObjectId, x, y, z, distance)
    if hitObjectId ~= nil then
        local object = g_currentMission:getNodeObject(hitObjectId)    
        if object ~= nil then
            -- check if the object is a implement or trailer then get the rootVehicle 
            local rootVehicle = object.rootVehicle
            local targetObject = object.spec_enterable and object or rootVehicle~=nil and rootVehicle.spec_enterable and rootVehicle
            if targetObject then 
                if targetObject ~= g_currentMission.controlledVehicle then 
                    -- this is a valid vehicle, so enter it
                    g_currentMission:requestToEnterVehicle(targetObject)
                end
                self:setClickToSwitchShowMouseCursor(false)
                return false
            end                
        end
    end
    return true
end