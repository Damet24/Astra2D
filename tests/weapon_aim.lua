local unpack = table.unpack or unpack
math.atan2 = math.atan2 or math.atan
love = { graphics = {}, math = { random = function() return 0.5 end } }
local graphics = love.graphics
function graphics.getDimensions() return 640, 360 end
function graphics.newCanvas() return {} end
function graphics.getCanvas() return nil end
function graphics.setCanvas() end
function graphics.clear() end
function graphics.getColor() return 1, 1, 1, 1 end
function graphics.setColor() end
function graphics.rectangle() end
function graphics.push() end
function graphics.pop() end
local drawArgs
function graphics.draw(...) drawArgs = { ... } end

local Scene = require("game.scenes.main")
local Components = require("engine.ecs.component")
local RenderSystem = require("engine.ecs.systems.renderSystem")
local playerTransform = { x = 120, y = 80 }
local weaponTransform = { x = 120, y = 80, rotation = 0 }
local weaponSprite = { image = "weapon", origin = { x = -5, y = 5 }, flipH = false }
local weapon = { id = "ak", timer = 0 }
local world = { nextEntity = 2, components = {} }
function world:update() end
function world:query(_, callback)
	callback(2, { Weapon = weapon, Transform = weaponTransform })
end
function world:getComponent(entity, name)
	if entity == 1 and name == Components.Transform then return playerTransform end
	if entity == 2 and name == Components.Sprite then return weaponSprite end
end
function world:createEntity()
	self.nextEntity = self.nextEntity + 1
	self.components[self.nextEntity] = {}
	return self.nextEntity
end
function world:addComponent(entity, name, data)
	self.components[entity][name] = data
end

local mouseX, mouseY
local context = {
	inputManager = {
		isJustPressed = function() return false end,
		isMouseDown = function() return true end,
		getMousePosition = function() return mouseX, mouseY end,
	},
	viewport = { getViewportDimensions = function() return 640, 360 end },
	resourceManager = { get = function() return "bullet" end },
}
local scene = Scene.new(context)
scene.player = 1
scene.world = world
scene.cameraManager = { getActive = function() return { getPosition = function() return 320, 180 end } end }

local directions = {
	{ 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 },
	{ -1, 0 }, { -1, -1 }, { 0, -1 }, { 1, -1 },
}
for _, direction in ipairs(directions) do
	local dx, dy = unpack(direction)
	mouseX, mouseY = playerTransform.x + dx * 50, playerTransform.y + dy * 50
	weapon.timer = 0
	scene:update(1 / 60)

	local length = math.sqrt(dx * dx + dy * dy)
	local expectedX, expectedY = dx / length, dy / length
	RenderSystem.drawEntity(world, { entity = 2, transform = weaponTransform, sprite = weaponSprite })
	local angle, scaleX, scaleY = drawArgs[4], drawArgs[5], drawArgs[6]
	assert(math.abs(math.cos(angle) * scaleX - expectedX) < 1e-9, "weapon must point toward the mouse on X")
	assert(math.abs(math.sin(angle) * scaleX - expectedY) < 1e-9, "weapon must point toward the mouse on Y")
	assert(scaleY == (dx < 0 and -1 or 1), "weapon should flip vertically when aiming left")

	local bullet = world.components[world.nextEntity]
	assert(math.abs(bullet.Velocity.x / 380 - expectedX) < 1e-9)
	assert(math.abs(bullet.Velocity.y / 380 - expectedY) < 1e-9)
end
print("weapon aim tests passed")
