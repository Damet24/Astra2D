# GameContext

`engine/core/gameContext.lua` es un pequeño contenedor compartido de servicios y la frontera mediante la que las escenas acceden a los servicios del motor. No construye, actualiza ni libera esos servicios. Consulta la [descripción general de la arquitectura](../overview.md).

## Responsabilidades y relaciones

[Engine](engine.md) crea el contexto con los gestores de recursos y audio. Después construye el [SceneLoader](scene-loader.md) con ese contexto, construye el [SceneManager](scene-manager.md) y añade al contexto los gestores de escenas y entrada. Durante `Engine:load()` añade el viewport antes de construir la primera escena. El loader pasa la **misma referencia de contexto** a cada constructor de escena de ese motor. Así no es necesario entregar el motor a una escena ni que esta cree servicios compartidos.

## Construcción pública y campos

`GameContext.new(services)` requiere un objeto `services` verdadero en Lua y valores verdaderos para `services.resourceManager` y `services.audioManager`; acepta `services.sceneManager` como opcional. Devuelve un contexto con esos tres campos. El constructor no copia otros campos de `services`, no valida las interfaces de los servicios ni ofrece otros métodos.

| Campo | Disponibilidad en el ciclo de vida normal del motor | Uso |
| --- | --- | --- |
| [`resourceManager`](resource-manager.md) | Obligatorio en la construcción | Adquirir recursos usando la escena como consumidor y liberarlos cuando ya no se necesiten. |
| [`audioManager`](audio-manager.md) | Obligatorio en la construcción | Reproducir y controlar audio compartido. |
| `sceneManager` | Opcional en la construcción; asignado por `Engine.new` | Solicitar transiciones diferidas. |
| [`inputManager`](input-manager.md) | Añadido por `Engine.new`, no por `GameContext.new` | Consultar acciones configuradas. |
| [`viewport`](rendering.md) | Añadido por `Engine:load()` | Acceder al viewport lógico de Shove y sus conversiones. |

Un contexto construido manualmente no recibe automáticamente `inputManager` ni `viewport`, aunque esas claves se pasen en `services`. Su propietario debe asignarlos. Como el objeto es compartido y mutable, los cambios son visibles para otras escenas; añadir o reemplazar servicios es una decisión arquitectónica, no una invitación a usarlo como localizador global de servicios.

## Ejemplo: acceso desde una escena

En una escena cuyo constructor guarda `context` en `self.context`, usa los servicios compartidos sin construirlos:

```lua
function MyScene:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop() -- diferido
    end
end

function MyScene:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

El ejemplo supone que `exit` está en `inputMaps` y que la escena se usa a sí misma como consumidor de recursos. Un `pop` no cambia la pila inmediatamente; consulta [SceneManager](scene-manager.md). El propio contexto no garantiza la limpieza ni impide acceder directamente a otros objetos.
