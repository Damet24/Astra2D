local Components = require("engine.ecs.component")

local ENEMY_SPEED = 60
local ENEMY_COMPONENT = "Enemy"

local function fixtureBelongsToEnemy(fixture, body, entity)
    if not fixture then
        return false
    end

    if fixture.getUserData and fixture:getUserData() == entity then
        return true
    end

    local fixtureBody = fixture:getBody()
    if fixtureBody == body then
        return true
    end

    if fixtureBody and body and fixtureBody.getUserData and body.getUserData then
        local fixtureBodyData = fixtureBody:getUserData()
        local bodyData = body:getUserData()
        if fixtureBodyData ~= nil and fixtureBodyData == bodyData then
            return true
        end
    end

    return false
end

local function isGrounded(body, entity)
    if not body or body.isDestroyed and body:isDestroyed() then
        return false
    end

    for _, contact in ipairs(body:getContacts() or {}) do
        if contact and contact:isTouching() and contact:isEnabled() then
            local first, second = contact:getFixtures()
            if first and second and not first:isSensor() and not second:isSensor() then
                local _, normalY = contact:getNormal()
                normalY = normalY or 0
                local firstIsEnemy = fixtureBelongsToEnemy(first, body, entity)
                local secondIsEnemy = fixtureBelongsToEnemy(second, body, entity)
                if (firstIsEnemy and normalY > 0.5) or (secondIsEnemy and normalY < -0.5) then
                    return true
                end
            end
        end
    end
    return false
end

local function updateEnemy(world, entity, rigidBody, velocity, animation)
    if not rigidBody or not rigidBody.body or rigidBody.body.isDestroyed and rigidBody.body:isDestroyed() then
        return
    end
    if not velocity or not animation then
        return
    end

    local body = rigidBody.body
    local _, velocityY = body:getLinearVelocity()
    velocity.x, velocity.y = -ENEMY_SPEED, velocityY
    body:setLinearVelocity(velocity.x, velocity.y)

    local animationName = isGrounded(body, entity) and "run" or "fall"
    if animation.current ~= animationName then
        animation.current = animationName
        animation.frame = 1
        animation.timer = 0
        animation.playing = true
        animation.loop = true
    end
end

local EnemySystem = {}

function EnemySystem.update(world)
    world:query(
        { ENEMY_COMPONENT, Components.RigidBody, Components.Velocity, Components.Animation },
        function(entity, components)
            updateEnemy(
                world,
                entity,
                components[Components.RigidBody],
                components[Components.Velocity],
                components[Components.Animation]
            )
        end
    )
end

-- Per-entity system kept for compatibility: EnemySystem.new(entity).
function EnemySystem.new(entity)
    return {
        update = function(world)
            updateEnemy(
                world,
                entity,
                world:getComponent(entity, Components.RigidBody),
                world:getComponent(entity, Components.Velocity),
                world:getComponent(entity, Components.Animation)
            )
        end,
    }
end

return EnemySystem
