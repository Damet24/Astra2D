# Changelog

Todas las versiones notables de Astra 2D se documentan en este archivo.

## [0.2.0] - 2026-11-18

### Añadido

- Entrada de ratón: botones con estado mantenido, pulsado y soltado, posición y delta por frame (`getMousePosition`, `getMouseDelta`, `isMouseDown`, `isMouseJustPressed`, `isMouseJustReleased`).
- Entrada de mando: botones y ejes con umbral de `0.5`; se sigue el primer mando conectado.
- Eventos `gamepad_connected` y `gamepad_disconnected` con `{ joystick, name }`.
- `context.events` expone el `EventManager` del motor.
- CLI `astra2d` con los comandos `init` y `scene:create`, y copia del motor empaquetada como respaldo sin conexión.

### Cambiado

- **Breaking:** los mapas de entrada ahora son tablas por dispositivo (`keys`, `mouse`, `gamepad` y `gamepad.axes`) en lugar de arrays planos de teclas.
- `InputManager.new(inputMaps, events)` recibe el gestor de eventos y ya no valida los mapas; las acciones desconocidas devuelven `false`.
- `Engine:load()` instala los callbacks de entrada de LÖVE; `main.lua` solo reenvía `load`, `update`, `draw` y `quit`.
- Orden de `Engine:update`: despacho de eventos, flancos de ejes, escenas, audio y limpieza final de entrada.
- La plantilla de proyecto del CLI y `examples/collect` usan el nuevo formato de entrada.
- Documentación en inglés y español actualizada para el nuevo sistema.

### Corregido

- El despliegue de la documentación con etiquetas de versión (`on.push.tags`).

### Eliminado

- Reenvío manual de `love.keypressed` y `love.keyreleased` en plantillas, ejemplos y documentación.
