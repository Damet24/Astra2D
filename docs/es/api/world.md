# World y ECS

`require("engine.ecs.world")` proporciona un contenedor ECS. `World.new(xg, yg, slepp)` devuelve un mundo independiente con `events` y un mundo de física de LÖVE en `physics`. El tercer parámetro se escribe `slepp` en el código; la gravedad predeterminada es `(0, 0)` y el reposo es `false`. La construcción necesita `love.physics` y establece su escala global en 64 píxeles por metro. No registra sistemas automáticamente. Los contactos están disponibles como eventos encolados y mediante los auxiliares por entidad descritos abajo. Consulta [física](physics.md) y [eventos](events.md).

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
| `query2(compA, compB, callback)` | Atajo para exactamente dos componentes. Consulta directamente ambos almacenes; si falta alguno, no hace nada. Para cada entidad presente en los dos llama a `callback(entity, a, b)` con las propias tablas de componente. No tiene modo "todas las entidades", no construye una tabla indexada y no valida el callback. |
| `onCollisionStarted(entity, callback)` | Registra un callback para inicios de contacto que impliquen a la entidad; devuelve una función de desuscripción. Consulta [callbacks de colisión](#callbacks-de-colision). |
| `onCollisionEnded(entity, callback)` | Registra un callback para fines de contacto que impliquen a la entidad; devuelve una función de desuscripción. |

## Sistemas y ciclo de vida

`addSystem(system)` añade una tabla y llama inmediatamente a `system.init(world)` si existe. `update(dt)` llama a cada `system.update(world, dt)` en orden de registro, despacha eventos y después llama a `flushDestroy()`. `draw()` llama a cada `system.draw(world)` en orden de registro. Son funciones normales, no métodos con dos puntos. No hay validación de esquema ni protección de errores de callbacks; un error interrumpe la operación.

Los sistemas incluidos son `movementSystem`, `physicsMovementSystem`, `physicsSystem`, `physicsSyncSystem`, `collisionSystem`, `animationSystem`, `renderSystem` y `physicsDebugSystem`. `damageSystem.update` está vacío actualmente. Movement integra `Transform` y `Velocity` para entidades sin `RigidBody`; los sistemas físicos y su orden se detallan en [física](physics.md). Animation usa `Sprite.animations[Animation.current]`, `Animation.frame`, `timer`, `playing` y `loop`; durante la reproducción, el `frameDuration` de la animación seleccionada debe ser un número positivo. Consulta [renderizado](rendering.md) para los campos de sprite.

## Callbacks de colisión

`onCollisionStarted(entity, callback)` y `onCollisionEnded(entity, callback)` registran un listener solo para los contactos que implican a una entidad viva concreta. Validan con `Invalid entity` un ID desconocido o ya eliminado y con `callback must be a function` un callback que no sea función. El callback se llama como `callback(otherEntity, collision)` cuando se despachan los eventos; se omiten los contactos si alguna de las dos entidades no existe o está pendiente de borrado. Ambos métodos devuelven una función de desuscripción: al llamarla, el listener se desactiva de inmediato y se encola su eliminación de `world.events`. Esa eliminación se aplica en el siguiente vaciado del gestor de eventos, que ocurre al final de cada despacho.

La tabla `collision` está expresada respecto a la entidad registrada:

| Campo | Significado |
| --- | --- |
| `normal` | Normal de contacto `{ x, y }` en eventos `collision_started` sin sensores; apunta desde la fixture de la entidad registrada hacia la otra fixture. Vale `nil` en contactos con sensores. |
| `selfVelocity` | Velocidad lineal `{ x, y }` del cuerpo de la entidad registrada al comenzar el contacto. |
| `otherVelocity` | Velocidad lineal `{ x, y }` del otro cuerpo al comenzar el contacto. |
| `relativeVelocity` | `{ x, y }` igual a `otherVelocity - selfVelocity`. |

Los cuatro campos valen `nil` en `collision_ended`. Registra `collisionSystem` para que se produzcan estos eventos; [física](physics.md) documenta los datos de los eventos directos.

```lua
local stop = world:onCollisionStarted(id, function(other, collision)
    if collision.normal then
        print("hit", other, collision.normal.x, collision.normal.y)
    end
end)

-- Más tarde, cuando el listener ya no sea necesario:
stop()
```

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
