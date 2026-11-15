# Camera manager and cameras

`engine/camera/cameraManager.lua` manages named `Camera` objects; `engine/camera/camera.lua` wraps the Hump camera adapter. They provide a world-space view, independently of ECS and scene management. A scene may create its own manager, as the level does, but scenes are not required to have one. Neither the engine nor `Scene.new()` selects a camera automatically.

## Implementation and credits

Astra 2D's `Camera` delegates to `engine/camera/adapters/humpCamera.lua`, which
wraps the bundled `hump.camera` implementation in `engine/lib/hump/camera.lua`.
The adapter adds Astra 2D's viewport, clipping, and drawing interface around
HUMP's camera.

Credit to Matthias Richter and the [HUMP project](https://github.com/vrld/hump)
for `hump.camera`. The bundled file retains its copyright and license notice.

## Manager API

`CameraManager.new()` starts with an empty registry and no active camera.

| Method | Behavior |
| --- | --- |
| `add(id, config)` | Creates and returns a camera; fails for an invalid or duplicate ID or invalid camera config. Does not select it. |
| `get(id)` | Returns the camera; fails if the ID is invalid or missing. |
| `setActive(id)` | Requires an existing camera and selects it. |
| `getActive()` | Returns the selected camera, or `nil` if none is selected. |
| `remove(id)` | Requires an existing camera; removing the active one clears the selection. |

IDs must be nonempty strings. A caller must decide what to do when `getActive()` is `nil`: skip rendering, draw without a camera, or assert an application invariant. The supplied level selects `gameplay` during `onLoad`; it asserts an active camera in initialization/update and dereferences it directly in `draw`, so removing that camera without selecting another makes that level fail. That is a level-specific assumption, not a general scene guarantee.

## Camera configuration and API

`Camera.new(config)` also works independently of the manager. `config` may be omitted. Its fields are:

- `x`, `y`: world position at the viewport center; default `0, 0`.
- `zoom`: positive number, default `1`; `rotation`: radians, default `0`.
- `viewport`: optional `{ x, y, width, height, clip }` in logical coordinates. `x` and `y` default to zero; if the table is supplied, `width` and `height` must be positive numbers. With no table, the current LÖVE drawing target dimensions are used, which may not match the engine's logical resolution. Set explicit dimensions when using the engine viewport. `clip = true` intersects the existing scissor; clipping is otherwise off.

`setPosition(x, y)`, `getPosition()`, `move(dx, dy)`, `setZoom(zoom)`, `getZoom()`, `setRotation(radians)`, and `getRotation()` manipulate the view. `setZoom` requires a positive number. `setViewport(tableOrNil)` changes or resets the viewport, and `getViewport()` returns `x, y, width, height`. The viewport cannot be changed while attached. The adapter retains the supplied viewport table rather than copying it.

`cameraCoords(worldX, worldY)` maps world to logical camera/viewport coordinates; `worldCoords(logicalX, logicalY)` maps back. These conversions do not include Shove's physical-window transform or test whether the point lies inside the camera viewport. For mouse input, first convert from physical to logical coordinates and check Shove's `inside` result; for a smaller camera viewport, also check its bounds if needed:

```lua
local inside, x, y = context.viewport.screenToViewport(love.mouse.getPosition())
local camera = cameraManager:getActive()
if inside and camera then
    local worldX, worldY = camera:worldCoords(x, y)
    -- Use worldX, worldY.
end
```

## Drawing and failure conditions

```lua
local CameraManager = require("engine.camera.cameraManager")
local width, height = context.viewport.getViewportDimensions()
local cameras = CameraManager.new()
cameras:add("world", {
    x = width / 2, y = height / 2,
    viewport = { width = width, height = height },
})
cameras:setActive("world")

local camera = cameras:getActive()
if camera then
    camera:draw(function() pipeline:draw() end)
end
-- Draw logical-space UI after the camera.
```

`draw(callback)` requires a function, attaches, calls it, then detaches. If the callback errors and has not popped the camera's own stack frames, detach unwinds extra pushes, restores graphics state/scissor, and rethrows the callback error. It does not return the callback's result. `attach()` and `detach()` are available for manual management; the same camera cannot be attached twice, detached while unattached, or have its viewport changed while attached. The callback must not pop the camera's frames: premature popping can make `detach()` fail and cleanup is not guaranteed. If attachment itself fails, the adapter unwinds the stack frames it pushed and propagates the error; the callback is not run. In particular, a clipped viewport requires an axis-aligned outer graphics transform (translation and scaling are supported), otherwise attachment fails. Errors during detach are not protected and may supersede a callback error.

The manager does not attach cameras automatically or clean up scenes. See [Rendering](rendering.md) for the viewport and layer pipeline, and [Scene](scene.md) for ownership.
