# Crear una superposición de pausa con escenas

## Objetivo y requisitos

Crea un contador en marcha y una superposición de pausa. Escape pausa y reanuda el contador, que permanece visible debajo. Parte de [Tu primer proyecto](/es/getting-started/first-project), incluidos sus callbacks de LÖVE y el directorio `engine/`. Este tutorial crea sus propias escenas y no necesita archivos de imagen ni audio.

## 1. Configurar la acción y la escena inicial

Añade `pause = { "escape" }` a la tabla de `game/inputMaps.lua`, conservando las demás acciones. En `main.lua`, establece `initialScene = "guideLevel"` en `Engine.new`; mantén `inputMaps = require("game.inputMaps")` y los callbacks existentes.

## 2. Crear la escena en marcha

Crea `game/scenes/guideLevel.lua`:

```lua
local Scene = require("engine.scene.scene")
local Level = {}
Level.__index = Level
setmetatable(Level, { __index = Scene })

function Level.new(context)
    local self = setmetatable(Scene.new(), Level)
    self.context = context
    self.elapsed = 0
    return self
end

function Level:update(dt)
    self.elapsed = self.elapsed + dt
    if self.context.inputManager:isJustPressed("pause") then
        self.context.sceneManager:push("guidePause")
    end
end

function Level:draw()
    love.graphics.print(string.format("Time: %.1f", self.elapsed), 16, 16)
    love.graphics.print("Escape: pause", 16, 40)
end

return Level
```

## 3. Crear la superposición y ejecutar

Crea `game/scenes/guidePause.lua`:

```lua
local Scene = require("engine.scene.scene")
local Pause = {}
Pause.__index = Pause
setmetatable(Pause, { __index = Scene })

function Pause.new(context)
    local self = setmetatable(Scene.new(), Pause)
    self.context = context
    self.drawBelow = true
    return self
end

function Pause:update(dt)
    if self.context.inputManager:isJustPressed("pause") then
        self.context.sceneManager:pop()
    end
end

function Pause:draw()
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 320, 180)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Paused - press Escape", 16, 80)
    love.graphics.pop()
end

return Pause
```

Ejecuta `love .` desde la raíz del proyecto. Con la resolución lógica de 320 × 180 del primer proyecto, la superposición cubre la pantalla; adapta el rectángulo a tu resolución. Pulsa y suelta Escape, observa cómo se detiene el contador y vuelve a pulsar Escape para reanudarlo. `game/scenes/pause.lua` del repositorio usa el mismo patrón, y `game/scenes/levels/level.lua` lo inserta en la pila.

## Ciclo de vida y transiciones

El `scenesPath` predeterminado es `game.scenes`, así que `guidePause` resuelve al módulo que acabas de crear. `push` carga la escena nueva y llama a su `onLoad`, después al `onExit` de la escena anterior y finalmente al `onEnter` de la nueva. `pop` llama a `onExit` y `onDestroy` de la escena superior y después a `onEnter` de la escena descubierta. Libera los recursos propios de la escena en `onDestroy`, no en `onExit`, porque una escena cubierta puede volver. La clase base `Scene` proporciona hooks vacíos.

Aquí `drawBelow = true` dibuja el contador debajo, mientras que el valor predeterminado `updateBelow = false` lo congela. Los indicadores funcionan independientemente y se evalúan descendiendo por la pila. `replace` descarta solo la escena superior; `clear` destruye toda la pila; `clearAndPush` la vacía e inicia una escena nueva.

## Errores y limitaciones

- Las transiciones se encolan: el update actual termina antes de aplicarlas. Las operaciones encoladas por hooks durante el procesamiento esperan a otra pasada. No esperes un cambio inmediato en la pila.
- Un módulo ausente o sin constructor `.new(context)` falla cuando se procesa la carga encolada. El cargador incorporado ignora el argumento opcional `dependencies` de la transición; usa `context` para servicios compartidos.
- `clearAndPush` llama a `onExit` incluso en escenas cubiertas; los hooks deben tolerar salidas repetidas. Los errores en el ciclo de vida no se revierten y pueden interrumpir la limpieza.
- Reenvía ambos callbacks de teclado y proporciona la asignación de la acción; de lo contrario, Escape no funcionará. La superposición pausa los updates de escenas, no el audio globalmente.

## Más información

[Arquitectura de SceneManager](/es/architecture/modules/scene-manager) · [Arquitectura de SceneLoader](/es/architecture/modules/scene-loader) · [Arquitectura de Scene](/es/architecture/modules/scene) · [API de SceneManager](/es/api/scene-manager).
