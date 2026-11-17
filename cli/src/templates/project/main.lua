local Engine = require("engine.engine")

local resourcesDefinitions = require("game.resources.definitions")
local inputMaps = require("game.inputMaps")

local GAME_RESOLUTION = {
	width = 1280,
	height = 720,
}

local engine = Engine.new({
	initialScene = "main",
	resourceDefinitions = resourcesDefinitions,
	inputMaps = inputMaps,
	window = {
		width = GAME_RESOLUTION.width,
		height = GAME_RESOLUTION.height,
		fullscreen = false,
		resizable = false,
		vsync = true,
	},

	rendering = {
		width = GAME_RESOLUTION.width,
		height = GAME_RESOLUTION.height,
		pixelPerfect = false,
		backgroundColor = { 0, 0, 0 },
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

function love.keypressed(key)
	engine:keypressed(key)
end

function love.keyreleased(key)
	engine:keyreleased(key)
end

function love.quit()
	engine:quit()
end
