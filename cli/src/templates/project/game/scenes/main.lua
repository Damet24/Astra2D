local Scene = require("engine.scene.scene")
local Main = {}
Main.__index = Main
setmetatable(Main, { __index = Scene })

function Main.new(context)
    local self = setmetatable(Scene.new(), Main)
    self.context = context
    self.elapsed = 0
    return self
end

function Main:update(dt)
    self.elapsed = self.elapsed + dt

    if self.context.inputManager:isJustPressed("exit") then
        love.event.quit()
    end
end

function Main:draw()
    love.graphics.print(string.format("Time: %.1f", self.elapsed), 16, 16)
    love.graphics.print("Press Enter or gamepad Start to exit", 16, 29)
end

return Main
