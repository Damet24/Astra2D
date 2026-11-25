# Your First Project

This guide creates a minimal Astra 2D project: one scene, a few input actions, and a movable square. It needs no assets, cameras, or ECS. Install LÖVE 11.5 and obtain the engine source as described in [Installation](/getting-started/installation).

## Project structure

Create a folder for the game and copy the engine into it:

```text
my-game/
  engine/               # complete copy, including engine/lib/
  game/
    config/
      inputMaps.lua
    scenes/
      hello.lua
  main.lua
```

The folder must be named `engine`, because the engine modules import each other with the `engine.` prefix. It must be inside the LÖVE game source directory, next to `main.lua`, including when [packaging a `.love` file](/getting-started/installation#package-the-game). Keeping game configuration in `game/config/` matches the demo and the CLI template; `resourceDefinitions.lua` and `collisionLayer.lua` can be added there later as optional files.

## 1. Configure the entry point

Create `main.lua`. It builds the engine once and forwards the lifecycle callbacks. `Engine:load()` installs the input callbacks itself, so `main.lua` does not forward keyboard, mouse, gamepad, or joystick events:

```lua
local Engine = require("engine.engine")

local engine = Engine.new({
    initialScene = "hello",
    inputMaps = require("game.config.inputMaps"),

    audio = {
        masterVolume = 1.0,
        musicVolume = 0.8,
        sfxVolume = 1.0,
    },
    window = {
        width = 960,
        height = 540,
        fullscreen = false,
        resizable = true,
        vsync = true,
    },
    rendering = {
        width = 320,
        height = 180,
        pixelPerfect = true,
        backgroundColor = { 0.10, 0.14, 0.20 },
    },
})

function love.load()
    engine:load()
end

function love.update(dt)
    engine:update(dt)
end

function love.draw()
    engine:draw()
end

function love.quit()
    engine:quit()
end
```

The required `initialScene` and `inputMaps` are supplied here; `scenesPath` defaults to `game.scenes` and `resourceDefinitions` to `{}`. The logical resolution is `320 x 180`, while the window is `960 x 540`. With `pixelPerfect = true`, the engine uses integer scaling and nearest-neighbor filtering. See [Engine configuration](/getting-started/installation#engine-configuration) for all defaults.

## 2. Define input actions

Create `game/config/inputMaps.lua`. Each action is a table with optional `keys`, `mouse`, and `gamepad` sections:

```lua
return {
    move_left = {
        keys = { "left", "a" },
        gamepad = { "dpleft", axes = { leftx = -1 } },
    },
    move_right = {
        keys = { "right", "d" },
        gamepad = { "dpright", axes = { leftx = 1 } },
    },
    move_up = { keys = { "up", "w" } },
    move_down = { keys = { "down", "s" } },
}
```

Each section lists LÖVE binding names or, for `mouse`, button numbers; the optional `gamepad.axes` table maps an axis name to `-1` or `1`. Actions do not need every section, and the engine does not validate the names: unknown actions return `false` and typos never match. See the [input guide](/guides/input) for mouse, gamepad, and edge behavior.

## 3. Create the first scene

Create `game/scenes/hello.lua`. The default scene path and `initialScene = "hello"` resolve to this file. This scene extends the engine's `Scene` class and stores the `GameContext` passed to its constructor:

```lua
local Scene = require("engine.scene.scene")

local Hello = {}
Hello.__index = Hello

setmetatable(Hello, { __index = Scene })

function Hello.new(context)
    local self = Scene.new()
    setmetatable(self, Hello)

    self.context = context
    self.x = 160
    self.y = 90
    self.speed = 100

    return self
end

function Hello:onLoad()
    self.width, self.height = self.context.viewport.getViewportDimensions()
end

function Hello:update(dt)
    local input = self.context.inputManager
    local dx, dy = 0, 0

    if input:isDown("move_left") then dx = dx - 1 end
    if input:isDown("move_right") then dx = dx + 1 end
    if input:isDown("move_up") then dy = dy - 1 end
    if input:isDown("move_down") then dy = dy + 1 end

    -- Keep diagonal movement at the same speed.
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt

    -- Keep the square inside the logical viewport.
    self.x = math.max(8, math.min(self.width - 8, self.x))
    self.y = math.max(8, math.min(self.height - 8, self.y))
end

function Hello:draw()
    love.graphics.push("all")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Move with the arrow keys or WASD", 8, 8)

    love.graphics.setColor(1, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)

    love.graphics.pop()
end

return Hello
```

No `onDestroy` override is needed here because this scene does not acquire resources. A scene that does should release them; see the [ResourceManager architecture](/architecture/modules/resource-manager).

## 4. Run the game

From the project root:

```sh
love .
```

You should see a `320 x 180` logical scene with instructions and a square that moves with the arrow keys or WASD inside the screen. Close the window to run `engine:quit()`. To run from elsewhere, pass `my-game/` as the argument instead of `.`.

## What just happened?

When LÖVE calls `love.load`, `Engine:load()`:

1. Applies the window settings and background color.
2. Creates the virtual-resolution viewport.
3. Pushes `initialScene` onto the scene stack.
4. Calls the scene's `onLoad` and `onEnter` callbacks.
5. Installs the LÖVE keyboard, mouse, gamepad, and joystick callbacks.

On every frame, `Engine:update()` dispatches queued events, recomputes gamepad
axis edges, updates the scene, updates audio, and finally clears the transient
input edges and mouse delta. `InputManager:isDown(action)` checks every binding
of that action, whether it comes from the keyboard, mouse, or gamepad.

`Engine:draw()` draws the scene stack through the viewport, which scales the
logical resolution to the window.

Scene changes are queued. If a scene calls `sceneManager:replace(...)` or
`sceneManager:push(...)`, the transition is processed at the end of the scene
manager update, after the current scene has finished updating.

## Next steps

- [ResourceManager](/architecture/modules/resource-manager) explains defining, loading, and releasing resources.
- [SceneManager](/architecture/modules/scene-manager) explains adding and transitioning between scenes.
- [Architecture overview](/architecture/overview) shows how the systems fit together.
- [Installation](/getting-started/installation#package-the-game) explains packaging the game and engine together.

## Common pitfalls

- **The scene class has no `new` function.** Every scene module must return a table
  with a `new` constructor.
- **The scene is not found.** Check the `initialScene` identifier and the
  `scenesPath` prefix. Dots map to folder separators.

- **Input does nothing.** Confirm the action name matches `game/config/inputMaps.lua`.
  The engine installs the LÖVE input callbacks during `Engine:load()`; do not
  forward `love.keypressed` or the other input callbacks yourself.
- **A transition is expected immediately.** Scene transitions requested during an update are deferred until the end of the scene manager update; do not expect the stack to change halfway through `update`.
- **Resources stay loaded.** Release every consumer in `onDestroy` with
  `resourceManager:releaseAll(self)`.
