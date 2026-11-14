local Scene = require("engine.scene.scene")

local Pause = {}
Pause.__index = Pause
setmetatable(Pause, { __index = Scene })

function Pause.new(context)
    local self = setmetatable(Scene.new(), Pause)
    self.context = context
    self.drawBelow = true
    return self
end

function Pause:onLoad()
    self.font = self.context.resourceManager:get(self, "hud")
end

function Pause:update()
    if self.context.inputManager:isJustPressed("pause") then
        self.context.sceneManager:pop()
    end
end

function Pause:draw()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 400, 225)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf("Paused - press Esc to resume", 0, 105, 400, "center")
end

function Pause:onDestroy()
    self.context.resourceManager:releaseAll(self)
end

return Pause
