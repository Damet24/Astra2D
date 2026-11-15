# Cameras

`require("engine.camera.cameraManager")` manages named cameras; `require("engine.camera.camera")` constructs one independently. The public camera wraps an adapter to the vendored HUMP camera; HUMP internals are not engine API. No camera is selected or attached automatically.

## Camera manager

`CameraManager.new()` returns an empty manager. IDs must be nonempty strings. Except as stated, methods return no values.

| Method | Effect and return |
| --- | --- |
| `add(id, config)` | Creates and returns a camera; asserts on invalid or duplicate ID or invalid config. Does not select it. |
| `get(id)` | Returns the camera; asserts on invalid or missing ID. |
| `setActive(id)` | Selects an existing camera; asserts for invalid or missing ID. |
| `getActive()` | Returns the selected camera, or `nil`. |
| `remove(id)` | Removes an existing camera; clears the selection if active. Asserts for invalid or missing ID. |

## Camera

`Camera.new(config)` returns a camera. `config` may be omitted: `x`, `y` default to 0, `zoom` to 1 and `rotation` to 0 radians. Position is the world point at the viewport center. The constructor uses `config.zoom or 1`, so `nil` and `false` select the default; any other value must be a positive number. Unlike the constructor, `setZoom(false)` fails validation. Optional `viewport = { x, y, width, height, clip }` uses logical coordinates; x/y default to 0 and a supplied table requires positive numeric width and height. Without one, the current LÖVE drawing target dimensions are used, not necessarily the engine's logical resolution. The supplied table is retained, not copied.

| Method | Parameters, return and effect |
| --- | --- |
| `setPosition(x, y)`, `move(dx, dy)` | Set or move the world position. |
| `getPosition()` | Returns `x, y`. |
| `setZoom(zoom)`, `getZoom()` | Set or return zoom; setting asserts unless positive numeric. |
| `setRotation(radians)`, `getRotation()` | Set or return rotation in radians. |
| `setViewport(viewport)` | Set the table or `nil` to reset; validates type and dimensions and asserts while attached. |
| `getViewport()` | Returns `x, y, width, height`. |
| `cameraCoords(worldX, worldY)` | Returns logical viewport coordinates. |
| `worldCoords(logicalX, logicalY)` | Returns world coordinates. Neither conversion tests bounds or includes the physical window transform. |
| `attach()`, `detach()` | Apply and restore camera graphics state. The same camera cannot be attached twice or detached when unattached. |
| `draw(callback)` | Requires a function, attaches, calls it without arguments, then detaches. Does not return the callback result. |

With `clip = true`, attachment intersects the existing scissor and requires an axis-aligned outer transform. Attachment failure unwinds its pushes. `draw` rethrows callback errors after detaching and unwinds extra pushes, provided the callback has not popped the camera's own frames. Premature pops can make detach fail; detach errors are not protected and can supersede callback errors.

## Example

```lua
local Manager = require("engine.camera.cameraManager")
local cameras = Manager.new()
cameras:add("world", { x = 160, y = 90, viewport = { width = 320, height = 180 } })
cameras:setActive("world")
local camera = cameras:getActive()
camera:draw(function() love.graphics.rectangle("fill", 150, 80, 20, 20) end)
local worldX, worldY = camera:worldCoords(160, 90)
```

For mouse input, first convert physical coordinates with `context.viewport.screenToViewport` and check its `inside` result; separately check camera viewport bounds when needed. See [camera architecture](../architecture/modules/camera-manager.md), the [camera guide](../guides/cameras.md), and [rendering](rendering.md).
