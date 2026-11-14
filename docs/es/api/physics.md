# Física

El motor proporciona un constructor y una fábrica de rectángulos, no una API propia de objetos físicos. `world.physics` es un [World de LÖVE](https://love2d.org/wiki/World) nativo; los cuerpos y fixtures devueltos por la fábrica son objetos nativos [Body](https://love2d.org/wiki/Body) y [Fixture](https://love2d.org/wiki/Fixture). Sus métodos, callbacks, restricciones y errores son de LÖVE, no envoltorios del motor.

## Construcción y fábrica

- `PhysicsWorld.new(gravityX, gravityY, sleeping)` de `require("engine.physics.physics_world")` llama a `love.physics.setMeter(PhysicsWorld.PIXELS_PER_METER)` (64, global) y devuelve `love.physics.newWorld(gravityX or 0, gravityY or 0, sleeping or false)`. `World.new` lo invoca. Establece la escala antes de crear cuerpos; la API de LÖVE usa píxeles, así que no dividas las posiciones por 64.
- `PhysicsFactory.create(world, entity)` de `require("engine.physics.physics_factory")` devuelve `body, fixture`. Requiere `Transform`, `RigidBody` y `Collider`, y verifica que no exista `RigidBody.body`, que `Collider.shape == "rectangle"` y que `width` y `height` sean positivos. La ausencia de componentes, cuerpo duplicado, forma no admitida o dimensiones inválidas producen aserciones; también pueden propagarse tipos incompatibles y errores de LÖVE.

`Transform.x`, `y` indican la posición del cuerpo; `rotation` vale 0 radianes por defecto. `RigidBody.type` vale `"dynamic"` por defecto (LÖVE también admite `"static"` y `"kinematic"`). `Collider.offsetX`/`offsetY` valen 0, `density` vale 1 y `sensor` vale false por defecto. La fábrica crea un rectángulo centrado con esos desplazamientos locales, establece el ID de entidad como datos de usuario del fixture y guarda el cuerpo en `RigidBody.body`. Añadir componentes por sí solo no lo crea.

## Sistemas y contactos

Los sistemas son opcionales. Un orden habitual de registro es `movementSystem`, `physicsMovementSystem`, `physicsSystem`, `physicsSyncSystem`, `collisionSystem`. El primero integra entidades sin cuerpo rígido. Physics movement aplica `Velocity.x/y` a cuerpos no estáticos solo cuando cambia la orden efectiva, limitada opcionalmente por `Movement.maxSpeed`; la gravedad y los contactos pueden modificar después la velocidad física. La física avanza en pasos fijos de 1/60 s con un acumulador, sin límite de pasos ni interpolación. Sync copia la posición y el ángulo del cuerpo a `Transform`.

`CollisionSystem.init` reemplaza los callbacks del mundo LÖVE por callbacks de inicio/fin, que recogen los datos de usuario de los fixtures. Su actualización encola `collision_started` y `collision_ended` con `{ entityA, entityB }`; regístralo después del paso físico para procesar los contactos de esa actualización. Los IDs pueden ser `nil` si un fixture no tiene datos de usuario. No se conserva el `Contact`. World despacha eventos después de los sistemas y luego destruye las entidades pendientes y sus cuerpos actuales. Los contactos producidos durante la destrucción se procesan en una actualización posterior. Quitar `RigidBody` por separado no destruye su cuerpo.

## Ejemplo

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local Factory = require("engine.physics.physics_factory")
local world = World.new(0, 640, true)
world:addSystem(require("engine.ecs.systems.physicsSystem"))
world:addSystem(require("engine.ecs.systems.physicsSyncSystem"))
world:addSystem(require("engine.ecs.systems.collisionSystem"))
world.events:on("collision_started", function(contact)
    print(contact.entityA, contact.entityB)
end)
local id = world:createEntity()
world:addComponent(id, C.Transform, { x = 100, y = 100 })
world:addComponent(id, C.RigidBody, { type = "dynamic" })
world:addComponent(id, C.Collider, { shape = "rectangle", width = 32, height = 32 })
local body, fixture = Factory.create(world, id)
body:setFixedRotation(true) -- método Body de LÖVE
world:update(1 / 60)
```

`PhysicsDebugSystem.draw(world)` dibuja contornos de fixtures poligonales y circulares con gráficos de LÖVE. Consulta la [guía de ECS y física](../guides/ecs.md), la [arquitectura de World](../architecture/modules/world.md), [eventos](events.md) y [física de LÖVE](https://love2d.org/wiki/love.physics).
