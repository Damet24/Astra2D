# Asignar acciones de teclado, ratón y mando

## Objetivo y requisitos

Mueve un marcador con teclas, clics de ratón o un mando, y cuenta pulsaciones y liberaciones. Parte de [Tu primer proyecto](/es/getting-started/first-project), incluido su directorio `engine/`. No se necesitan recursos personalizados. El motor instala los callbacks de entrada de LÖVE durante `Engine:load()`, así que `main.lua` solo reenvía `load`, `update`, `draw` y `quit`.

## 1. Asignar acciones a dispositivos

Añade estas entradas a la tabla de `game/inputMaps.lua`, conservando las demás acciones:

```lua
guide_left = {
    keys = { "left", "a" },
    gamepad = {
        "dpleft",
        axes = { leftx = -1 },
    },
},
guide_right = {
    keys = { "right", "d" },
    gamepad = {
        "dpright",
        axes = { leftx = 1 },
    },
},
guide_count = {
    keys = { "space" },
    mouse = { 1 },
    gamepad = { "a" },
},
```

Cada acción es una tabla con secciones opcionales `keys`, `mouse` y `gamepad`. `keys` contiene nombres de teclas de LÖVE, `mouse` contiene números de botón de LÖVE (`1` izquierdo, `2` derecho, `3` central) y `gamepad` contiene nombres de botón de mando de LÖVE y una tabla opcional `axes` que asigna un nombre de eje a `-1` o `1`. Asegúrate de que `Engine.new` reciba `inputMaps = require("game.inputMaps")` y establece `initialScene = "guideInput"`.

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
    self.y = 90
    self.presses = 0
    self.releases = 0
    return self
end

function InputScene:update(dt)
    local input = self.context.inputManager
    local direction = 0
    if input:isDown("guide_left") then direction = direction - 1 end
    if input:isDown("guide_right") then direction = direction + 1 end
    self.x = math.max(8, math.min(312, self.x + direction * 100 * dt))

    if input:isJustPressed("guide_count") then self.presses = self.presses + 1 end
    if input:isJustReleased("guide_count") then self.releases = self.releases + 1 end
end

function InputScene:draw()
    local input = self.context.inputManager
    local mx, my = input:getMousePosition()

    love.graphics.print("Flechas/A/D o cruceta/stick: mover", 8, 8)
    love.graphics.print("Espacio, clic o botón A: contar", 8, 28)
    love.graphics.print("Pulsaciones: " .. self.presses .. " Liberaciones: " .. self.releases, 8, 48)
    love.graphics.print("Ratón: " .. mx .. ", " .. my, 8, 68)
    love.graphics.rectangle("fill", self.x, self.y, 16, 16)
end

return InputScene
```

## 3. Ejecutar y observar

Ejecuta `love .` desde la raíz del proyecto. Mantén pulsada Izquierda/A, Derecha/D, la cruceta o el stick izquierdo para moverte; pulsa y suelta Espacio, un botón del ratón o el botón A del mando para actualizar los contadores. Las direcciones opuestas se cancelan. Los límites suponen el viewport lógico de `320 x 180` del primer proyecto; adáptalos si usas otra resolución. `game/inputMaps.lua` y `game/ecs/systems/playerSystem.lua` del juego de ejemplo también asignan y consultan acciones.

## Ciclo de vida por frame y flancos

`Engine:load()` sustituye los manejadores de LÖVE `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `mousemoved`, `gamepadpressed`, `gamepadreleased`, `gamepadaxis`, `joystickadded` y `joystickremoved` por los suyos. No reenvíes esos callbacks manualmente. Si el juego necesita un tratamiento adicional, define sus callbacks después de `engine:load()` y llama también al método correspondiente del motor.

Durante `Engine:update(dt)` el motor despacha los eventos encolados, recalcula los flancos de los ejes del mando, actualiza las escenas, actualiza el audio y, por último, borra los eventos transitorios y el delta del ratón. `isDown` permanece en `true` mientras se mantenga cualquier asignación; `isJustPressed` e `isJustReleased` describen las asignaciones que cambiaron desde el frame anterior. Las consultas no consumen los eventos, y pulsar una asignación que ya estaba activa no crea otra pulsación.

Los flancos se registran por asignación y se combinan con OR entre dispositivos: soltar una asignación puede indicar una liberación mientras otra sigue activa, y pulsar y soltar entre actualizaciones puede hacer que ambas consultas devuelvan `true`.

## Ratón

`InputManager` guarda la última posición del ratón al pulsar, soltar y mover, y acumula el desplazamiento en un delta por frame que `reset()` borra. `getMousePosition()` y `getMouseDelta()` devuelven coordenadas de ventana, no del viewport lógico; conviértelas con `context.viewport.screenToViewport(...)` antes de dibujar o de compararlas con posiciones del mundo de una cámara.

## Mando

Solo se sigue el primer mando conectado. Un segundo mando se ignora hasta que se retire el primero. Los botones usan nombres de LÖVE como `a`, `b`, `x`, `y`, `dpup`, `dpleft` o `start`. Los ejes usan nombres como `leftx`, `lefty` o `triggerleft` y cuentan como pulsados cuando su valor alcanza `0.5` en valor absoluto; `-1` lee la mitad negativa del eje y `1` la positiva. Las asignaciones por eje necesitan al menos un `InputManager:update()` antes de informar de su estado.

Cuando se conecta o retira un mando, el gestor emite `gamepad_connected` o `gamepad_disconnected` a través del gestor de eventos del motor. Ambos datos contienen `{ joystick = joystick, name = joystick:getName() }`; consulta [Eventos](/es/api/events).

## Errores y limitaciones

- Los mapas no se validan. Se puede consultar cualquier nombre de acción: las acciones desconocidas devuelven `false`, y una acción sin `keys`, `mouse` ni `gamepad` simplemente no tiene asignaciones. Un valor de acción que no sea una tabla falla al consultarlo.
- Los nombres de teclas, botones, ejes y mandos no se contrastan con LÖVE; un error tipográfico nunca coincide.
- El estado mantenido no se borra automáticamente al perder el foco. El gestor conserva la tabla de asignaciones proporcionada en lugar de copiarla.
- Los números de botón del ratón y los nombres del mando siguen las convenciones de LÖVE; esta página no los traduce por plataforma.
- `InputManager` solo emite eventos de mando cuando recibe un gestor de eventos; el motor siempre proporciona uno.

## Más información

[Arquitectura de InputManager](/es/architecture/modules/input-manager) · [Arquitectura de Engine](/es/architecture/modules/engine) · [API de InputManager](/es/api/input-manager) · [API de Eventos](/es/api/events).
