local CollisionSystem = {}

function CollisionSystem.init(world)
    world.pendingContacts = {}

    world.physics:setCallbacks(function(first, second, contact)
        local normalX, normalY

        if not first:isSensor() and not second:isSensor() then
            normalX, normalY = contact:getNormal()
        end

        local velocityAX, velocityAY =
            first:getBody():getLinearVelocity()

        local velocityBX, velocityBY =
            second:getBody():getLinearVelocity()

        table.insert(world.pendingContacts, {
            name = "collision_started",

            entityA = first:getUserData(),
            entityB = second:getUserData(),

            normalX = normalX,
            normalY = normalY,

            velocityAX = velocityAX,
            velocityAY = velocityAY,

            velocityBX = velocityBX,
            velocityBY = velocityBY,

            sensorA = first:isSensor(),
            sensorB = second:isSensor(),
        })
    end, function(first, second)
        table.insert(world.pendingContacts, {
            name = "collision_ended",
            entityA = first:getUserData(),
            entityB = second:getUserData(),
        })
    end)
end

function CollisionSystem.update(world)
    local contacts = world.pendingContacts or {}
    world.pendingContacts = {}

    for _, contact in ipairs(contacts) do
        world.events:emit(contact.name, contact)
    end
end

return CollisionSystem
