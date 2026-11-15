# Entities, systems, and physics

## Prerequisites

Start with the [first project](/getting-started/first-project) and LÖVE, including the `move_left` and `move_right` input actions and forwarded key callbacks. This example fits its `320 × 180` logical viewport. A scene owns the `World`; neither the engine nor the scene manager creates or updates it automatically.

## 1. Create a scene with an entity and a system

Create `game/scenes/ecs_tutorial.lua`, set `initialScene = "ecs_tutorial"` in `main.lua`, and run `love .`. The green outlined box falls onto the floor and moves horizontally with arrows or A/D. Contact IDs are printed to the console.

```lua
local Scene = require("engine.scene.scene")
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.physics_factory")
local PhysicsMovement = require("engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local PhysicsSync = require("engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("engine.ecs.systems.collisionSystem")
local PhysicsDebug = require("engine.ecs.systems.physicsDebugSystem")

local Tutorial = {}
Tutorial.__index = Tutorial
setmetatable(Tutorial, { __index = Scene })

function Tutorial.new(context)
    local self = Scene.new()
    setmetatable(self, Tutorial)
    self.context = context
    return self
end

function Tutorial:onLoad()
    local world = World.new(0, 640, true)
    self.world = world

    local player = world:createEntity()
    world:addComponent(player, C.Transform, { x = 160, y = 40 })
    world:addComponent(player, C.Velocity, { x = 0, y = 0 })
    world:addComponent(player, C.RigidBody, { type = "dynamic" })
    world:addComponent(player, C.Collider, { shape = "rectangle", width = 18, height = 28 })
    local body, fixture = PhysicsFactory.create(world, player)
    body:setFixedRotation(true)
    fixture:setFriction(0)

    local floor = world:createEntity()
    world:addComponent(floor, C.Transform, { x = 160, y = 164 })
    world:addComponent(floor, C.RigidBody, { type = "static" })
    world:addComponent(floor, C.Collider, { shape = "rectangle", width = 300, height = 16 })
    PhysicsFactory.create(world, floor)

    local input = self.context.inputManager
    local ControlSystem = {}
    function ControlSystem.update(w, dt)
        w:query({ C.Velocity, C.RigidBody }, function(entity, components)
            if entity == player then
                local x = 0
                if input:isDown("move_left") then x = x - 1 end
                if input:isDown("move_right") then x = x + 1 end
                components.Velocity.x = x * 100
            end
        end)
    end

    world:addSystem(ControlSystem)
    world:addSystem(PhysicsMovement)
    world:addSystem(PhysicsSystem)
    world:addSystem(PhysicsSync)
    world:addSystem(CollisionSystem)
    world.events:on("collision_started", function(contact)
        print("collision_started", contact.entityA, contact.entityB)
    end)
end

function Tutorial:update(dt)
    self.world:update(dt)
end

function Tutorial:draw()
    PhysicsDebug.draw(self.world)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Move: left / right", 8, 8)
end

function Tutorial:onDestroy()
    self.world.physics:destroy()
end

return Tutorial
```

`createEntity` returns a numeric ID. Components are tables indexed by that ID and named using `C`; `query` passes a table keyed by component name, but entity traversal order is unspecified. A system is a table with plain functions such as `update(world, dt)`, not colon methods. `addSystem` immediately calls its optional `init(world)`. `PhysicsFactory.create` explicitly creates the body and fixture and associates fixture user data with the entity; components alone do not create them. Both the player and floor need colliders.

## 2. Follow the frame order

`World:update(dt)` runs systems **in insertion order**, then dispatches events, then flushes pending entity destruction:

1. `ControlSystem` sets the desired horizontal velocity.
2. `PhysicsMovement` sends changed `Velocity` commands to non-static bodies. It sends both axes when either command changes; unchanged commands are not resent, allowing gravity and collisions to affect the body. `Velocity` is a command, not the current physical velocity.
3. `PhysicsSystem` advances the LÖVE physics world in accumulated `1/60`-second steps, with no step cap. A frame shorter than a step may do no physics step.
4. `PhysicsSync` copies body position and angle into `Transform`. Use the body to reposition physical entities; changing only `Transform` will be overwritten by sync.
5. `CollisionSystem` queues contact events produced by the step. It installs and replaces physics callbacks when registered; events contain fixture entity IDs and are dispatched after all systems.

For non-physics entities, register `engine.ecs.systems.movementSystem`: it integrates `Transform` and `Velocity` with `dt` and skips entities with `RigidBody`. For sprites, register animation as needed and use `RenderSystem.draw` or submit sprites with tiles through a pipeline; neither rendering nor physics systems are registered automatically. See [rendering architecture](/architecture/modules/rendering).

## 3. Destruction and limitations

`world:destroyEntity(id)` defers removal until after systems and event dispatch, so the entity can still appear in queries during that update. Flushing also destroys its `RigidBody.body`; removing the component directly does not. This example destroys its owned LÖVE physics world when the scene is destroyed; there is no `World:destroy()` helper. Factory colliders are rectangles with positive dimensions only. `World.new` sets LÖVE's global physics scale to 64 pixels per meter.

See [world architecture](/architecture/modules/world), the [world](/api/world) and [rendering](/api/rendering) APIs, and the [Tiled](/guides/tiled) and [camera](/guides/cameras) tutorials.
