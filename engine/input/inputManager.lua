local InputManager = {}
InputManager.__index = InputManager

local AXIS_THRESHOLD = 0.5

function InputManager.new(inputMaps, events)
    local self = setmetatable({}, InputManager)

    self.inputMaps = inputMaps
    self.events = events

    self.devices = {
        keyboard = {
            pressed = {},
            justPressed = {},
            justReleased = {},
        },
        mouse = {
            pressed = {},
            justPressed = {},
            justReleased = {},
            position = { x = 0, y = 0 },
            delta = { x = 0, y = 0 },
        },
        gamepad = {
            pressed = {},
            justPressed = {},
            justReleased = {},
            axes = {},
            axisStates = {},
            joystick = nil,
        },
    }

    return self
end

function InputManager:keypressed(key)
    local keyboard = self.devices.keyboard

    if not keyboard.pressed[key] then
        keyboard.pressed[key] = true
        keyboard.justPressed[key] = true
    end
end

function InputManager:keyreleased(key)
    local keyboard = self.devices.keyboard

    if keyboard.pressed[key] then
        keyboard.pressed[key] = nil
        keyboard.justReleased[key] = true
    end
end

function InputManager:update()
    self:_updateAxisStates()
end

function InputManager:reset()
    for _, device in pairs(self.devices) do
        device.justPressed = {}
        device.justReleased = {}
    end

    self.devices.mouse.delta = { x = 0, y = 0 }
end

function InputManager:_isAxisDown(axisBindings, axisStates)
    if not axisBindings then
        return false
    end

    for axis, direction in pairs(axisBindings) do
        local state = axisStates[axis]

        if state then
            if direction < 0 and state.negative then
                return true
            elseif direction > 0 and state.positive then
                return true
            end
        end
    end

    return false
end

function InputManager:_isAxisActive(axisBindings, state)
    if not axisBindings then
        return false
    end

    for axis, direction in pairs(axisBindings) do
        local key = axis .. (direction < 0 and "_negative" or "_positive")

        if state[key] then
            return true
        end
    end

    return false
end

function InputManager:_isBindingActive(bindings, state)
    if not bindings then
        return false
    end

    for _, binding in ipairs(bindings) do
        if state[binding] then
            return true
        end
    end

    return false
end

function InputManager:_updateAxisStates()
    local gamepad = self.devices.gamepad

    for axis, value in pairs(gamepad.axes) do
        local positive = value >= AXIS_THRESHOLD
        local negative = value <= -AXIS_THRESHOLD

        local previous = gamepad.axisStates[axis] or {
            positive = false,
            negative = false,
        }

        if positive and not previous.positive then
            gamepad.justPressed[axis .. "_positive"] = true
        elseif not positive and previous.positive then
            gamepad.justReleased[axis .. "_positive"] = true
        end

        if negative and not previous.negative then
            gamepad.justPressed[axis .. "_negative"] = true
        elseif not negative and previous.negative then
            gamepad.justReleased[axis .. "_negative"] = true
        end

        gamepad.axisStates[axis] = {
            positive = positive,
            negative = negative,
        }
    end
end

function InputManager:isDown(action)
    local bindings = self.inputMaps[action]

    if not bindings then
        return false
    end

    local devices = self.devices

    return self:_isBindingActive(bindings.keys, devices.keyboard.pressed)
        or self:_isBindingActive(bindings.mouse, devices.mouse.pressed)
        or self:_isBindingActive(bindings.gamepad, devices.gamepad.pressed)
        or self:_isAxisDown(
            bindings.gamepad and bindings.gamepad.axes,
            devices.gamepad.axisStates
        )
end

function InputManager:isJustPressed(action)
    local bindings = self.inputMaps[action]

    if not bindings then
        return false
    end

    local devices = self.devices

    return self:_isBindingActive(bindings.keys, devices.keyboard.justPressed)
        or self:_isBindingActive(bindings.mouse, devices.mouse.justPressed)
        or self:_isBindingActive(bindings.gamepad, devices.gamepad.justPressed)
        or self:_isAxisActive(
            bindings.gamepad and bindings.gamepad.axes,
            devices.gamepad.justPressed
        )
end

function InputManager:isJustReleased(action)
    local bindings = self.inputMaps[action]

    if not bindings then
        return false
    end

    local devices = self.devices

    return self:_isBindingActive(bindings.keys, devices.keyboard.justReleased)
        or self:_isBindingActive(bindings.mouse, devices.mouse.justReleased)
        or self:_isBindingActive(bindings.gamepad, devices.gamepad.justReleased)
        or self:_isAxisActive(
            bindings.gamepad and bindings.gamepad.axes,
            devices.gamepad.justReleased
        )
end

function InputManager:mousepressed(x, y, button, istouch, presses)
    local mouse = self.devices.mouse

    if not mouse.pressed[button] then
        mouse.pressed[button] = true
        mouse.justPressed[button] = true
    end

    mouse.position.x = x
    mouse.position.y = y
end

function InputManager:mousereleased(x, y, button, istouch, presses)
    local mouse = self.devices.mouse

    if mouse.pressed[button] then
        mouse.pressed[button] = nil
        mouse.justReleased[button] = true
    end

    mouse.position.x = x
    mouse.position.y = y
end

function InputManager:mousemoved(x, y, dx, dy, istouch)
    local mouse = self.devices.mouse

    mouse.position.x = x
    mouse.position.y = y

    mouse.delta.x = mouse.delta.x + dx
    mouse.delta.y = mouse.delta.y + dy
end

function InputManager:gamepadpressed(joystick, button)
    local gamepad = self.devices.gamepad

    if gamepad.joystick ~= joystick then
        return
    end

    if not gamepad.pressed[button] then
        gamepad.pressed[button] = true
        gamepad.justPressed[button] = true
    end
end

function InputManager:gamepadreleased(joystick, button)
    local gamepad = self.devices.gamepad

    if gamepad.joystick ~= joystick then
        return
    end

    if gamepad.pressed[button] then
        gamepad.pressed[button] = nil
        gamepad.justReleased[button] = true
    end
end

function InputManager:gamepadaxis(joystick, axis, value)
    local gamepad = self.devices.gamepad

    if gamepad.joystick ~= joystick then
        return
    end

    gamepad.axes[axis] = value
end

function InputManager:joystickadded(joystick)
    if not joystick:isGamepad() then
        return
    end

    local gamepad = self.devices.gamepad

    if gamepad.joystick then
        return
    end

    gamepad.joystick = joystick
    self.events:emit("gamepad_connected", {
        joystick = joystick,
        name = joystick:getName(),
    })
end

function InputManager:joystickremoved(joystick)
    local gamepad = self.devices.gamepad

    if gamepad.joystick ~= joystick then
        return
    end

    self.events:emit("gamepad_disconnected", {
        joystick = joystick,
        name = joystick:getName(),
    })

    gamepad.joystick = nil
    gamepad.pressed = {}
    gamepad.justPressed = {}
    gamepad.justReleased = {}
    gamepad.axes = {}
    gamepad.axisStates = {}
end

function InputManager:isMouseDown(button)
    return self.devices.mouse.pressed[button] == true
end

function InputManager:isMouseJustPressed(button)
    return self.devices.mouse.justPressed[button] == true
end

function InputManager:isMouseJustReleased(button)
    return self.devices.mouse.justReleased[button] == true
end

function InputManager:getMousePosition()
    local position = self.devices.mouse.position

    return position.x, position.y
end

function InputManager:getMouseDelta()
    local delta = self.devices.mouse.delta

    return delta.x, delta.y
end

return InputManager
