local Engine = require("engine.engine")

local resourcesDefinitions = require("game.config.resourceDefinitions")
local inputMaps = require("game.config.inputMaps")

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

-- Engine:load() instala los callbacks de entrada de LÖVE; no los reenvíes aquí.
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
