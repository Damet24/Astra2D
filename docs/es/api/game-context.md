# API de GameContext

Módulo: `require("engine.core.gameContext")`. Contenedor mutable de servicios compartido por las escenas; no gestiona su ciclo de vida. Consulta la [arquitectura](../architecture/modules/game-context.md) y [tu primer proyecto](../getting-started/first-project.md).

## Construcción y campos

`GameContext.new(services)` devuelve un contexto. `services` debe ser verdadero y proporcionar `resourceManager` y `audioManager` verdaderos; los valores ausentes provocan aserciones. Copia el `sceneManager` opcional; no valida las interfaces ni copia otros campos. Es el único método.

| Campo | Disponibilidad y dependencia |
| --- | --- |
| `resourceManager` | Obligatorio al construir; [ResourceManager](resource-manager.md) compartido. |
| `audioManager` | Obligatorio al construir; [AudioManager](audio-manager.md) compartido. |
| `sceneManager` | Opcional al construir; [Engine](engine.md) lo asigna después de crear el cargador y el gestor. |
| `inputManager` | Lo asigna `Engine.new`, no este constructor. |
| `viewport` | Lo asigna `Engine:load()` antes de construir la escena inicial. |

El [SceneLoader](scene-loader.md) integrado pasa la misma referencia al contexto a cada constructor de escena. Los contextos construidos manualmente no reciben entrada ni viewport automáticamente, aunque esas claves se incluyan en `services`. El contenedor no actualiza ni libera los servicios.

## Ejemplo

En una escena que guarda el `context` recibido por su constructor:

```lua
function MyScene:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

Esto libera el interés de la escena como consumidora; el contexto no lo hace automáticamente.
