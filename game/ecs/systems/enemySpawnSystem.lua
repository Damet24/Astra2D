local Components = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.PhysicsFactory")

local EnemySpawnSystem = {}

-- The logical viewport is 256px wide, so 112px is just inside its edge.
local SPAWN_MARGIN = 115

local function createEnemy(world, spawn, image, animations)
    local entity = world:createEntity()
    world:addComponent(entity, "Enemy")
    world:addComponent(entity, Components.Transform, { x = spawn.x, y = spawn.y })
    world:addComponent(entity, Components.Velocity, { x = 0, y = 0 })
    world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
    world:addComponent(entity, Components.Collider, { shape = "rectangle", width = 18, height = 28 })
    world:addComponent(entity, Components.Sprite, {
        image = image,
        layer = 40,
        origin = { x = 16, y = 16 },
        flipH = true,
        animations = animations,
    })
    world:addComponent(entity, Components.Animation,
        { current = "fall", frame = 1, timer = 0, playing = true, loop = true })
    local body, fixture = PhysicsFactory.create(world, entity)
    fixture:setFriction(0)
    body:setFixedRotation(true)
    return entity
end

local function isInSpawnRange(spawnX, playerX)
    return spawnX >= playerX - SPAWN_MARGIN and spawnX <= playerX + SPAWN_MARGIN
end

function EnemySpawnSystem.new(player, image, animations)
    return {
        update = function(world)
            local playerPosition = world:getComponent(player, Components.Transform)
            if not playerPosition then
                return
            end

            -- Collect first: adding entities while world:query iterates
            -- world.entities can skip or repeat entries.
            local spawns = {}
            world:query({ "EnemySpawn" }, function(entity, components)
                if world.pendingDestroy and world.pendingDestroy[entity] then
                    return
                end
                local spawn = components.EnemySpawn
                if spawn and isInSpawnRange(spawn.x, playerPosition.x) then
                    table.insert(spawns, { entity = entity, spawn = spawn })
                end
            end)

            for _, entry in ipairs(spawns) do
                createEnemy(world, entry.spawn, image, animations)
                world:destroyEntity(entry.entity)
            end
        end,
    }
end

return EnemySpawnSystem
