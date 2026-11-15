local Scene = require("engine.scene.scene")
local World = require("engine.ecs.world")
local Components = require("engine.ecs.component")
local MovementSystem = require("engine.ecs.systems.movementSystem")
local Camera = require("engine.camera.camera")

local Field = {}
Field.__index = Field
setmetatable(Field, { __index = Scene })

local WIDTH, HEIGHT = 800, 450
local SPEED = 140

function Field.new(context)
    local self = setmetatable(Scene.new(), Field)
    self.context = context
    return self
end

function Field:onLoad()
    self.font = self.context.resourceManager:get(self, "hud")
    self.world = World.new(0, 0)
    self.world:addSystem(MovementSystem)
    self.camera = Camera.new({ viewport = { x = 0, y = 0, width = 400, height = 225 } })
    self.player = self.world:createEntity()
    self.world:addComponent(self.player, Components.Transform, { x = 100, y = 225 })
    self.world:addComponent(self.player, Components.Velocity, { x = 0, y = 0 })
    self.world:addComponent(self.player, Components.Movement, { maxSpeed = SPEED })

    for _, position in ipairs({ { 220, 225 }, { 450, 125 }, { 700, 325 } }) do
        local pickup = self.world:createEntity()
        self.world:addComponent(pickup, Components.Transform, { x = position[1], y = position[2] })
        self.world:addComponent(pickup, "Pickup")
    end
    self.collected = 0
    self.camera:setPosition(100, 225)
end

function Field:update(dt)
    local input = self.context.inputManager
    if input:isJustPressed("pause") then
        self.context.sceneManager:push("pause")
        return
    end
    if input:isJustPressed("restart") then
        self.context.sceneManager:replace("field")
        return
    end

    local velocity = self.world:getComponent(self.player, Components.Velocity)
    velocity.x = ((input:isDown("right") and 1 or 0) - (input:isDown("left") and 1 or 0)) * SPEED
    velocity.y = ((input:isDown("down") and 1 or 0) - (input:isDown("up") and 1 or 0)) * SPEED
    self.world:update(dt)

    local player = self.world:getComponent(self.player, Components.Transform)
    player.x = math.max(12, math.min(WIDTH - 12, player.x))
    player.y = math.max(12, math.min(HEIGHT - 12, player.y))
    self.camera:setPosition(player.x, player.y)

    self.world:query({ Components.Transform, "Pickup" }, function(entity, components)
        local item = components.Transform
        if (item.x - player.x) ^ 2 + (item.y - player.y) ^ 2 < 20 ^ 2 then
            self.world:destroyEntity(entity)
            self.collected = self.collected + 1
        end
    end)
    self.world:flushDestroy()
end

function Field:draw()
    self.camera:draw(function()
        love.graphics.setColor(0.13, 0.2, 0.24)
        love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
        love.graphics.setColor(0.2, 0.31, 0.34)
        for x = 0, WIDTH, 50 do love.graphics.line(x, 0, x, HEIGHT) end
        for y = 0, HEIGHT, 50 do love.graphics.line(0, y, WIDTH, y) end
        self.world:query({ Components.Transform, "Pickup" }, function(_, components)
            love.graphics.setColor(1, 0.8, 0.25)
            love.graphics.circle("fill", components.Transform.x, components.Transform.y, 7)
        end)
        local player = self.world:getComponent(self.player, Components.Transform)
        love.graphics.setColor(0.4, 0.8, 1)
        love.graphics.circle("fill", player.x, player.y, 10)
    end)

    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Collect: " .. self.collected .. "/3", 8, 8)
    love.graphics.print("WASD / arrows: move   |   Esc: pause   |   R: restart", 8, 23)
    if self.collected == 3 then
        love.graphics.printf("All collected! Press R to play again.", 0, 42, 400, "center")
    end
end

function Field:onDestroy()
    self.world.physics:destroy()
    self.context.resourceManager:releaseAll(self)
end

return Field
