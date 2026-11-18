# API de InputManager

Módulo: `require("engine.input.inputManager")`. Asigna eventos de teclado, ratón y mando a acciones con nombre. Consulta la [arquitectura](../architecture/modules/input-manager.md), la [guía de entrada](../guides/input.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y dependencias

`InputManager.new(inputMaps, events)` devuelve un gestor con el estado de los dispositivos vacío y conserva la tabla de asignaciones original. `inputMaps` debe ser una tabla (puede estar vacía); cada acción es una tabla con secciones opcionales `keys`, `mouse` y `gamepad`:

```lua
{
    jump = {
        keys = { "space" },
        mouse = { 1 },
        gamepad = {
            "a",
            axes = { leftx = 1 },
        },
    },
}
```

`keys` y `gamepad` contienen nombres de tecla y de botón de LÖVE; `mouse` contiene números de botón de LÖVE. La tabla opcional `gamepad.axes` asigna un nombre de eje a `-1` (mitad negativa) o `1` (mitad positiva). Las asignaciones no se validan y los nombres no se contrastan con LÖVE. `events` es un [EventManager](events.md) opcional usado para emitir `gamepad_connected` y `gamepad_disconnected`; las consultas funcionan sin él, pero conectar un mando provoca un error.

[Engine](engine.md) construye el gestor a partir de su `inputMaps` y su gestor de eventos, y lo expone como `context.inputManager`. El gestor conserva la tabla que recibe en lugar de copiarla.

## Métodos y tiempos de eventos

`action` es el nombre de una acción asignada, `key` una cadena de tecla de LÖVE, `button` un número de botón de ratón o un nombre de botón de mando, y `axis` un nombre de eje de LÖVE. Excepto las consultas, los métodos **no devuelven valores**.

| Firma | Resultado y efectos |
| --- | --- |
| `input:keypressed(key)` / `input:keyreleased(key)` | Marca una tecla que no estaba pulsada como pulsada y recién pulsada, o la libera y la marca recién soltada. Las repeticiones mientras sigue pulsada y las liberaciones de teclas no pulsadas no crean flancos. |
| `input:mousepressed(x, y, button, istouch, presses)` / `input:mousereleased(x, y, button, istouch, presses)` | Aplica las mismas reglas por botón del ratón; además guarda la posición. |
| `input:mousemoved(x, y, dx, dy, istouch)` | Guarda la posición y acumula `dx`/`dy` en el delta del frame. |
| `input:gamepadpressed(joystick, button)` / `input:gamepadreleased(joystick, button)` | Aplican las mismas reglas por botón. Los eventos de un joystick distinto del mando seguido se ignoran. |
| `input:gamepadaxis(joystick, axis, value)` | Guarda el valor bruto del eje; `update()` lo convierte en flancos. |
| `input:joystickadded(joystick)` | Sigue el primer mando y emite `gamepad_connected` con `{ joystick, name }`; ignora los joysticks que no son mandos y los mandos adicionales. Requiere `events`. |
| `input:joystickremoved(joystick)` | Si es el mando seguido, emite `gamepad_disconnected` con `{ joystick, name }` y borra todo el estado del mando. Requiere `events`. |
| `input:isDown(action)` | Booleano: alguna tecla, botón de ratón, botón de mando o mitad de eje asignado a la acción está activo. |
| `input:isJustPressed(action)` | Booleano: alguna asignación se activó desde el último `reset`. |
| `input:isJustReleased(action)` | Booleano: alguna asignación se desactivó desde el último `reset`. |
| `input:isMouseDown(button)`, `input:isMouseJustPressed(button)`, `input:isMouseJustReleased(button)` | Consultas directas del ratón que no necesitan una acción. |
| `input:getMousePosition()` | Última posición `x, y` del ratón en coordenadas de ventana. |
| `input:getMouseDelta()` | `dx, dy` acumulados desde el último `reset`. |
| `input:update()` | Recalcula los estados de los ejes del mando y crea sus flancos de pulsación y liberación. **No** borra los flancos. |
| `input:reset()` | Borra todas las tablas de recién pulsado y recién soltado y el delta del ratón; el estado mantenido y los estados de los ejes permanecen. |

Las acciones desconocidas devuelven `false`. Una acción puede mezclar dispositivos; las consultas combinan con OR todas las asignaciones, así que liberar un dispositivo puede indicar una liberación mientras otro mantiene la acción activa. Las consultas no consumen los flancos.

Los ejes cuentan como activos a partir de `0.5` en valor absoluto, y la dirección `-1`/`1` selecciona la mitad negativa o positiva. Una asignación por eje no puede informar de su estado hasta que `update()` haya visto un valor del eje. `reset()` no borra las asignaciones mantenidas y la pérdida de foco no las restablece automáticamente.

`Engine:update(dt)` despacha los eventos, llama a `input:update()`, actualiza escenas y audio y después llama a `input:reset()`. Lee las acciones transitorias durante la actualización de la escena o del sistema, antes de ese reset final. El motor instala los callbacks de LÖVE durante `load`, así que los juegos no tienen que reenviarlos.

## Ejemplo

```lua
local InputManager = require("engine.input.inputManager")
local input = InputManager.new({ jump = { keys = { "space" } } })
input:keypressed("space")
local pressed = input:isJustPressed("jump") -- true
input:update() -- recalcula los flancos de los ejes; no borra la pulsación
input:reset() -- borra los flancos transitorios, no la tecla mantenida
input:keyreleased("space")
```
