# Tiled maps: drawing and collisions

## Prerequisites

Use the repository with LÖVE and Tiled installed. The [first project](/getting-started/first-project) explains scenes and the entry point; this example uses the repository's existing `terrain` resource and `256 × 240` logical resolution. Run it from the project root. Only load Lua maps you trust: `require` executes Lua code.

## 1. Prepare and export a map

1. Open `game/tiled/maps/vIllage.tmx` in Tiled and use **File → Save As…** to make a copy at `game/tiled/maps/tutorial.tmx`; do not modify the original. It is a finite orthogonal map with 16 × 16 tiles and the `Terrain (16x16)` tileset. Alternatively create a new finite orthogonal map with that tileset, 16 × 16 tiles, and at least 16 × 15 cells.
2. Keep or paint a visible tile layer. Reuse the copy's top-level `walls` and `objects` layers rather than adding duplicates; on a new map, create them. Set both layers' tile and pixel offsets to zero. In `walls`, edit the existing floor rectangle to `x=0, y=208, width=256, height=32, rotation=0` and remove the other wall objects in the copy, leaving exactly one floor. In `objects`, move the existing **point** named `playerSpawn` to `(80, 32)` and ensure it is the only `playerSpawn` point. On a new map, create that rectangle and point. The original map already has a floor and a spawn at approximately `(45.6364, 193.273)`; adding another floor would overlap it, and that spawn nearly touches the floor rather than visibly falling.
3. Use Tiled's **File → Export As…**, choose **Lua files**, and export the copy or new map to `game/maps/tutorial.lua`. The original map may have an existing export target: explicitly choose this new path rather than exporting over `game/maps/village.lua`. Keep the copied or new `.tmx` as the editable source and re-export after changes. The export should return a Lua table with `layers`, `tilesets`, and flat tile `data`. Check the exact tileset name in that table. The image is loaded separately, not from the exported TSX filename.
4. In the exported tile layer, an integer custom property `layer` controls pipeline order. For example, use `10` for background and `50` for foreground. Omit it to use the layer's 1-based position in `map.layers`, counting object layers too.

## 2. Create a scene

Create `game/scenes/tiled_tutorial.lua`. The existing resource definition `terrain` points to `game/assets/images/Terrain/Terrain (16x16).png`; the image is a regular grid without margins or spacing. The example creates static wall bodies **and** a dynamic test body, and draws their green outlines:

```lua
local Scene = require("engine.scene.scene")
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.PhysicsFactory")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local PhysicsSync = require("engine.ecs.systems.physicsSyncSystem")
local PhysicsDebug = require("engine.ecs.systems.physicsDebugSystem")
local TilemapRender = require("engine.tilemap.tilemaprender")
local Pipeline = require("engine.graphics.RenderPipeline")
local utils = require("engine.graphics.utils")
local map = require("game.maps.tutorial")

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
    local image = self.context.resourceManager:get(self, "terrain")
    self.renderer = TilemapRender.new(map, {
        ["Terrain (16x16)"] = utils.loadQuads(image, 16, 16),
    })
    self.pipeline = Pipeline.new()
    self.world = World.new(0, 640, true)
    self.world:addSystem(PhysicsSystem)
    self.world:addSystem(PhysicsSync)

    local spawn = { x = 80, y = 32 }
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.name == "walls" then
            local ox = (layer.x or 0) * map.tilewidth + (layer.offsetx or 0)
            local oy = (layer.y or 0) * map.tileheight + (layer.offsety or 0)
            for _, object in ipairs(layer.objects) do
                assert(object.shape == "rectangle", "walls must contain only rectangles")
                local angle = math.rad(object.rotation or 0)
                local cos, sin = math.cos(angle), math.sin(angle)
                local entity = self.world:createEntity()
                self.world:addComponent(entity, C.Transform, {
                    x = ox + object.x + cos * object.width / 2 - sin * object.height / 2,
                    y = oy + object.y + sin * object.width / 2 + cos * object.height / 2,
                    rotation = angle,
                })
                self.world:addComponent(entity, C.RigidBody, { type = "static" })
                self.world:addComponent(entity, C.Collider, {
                    shape = "rectangle", width = object.width, height = object.height,
                })
                PhysicsFactory.create(self.world, entity)
            end
        elseif layer.type == "objectgroup" and layer.name == "objects" then
            for _, object in ipairs(layer.objects) do
                if object.name == "playerSpawn" and object.shape == "point" then
                    spawn = { x = object.x + (layer.offsetx or 0),
                              y = object.y + (layer.offsety or 0) }
                    break
                end
            end
        end
    end

    local player = self.world:createEntity()
    self.world:addComponent(player, C.Transform, { x = spawn.x, y = spawn.y })
    self.world:addComponent(player, C.RigidBody, { type = "dynamic" })
    self.world:addComponent(player, C.Collider, { shape = "rectangle", width = 18, height = 28 })
    local body = PhysicsFactory.create(self.world, player)
    body:setFixedRotation(true)
end

function Tutorial:update(dt)
    self.world:update(dt)
end

function Tutorial:draw()
    self.pipeline:clear()
    self.renderer:submit(self.pipeline)
    self.pipeline:draw()
    PhysicsDebug.draw(self.world)
end

function Tutorial:onDestroy()
    self.world.physics:destroy()
    self.context.resourceManager:releaseAll(self)
end

return Tutorial
```

Set `initialScene = "tiled_tutorial"` in `main.lua`, then run `love .`. The box should fall onto a wall; if it falls through, check the layer name, rectangle placement and exported file. This scene draws in logical coordinates without a camera, so only the top-left `256 × 240` is visible. The wall center formula accounts for Tiled's rotation around the rectangle's top-left. As in the supplied level, spawn offsets use `offsetx`/`offsety`, not object-layer `x`/`y`; keep the spawn layer at zero tile offset.

## 3. Understand what is and is not automatic

- `TilemapRender` draws visible top-level tile layers; it does not create physics. The repository's `game/scenes/levels/level.lua` implements the `walls` and `objects` conventions, including the fallback spawn, independently of the engine. A wall named `leftWall` also has special camera-follow behavior in that game level, not in this tutorial. Tiled tile collision shapes, hidden wall layers, and object visibility do not automatically control physics: this wall loop processes every object in a matching layer.
- The renderer uses ascending `firstgid` ranges and quads indexed by GID; tileset names must match the supplied table. `loadQuads` assumes a regular image grid. Unsupported or missing quads are skipped. It does not decode flipped/rotated GID flags, tileset spacing/margins, tile animations, image collections, group/image/object layers, infinite chunks, or culling. Use unflipped finite orthogonal tile layers and simple grid tilesets.
- `submit` orders layers through the pipeline; `render()` instead draws visible tile layers directly in map order. Clear and resubmit each frame when mixing layers with ECS sprites. Pipeline layers sort ascending, ties by submission order.
- `PhysicsFactory.create` supports positive-size rectangles only and is required after adding `Transform`, `RigidBody`, and `Collider`. Adding components alone creates no fixture. Physics needs `world:update(dt)` and a registered `PhysicsSystem`; the scene owns the physics world and image consumer.

See the [rendering architecture](/architecture/modules/rendering), [world architecture](/architecture/modules/world), and the [tilemap](/api/tilemap), [rendering](/api/rendering), and [world](/api/world) API references. Continue with [cameras](/guides/cameras) or [ECS](/guides/ecs).
