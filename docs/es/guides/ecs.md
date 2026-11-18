# Entidades, sistemas y física

## Prerrequisitos

Empieza con [Tu primer proyecto](/es/getting-started/first-project) y LÖVE, incluidas las acciones de entrada `move_left` y `move_right`. Este ejemplo cabe en su viewport lógico de `320 × 180`. La escena es dueña de `World`; ni el motor ni el gestor de escenas lo crean o actualizan automáticamente.

## 1. Crear una escena con una entidad y un sistema

Crea `game/scenes/ecs_tutorial.lua`, establece `initialScene = "ecs_tutorial"` en `main.lua` y ejecuta `love .`. La caja con contorno verde cae sobre el suelo y se mueve horizontalmente con las flechas o A/D. Los ID de contacto se imprimen en la consola.

```lua
local Scene = require("engine.scene.scene")
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.physics_factory")
local PhysicsMovement = require("engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local PhysicsSync = require("engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("engine.ecs.systems.collisionSystem")
local PhysicsDebug = require("engine.ecs.systems.physicsDebugSystem")

local Tutorial = {}
Tutorial.__index = Tutorial
setmetatable(Tutorial, { __index = Scene })

function Tutorial.new(context)
    local self = Scene.new()
    setmetatable(self, Tutorial)
    self.context = context
    return self
end

function Tutorial:onLoad()
    local world = World.new(0, 640, true)
    self.world = world

    local player = world:createEntity()
    world:addComponent(player, C.Transform, { x = 160, y = 40 })
    world:addComponent(player, C.Velocity, { x = 0, y = 0 })
    world:addComponent(player, C.RigidBody, { type = "dynamic" })
    world:addComponent(player, C.Collider, { shape = "rectangle", width = 18, height = 28 })
    local body, fixture = PhysicsFactory.create(world, player)
    body:setFixedRotation(true)
    fixture:setFriction(0)

    local floor = world:createEntity()
    world:addComponent(floor, C.Transform, { x = 160, y = 164 })
    world:addComponent(floor, C.RigidBody, { type = "static" })
    world:addComponent(floor, C.Collider, { shape = "rectangle", width = 300, height = 16 })
    PhysicsFactory.create(world, floor)

    local input = self.context.inputManager
    local ControlSystem = {}
    function ControlSystem.update(w, dt)
        w:query({ C.Velocity, C.RigidBody }, function(entity, components)
            if entity == player then
                local x = 0
                if input:isDown("move_left") then x = x - 1 end
                if input:isDown("move_right") then x = x + 1 end
                components.Velocity.x = x * 100
            end
        end)
    end

    world:addSystem(ControlSystem)
    world:addSystem(PhysicsMovement)
    world:addSystem(PhysicsSystem)
    world:addSystem(PhysicsSync)
    world:addSystem(CollisionSystem)
    world:onCollisionStarted(player, function(other, collision)
        print("collision_started", player, other)
        if collision.normal then
            print("normal", collision.normal.x, collision.normal.y)
        end
    end)
end

function Tutorial:update(dt)
    self.world:update(dt)
end

function Tutorial:draw()
    PhysicsDebug.draw(self.world)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Move: left / right", 8, 8)
end

function Tutorial:onDestroy()
    self.world.physics:destroy()
end

return Tutorial
```

`createEntity` devuelve un ID numérico. Los componentes son tablas indexadas por ese ID y nombradas mediante `C`; `query` pasa una tabla indexada por nombre de componente, pero el orden de recorrido de las entidades no está especificado. Un sistema es una tabla con funciones normales como `update(world, dt)`, no métodos con dos puntos. `addSystem` llama inmediatamente a su `init(world)` opcional. `PhysicsFactory.create` crea explícitamente el cuerpo y la fixture y asocia los datos de usuario de la fixture con la entidad; los componentes por sí solos no los crean. Tanto el jugador como el suelo necesitan colliders.

## 2. Seguir el orden del frame

