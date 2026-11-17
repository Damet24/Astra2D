love = {
	graphics = { newQuad = function(...) return { ... } end },
	physics = {
		newRectangleShape = function(x, y, width, height)
			return { x = x, y = y, width = width, height = height }
		end,
		newBody = function(_, x, y, bodyType)
			local body = { x = x, y = y, type = bodyType, velocityX = 0, velocityY = 0, destroyed = false }
			function body:setAngle(angle) self.angle = angle end
			function body:setFixedRotation(fixed) self.fixedRotation = fixed end
			function body:getLinearVelocity() return self.velocityX, self.velocityY end
			function body:setLinearVelocity(vx, vy) self.velocityX, self.velocityY = vx, vy end
			function body:isDestroyed() return self.destroyed end
			function body:destroy() self.destroyed = true end
			return body
		end,
		newFixture = function(body, shape)
			body.shape = shape
			return { setSensor = function() end, setUserData = function() end, setFriction = function() end }
		end,
	},
}
package.loaded["engine.physics.physics_world"] = { new = function() return {} end }
package.loaded["engine.ecs.systems.collisionSystem"] = {}

local Level = require("game.scenes.levels.level")
local Components = require("engine.ecs.component")
local image = { getDimensions = function() return 32, 32 end }
local context = {
	resourceManager = { get = function() return image end },
	viewport = { getViewportDimensions = function() return 320, 240 end },
	audioManager = { playMusic = function() end, playSound = function() end },
}

local function loadLevel()
	local level = Level.new(context, {
		map = { width = 20, height = 15, tilewidth = 16, tileheight = 16, layers = {} },
		background = "background_blue",
		enemySpawns = { { x = 120, y = 100 } },
	})
	level:onLoad()
	local world = level.world
	local enemy = level.player + 1
	assert(world.entities[enemy], "enemy spawn did not create an entity")
	local playerBody = assert(world:getComponent(level.player, Components.RigidBody)).body
	local enemyBody = assert(world:getComponent(enemy, Components.RigidBody)).body
	local velocity = assert(world:getComponent(level.player, Components.Velocity))
	playerBody:setLinearVelocity(37, 240)
	velocity.x, velocity.y = 37, 240
	return level, enemy, playerBody, enemyBody, velocity
end

local function contact(player, other, playerFirst, normalY, playerVelocityY, otherVelocityY)
	if playerFirst then
		return { entityA = player, entityB = other, normalY = normalY,
			velocityAY = playerVelocityY, velocityBY = otherVelocityY }
	end
	return { entityA = other, entityB = player, normalY = -normalY,
		velocityAY = otherVelocityY, velocityBY = playerVelocityY }
end

local failures = 0
local function test(name, fn)
	local ok, message = pcall(fn)
	if not ok then
		failures = failures + 1
		io.stderr:write("FAIL ", name, ": ", tostring(message), "\n")
	end
end

test("enemy spawn has marker", function()
	local level, enemy = loadLevel()
	assert(level.world:hasComponent(enemy, "Enemy"), "spawned enemy lacks Enemy component")
	assert(not level.world:hasComponent(level.player, "Enemy"), "player must not be marked as an enemy")
end)

for _, playerFirst in ipairs({ true, false }) do
	local order = playerFirst and "player first" or "player second"
	test("stomp, " .. order, function()
		local level, enemy, playerBody, enemyBody, velocity = loadLevel()
		local world = level.world
		world.events:emit("collision_started", contact(level.player, enemy, playerFirst, 1, 240, 30))
		assert(not world.pendingDestroy[enemy], "event must be queued until dispatch")
		assert(playerBody.velocityY == 240, "event must not bounce before dispatch")
		world.events:dispatch()

		assert(world.pendingDestroy[enemy], "stomp must schedule enemy destruction")
		assert(world.entities[enemy] and not enemyBody:isDestroyed(), "enemy destruction must be deferred")
		assert(world:getComponent(enemy, Components.RigidBody), "components must remain until flush")
		local vx, vy = playerBody:getLinearVelocity()
		assert(vx == 37 and vy < 0, "stomp must bounce upward without changing horizontal speed")
		assert(velocity.x == vx and velocity.y == vy, "velocity component must match the bounce")

		world:flushDestroy()
		assert(not world.entities[enemy] and enemyBody:isDestroyed(), "flush must destroy the enemy and its body")
		assert(not world.pendingDestroy[enemy], "flush must clear pending destruction")
		assert(not world:getComponent(enemy, Components.RigidBody), "flush must remove enemy components")
		assert(world.entities[level.player] and not playerBody:isDestroyed(), "stomp must preserve the player")
	end)

	for _, case in ipairs({
		{ name = "side collision", normalY = 0, playerVelocityY = 240, otherVelocityY = 30 },
		{ name = "opposite normal", normalY = -1, playerVelocityY = 240, otherVelocityY = 30 },
		{ name = "not descending relative to enemy", normalY = 1, playerVelocityY = 30, otherVelocityY = 240 },
	}) do
		test(case.name .. ", " .. order, function()
			local level, enemy, playerBody, enemyBody, velocity = loadLevel()
			local world = level.world
			assert(world:hasComponent(enemy, "Enemy"), "collision must involve a marked enemy")
			world.events:emit("collision_started", contact(level.player, enemy, playerFirst,
				case.normalY, case.playerVelocityY, case.otherVelocityY))
			world.events:dispatch()
			assert(not world.pendingDestroy[enemy], "non-stomp must not schedule destruction")
			world:flushDestroy()
			assert(world.entities[enemy] and not enemyBody:isDestroyed(), "non-stomp must preserve the enemy")
			local vx, vy = playerBody:getLinearVelocity()
			assert(vx == 37 and vy == 240 and velocity.x == 37 and velocity.y == 240,
				"non-stomp must not bounce the player")
		end)
	end

	for _, withVelocities in ipairs({ true, false }) do
		local description = withVelocities and "with velocities" or "without velocities"
		test("non-enemy contact " .. description .. ", " .. order, function()
			local level, enemy, playerBody, enemyBody, velocity = loadLevel()
			local world = level.world
			local other = world:createEntity()
			local playerVelocityY = withVelocities and 240 or nil
			local otherVelocityY = withVelocities and 30 or nil
			world.events:emit("collision_started", contact(level.player, other, playerFirst, 1,
				playerVelocityY, otherVelocityY))
			world.events:dispatch()
			assert(not world.pendingDestroy[other] and not world.pendingDestroy[enemy],
				"non-enemy contact must not schedule destruction")
			world:flushDestroy()
			assert(world.entities[other] and world.entities[enemy] and not enemyBody:isDestroyed(),
				"non-enemy contact must preserve both entities")
			local vx, vy = playerBody:getLinearVelocity()
			assert(vx == 37 and vy == 240 and velocity.x == 37 and velocity.y == 240,
				"non-enemy contact must not bounce the player")
		end)
	end
end

if failures > 0 then
	io.stderr:write(failures, " level stomp test(s) failed\n")
	os.exit(1)
end
print("level stomp tests passed")
