# World and ECS

`require("engine.ecs.world")` provides an ECS container. `World.new(xg, yg, slepp)` returns an independent world with `events` and a LÖVE `physics` world. The third parameter is spelled `slepp` in the source; gravity defaults to `(0, 0)` and sleeping to `false`. Construction needs `love.physics` and sets its global meter scale to 64. No systems are registered automatically. See [physics](physics.md) and [events](events.md).

## Entities and components

Except where a return is specified, methods return no values. Component names are keys, normally the strings exported by `require("engine.ecs.component")`: `Transform`, `Velocity`, `Movement`, `Health`, `Damage`, `Sprite`, `PendingDamage`, `RigidBody`, `Collider`, `Animation`, `Input`, `Actions`. The module only defines names, not schemas or constructors; systems interpret the stored data.

| Method | Parameters, return and effect |
| --- | --- |
| `createEntity()` | Returns a new numeric ID, starting at 1 per world and increasing monotonically. |
| `destroyEntity(entity)` | Marks an existing ID for deletion; unknown IDs are ignored. It remains queryable until flush. |
| `flushDestroy()` | Removes marked entities and all their components; destroys their current `RigidBody.body` if present and not already destroyed. Clears the pending set. |
| `addComponent(entity, name, data)` | Stores or replaces data under the name; `nil` or `false` data becomes `{}`. Asserts `Invalid entity` if the ID is not live. |
| `getComponent(entity, name)` | Returns stored data or `nil`; it does not validate the entity. |
| `hasComponent(entity, name)` | Returns whether the stored value is non-`nil`. |
| `removeComponent(entity, name)` | Removes the entry if present; removing `RigidBody` does not destroy its body. |
| `query(componentNames, callback)` | Iterates live IDs matching all names in the array and calls `callback(entity, components)`, with components keyed by name. An empty array matches all IDs; order is unspecified (`pairs`). Matching uses truthiness, not just non-`nil`. |

## Systems and lifecycle

`addSystem(system)` appends a table and immediately calls `system.init(world)` if present. `update(dt)` calls each `system.update(world, dt)` in registration order, dispatches events, then calls `flushDestroy()`. `draw()` calls each `system.draw(world)` in registration order. These are plain functions, not colon methods. No schema or callback error handling is provided; errors interrupt the operation.

Included systems are `movementSystem`, `physicsMovementSystem`, `physicsSystem`, `physicsSyncSystem`, `collisionSystem`, `animationSystem`, `renderSystem` and `physicsDebugSystem`. `damageSystem.update` is currently empty. Movement integrates `Transform` and `Velocity` for entities without `RigidBody`; the physics systems and ordering are detailed in [physics](physics.md). Animation uses `Sprite.animations[Animation.current]`, `Animation.frame`, `timer`, `playing` and `loop`; when playing, the selected animation's `frameDuration` must be a positive number. See [rendering](rendering.md) for sprite fields.

## Example

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local world = World.new(0, 0, false)
world:addSystem(require("engine.ecs.systems.movementSystem"))
local id = world:createEntity()
world:addComponent(id, C.Transform, { x = 10, y = 20 })
world:addComponent(id, C.Velocity, { x = 30, y = 0 })
world:update(0.5) -- Transform.x is 25
world:destroyEntity(id)
world:update(0)   -- systems and events run before removal
```

There is no `World:destroy()` method; owners manage other cleanup. See [world architecture](../architecture/modules/world.md) and the [ECS guide](../guides/ecs.md).
