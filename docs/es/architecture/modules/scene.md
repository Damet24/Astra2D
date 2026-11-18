# Scene

`engine/scene/scene.lua` define la interfaz mínima de una parte del juego: menú, nivel, capa de pausa u otro estado gestionado de forma independiente. La escena coordina su comportamiento y los recursos que decida crear; no necesita `World`, cámara ni pipeline de renderizado. Por ejemplo, `game/scenes/pause.lua` dibuja una capa en espacio lógico sin ninguno de ellos, mientras que `game/scenes/levels/level.lua` crea los tres.

## Construcción y hooks públicos

- `Scene.new()` devuelve una instancia con `updateBelow = false` y `drawBelow = false`. No guarda el contexto ni reserva otros servicios.
- Sobrescribe `onLoad()`, `onEnter()`, `onExit()` y `onDestroy()` para gestionar el ciclo de vida; las implementaciones base no hacen nada.
- Sobrescribe `update(dt)` y `draw()` para el comportamiento por frame; las implementaciones base no hacen nada. `dt` es el tiempo transcurrido del frame en segundos proporcionado por LÖVE.
- El loader llama a `new(context)` del módulo de escena. Una subclase debe guardar `context` por su cuenta si lo necesita. El contexto proporciona servicios compartidos como `sceneManager`, `resourceManager`, `audioManager`, `inputManager` y, una vez cargado el motor, `viewport`.

Una capa mínima, sin mundo ni cámara:

```lua
local Scene = require("engine.scene.scene")
local Overlay = {}
Overlay.__index = Overlay
setmetatable(Overlay, { __index = Scene })

function Overlay.new(context)
    local self = setmetatable(Scene.new(), Overlay)
    self.context = context
    self.drawBelow = true
    return self
end

function Overlay:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop()
    end
end

function Overlay:draw()
    love.graphics.print("Paused", 10, 10)
end

return Overlay
```

Coloca el módulo bajo el `scenesPath` configurado y apila su identificador. Con `drawBelow = true` y el `updateBelow = false` por defecto, las escenas inferiores pueden dibujarse pero no se actualizan. Los flags son independientes: el gestor recorre la pila desde arriba hasta encontrar un flag falso y después actualiza o dibuja el rango seleccionado de abajo arriba. El flag de cada escena inferior decide si el recorrido continúa por debajo de ella.

## Ciclo de vida y relaciones

`SceneLoader` resuelve `scenesPath .. "." .. sceneName` (prefijo por defecto `game.scenes`), carga con `require` una tabla con función `.new` y llama a `new(context)`. `SceneManager` posee la pila; las escenas solicitan `push`, `pop`, `replace`, `clear` o `clearAndPush` mediante `context.sceneManager`. Las solicitudes se encolan y no se aplican inmediatamente: normalmente se procesan después de actualizar las escenas; la carga y el cierre del motor las procesan explícitamente. Las operaciones encoladas durante el procesamiento esperan a otra pasada. Aunque las transiciones aceptan una tabla `dependencies`, el loader actual la ignora.

Para pilas no vacías, el orden de callbacks es:

| Operación | Orden |
| --- | --- |
| `push` | `onLoad` de la nueva; `onExit` de la anterior superior; `onEnter` de la nueva. |
| `pop` | `onExit` y después `onDestroy` de la superior; `onEnter` de la escena descubierta. |
| `replace` | `onLoad` de la nueva; `onExit` y `onDestroy` de la antigua superior; `onEnter` de la nueva. |
| `clear` | `onExit` de la superior; `onDestroy` de todas las escenas, de arriba abajo. |
| `clearAndPush` | `onLoad` de la nueva; `onExit` de todas las antiguas y después `onDestroy` de todas, en ambos casos de arriba abajo; `onEnter` de la nueva. |

Un `pop` sobre una pila vacía no hace nada. `onEnter` y `onExit` pueden ejecutarse de nuevo al cubrir o descubrir una escena; en particular, `clearAndPush` llama a `onExit` incluso en escenas que ya estaban cubiertas. Los callbacks no forman una transacción protegida: un error puede interrumpir la secuencia y la limpieza. Una escena que adquiere recursos debe liberarlos en `onDestroy`, por ejemplo con `context.resourceManager:releaseAll(self)`; la clase base no limpia automáticamente mundos, cámaras ni recursos.

Durante un frame del motor, el motor despacha los eventos encolados, resuelve los flancos de los ejes del mando, actualiza el gestor de escenas, actualiza el audio y, por último, limpia el estado transitorio de entrada y el delta del ratón. El dibujo ocurre dentro del viewport de resolución lógica del motor. Consulta [World](world.md), [Gestor de cámaras](camera-manager.md) y [Renderizado](rendering.md) para conocer los componentes opcionales que puede poseer una escena.