`World:update(dt)` ejecuta los sistemas **en orden de inserción**, después despacha eventos y finalmente aplica las destrucciones pendientes de entidades:

1. `ControlSystem` establece la velocidad horizontal deseada.
2. `PhysicsMovement` envía los comandos `Velocity` modificados a cuerpos no estáticos. Envía ambos ejes cuando cambia cualquiera de ellos; los comandos sin cambios no se reenvían, permitiendo que la gravedad y las colisiones afecten al cuerpo. `Velocity` es un comando, no la velocidad física actual.
3. `PhysicsSystem` avanza el mundo físico de LÖVE en pasos acumulados de `1/60` de segundo, sin límite de pasos. Un frame más corto que un paso puede no ejecutar ningún paso físico.
4. `PhysicsSync` copia la posición y el ángulo del cuerpo a `Transform`. Usa el cuerpo para recolocar entidades físicas; si solo cambias `Transform`, la sincronización lo sobrescribirá.
5. `CollisionSystem` encola los eventos de contacto producidos por el paso. Al registrarse instala y reemplaza los callbacks de física. Los eventos contienen los ID de entidad de las fixtures; `collision_started` también incluye las velocidades de ambos cuerpos, los indicadores de sensor y, si ninguna fixture es sensor, la normal de la fixture A hacia la B. Los eventos se despachan después de todos los sistemas.

Para entidades sin física, registra `engine.ecs.systems.movementSystem`: integra `Transform` y `Velocity` con `dt` y omite entidades con `RigidBody`. Para sprites, registra la animación si es necesario y usa `RenderSystem.draw` o envía sprites junto con tiles a través de un pipeline; ni los sistemas de renderizado ni los de física se registran automáticamente. Consulta la [arquitectura de renderizado](/es/architecture/modules/rendering).

## 3. Callbacks de colisión por entidad

`world:onCollisionStarted(entity, callback)` y `world:onCollisionEnded(entity, callback)` escuchan solo los contactos que implican a esa entidad. El callback recibe `(otherEntity, collision)` y se omite si alguna de las dos entidades se ha destruido o está marcada para borrado. Cada llamada devuelve una función de desuscripción:

```lua
local stop = world:onCollisionStarted(player, function(other, collision)
    print("contact with", other)
    if collision.normal then
        print("normal", collision.normal.x, collision.normal.y)
    end
    print("relative velocity", collision.relativeVelocity.x, collision.relativeVelocity.y)
end)

-- Cuando el listener ya no sea necesario:
stop()
```

`collision.normal`, `selfVelocity`, `otherVelocity` y `relativeVelocity` son tablas `{ x, y }` relativas a la entidad registrada: `relativeVelocity` es `otherVelocity - selfVelocity`, y la normal se invierte para la segunda fixture de modo que apunte desde la entidad registrada hacia la otra. La normal es `nil` en contactos con sensores y los cuatro campos valen `nil` en `collision_ended`. Los listeners directos de `world.events` siguen disponibles; consulta [eventos](/es/api/events) y [física](/es/api/physics).

## 4. Destrucción y limitaciones

`world:destroyEntity(id)` difiere la eliminación hasta después de los sistemas y el despacho de eventos, por lo que la entidad aún puede aparecer en consultas durante esa actualización. Al aplicar la eliminación también se destruye su `RigidBody.body`; quitar el componente directamente no lo destruye. Este ejemplo destruye el mundo físico de LÖVE que le pertenece cuando se destruye la escena; no existe un método auxiliar `World:destroy()`. Los colliders de la factory solo son rectángulos de dimensiones positivas. `World.new` establece la escala global de física de LÖVE en 64 píxeles por metro.

Consulta la [arquitectura de World](/es/architecture/modules/world), las API de [World](/es/api/world) y [renderizado](/es/api/rendering), y los tutoriales de [Tiled](/es/guides/tiled) y [cámaras](/es/guides/cameras).
