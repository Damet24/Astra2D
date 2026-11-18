love = {
	physics = {
		setMeter = function() end,
		newRectangleShape = function(...)
			return { ... }
		end,
		newBody = function(_, x, y, bodyType)
			local body = { x = x, y = y, type = bodyType }
			function body:setAngle(angle) self.angle = angle end
			function body:setFixedRotation(fixed) self.fixedRotation = fixed end
			return body
		end,
		newFixture = function(body)
			local fixture = {}
			function fixture:setSensor(value) self.sensor = value end
			function fixture:setUserData(value) self.userData = value end
			function fixture:setFriction(value) self.friction = value end
			function fixture:getBody() return body end
			function fixture:getUserData() return self.userData end
			return fixture
		end,
	},
}

local Components = require("engine.ecs.component")
local EnemySpawnSystem = require("game.ecs.systems.enemySpawnSystem")

local function newWorld()
	local world = {
		entities = {},
		components = {},
		pendingDestroy = {},
		nextEntityId = 0,
		physics = {},
	}
	function world:createEntity()
		self.nextEntityId = self.nextEntityId + 1
		self.entities[self.nextEntityId] = true
		return self.nextEntityId
	end
	function world:addComponent(entity, name, data)
		self.components[name] = self.components[name] or {}
		self.components[name][entity] = data or {}
	end
	function world:getComponent(entity, name)
		local storage = self.components[name]
		return storage and storage[entity] or nil
	end
	function world:hasComponent(entity, name)
		return self:getComponent(entity, name) ~= nil
	end
	function world:destroyEntity(entity)
		self.pendingDestroy[entity] = true
	end
	function world:query(names, callback)
		for entity in pairs(self.entities) do
			local components = {}
			local matches = true
			for _, name in ipairs(names) do
				local component = self:getComponent(entity, name)
				if not component then
					matches = false
					break
				end
				components[name] = component
			end
			if matches then
				callback(entity, components)
			end
		end
	end
	return world
end

local world = newWorld()
local player = world:createEntity()
world:addComponent(player, Components.Transform, { x = 0, y = 0 })

local nearMarker = world:createEntity()
world:addComponent(nearMarker, "EnemySpawn", { x = 100, y = 50 })
local farMarker = world:createEntity()
world:addComponent(farMarker, "EnemySpawn", { x = 500, y = 50 })
local behindMarker = world:createEntity()
world:addComponent(behindMarker, "EnemySpawn", { x = -200, y = 50 })

local image = {}
local animations = { run = {}, fall = {} }
local system = EnemySpawnSystem.new(player, image, animations)

local function enemyCount()
	local count = 0
	for entity in pairs(world.entities) do
		if world:hasComponent(entity, "Enemy") then
			count = count + 1
		end
	end
	return count
end

system.update(world)
assert(enemyCount() == 1, "only the enemy inside the spawn range should spawn")
assert(world.pendingDestroy[nearMarker], "used spawn marker must be destroyed")
assert(not world.pendingDestroy[farMarker], "far spawn marker must be kept")
assert(not world.pendingDestroy[behindMarker], "behind spawn marker must be kept")

system.update(world)
assert(enemyCount() == 1, "the same spawn marker must not create a second enemy")

local playerPosition = world:getComponent(player, Components.Transform)
playerPosition.x = 400
system.update(world)
assert(enemyCount() == 2, "the far enemy must spawn when the player gets closer")
assert(world.pendingDestroy[farMarker], "far spawn marker must be consumed once in range")

local enemy
for entity in pairs(world.entities) do
	if world:hasComponent(entity, "Enemy") and not enemy then
		enemy = entity
	end
end
local transform = assert(world:getComponent(enemy, Components.Transform))
local rigidBody = assert(world:getComponent(enemy, Components.RigidBody))
local animation = assert(world:getComponent(enemy, Components.Animation))
assert(transform.x == 100 and transform.y == 50, "enemy must spawn at the marker position")
assert(rigidBody.type == "dynamic" and rigidBody.body.fixedRotation, "enemy body must be a fixed-rotation dynamic body")
assert(animation.current == "fall" and animation.playing, "enemy must start with the fall animation")

print("enemy spawn system tests passed")
