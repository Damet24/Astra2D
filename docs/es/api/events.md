# Eventos

`require("engine.core.events")` implementa un gestor de eventos encolados. Cada [mundo](world.md) crea uno en `world.events`; [Engine](engine.md) crea otro y lo expone como `context.events`; `EventManager.new()` también devuelve un gestor independiente. Los métodos siguientes no devuelven valores ni validan explícitamente los tipos de argumentos.

## API

| Método | Parámetros y efecto |
| --- | --- |
| `on(eventName, callback)` | Añade un listener, llamado como `callback(data)`. Se permiten registros duplicados. |
| `emit(eventName, data)` | Encola un evento con nombre y datos arbitrarios (incluso `nil`); no invoca listeners inmediatamente. |
| `dispatch()` | Toma la cola actual, entrega eventos en orden de inserción y listeners en orden de registro, y después llama a `flush()`. Los eventos emitidos por listeners esperan a otro despacho. |
| `off(eventName, callback)` | Encola la eliminación del primer callback idéntico; ignora nombres o callbacks ausentes al vaciar. |
| `flush()` | Aplica inmediatamente las eliminaciones encoladas, en orden, sin despachar eventos. |

`off` no detiene un listener durante el despacho actual salvo que el llamador vacíe explícitamente la operación pendiente. `on` es inmediato. El despacho recorre la lista activa de listeners: añadir uno con `on` durante un callback puede ejecutarlo en el mismo despacho, y llamar a `flush` después de `off` puede desplazar la lista y omitir un listener posterior. Para una entrega predecible, difiere los registros y el vaciado explícito hasta que termine el despacho. `World:update(dt)` despacha tras actualizar todos los sistemas y antes de destruir las entidades pendientes. Los errores de callbacks se propagan e interrumpen el despacho; la cola actual ya se ha separado y no se llega al `flush()` final. El gestor genérico no ofrece desuscripción automática; los auxiliares de colisión de World descritos abajo sí devuelven una.

## Ejemplo

```lua
local Events = require("engine.core.events")
local events = Events.new()
local function listener(data) print(data.score) end
events:on("scored", listener)
events:emit("scored", { score = 10 })
events:dispatch()
events:off("scored", listener)
events:flush()
```

`CollisionSystem` emite `collision_started` y `collision_ended` con `{ entityA, entityB }`. Los eventos de inicio también contienen `normalX`/`normalY` (solo en contactos sin sensores), las velocidades de ambos cuerpos `velocityAX`/`velocityAY` y `velocityBX`/`velocityBY`, y los booleanos `sensorA`/`sensorB`; consulta [física](physics.md) para los datos completos. `World:onCollisionStarted` y `World:onCollisionEnded` envuelven estos eventos con callbacks por entidad y una función de desuscripción; consulta [world](world.md). Consulta también la [arquitectura de World](../architecture/modules/world.md) y la [guía de ECS](../guides/ecs.md).

`InputManager` emite `gamepad_connected` y `gamepad_disconnected` a través del gestor del motor cuando empieza o deja de seguir un mando. Ambos contienen `{ joystick, name }`, donde `name` es `joystick:getName()`. El motor despacha los eventos encolados al inicio del siguiente `Engine:update(dt)`, así que suscríbete con `context.events:on(...)`.
