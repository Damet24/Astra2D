---@diagnostic disable: duplicate-set-field
local Engine = require("engine.engine")

local resourcesDefinitions = require("game.config.resourceDefinitions")
local inputMaps = require("game.config.inputMaps")

local GAME_RESOLUTION = {
    width = 256,
    height = 240,
}

local engine = Engine.new({
    initialScene = "mainMenu",
    resourceDefinitions = resourcesDefinitions,
    inputMaps = inputMaps,
    window = {
        width = GAME_RESOLUTION.width * 3,
        height = GAME_RESOLUTION.height * 3,
        fullscreen = false,
        resizable = false,
        vsync = true,
    },

    rendering = {
        width = GAME_RESOLUTION.width,
        height = GAME_RESOLUTION.height,
        pixelPerfect = true,
        backgroundColor = { 0.18, 0.25, 0.34 },
    },

    audio = {
        masterVolume = 0.1,
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
