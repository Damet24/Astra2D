# Moverse con acciones y detectar eventos de teclas

## Objetivo y requisitos

Mueve un marcador con dos teclas y cuenta pulsaciones y liberaciones. Parte de [Tu primer proyecto](/es/getting-started/first-project), incluidos su directorio `engine/` y los callbacks de LÖVE. No se necesitan recursos personalizados.

## 1. Asignar teclas a las acciones

Añade estas entradas a la tabla de `game/inputMaps.lua`, conservando las demás acciones:

```lua
guide_left = { "left", "a" },
guide_right = { "right", "d" },
guide_count = { "space" },
```

Son entradas de tabla. Asegúrate de que `Engine.new` reciba `inputMaps = require("game.inputMaps")` y establece `initialScene = "guideInput"`. En `main.lua`, mantén los callbacks del primer proyecto, especialmente:

```lua
function love.keypressed(key)
    engine:keypressed(key)
end

function love.keyreleased(key)
    engine:keyreleased(key)
end
```

## 2. Crear la escena de entrada

Crea `game/scenes/guideInput.lua`:

```lua
local Scene = require("engine.scene.scene")
local InputScene = {}
InputScene.__index = InputScene
setmetatable(InputScene, { __index = Scene })

function InputScene.new(context)
    local self = setmetatable(Scene.new(), InputScene)
    self.context = context
    self.x = 160
    self.presses = 0
    self.releases = 0
    return self
end

function InputScene:update(dt)
    local input = self.context.inputManager
    local direction = 0
    if input:isDown("guide_left") then direction = direction - 1 end
    if input:isDown("guide_right") then direction = direction + 1 end
    self.x = math.max(0, math.min(304, self.x + direction * 100 * dt))
    if input:isJustPressed("guide_count") then self.presses = self.presses + 1 end
    if input:isJustReleased("guide_count") then self.releases = self.releases + 1 end
end

function InputScene:draw()
    love.graphics.print("Arrows/A/D: move; Space: count", 8, 8)
    love.graphics.print("Presses: " .. self.presses .. " Releases: " .. self.releases, 8, 28)
    love.graphics.rectangle("fill", self.x, 70, 16, 16)
end

return InputScene
```

## 3. Ejecutar y observar

Ejecuta `love .` desde la raíz del proyecto. Mantén pulsada Izquierda/A o Derecha/D para moverte; pulsa y suelta Espacio para actualizar los dos contadores. Las direcciones opuestas se cancelan. Los límites suponen la anchura lógica de 320 píxeles del primer proyecto; adáptalos si usas otra resolución. `game/inputMaps.lua` y `game/ecs/systems/playerSystem.lua` del juego de ejemplo también asignan y consultan acciones.

## Ciclo de vida por frame y eventos de teclas

LÖVE envía eventos de teclado al motor. Durante `Engine:update(dt)`, las escenas leen el estado actual; después de las transiciones de escena y del update de audio, el motor borra los eventos transitorios. `isDown` permanece en `true` mientras se mantenga cualquier tecla asignada; `isJustPressed` e `isJustReleased` describen eventos de tecla desde el último update de input. Las consultas no los consumen. No limpies el input manualmente antes de actualizar las escenas.

Los eventos se registran por tecla y se combinan con OR: soltar una tecla asignada puede indicar una liberación mientras otra sigue pulsada. Pulsar y soltar entre updates puede hacer que ambas consultas de eventos sean verdaderas. Los eventos de pulsación repetidos mientras se mantiene la tecla no crean nuevos eventos de pulsación.

## Errores y limitaciones

- `inputMaps` es obligatorio, aunque esté vacío. Cada acción necesita un array contiguo no vacío de cadenas de teclas únicas y no vacías; las tablas incorrectas fallan al construir el gestor. Los nombres de acción desconocidos devuelven `false`, y las cadenas de teclas no se validan contra la lista de LÖVE.
- Solo se gestionan callbacks de teclado; cadenas que parecen botones de gamepad no añaden soporte para gamepad. Los callbacks imprimen actualmente las teclas en la consola.
- El estado de tecla pulsada no se borra automáticamente al perder el foco. El gestor conserva la tabla de asignaciones proporcionada en lugar de copiarla.

## Más información

[Arquitectura de InputManager](/es/architecture/modules/input-manager) · [Arquitectura de Engine](/es/architecture/modules/engine) · [API de InputManager](/es/api/input-manager).
