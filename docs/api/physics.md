# Physics

The engine provides a constructor and a rectangle factory, not its own physics object API. `world.physics` is a native [LÖVE World](https://love2d.org/wiki/World); bodies and fixtures returned by the factory are native [Body](https://love2d.org/wiki/Body) and [Fixture](https://love2d.org/wiki/Fixture) objects. Their methods, callbacks, restrictions and errors are LÖVE's, not engine wrappers.

## Construction and factory

- `PhysicsWorld.new(gravityX, gravityY, sleeping)` from `require("engine.physics.PhysicsWorld")` calls `love.physics.setMeter(PhysicsWorld.PIXELS_PER_METER)` (64, global) and returns `love.physics.newWorld(gravityX or 0, gravityY or 0, sleeping or false)`. `World.new` invokes it. Set the scale before creating bodies; LÖVE uses pixels in its API, so do not divide positions by 64.
- `PhysicsFactory.create(world, entity)` from `require("engine.physics.PhysicsFactory")` returns `body, fixture`. It requires `Transform`, `RigidBody`, and `Collider`, asserts that `RigidBody.body` is absent, `Collider.shape == "rectangle"`, and positive `width` and `height`. Missing components, duplicate body, unsupported shape or invalid dimensions raise assertions; incompatible field types and LÖVE errors may also propagate.

`Transform.x`, `y` give the body position; `rotation` defaults to 0 radians. `RigidBody.type` defaults to `"dynamic"` (LÖVE also supports `"static"` and `"kinematic"`). `Collider.offsetX`/`offsetY` default to 0, `density` to 1, and `sensor` to false. The factory creates one centered rectangle with those local offsets, sets fixture user data to the entity ID and stores the body as `RigidBody.body`. Adding components alone does not create it.

## Systems and contacts

Systems are opt-in. A typical registration order is `movementSystem`, `physicsMovementSystem`, `physicsSystem`, `physicsSyncSystem`, `collisionSystem`. The first integrates non-rigid entities. Physics movement applies `Velocity.x/y` to non-static bodies only when the effective command changes, optionally capped by `Movement.maxSpeed`; gravity and contacts can subsequently alter physical velocity. Physics advances in fixed 1/60 s steps using an accumulator, with no step cap or interpolation. Sync copies body position and angle to `Transform`.

`CollisionSystem.init` replaces the LÖVE world's callbacks with begin/end callbacks that collect fixture user data. Its update queues `collision_started` and `collision_ended` events and emits the whole contact table; install it after the physics step to process contacts from that update. Both events contain `entityA` and `entityB` (fixture user data, possibly `nil`). `collision_started` also contains `normalX` and `normalY` (both `nil` when either fixture is a sensor), the body velocities `velocityAX`/`velocityAY` and `velocityBX`/`velocityBY` captured when contact begins, and the booleans `sensorA` and `sensorB`. The normal goes from fixture A to fixture B; sensor contacts have none. `collision_ended` carries only the two entity IDs. No `Contact` is retained. World events dispatch after systems, then pending entities and their current bodies are destroyed. Contacts produced during destruction are processed in a later update. Removing `RigidBody` separately does not destroy its body. For entity-relative vectors and automatic filtering of destroyed entities, use `World:onCollisionStarted` / `World:onCollisionEnded` in [world](world.md).

## Example

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local Factory = require("engine.physics.PhysicsFactory")
local world = World.new(0, 640, true)
world:addSystem(require("engine.ecs.systems.physicsSystem"))
world:addSystem(require("engine.ecs.systems.physicsSyncSystem"))
world:addSystem(require("engine.ecs.systems.collisionSystem"))
world.events:on("collision_started", function(contact)
    print(contact.entityA, contact.entityB)
end)
local id = world:createEntity()
world:addComponent(id, C.Transform, { x = 100, y = 100 })
world:addComponent(id, C.RigidBody, { type = "dynamic" })
world:addComponent(id, C.Collider, { shape = "rectangle", width = 32, height = 32 })
local body, fixture = Factory.create(world, id)
body:setFixedRotation(true) -- LÖVE Body method

local stop = world:onCollisionStarted(id, function(other, collision)
    if collision.normal then
        print("hit", other, collision.normal.x, collision.normal.y)
    end
end)
-- stop() unsubscribes when no longer needed

world:update(1 / 60)
```

`PhysicsDebugSystem.draw(world)` draws polygon and circle fixture outlines using LÖVE graphics. See the [ECS and physics guide](../guides/ecs.md), [world architecture](../architecture/modules/world.md), [events](events.md), and [LÖVE physics](https://love2d.org/wiki/love.physics).
