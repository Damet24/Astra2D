local Scene = require("engine.scene.scene")
local Main = {}
Main.__index = Main
setmetatable(Main, { __index = Scene })

function Main.new(context)
    local self = setmetatable(Scene.new(), Main)
    self.context = context
    return self
end

function Main:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        love.event.quit()
    end
end

function Main:draw()
    love.graphics.print(string.format("Time: %.1f", self.elapsed), 16, 16)
end

return Main
