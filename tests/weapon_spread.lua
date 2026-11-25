math.atan2 = math.atan2 or math.atan
love = { graphics = {}, math = { random = function() return 0.75 end } }
local graphics = love.graphics
function graphics.getDimensions() return 640, 360 end
function graphics.newCanvas() return {} end
function graphics.getCanvas() return nil end
function graphics.setCanvas() end
function graphics.clear() end
function graphics.getColor() return 1, 1, 1, 1 end
function graphics.setColor() end
function graphics.rectangle() end

local Scene = require("game.scenes.main")
local Components = require("engine.ecs.component")
local transform = { x = 120, y = 80, rotation = 0 }
local sprite = { flipH = false }
local weapon = { id = "ak", timer = 0, spread = 0 }
local world = { nextEntity = 2, components = {} }
function world:update() end
function world:query(_, callback)
	callback(2, { Weapon = weapon, Transform = transform })
end
function world:getComponent(entity, name)
	if entity == 2 and name == Components.Sprite then return sprite end
end
function world:createEntity()
	self.nextEntity = self.nextEntity + 1
	self.components[self.nextEntity] = {}
	return self.nextEntity
end
function world:addComponent(entity, name, data)
	self.components[entity][name] = data
end

local firing = true
local context = {
	inputManager = {
		isJustPressed = function() return false end,
		isMouseDown = function() return firing end,
		getMousePosition = function() return 220, 80 end,
	},
	viewport = { getViewportDimensions = function() return 640, 360 end },
	resourceManager = { get = function() return "bullet" end },
}
local scene = Scene.new(context)
scene.world = world
scene.cameraManager = { getActive = function() return { getPosition = function() return 320, 180 end } end }
local function close(a, b) return math.abs(a - b) < 1e-9 end

scene:update(0)
assert(close(world.components[3].Transform.rotation, 0), "first shot must be accurate")
assert(close(weapon.spread, math.rad(0.5)), "first shot must increase spread for the next shot")
scene:update(0.01)
assert(world.nextEntity == 3 and close(weapon.spread, math.rad(0.5)), "cooldown must not increase spread")
scene:update(0.14)
assert(close(world.components[4].Transform.rotation, math.rad(0.5) * 0.25), "second shot must use accumulated spread")
for _ = 1, 20 do scene:update(0.14) end
assert(close(weapon.spread, math.rad(4)), "spread must stop at the AK limit")
firing = false
scene:update(10)
assert(close(weapon.spread, math.rad(4)), "spread must be retained when not firing")

weapon = { id = "shotgun", timer = 0, spread = 0 }
firing = true
local firstPellet = world.nextEntity + 1
scene:update(0)
for entity = firstPellet, firstPellet + 4 do
	assert(close(world.components[entity].Transform.rotation, 0), "all pellets of the first shot use zero spread")
end
assert(close(weapon.spread, math.rad(4)), "spread increases once per shotgun shot, not per pellet")
scene:update(0.65)
for entity = firstPellet + 5, firstPellet + 9 do
	assert(close(world.components[entity].Transform.rotation, math.rad(4) * 0.25), "pellets use the same accumulated spread")
end
for _ = 1, 10 do scene:update(0.65) end
assert(close(weapon.spread, math.rad(22)), "spread must stop at the shotgun limit")
print("weapon spread tests passed")
