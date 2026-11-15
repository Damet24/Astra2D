# World y ECS

`require("engine.ecs.world")` proporciona un contenedor ECS. `World.new(xg, yg, slepp)` devuelve un mundo independiente con `events` y un mundo de física de LÖVE en `physics`. El tercer parámetro se escribe `slepp` en el código; la gravedad predeterminada es `(0, 0)` y el reposo es `false`. La construcción necesita `love.physics` y establece su escala global en 64 píxeles por metro. No registra sistemas automáticamente. Consulta [física](physics.md) y [eventos](events.md).

## Entidades y componentes

Salvo donde se indique un retorno, los métodos no devuelven valores. Los nombres de componente son claves, normalmente las cadenas exportadas por `require("engine.ecs.component")`: `Transform`, `Velocity`, `Movement`, `Health`, `Damage`, `Sprite`, `PendingDamage`, `RigidBody`, `Collider`, `Animation`, `Input`, `Actions`. El módulo solo define nombres, no esquemas ni constructores; los sistemas interpretan los datos almacenados.

| Método | Parámetros, retorno y efecto |
| --- | --- |
| `createEntity()` | Devuelve un ID numérico nuevo, que comienza en 1 por mundo y aumenta de forma monotónica. |
| `destroyEntity(entity)` | Marca un ID existente para borrado; ignora IDs desconocidos. Sigue apareciendo en consultas hasta el vaciado. |
| `flushDestroy()` | Elimina las entidades marcadas y todos sus componentes; destruye su `RigidBody.body` actual si existe y no está destruido. Vacía el conjunto pendiente. |
| `addComponent(entity, name, data)` | Guarda o reemplaza los datos bajo el nombre; si `data` es `nil` o `false`, guarda `{}`. Falla con `Invalid entity` si el ID no está vivo. |
| `getComponent(entity, name)` | Devuelve los datos almacenados o `nil`; no valida la entidad. |
| `hasComponent(entity, name)` | Devuelve si el valor almacenado no es `nil`. |
| `removeComponent(entity, name)` | Elimina la entrada si existe; quitar `RigidBody` no destruye su cuerpo. |
| `query(componentNames, callback)` | Recorre los IDs vivos que coinciden con todos los nombres del array y llama a `callback(entity, components)`, con componentes indexados por nombre. Un array vacío coincide con todos; el orden no está definido (`pairs`). La coincidencia usa veracidad, no solo ausencia de `nil`. |

## Sistemas y ciclo de vida

`addSystem(system)` añade una tabla y llama inmediatamente a `system.init(world)` si existe. `update(dt)` llama a cada `system.update(world, dt)` en orden de registro, despacha eventos y después llama a `flushDestroy()`. `draw()` llama a cada `system.draw(world)` en orden de registro. Son funciones normales, no métodos con dos puntos. No hay validación de esquema ni protección de errores de callbacks; un error interrumpe la operación.

Los sistemas incluidos son `movementSystem`, `physicsMovementSystem`, `physicsSystem`, `physicsSyncSystem`, `collisionSystem`, `animationSystem`, `renderSystem` y `physicsDebugSystem`. `damageSystem.update` está vacío actualmente. Movement integra `Transform` y `Velocity` para entidades sin `RigidBody`; los sistemas físicos y su orden se detallan en [física](physics.md). Animation usa `Sprite.animations[Animation.current]`, `Animation.frame`, `timer`, `playing` y `loop`; durante la reproducción, el `frameDuration` de la animación seleccionada debe ser un número positivo. Consulta [renderizado](rendering.md) para los campos de sprite.

## Ejemplo

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local world = World.new(0, 0, false)
world:addSystem(require("engine.ecs.systems.movementSystem"))
local id = world:createEntity()
world:addComponent(id, C.Transform, { x = 10, y = 20 })
world:addComponent(id, C.Velocity, { x = 30, y = 0 })
world:update(0.5) -- Transform.x vale 25
world:destroyEntity(id)
world:update(0)   -- los sistemas y eventos se ejecutan antes del borrado
```

No existe `World:destroy()`; el propietario gestiona las demás tareas de limpieza. Consulta la [arquitectura de World](../architecture/modules/world.md) y la [guía de ECS](../guides/ecs.md).
