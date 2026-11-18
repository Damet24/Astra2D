local EnemySystem = require("game.ecs.systems.enemySystem")
local Components = require("engine.ecs.component")

local function makeEnemy()
	local body = { x = 25, y = 0, contacts = {} }
	function body:getContacts() return self.contacts end
	function body:getLinearVelocity() return self.x, self.y end
	function body:setLinearVelocity(x, y) self.x, self.y = x, y end

	local components = {
		[Components.RigidBody] = { body = body },
		[Components.Velocity] = { x = 99, y = 999 },
		[Components.Animation] = { current = "fall", frame = 4, timer = 0.07 },
	}
	local world = {}
	function world:getComponent(entity, name)
		assert(entity == 7, "system accessed the wrong entity")
		return components[name]
	end
	return body, components, world, EnemySystem.new(7)
end

local function makeContact(body, options)
	options = options or {}
	local otherBody = {}
	local enemyFixture = {
		getBody = function() return body end,
		isSensor = function() return options.enemySensor or false end,
	}
	local otherFixture = {
		getBody = function() return otherBody end,
		isSensor = function() return options.otherSensor or false end,
	}
	local first = options.enemySecond and otherFixture or enemyFixture
	local second = options.enemySecond and enemyFixture or otherFixture
	return {
		isTouching = function() return options.touching ~= false end,
		isEnabled = function() return options.enabled ~= false end,
		getFixtures = function() return first, second end,
		getNormal = function() return 0, options.normalY or 0 end,
	}
end

local body, components, world, system = makeEnemy()
local velocity = components[Components.Velocity]
local animation = components[Components.Animation]
local function update() system.update(world, 1 / 60) end

-- Use the body's current vertical velocity, rather than a stale component value.
body.y = 42
update()
assert(velocity.x == -60 and velocity.y == 42, "falling velocity must keep gravity and move left")
assert(body.y == 42, "updating the enemy must not cancel vertical velocity")
assert(animation.current == "fall" and animation.frame == 4 and animation.timer == 0.07,
	"an unchanged fall animation must keep its frame and timer")
body.y = -31
update()
assert(velocity.x == -60 and velocity.y == -31 and body.y == -31,
	"leftward movement must preserve upward velocity too")

local floor = makeContact(body, { normalY = 1 })
body.contacts = { floor }
body.y = 0
update()
assert(velocity.x == -60 and velocity.y == 0, "enemy must keep moving left on the ground")
assert(animation.current == "run" and animation.frame == 1 and animation.timer == 0,
	"landing must switch to run and reset frame and timer")
animation.frame, animation.timer = 6, 0.04
update()
assert(animation.current == "run" and animation.frame == 6 and animation.timer == 0.04,
	"an unchanged run animation must keep its frame and timer")

body.contacts = {}
body.y = 20
update()
assert(velocity.x == -60 and velocity.y == 20, "enemy must keep moving left after leaving the ground")
assert(animation.current == "fall" and animation.frame == 1 and animation.timer == 0,
	"leaving the ground must switch to fall and reset frame and timer")

local cases = {
	{ "floor, enemy first", { normalY = 1 }, "run" },
	{ "floor, enemy second", { enemySecond = true, normalY = -1 }, "run" },
	{ "opposite normal, enemy first", { normalY = -1 }, "fall" },
	{ "opposite normal, enemy second", { enemySecond = true, normalY = 1 }, "fall" },
	{ "wall", { normalY = 0 }, "fall" },
	{ "threshold is strict, enemy first", { normalY = 0.5 }, "fall" },
	{ "threshold is strict, enemy second", { enemySecond = true, normalY = -0.5 }, "fall" },
	{ "not touching", { normalY = 1, touching = false }, "fall" },
	{ "disabled", { normalY = 1, enabled = false }, "fall" },
	{ "enemy fixture is a sensor", { normalY = 1, enemySensor = true }, "fall" },
	{ "floor fixture is a sensor", { normalY = 1, otherSensor = true }, "fall" },
	{ "sensor with enemy second", { enemySecond = true, normalY = -1, otherSensor = true }, "fall" },
}
for _, case in ipairs(cases) do
	body.contacts = { makeContact(body, case[2]) }
	animation.current, animation.frame, animation.timer = "unrelated", 8, 0.08
	update()
	assert(animation.current == case[3], case[1] .. ": wrong animation")
	assert(animation.frame == 1 and animation.timer == 0, case[1] .. ": transition did not reset animation")
	assert(velocity.x == -60, case[1] .. ": enemy stopped moving left")
end

body.contacts = {
	makeContact(body, { normalY = 0 }),
	makeContact(body, { normalY = 1, otherSensor = true }),
	makeContact(body, { enemySecond = true, normalY = -1 }),
}
update()
assert(animation.current == "run", "a valid floor among other contacts must count as grounded")

-- LÖVE may hand out a different Lua proxy for the same Box2D body. The
-- fixture userData is the reliable link to the enemy entity in that case.
local proxyBody = { getUserData = function() return 7 end }
local proxyEnemyFixture = {
	getBody = function() return proxyBody end,
	getUserData = function() return 7 end,
	isSensor = function() return false end,
}
local proxyFloorFixture = {
	getBody = function() return {} end,
	isSensor = function() return false end,
}
body.contacts = {
	{
		isTouching = function() return true end,
		isEnabled = function() return true end,
		getFixtures = function() return proxyEnemyFixture, proxyFloorFixture end,
		getNormal = function() return 0, 1 end,
	},
}
animation.current, animation.frame, animation.timer = "unrelated", 8, 0.08
update()
assert(animation.current == "run", "a body proxy with matching fixture userData must count as grounded")

-- The global system must only query entities marked as enemies, otherwise it
-- tries to move the player, walls, collectibles and spawn markers too.
local enemyComponents = {
	["Enemy"] = true,
	[Components.RigidBody] = components[Components.RigidBody],
	[Components.Velocity] = components[Components.Velocity],
	[Components.Animation] = components[Components.Animation],
}
local globalEntities = {
	[7] = enemyComponents,
	[8] = { [Components.Transform] = {} }, -- e.g. a spawn marker without physics
}
local queriedNames
local globalWorld = {}
function globalWorld:query(names, callback)
	queriedNames = names
	for entity, entityComponents in pairs(globalEntities) do
		local matches = true
		for _, name in ipairs(names) do
			if not entityComponents[name] then
				matches = false
				break
			end
		end
		if matches then
			callback(entity, entityComponents)
		end
	end
end

velocity.x, velocity.y = 99, 999
animation.current = "fall"
EnemySystem.update(globalWorld)
assert(queriedNames and queriedNames[1] == "Enemy", "global system must filter by the Enemy component")
assert(velocity.x == -60 and velocity.y == body.y, "global system must move the enemy")
assert(animation.current == "run", "global system must animate the grounded enemy")
print("enemy system tests passed")
