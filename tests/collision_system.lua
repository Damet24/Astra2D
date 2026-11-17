local CollisionSystem = require("engine.ecs.systems.collisionSystem")
local EventManager = require("engine.core.events")

local physics = {}
function physics:setCallbacks(beginContact, endContact)
	self.beginContact = beginContact
	self.endContact = endContact
end

local world = { physics = physics, events = EventManager.new() }
CollisionSystem.init(world)

local function fixture(id, velocityY, sensor)
	local body = { velocityY = velocityY }
	function body:getLinearVelocity() return 0, self.velocityY end
	return {
		getUserData = function() return id end,
		getBody = function() return body end,
		isSensor = function() return sensor end,
	}, body
end

local first, firstBody = fixture(1, 150, false)
local second, secondBody = fixture(2, 20, false)
local normalY = 1
local contact = { getNormal = function() return 0, normalY end }
local started, ended = {}, {}
world.events:on("collision_started", function(event) started[#started + 1] = event end)
world.events:on("collision_ended", function(event) ended[#ended + 1] = event end)

physics.beginContact(first, second, contact)
firstBody.velocityY, secondBody.velocityY, normalY = 0, 0, -1
CollisionSystem.update(world)
world.events:dispatch()
assert(#started == 1 and started[1].entityA == 1 and started[1].entityB == 2)
assert(started[1].normalY == 1 and started[1].velocityAY == 150 and started[1].velocityBY == 20,
	"collision data must be captured at the start of contact")

local sensor = fixture(3, 0, true)
physics.beginContact(sensor, first, { getNormal = function() error("sensor has no contact normal") end })
physics.endContact(first, second)
CollisionSystem.update(world)
world.events:dispatch()
assert(#started == 2 and started[2].entityA == 3 and started[2].normalY == nil)
assert(started[2].velocityAY == 0 and started[2].velocityBY == 0)
assert(#ended == 1 and ended[1].entityA == 1 and ended[1].entityB == 2)
assert(ended[1].normalY == nil and ended[1].velocityAY == nil)
print("collision system tests passed")
