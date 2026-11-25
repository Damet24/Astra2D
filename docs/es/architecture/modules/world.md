# World

`engine/ecs/world.lua` es un contenedor ECS con su propio gestor de eventos y mundo físico de LÖVE. Una escena puede crear y dirigir un mundo, pero ni `Scene` ni `SceneManager` lo crean automáticamente. Los mundos son instancias independientes y no conocen su escena. El nivel de `game/scenes/levels/level.lua` muestra una configuración posible.

## Construcción y API ECS

`World.new(xg, yg, slepp)` crea tablas vacías de entidades, componentes y sistemas, `world.events` y `world.physics`. El tercer parámetro se escribe `slepp` en el código y activa el reposo físico cuando es verdadero. La gravedad por defecto es `(0, 0)` y el reposo es falso. La construcción requiere `love.physics` y establece su escala global en 64 píxeles por metro. No se registra ningún sistema automáticamente.

- `createEntity()` devuelve un identificador numérico creciente, que comienza en 1 para cada mundo.
- `destroyEntity(entity)` marca una entidad existente para eliminarla más tarde; ignora identificadores desconocidos. `flushDestroy()` elimina las entidades marcadas y todos sus componentes y destruye su `RigidBody.body` si existe y no estaba destruido. Hasta el vaciado, las entidades marcadas siguen participando en las consultas. Eliminar un componente `RigidBody` por separado **no** destruye su cuerpo.
- `addComponent(entity, name, data)` requiere una entidad existente y guarda o sustituye `components[name][entity]` por `data` o `{}`. `getComponent(entity, name)` devuelve los datos o `nil`; `hasComponent` comprueba que no sea `nil`; `removeComponent` elimina la entrada. Los nombres están en `engine/ecs/component.lua`.
- `query(componentNames, callback)` visita las entidades con todos los componentes indicados y llama a `callback(entity, components)`, donde la segunda tabla usa los nombres como claves. El recorrido usa `pairs`, por lo que el orden de entidades no está garantizado. Una lista vacía selecciona todas las entidades.
- `query2(compA, compB, callback)` visita las entidades que tienen ambos componentes y llama a `callback(entity, a, b)` con las tablas de componente directamente. No hace nada si falta alguno de los dos almacenes; el orden tampoco está definido. `physicsSyncSystem` lo usa para `Transform` y `RigidBody`.
- `addSystem(system)` lo añade al final y llama inmediatamente a `system.init(world)` si existe. Los sistemas usan funciones normales, no métodos con dos puntos: `init(world)`, `update(world, dt)` y `draw(world)` son opcionales.
- `update(dt)` llama a los updates de los sistemas en orden de inserción, despacha eventos y después vacía las destrucciones diferidas. `draw()` llama a los dibujos en orden de inserción; no actualiza ni elimina entidades.

```lua
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local Movement = require("engine.ecs.systems.movementSystem")

local world = World.new(0, 0, false)
world:addSystem(Movement)
local entity = world:createEntity()
world:addComponent(entity, C.Transform, { x = 10, y = 20 })
world:addComponent(entity, C.Velocity, { x = 30, y = 0 })
world:update(0.5) -- x pasa a 25
world:destroyEntity(entity)
world:update(0)   -- los sistemas y eventos se ejecutan antes de eliminarla
```

## Sistemas, eventos y física

El orden importa; el mundo no deduce dependencias. El motor incluye:

- `MovementSystem`: integra `Transform` + `Velocity` con `dt`, con límite opcional `Movement.maxSpeed`; omite entidades con `RigidBody`.
- `PhysicsMovementSystem`: aplica `Velocity` a cuerpos no estáticos, con límite opcional `Movement.maxSpeed`, solo cuando cambia la velocidad solicitada. `PhysicsSystem` avanza la física en pasos fijos de 1/60 segundos con un acumulador; no limita el número de pasos. `PhysicsSyncSystem` copia la posición y el ángulo del cuerpo a `Transform`. Regístralos en ese orden si quieres ese comportamiento.
- `CollisionSystem.init` instala callbacks de física y encola contactos; su update emite `collision_started` y `collision_ended` a partir de los datos de usuario de las fixtures. Los eventos de inicio también incluyen las velocidades de ambos cuerpos, los indicadores de sensor y la normal de A hacia B cuando ninguna fixture es sensor; los de fin solo contienen `entityA` y `entityB`. Regístralo después del paso físico para procesar los contactos producidos en esa actualización. La instalación reemplaza callbacks físicos existentes.
- `AnimationSystem` avanza una `Animation` en reproducción usando la entrada seleccionada de `Sprite.animations`; `frameDuration` debe ser positivo. `RenderSystem` dibuja o envía sprites; `PhysicsDebugSystem` dibuja contornos de polígonos y círculos. `DamageSystem.update` está vacío actualmente.

`world.events:on(name, callback)` registra un listener; `emit(name, data)` encola un evento; `off(name, callback)` encola su eliminación. El despacho ocurre después de todos los updates de sistemas y antes de destruir entidades. Los eventos emitidos durante el despacho esperan al siguiente, y las eliminaciones encoladas se aplican después del despacho actual.

`World:onCollisionStarted(entity, callback)` y `World:onCollisionEnded(entity, callback)` envuelven los eventos de colisión para una entidad. Sus callbacks reciben `(otherEntity, collision)` y se omiten si alguna de las dos entidades ya no existe o está pendiente de borrado. La tabla `collision` expone `normal`, `selfVelocity`, `otherVelocity` y `relativeVelocity` (`otherVelocity - selfVelocity`), todo respecto a la entidad registrada y con valor `nil` en `collision_ended`; `normal` también es `nil` en contactos con sensores. Cada método devuelve una función que desactiva el listener y encola su eliminación de `world.events`.

`PhysicsFactory.create(world, entity)` requiere `Transform`, `RigidBody` y `Collider`, y que aún no exista un cuerpo. Crea un cuerpo y una fixture de LÖVE, guarda el cuerpo en `RigidBody.body` y asigna la entidad como dato de usuario de la fixture. Solo admite colliders rectangulares con `width` y `height` positivos; entre los campos opcionales están `offsetX`, `offsetY`, `density`, `sensor`, `layer` y `mask`. Los dos últimos son arrays de categorías 1-16 que usa `CollisionFilter.apply`: `layer` vale `{ 1 }` por defecto y `mask` no se aplica por defecto (colisiona con todo). Consulta [física](/es/api/physics). El tipo de cuerpo por defecto es `dynamic`. La factoría es explícita: añadir componentes por sí solo no crea el cuerpo. No hay un método `World:destroy()`; quien posea el mundo debe gestionar cualquier limpieza adicional de física o recursos que necesite.

Consulta [Scene](scene.md) para la propiedad y [Renderizado](rendering.md) para el envío y el orden de dibujo.
