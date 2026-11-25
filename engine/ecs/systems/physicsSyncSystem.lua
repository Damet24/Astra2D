local Components = require("engine.ecs.component")

local PhysicsSyncSystem = {}

function PhysicsSyncSystem.update(world)
    world:query2(
        Components.Transform, Components.RigidBody,
        function(entity, transform, rigidBody)
            local body = rigidBody.body
            if body then
                transform.x, transform.y = body:getPosition()
                transform.rotation = body:getAngle()
            end
        end)
end

return PhysicsSyncSystem
