# SceneManager

`engine/scene/sceneManager.lua` manages a stack of `{ id, scene }` entries, scene lifecycle callbacks, and update/draw selection. It delegates construction to a [SceneLoader](scene-loader.md); scenes normally request transitions through `context.sceneManager`. See the [architecture overview](../overview.md) and [GameContext](game-context.md).

## Public operations

`SceneManager.new(sceneLoader)` requires a truthy loader exposing `load(sceneId, dependencies)`. The manager starts with an empty stack and queue.

| Method | Effect when processed |
| --- | --- |
| `push(sceneId, dependencies)` | Load a new scene and place it on top; retain the old top. |
| `pop()` | Remove and destroy the top; re-enter the scene below. No-op on an empty stack. |
| `replace(sceneId, dependencies)` | Load a new scene and replace the top; also works on an empty stack. |
| `clear()` | Empty the stack and destroy its scenes. |
| `clearAndPush(sceneId, dependencies)` | Load a new scene, remove all existing scenes, then enter the new one. |
| `update(dt)` | Update selected scenes bottom to top, then process one pending batch. |
| `draw()` | Draw selected scenes bottom to top; it does **not** process the queue. |
| `processPendingOperations()` | Explicitly process the currently pending batch. `Engine:load()` and `Engine:quit()` call it as well. |

All five transition methods **only enqueue** requests. Operations are applied in insertion order. Processing detaches the current queue first: requests made by lifecycle callbacks during that batch go into a new queue for a later processing call, not the current batch. This applies to shutdown as well; `Engine:quit()` does not repeatedly drain that new queue. Calling `processPendingOperations` manually can change the stack at that point, so avoid doing it from an executing scene callback.

For `push`, `replace`, and `clearAndPush`, the manager shallow-merges `{ manager = self }` with the optional `dependencies` table, allowing supplied keys to override it, and passes the result to the loader. The built-in loader **ignores** this argument and calls the scene constructor with the context only; do not rely on these dependencies reaching a scene. A custom loader may use them.

## Lifecycle order

| Operation | Order |
| --- | --- |
| `push` | Construct new scene; new `onLoad`; old top `onExit` if any; insert new scene; new `onEnter`. |
| `pop` | Top `onExit`; remove top; top `onDestroy`; previous top `onEnter` if any. |
| `replace` | Construct new scene; new `onLoad`; old top `onExit`, remove and `onDestroy` if any; insert new scene; new `onEnter`. |
| `clear` | Detach the entire stack; old top `onExit` if any; `onDestroy` for every old scene from top to bottom. |
| `clearAndPush` | Construct new scene; new `onLoad`; `onExit` for **every** old scene top to bottom; `onDestroy` for every old scene top to bottom; replace stack; new `onEnter`. |

The `clearAndPush` behavior differs from `clear`: even covered scenes receive `onExit` again. `onLoad` is called once for each normally constructed instance; `onEnter`/`onExit` accompany stack transitions and `onDestroy` discards it. Callbacks and loading are not protected or rolled back: an error can interrupt the batch, lose its unprocessed operations, leave a partially changed stack, and prevent later engine cleanup.

## Update and draw policy

For each pass the manager starts at the top and walks downward while the current scene's `updateBelow` or `drawBelow`, respectively, is truthy. It then visits the selected range from bottom to top. The base [Scene](scene.md) sets both flags to `false` in `Scene.new()`; update and draw are independent. An overlay with `drawBelow = true` and `updateBelow = false` shows the scene beneath without updating it. A deeper scene is included only if every scene above it in that pass allows it.

## Example: pause overlay

The repository's `game/scenes/pause.lua` sets `drawBelow = true` and inherits `updateBelow = false`. From another scene with a stored context:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

The current update completes before the push is applied. The pause scene can request `self.context.sceneManager:pop()` to return. Requests made during `draw()` also wait for a later processing call, normally the next update. Do not expect immediate stack changes.
