local Engine = require("engine.engine")

local engine = Engine.new({
    scenesPath = "scenes",
    initialScene = "field",
    inputMaps = {
        left = { "left", "a" },
        right = { "right", "d" },
        up = { "up", "w" },
        down = { "down", "s" },
        pause = { "escape" },
        restart = { "r" },
    },
    resourceDefinitions = {
        hud = { type = "font", size = 12 },
    },
    window = { width = 800, height = 450, resizable = false, vsync = false },
    rendering = { width = 400, height = 225, backgroundColor = { 0.06, 0.09, 0.13 } },
})

function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.keypressed(key) engine:keypressed(key) end
function love.keyreleased(key) engine:keyreleased(key) end
function love.quit() engine:quit() end

if os.getenv("ASTRA_EXAMPLE_SMOKE") == "1" then
    require("smoke").install(engine)
end
