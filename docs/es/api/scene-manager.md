# API de SceneManager

Módulo: `require("engine.scene.sceneManager")`. Gestiona una pila de entradas `{ id, scene }` mediante un cargador. Consulta la [arquitectura](../architecture/modules/scene-manager.md), la [guía de escenas](../guides/scenes.md) y [tu primer proyecto](../getting-started/first-project.md).

## Construcción y dependencias

`SceneManager.new(sceneLoader)` devuelve un gestor vacío; exige que `sceneLoader` sea verdadero. El gestor llama a `loader:load(sceneId, dependencies)` sobre la instancia del cargador; este método debe devolver una escena con los callbacks de [Scene](scene.md). Los errores de carga y de callbacks se propagan.

En los métodos de transición, `sceneId` identifica la escena para el cargador y `dependencies` es una tabla opcional. Al encolar se fusiona superficialmente `{ manager = self }` con `dependencies`, cuyas claves prevalecen. El [cargador integrado](scene-loader.md) ignora esta tabla; uno personalizado puede usarla.

## Métodos

Todos los métodos de instancia siguientes **no devuelven valores**. `push`, `pop`, `replace`, `clear` y `clearAndPush` solo encolan operaciones; no modifican la pila inmediatamente.

| Firma | Efecto |
| --- | --- |
| `manager:push(sceneId, dependencies)` | Encola un apilado. |
| `manager:pop()` | Encola una extracción; procesarla con pila vacía no hace nada. |
| `manager:replace(sceneId, dependencies)` | Encola el reemplazo de la cima; funciona con pila vacía. |
| `manager:clear()` | Encola la eliminación de todas las escenas. |
| `manager:clearAndPush(sceneId, dependencies)` | Encola el reemplazo de toda la pila. |
| `manager:processPendingOperations()` | Separa y procesa un lote en orden de inserción. Las operaciones encoladas durante los callbacks esperan otra llamada. |
| `manager:update(dt)` | Actualiza las escenas seleccionadas de abajo arriba con los segundos transcurridos `dt`, y procesa un lote. |
| `manager:draw()` | Dibuja las escenas seleccionadas de abajo arriba; no procesa la cola. |
| `manager:applyPush(sceneId, dependencies)` | Carga y apila inmediatamente; pasa `dependencies` directamente al cargador. |
| `manager:applyPop()` | Extrae inmediatamente, o no hace nada si la pila está vacía. |
| `manager:applyReplace(sceneId, dependencies)` | Carga y reemplaza la cima inmediatamente. |
| `manager:applyClear()` | Vacía la pila inmediatamente. |
| `manager:applyClearAndPush(sceneId, dependencies)` | Carga y reemplaza toda la pila inmediatamente. |

Los métodos `apply*` son operaciones de implementación expuestas; a diferencia de las solicitudes encoladas, no fusionan dependencias ni difieren la mutación. Llamarlos, o procesar manualmente, durante un callback de escena puede modificar la pila a mitad del recorrido.

## Ciclo de vida y cola

| Operación | Orden exacto |
| --- | --- |
| Push | Construir nueva, `onLoad` de la nueva, `onExit` de la cima anterior si existe, insertar nueva, `onEnter` de la nueva. |
| Pop | `onExit` de la cima, extraer, `onDestroy` de la cima, `onEnter` de la anterior si existe. |
| Replace | Construir nueva, `onLoad` de la nueva, `onExit`, extracción y `onDestroy` de la cima anterior si existe, insertar nueva, `onEnter` de la nueva. |
| Clear | Separar pila, `onExit` de la cima si existe, todos los `onDestroy` de arriba abajo. |
| Clear and push | Construir nueva, `onLoad` de la nueva, todos los `onExit` anteriores de arriba abajo, todos los `onDestroy` anteriores de arriba abajo, reemplazar pila, `onEnter` de la nueva. |

Clear-and-push vuelve a llamar a `onExit` en escenas cubiertas, a diferencia de clear. Load y quit procesan explícitamente un lote; draw nunca lo hace. Los errores no se revierten: un lote fallido puede perder sus operaciones restantes, dejar la pila parcialmente modificada e impedir la limpieza posterior.

En update/draw se desciende desde la cima mientras cada escena tenga `updateBelow`/`drawBelow`, respectivamente, verdadero; después se recorre el intervalo seleccionado de abajo arriba. Las opciones son independientes y valen false por defecto en `Scene.new()`.

## Ejemplo

```lua
-- En una escena con el mapa de entrada del repositorio:
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

Normalmente el apilado se aplica después del update de la escena actual, no en el lugar de la llamada.
