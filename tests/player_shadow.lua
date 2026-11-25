local unpack = table.unpack or unpack
local calls = {}
local color = { 1, 1, 1, 1 }
local colorStack = {}
love = { graphics = {} }
local graphics = love.graphics
function graphics.getDimensions() return 640, 360 end
function graphics.newCanvas() return "background" end
function graphics.getCanvas() return nil end
function graphics.setCanvas() end
function graphics.clear() end
function graphics.getColor() return unpack(color) end
function graphics.setColor(r, g, b, a)
	if type(r) == "table" then
		color = { unpack(r) }
	else
		color = { r, g, b, a }
	end
end
function graphics.rectangle() end
function graphics.push()
	colorStack[#colorStack + 1] = { unpack(color) }
end
function graphics.pop()
	color = table.remove(colorStack)
end
function graphics.ellipse(mode, x, y, radiusX, radiusY)
	calls[#calls + 1] = { kind = "shadow", mode = mode, x = x, y = y, radiusX = radiusX, radiusY = radiusY, color = color }
end
function graphics.draw(image)
	calls[#calls + 1] = { kind = image }
end

local Scene = require("game.scenes.main")
local Components = require("engine.ecs.component")
local RenderPipeline = require("engine.graphics.RenderPipeline")
local transform = { x = 120, y = 80 }
local sprite = { image = "player", layer = 40, origin = { x = 24, y = 24 } }
local world = {}
function world:getComponent(entity, component)
	if entity == 1 and component == Components.Transform then return transform end
end
function world:query(_, callback)
	if transform then callback(1, { Transform = transform, Sprite = sprite }) end
end
local scene = Scene.new({})
scene.player = 1
scene.world = world
scene.pipeline = RenderPipeline.new()
scene.cameraManager = { getActive = function() return { draw = function(_, draw) draw() end } end }

scene:draw()
assert(#calls == 3 and calls[1].kind == "background" and calls[2].kind == "shadow" and calls[3].kind == "player")
local shadow = calls[2]
assert(shadow.mode == "fill" and shadow.x == 120 and shadow.y == 96)
assert(shadow.radiusX == 14 and shadow.radiusY == 4 and shadow.color[4] == 0.35)
assert(color[1] == 1 and color[2] == 1 and color[3] == 1 and color[4] == 1)

calls = {}
transform.x, transform.y = 25, 30
scene:draw()
assert(calls[2].x == 25 and calls[2].y == 46, "shadow must follow the player")

calls = {}
transform = nil
scene:draw()
assert(#calls == 1 and calls[1].kind == "background", "no shadow should be drawn without a player transform")
print("player shadow tests passed")
