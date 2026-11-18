local Engine = require("engine.engine")

local engine = Engine.new({
    scenesPath = "scenes",
    initialScene = "field",
    inputMaps = {
        left = {
            keys = { "left", "a" },
            gamepad = { "dpleft", axes = { leftx = -1 } },
        },
        right = {
            keys = { "right", "d" },
            gamepad = { "dpright", axes = { leftx = 1 } },
        },
        up = {
            keys = { "up", "w" },
            gamepad = { "dpup", axes = { lefty = -1 } },
        },
        down = {
            keys = { "down", "s" },
            gamepad = { "dpdown", axes = { lefty = 1 } },
        },
        pause = {
            keys = { "escape" },
            gamepad = { "start" },
        },
        restart = {
            keys = { "r" },
            gamepad = { "back" },
        },
    },
    resourceDefinitions = {
        hud = { type = "font", size = 12 },
    },
    window = { width = 800, height = 450, resizable = false, vsync = false },
    rendering = { width = 400, height = 225, backgroundColor = { 0.06, 0.09, 0.13 } },
})

-- Engine:load() installs the LÖVE input callbacks, so main.lua does not forward them.
function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.quit() engine:quit() end

if os.getenv("ASTRA_EXAMPLE_SMOKE") == "1" then
    require("smoke").install(engine)
end
