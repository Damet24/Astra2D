# SceneManager API

Module: `require("engine.scene.sceneManager")`. Manages a stack of `{ id, scene }` entries using a loader. See [architecture](../architecture/modules/scene-manager.md), the [scenes guide](../guides/scenes.md) and [first project](../getting-started/first-project.md).

## Construction and dependencies

`SceneManager.new(sceneLoader)` returns an empty manager; it asserts that `sceneLoader` is truthy. The manager calls `loader:load(sceneId, dependencies)` on the loader instance; this method must return a scene with the callbacks in [Scene](scene.md). Errors from loading and callbacks propagate.

For transition methods, `sceneId` is the loader's scene identifier and `dependencies` is an optional table. Enqueueing shallow-merges `{ manager = self }` with `dependencies`, whose keys override it. The [built-in loader](scene-loader.md) ignores this table; custom loaders may use it.

## Methods

Every instance method below returns **no values**. `push`, `pop`, `replace`, `clear` and `clearAndPush` only enqueue operations; they do not immediately modify the stack.

| Signature | Effect |
| --- | --- |
| `manager:push(sceneId, dependencies)` | Enqueue a push. |
| `manager:pop()` | Enqueue a pop; processing an empty stack is a no-op. |
| `manager:replace(sceneId, dependencies)` | Enqueue replacement of the top; works on an empty stack. |
| `manager:clear()` | Enqueue removal of all scenes. |
| `manager:clearAndPush(sceneId, dependencies)` | Enqueue replacement of the entire stack. |
| `manager:processPendingOperations()` | Detach and process one batch in insertion order. Operations queued during callbacks wait for another call. |
| `manager:update(dt)` | Update selected scenes bottom to top using elapsed seconds `dt`, then process one batch. |
| `manager:draw()` | Draw selected scenes bottom to top; does not process the queue. |
| `manager:applyPush(sceneId, dependencies)` | Immediately load and push; passes `dependencies` directly to the loader. |
| `manager:applyPop()` | Immediately pop, or no-op if empty. |
| `manager:applyReplace(sceneId, dependencies)` | Immediately load and replace the top. |
| `manager:applyClear()` | Immediately clear the stack. |
| `manager:applyClearAndPush(sceneId, dependencies)` | Immediately load and replace the entire stack. |

The `apply*` methods are exposed implementation operations; unlike queued requests, they do not merge dependencies or defer mutation. Calling them, or processing manually, during a scene callback can mutate the stack mid-pass.

## Lifecycle and queue

| Operation | Exact order |
| --- | --- |
| Push | Construct new, new `onLoad`, old top `onExit` if present, insert new, new `onEnter`. |
| Pop | Top `onExit`, remove, top `onDestroy`, previous `onEnter` if present. |
| Replace | Construct new, new `onLoad`, old top `onExit`, remove and `onDestroy` if present, insert new, new `onEnter`. |
| Clear | Detach stack, top `onExit` if present, all `onDestroy` top to bottom. |
| Clear and push | Construct new, new `onLoad`, every old `onExit` top to bottom, every old `onDestroy` top to bottom, replace stack, new `onEnter`. |

Clear-and-push exits covered scenes again, unlike clear. Load and quit explicitly process one batch; draw never does. Errors are not rolled back: a failed batch can lose its remaining operations, leave a partially changed stack and prevent subsequent cleanup.

For update/draw, walk down from the top while each scene's respective `updateBelow`/`drawBelow` is truthy, then visit the selected range bottom to top. The flags are independent and default to false in `Scene.new()`.

## Example

```lua
-- In a scene with the repository's input map:
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

The push normally takes effect after the current scene update, not at the call site.
