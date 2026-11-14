# SceneManager

`engine/scene/sceneManager.lua` administra una pila de entradas `{ id, scene }`, los callbacks del ciclo de vida y la selección de escenas para actualizar y dibujar. Delega la construcción a [SceneLoader](scene-loader.md); las escenas normalmente solicitan transiciones mediante `context.sceneManager`. Consulta la [descripción general de la arquitectura](../overview.md) y [GameContext](game-context.md).

## Operaciones públicas

`SceneManager.new(sceneLoader)` requiere un loader verdadero en Lua que exponga `load(sceneId, dependencies)`. El gestor empieza con la pila y la cola vacías.

| Método | Efecto al procesarse |
| --- | --- |
| `push(sceneId, dependencies)` | Carga una escena nueva y la coloca encima, conservando la anterior. |
| `pop()` | Retira y destruye la escena superior; vuelve a entrar en la de debajo. No hace nada si la pila está vacía. |
| `replace(sceneId, dependencies)` | Carga una escena nueva y reemplaza la superior; también funciona con la pila vacía. |
| `clear()` | Vacía la pila y destruye sus escenas. |
| `clearAndPush(sceneId, dependencies)` | Carga una escena nueva, retira todas las existentes y entra en la nueva. |
| `update(dt)` | Actualiza las escenas seleccionadas de abajo hacia arriba y luego procesa un lote pendiente. |
| `draw()` | Dibuja las escenas seleccionadas de abajo hacia arriba; **no** procesa la cola. |
| `processPendingOperations()` | Procesa explícitamente el lote pendiente actual. `Engine:load()` y `Engine:quit()` también lo llaman. |

Los cinco métodos de transición **solo encolan** solicitudes. Las operaciones se aplican en orden de inserción. El procesamiento separa primero la cola actual: las solicitudes hechas por callbacks del ciclo de vida durante ese lote van a una cola nueva para una llamada de procesamiento posterior, no al lote actual. Esto también se aplica al apagado; `Engine:quit()` no vacía repetidamente esa cola nueva. Llamar a `processPendingOperations` manualmente puede cambiar la pila en ese momento, por lo que conviene evitarlo desde un callback de escena en ejecución.

Para `push`, `replace` y `clearAndPush`, el gestor combina superficialmente `{ manager = self }` con la tabla opcional `dependencies`, permitiendo que las claves suministradas la sobrescriban, y pasa el resultado al loader. El loader integrado **ignora** este argumento y llama al constructor solo con el contexto; no dependas de que esas dependencias lleguen a una escena. Un loader personalizado sí podría usarlas.

## Orden del ciclo de vida

| Operación | Orden |
| --- | --- |
| `push` | Construir escena nueva; `onLoad` de la nueva; `onExit` de la antigua superior si existe; insertar la nueva; `onEnter` de la nueva. |
| `pop` | `onExit` de la superior; retirarla; su `onDestroy`; `onEnter` de la superior anterior si existe. |
| `replace` | Construir escena nueva; `onLoad` de la nueva; `onExit` de la antigua superior, retirarla y ejecutar su `onDestroy` si existe; insertar la nueva; `onEnter` de la nueva. |
| `clear` | Separar toda la pila; `onExit` de la antigua superior si existe; `onDestroy` de cada escena antigua de arriba hacia abajo. |
| `clearAndPush` | Construir escena nueva; `onLoad` de la nueva; `onExit` de **todas** las escenas antiguas de arriba hacia abajo; `onDestroy` de todas ellas de arriba hacia abajo; reemplazar la pila; `onEnter` de la nueva. |

`clearAndPush` se diferencia de `clear`: incluso las escenas cubiertas reciben `onExit` de nuevo. `onLoad` se llama una vez por cada instancia construida normalmente; `onEnter`/`onExit` acompañan las transiciones de pila y `onDestroy` descarta la instancia. Los callbacks y la carga no están protegidos ni se revierten: un error puede interrumpir el lote, perder sus operaciones no procesadas, dejar la pila parcialmente modificada e impedir la limpieza posterior del motor.

## Política de actualización y dibujo

Para cada pasada el gestor empieza arriba y baja mientras `updateBelow` o `drawBelow`, respectivamente, de la escena actual sea verdadero en Lua. Después recorre el intervalo seleccionado de abajo hacia arriba. La [Scene](scene.md) base fija ambos flags a `false` en `Scene.new()`; actualización y dibujo son independientes. Una superposición con `drawBelow = true` y `updateBelow = false` muestra la escena inferior sin actualizarla. Una escena más profunda solo se incluye si todas las escenas que tiene encima lo permiten en esa pasada.

## Ejemplo: superposición de pausa

El archivo `game/scenes/pause.lua` del repositorio establece `drawBelow = true` y hereda `updateBelow = false`. Desde otra escena que guarda el contexto:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

La actualización actual termina antes de aplicar el `push`. La escena de pausa puede solicitar `self.context.sceneManager:pop()` para volver. Las solicitudes hechas durante `draw()` también esperan a una llamada de procesamiento posterior, normalmente la siguiente actualización. No esperes cambios inmediatos en la pila.
