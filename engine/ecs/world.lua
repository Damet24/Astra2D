local EventManager = require("engine.core.events")
local PhysicsWorld = require("engine.physics.physics_world")
local Components = require("engine.ecs.component")

local World = {}
World.__index = World

function World.new(xg, yg, slepp)
	local self = setmetatable({}, World)

	self.nextEntityId = 0
	self.entities = {}
	self.components = {}
	self.systems = {}
	self.pendingDestroy = {}

	self.events = EventManager.new()
	self.physics = PhysicsWorld.new(xg, yg, slepp)

	return self
end

function World:createEntity()
	self.nextEntityId = self.nextEntityId + 1
	local entity = self.nextEntityId
	self.entities[entity] = true
	return entity
end

function World:destroyEntity(entity)
	if not self.entities[entity] then
		return
	end

	self.pendingDestroy[entity] = true
end

function World:flushDestroy()
	for entity in pairs(self.pendingDestroy) do
		local rigidBody = self:getComponent(entity, Components.RigidBody)
		if rigidBody and rigidBody.body and not rigidBody.body:isDestroyed() then
			rigidBody.body:destroy()
		end
		self.entities[entity] = nil

		for _, storage in pairs(self.components) do
			storage[entity] = nil
		end
	end

	self.pendingDestroy = {}
end

-- COMPONENT MANAGMENT

function World:addComponent(entity, name, data)
	assert(self.entities[entity], "Invalid entity")
	self.components[name] = self.components[name] or {}
	self.components[name][entity] = data or {}
end

function World:getComponent(entity, name)
	local storage = self.components[name]

	if not storage then
		return nil
	end

	return storage[entity]
end

function World:hasComponent(entity, name)
	return self:getComponent(entity, name) ~= nil
end

function World:removeComponent(entity, name)
	local storage = self.components[name]

	if storage then
		storage[entity] = nil
	end
end

-- ENTITY QUERY

function World:query(componentNames, callback)
	for entity in pairs(self.entities) do
		local components = {}
		local matches = true

		for _, name in ipairs(componentNames) do
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

-- SYSTEM MANAGEMENT

function World:addSystem(system)
	table.insert(self.systems, system)
	if system.init then
		system.init(self)
	end
end

function World:update(dt)
	for _, system in ipairs(self.systems) do
		if system.update then
			system.update(self, dt)
		end
	end

	self.events:dispatch()

	self:flushDestroy()
end

function World:draw()
    for _, system in ipairs(self.systems) do
        if system.draw then
            system.draw(self)
        end
    end
end


local function createCollisionInfo(contact, entityIsA)
    local selfVelocity
    local otherVelocity
    local normal

    if entityIsA then
        if contact.normalX and contact.normalY then
            normal = {
                x = contact.normalX,
                y = contact.normalY,
            }
        end

        if contact.velocityAX and contact.velocityAY then
            selfVelocity = {
                x = contact.velocityAX,
                y = contact.velocityAY,
            }
        end

        if contact.velocityBX and contact.velocityBY then
            otherVelocity = {
                x = contact.velocityBX,
                y = contact.velocityBY,
            }
        end
    else
        if contact.normalX and contact.normalY then
            normal = {
                x = -contact.normalX,
                y = -contact.normalY,
            }
        end

        if contact.velocityBX and contact.velocityBY then
            selfVelocity = {
                x = contact.velocityBX,
                y = contact.velocityBY,
            }
        end

        if contact.velocityAX and contact.velocityAY then
            otherVelocity = {
                x = contact.velocityAX,
                y = contact.velocityAY,
            }
        end
    end

    local relativeVelocity

    if selfVelocity and otherVelocity then
        relativeVelocity = {
            x = otherVelocity.x - selfVelocity.x,
            y = otherVelocity.y - selfVelocity.y,
        }
    end

    return {
        normal = normal,
        selfVelocity = selfVelocity,
        otherVelocity = otherVelocity,
        relativeVelocity = relativeVelocity,
    }
end

function World:_onCollision(eventName, entity, callback)
    assert(self.entities[entity], "Invalid entity")
    assert(type(callback) == "function", "callback must be a function")

    local active = true

    local listener = function(contact)
        if not active then
            return
        end

        if not self.entities[entity] or self.pendingDestroy[entity] then
            return
        end

        local other
        local entityIsA

        if contact.entityA == entity then
            other = contact.entityB
            entityIsA = true
        elseif contact.entityB == entity then
            other = contact.entityA
            entityIsA = false
        end

        if not other then
            return
        end

        if not self.entities[other] or self.pendingDestroy[other] then
            return
        end

        local collision = createCollisionInfo(contact, entityIsA)

        callback(other, collision)
    end

    self.events:on(eventName, listener)

    -- Return an unsubscribe function.
    return function()
        if not active then
            return
        end

        active = false
        self.events:off(eventName, listener)
    end
end

function World:onCollisionStarted(entity, callback)
    return self:_onCollision("collision_started", entity, callback)
end

function World:onCollisionEnded(entity, callback)
    return self:_onCollision("collision_ended", entity, callback)
end


return World
