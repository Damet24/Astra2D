# Events

`require("engine.core.events")` implements a queued event manager. Every [world](world.md) creates one at `world.events`; `EventManager.new()` also returns an independent manager. Methods below return no values and do not explicitly validate argument types.

## API

| Method | Parameters and effect |
| --- | --- |
| `on(eventName, callback)` | Appends a listener; it is called as `callback(data)`. Duplicate registrations are allowed. |
| `emit(eventName, data)` | Queues a named event with arbitrary data (including `nil`); it does not invoke listeners immediately. |
| `dispatch()` | Takes the current queue, delivers events in enqueue order and listeners in registration order, then calls `flush()`. Events emitted by listeners wait for a later dispatch. |
| `off(eventName, callback)` | Queues removal of the first matching callback by identity; missing names or callbacks are ignored when flushed. |
| `flush()` | Applies queued removals immediately, in order, without dispatching events. |

`off` does not stop a listener during the current dispatch unless the caller explicitly flushes the pending operation. `on` is immediate. Dispatch iterates the live listener list: adding a listener with `on` during a callback may run it in the same dispatch, and calling `flush` after `off` can shift the list and skip a following listener. For predictable delivery, defer registrations and explicit flushing until dispatch finishes. `World:update(dt)` dispatches after all system updates and before deferred entity destruction. Callback errors propagate and interrupt dispatch; the current queue has already been detached and the final `flush()` is not reached. No automatic unsubscribe is provided.

## Example

```lua
local Events = require("engine.core.events")
local events = Events.new()
local function listener(data) print(data.score) end
events:on("scored", listener)
events:emit("scored", { score = 10 })
events:dispatch()
events:off("scored", listener)
events:flush()
```

`CollisionSystem` emits `collision_started` and `collision_ended` with `{ entityA, entityB }`; see [physics](physics.md). See also [world architecture](../architecture/modules/world.md) and the [ECS guide](../guides/ecs.md).
