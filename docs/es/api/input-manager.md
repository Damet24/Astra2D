# API de InputManager

Módulo: `require("engine.input.inputManager")`. Asigna eventos de teclado a acciones con nombre. Consulta la [arquitectura](../architecture/modules/input-manager.md), la [guía de entrada](../guides/input.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y dependencias

`InputManager.new(inputMaps)` devuelve un gestor con estado de teclas vacío y conserva la tabla original. `inputMaps` debe ser una tabla (puede estar vacía); cada acción debe ser una cadena no vacía asociada a un array contiguo no vacío de cadenas de teclas no vacías y únicas. La misma tecla puede aparecer en distintas acciones. Los mapas inválidos provocan aserciones; los nombres de teclas no se contrastan con LÖVE. [Engine](engine.md) exige este mapa y expone el gestor mediante el contexto. Solo se manejan eventos de teclado.

## Métodos y tiempos de eventos

`key` es una cadena de tecla de LÖVE; `action` es el nombre de una acción asignada. Excepto las consultas, los métodos **no devuelven valores**.

| Firma | Resultado y efectos |
| --- | --- |
| `input:keypressed(key)` | Imprime la tecla; si no estaba pulsada, la marca pulsada y recién pulsada. Las repeticiones mientras sigue pulsada no crean otro evento transitorio. |
| `input:keyreleased(key)` | Imprime la tecla; si estaba pulsada, elimina ese estado y la marca recién soltada. En caso contrario ignora la liberación. |
| `input:isDown(action)` | Booleano: alguna tecla asignada está pulsada. |
| `input:isJustPressed(action)` | Booleano: alguna tecla asignada se pulsó desde el último `update` de entrada. |
| `input:isJustReleased(action)` | Booleano: alguna tecla asignada se soltó desde el último `update` de entrada. |
| `input:update()` | Borra ambas tablas de eventos transitorios; las teclas pulsadas siguen pulsadas. |

Las acciones desconocidas devuelven false. Los eventos transitorios se registran por tecla y las consultas combinan las asignaciones con OR sin consumirlos: una liberación puede ser verdadera mientras otra tecla siga pulsada, y pulsar y soltar entre actualizaciones puede hacer verdaderos ambos eventos. La pérdida de foco no restablece automáticamente las teclas pulsadas.

Reenvía ambos callbacks de teclado de LÖVE. Durante un `Engine:update(dt)` activo, primero se actualizan escenas y transiciones, luego audio y finalmente se borran los eventos transitorios. Consúltalos durante la actualización de la escena; borrarlos antes los pierde. Engine reenvía eventos incluso antes de cargar o después de salir.

## Ejemplo

```lua
local InputManager = require("engine.input.inputManager")
local input = InputManager.new({ jump = { "space" } })
input:keypressed("space")
local pressed = input:isJustPressed("jump") -- true
input:update() -- borra el evento, no el estado pulsado
input:keyreleased("space")
```
