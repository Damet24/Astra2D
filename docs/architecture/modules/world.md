# World

`engine/ecs/world.lua` is an ECS container with its own event manager and LÖVE physics world. A scene may create and drive a world, but neither `Scene` nor `SceneManager` creates one automatically. Worlds are independent instances and do not know their scene. The game level in `game/scenes/levels/level.lua` demonstrates one possible setup.

## Construction and ECS API

`World.new(xg, yg, slepp)` creates empty entity/component/system tables, `world.events`, and `world.physics`. The third argument is spelled `slepp` in the source and enables physics sleeping when true. Gravity defaults to `(0, 0)`, sleeping to false. Construction requires `love.physics` and sets its global meter scale to 64 pixels per meter. No systems are registered automatically.

- `createEntity()` returns a monotonically increasing numeric ID, starting at 1 for each world.
- `destroyEntity(entity)` marks an existing entity for deferred removal; an unknown ID is ignored. `flushDestroy()` removes marked entities and all their components and destroys their `RigidBody.body` if present and not already destroyed. Until flush, marked entities still participate in queries. Removing a `RigidBody` component separately does **not** destroy its body.
- `addComponent(entity, name, data)` requires a live entity and stores/replaces `components[name][entity]` with `data` or `{}`. `getComponent(entity, name)` returns the data or `nil`; `hasComponent` tests for non-`nil`; `removeComponent` removes the entry. Names are provided by `engine/ecs/component.lua`.
- `query(componentNames, callback)` visits entities with every named component and calls `callback(entity, components)`, where the second table is keyed by component name. Traversal uses `pairs`, so entity order is not guaranteed. An empty list matches every entity.
- `addSystem(system)` appends it and immediately calls `system.init(world)` if present. Systems use plain functions, not colon methods: `init(world)`, `update(world, dt)`, and `draw(world)` are optional.
- `update(dt)` calls system updates in insertion order, dispatches events, then flushes deferred destruction. `draw()` calls system draws in insertion order; it neither updates nor flushes entities.

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local Movement = require("engine.ecs.systems.movementSystem")

local world = World.new(0, 0, false)
world:addSystem(Movement)
local entity = world:createEntity()
world:addComponent(entity, C.Transform, { x = 10, y = 20 })
world:addComponent(entity, C.Velocity, { x = 30, y = 0 })
world:update(0.5) -- x becomes 25
world:destroyEntity(entity)
world:update(0)   -- systems and events run before removal
```

## Systems, events, and physics

Order matters; the world does not infer dependencies. The engine includes:

- `MovementSystem`: integrates `Transform` + `Velocity` with `dt`, optionally capped by `Movement.maxSpeed`; skips entities with `RigidBody`.
- `PhysicsMovementSystem`: applies `Velocity` to non-static bodies, optionally capped by `Movement.maxSpeed`, only when the commanded velocity changes. `PhysicsSystem` advances physics in fixed 1/60-second steps using an accumulator; there is no step cap. `PhysicsSyncSystem` copies body position and angle to `Transform`. Register them in that order when this behavior is desired.
- `CollisionSystem.init` installs physics callbacks and queues contacts; its update emits `collision_started` and `collision_ended` with `{ entityA, entityB }` from fixture user data. Register it after the physics step to process contacts produced in that update. Its callback installation replaces existing physics callbacks.
- `AnimationSystem` advances a playing `Animation` using the selected `Sprite.animations` entry; `frameDuration` must be positive. `RenderSystem` draws or submits sprites; `PhysicsDebugSystem` draws polygon and circle outlines. `DamageSystem.update` is currently empty.

`world.events:on(name, callback)` registers a listener; `emit(name, data)` queues an event; `off(name, callback)` queues listener removal. Dispatch occurs after all system updates, before entity destruction. Events emitted while dispatching wait for a later dispatch, and queued removals are applied after the current dispatch.

`PhysicsFactory.create(world, entity)` requires `Transform`, `RigidBody`, and `Collider`, and a body must not already exist. It creates a LÖVE body and fixture, stores the body in `RigidBody.body`, and sets fixture user data to the entity. Only rectangle colliders with positive `width` and `height` are supported; optional fields include `offsetX`, `offsetY`, `density`, and `sensor`. Body type defaults to `dynamic`. The factory is explicit: adding components alone does not create a body. There is no `World:destroy()` method; owners must manage any additional physics or resource cleanup they need.

See [Scene](scene.md) for ownership and [Rendering](rendering.md) for submission and draw ordering.
