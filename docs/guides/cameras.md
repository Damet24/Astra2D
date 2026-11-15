# Cameras and coordinate spaces

## Prerequisites

Start with the [first project](/getting-started/first-project) and LÖVE. This standalone scene uses its `320 × 180` logical resolution and `move_left`, `move_right`, `move_up`, and `move_down` actions. The engine already wraps scene drawing in the logical viewport; the scene owns its camera.

## 1. Create a following camera

Create `game/scenes/camera_tutorial.lua`, set `initialScene = "camera_tutorial"` in `main.lua`, and run `love .`. Move with arrows or WASD and point the mouse at the world. The orange square stays centered; the white marker follows the pointer in world space.

```lua
local Scene = require("engine.scene.scene")
local CameraManager = require("engine.camera.cameraManager")

local Tutorial = {}
Tutorial.__index = Tutorial
setmetatable(Tutorial, { __index = Scene })

function Tutorial.new(context)
    local self = Scene.new()
    setmetatable(self, Tutorial)
    self.context = context
    self.x, self.y = 160, 90
    return self
end

function Tutorial:onLoad()
    local width, height = self.context.viewport.getViewportDimensions()
    self.cameras = CameraManager.new()
    self.cameras:add("gameplay", {
        x = self.x, y = self.y, zoom = 2,
        viewport = { x = 0, y = 0, width = width, height = height, clip = true },
    })
    self.cameras:setActive("gameplay")
end

function Tutorial:update(dt)
    local input = self.context.inputManager
    local dx, dy = 0, 0
    if input:isDown("move_left") then dx = dx - 1 end
    if input:isDown("move_right") then dx = dx + 1 end
    if input:isDown("move_up") then dy = dy - 1 end
    if input:isDown("move_down") then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end
    self.x, self.y = self.x + dx * 100 * dt, self.y + dy * 100 * dt
    local camera = self.cameras:getActive()
    if camera then camera:setPosition(self.x, self.y) end
end

function Tutorial:draw()
    local camera = self.cameras:getActive()
    if camera then
        local inside, x, y = self.context.viewport.screenToViewport(love.mouse.getPosition())
        local vx, vy, width, height = camera:getViewport()
        local worldX, worldY
        if inside and x >= vx and x < vx + width and y >= vy and y < vy + height then
            worldX, worldY = camera:worldCoords(x, y)
        end
        camera:draw(function()
            love.graphics.setColor(0.3, 0.6, 0.9)
            for x = -1000, 1000, 32 do
                love.graphics.line(x, -1000, x, 1000)
                love.graphics.line(-1000, x, 1000, x)
            end
            love.graphics.setColor(1, 0.7, 0.2)
            love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)
            if worldX then
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", worldX, worldY, 2)
            end
        end)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Move: arrows / WASD", 8, 8)
end

return Tutorial
```

`add` does not select a camera; `setActive` is explicit. `getActive()` may return `nil`, including after removal. This example skips world drawing in that case. UI is drawn after `camera:draw`, so it stays in logical screen space. A camera is not a physics object and does not update itself.

## 2. Convert coordinates and change zoom

The chain is **physical window → logical viewport → world**. `screenToViewport` returns `inside, x, y`; reject points outside the logical viewport and, for a smaller camera viewport, also check its logical rectangle as above. `camera:worldCoords(x, y)` then includes camera position, zoom, rotation and viewport offset. The reverse is `camera:cameraCoords(worldX, worldY)`, which returns logical coordinates, not physical window pixels. Neither camera conversion checks bounds.

Shove floors the centering offsets and the logical coordinates returned by `screenToViewport`. For `aspect` and `pixel` scaling, its conversion also uses the dimensions calculated from those rounded margins, which can differ slightly from the scaled drawing dimensions. After resizing, the converted position—and thus the marker or a hit test—can be slightly offset from the rendered position, especially near edges. Treat it as an approximate conversion rather than pixel-exact picking.

The configured camera position is the world point at the viewport center. With `zoom = 2`, an unrotated `320 × 180` viewport shows `160 × 90` world units; zoom must be positive (`camera:setZoom(1)` restores a 1:1 view). Window scaling is separate: the first project's `960 × 540` window scales the logical viewport, not the camera zoom. For pixel art, integer viewport scaling and integer zoom avoid fractional scaling, although subpixel camera positions can still affect pixels.

To clamp an **unrotated** camera to a map starting at `(0, 0)`, use half-extents `width / (2 * zoom)` and `height / (2 * zoom)`. Clamp the center between each half-extent and map size minus that half-extent; if the map is smaller than the view, center on that axis. Rotation needs different bounds. The supplied game level additionally locks horizontal camera progress and uses a hard-coded height of `240`; those are game policies, not camera behavior.

## Limitations and references

An explicit viewport is recommended: without it the camera uses the current LÖVE drawing target dimensions, which need not equal the logical size. `clip = true` intersects the existing scissor and requires an axis-aligned outer transform; clipping is otherwise off. Do not change the viewport while attached or pop the camera's graphics stack inside `draw`. See the [camera architecture](/architecture/modules/camera-manager), [rendering architecture](/architecture/modules/rendering), and the [camera](/api/camera) and [rendering](/api/rendering) APIs. For maps and entities see [Tiled](/guides/tiled) and [ECS](/guides/ecs).
