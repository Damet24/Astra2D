# InputManager

[Descripción general de la arquitectura](/es/architecture/overview) · [ResourceManager](./resource-manager) · [AudioManager](./audio-manager)

## Propósito y relaciones

`engine/input/inputManager.lua` asigna acciones con nombre a teclas de teclado, botones de ratón, botones de mando y ejes de mando. Registra el estado mantenido, recién pulsado y recién soltado por dispositivo y resuelve las consultas entre todas las asignaciones de una acción. [Engine](engine.md) lo construye a partir de `inputMaps` y su [EventManager](/es/api/events), lo expone como `context.inputManager` e instala todos los callbacks de entrada de LÖVE durante `load`. Las escenas consultan el contexto; sistemas como `PlayerSystem` reciben el gestor directamente.

El gestor mantiene tres grupos de estado: `keyboard`, `mouse` y `gamepad`. Cada grupo guarda tablas de pulsado, recién pulsado y recién soltado; el ratón añade posición y delta por frame; el mando añade ejes brutos, estados de umbral y el joystick seguido.

## Configuración

`InputManager.new(inputMaps, events)` recibe la tabla de asignaciones y un gestor de eventos opcional, también obligatoria como `inputMaps` de `Engine.new`. Se admite una tabla vacía. Cada acción se asigna a una tabla con secciones opcionales:

```lua
return {
    accept = {
        keys = { "return", "space" },
        mouse = { 1 },
        gamepad = { "a" },
    },
    move_left = {
        keys = { "left", "a" },
        gamepad = {
            "dpleft",
            axes = { leftx = -1 },
        },
    },
    jump = {
        keys = { "space" },
        gamepad = { "a" },
    },
}
```

`keys` contiene nombres de tecla de LÖVE, `mouse` contiene números de botón de LÖVE, y `gamepad` contiene nombres de botón de LÖVE y una tabla opcional `axes` cuyos valores son `-1` (mitad negativa) o `1` (mitad positiva). La misma tecla o botón puede pertenecer a acciones distintas. El gestor no valida nada: una sección ausente simplemente no aporta asignaciones, las acciones desconocidas devuelven `false` y un valor de acción que no sea una tabla falla al consultarlo. Los nombres de asignación no se contrastan con LÖVE. Se conserva la tabla original, sin copiarla.

El argumento `events` solo se usa para las notificaciones de conexión del mando. Sin él, el gestor sigue atendiendo consultas de teclado y ratón, pero `joystickadded` falla al intentar emitir. El motor siempre pasa su gestor de eventos.

## API pública y ciclo del frame

| Método | Comportamiento |
| --- | --- |
| `InputManager.new(inputMaps, events)` | Crea estados de dispositivo vacíos y conserva ambos argumentos. |
| `keypressed(key)` / `keyreleased(key)` | Actualiza los flancos del teclado: una tecla no pulsada pasa a pulsada y recién pulsada; una tecla pulsada pasa a liberada y recién soltada. Los demás eventos se ignoran. |
| `mousepressed(...)` / `mousereleased(...)` | Actualiza los flancos de los botones del ratón con las mismas reglas y guarda la posición. |
| `mousemoved(x, y, dx, dy, istouch)` | Guarda la posición y acumula el delta del frame. |
| `gamepadpressed(joystick, button)` / `gamepadreleased(joystick, button)` | Actualiza los flancos de botón solo para el mando seguido. |
| `gamepadaxis(joystick, axis, value)` | Guarda el valor bruto del eje para el mando seguido. |
| `joystickadded(joystick)` / `joystickremoved(joystick)` | Sigue el primer mando, emite `gamepad_connected` / `gamepad_disconnected` y borra el estado al desconectarlo. |
| `isDown(action)` / `isJustPressed(action)` / `isJustReleased(action)` | Combinan con OR todas las asignaciones de teclado, ratón, botones de mando y ejes de la acción. |
| `isMouseDown(button)` / `isMouseJustPressed(button)` / `isMouseJustReleased(button)` | Consultas directas de los botones del ratón. |
| `getMousePosition()` / `getMouseDelta()` | Posición en coordenadas de ventana y movimiento por frame. |
| `update()` | Convierte los ejes brutos en estados de umbral y flancos de eje. No borra los flancos existentes. |
| `reset()` | Vacía todas las tablas de recién pulsado y recién soltado y el delta del ratón; el estado mantenido y los ejes permanecen. |

Los ejes se activan a partir de `0.5` en valor absoluto. `update()` compara cada eje con su estado positivo/negativo anterior y registra flancos con los nombres sintéticos `<eje>_positive` y `<eje>_negative`; la dirección `-1`/`1` de una asignación selecciona la mitad que lee. Una asignación por eje no informa de nada hasta que `update()` ha procesado al menos un valor.

Las consultas devuelven `false` para acciones desconocidas y para acciones sin una sección coincidente. Los flancos se registran **por asignación** y se combinan con OR: soltar una asignación puede activar `isJustReleased` mientras otra mantiene `isDown` en `true`, y una pulsación y liberación entre resets puede hacer que ambas consultas de flanco devuelvan `true`. Las consultas no consumen los flancos, por lo que varios sistemas pueden leerlos.

`Engine:load()` instala los callbacks de LÖVE y reenvía eventos de teclado, ratón, mando y joystick. En cada frame cargado:

1. `EventManager:dispatch()` entrega los eventos encolados, incluidas las conexiones de mando del lote anterior.
2. `InputManager:update()` recalcula los flancos de los ejes.
3. Las escenas y los sistemas se actualizan y leen el estado de entrada actual.
4. Se ejecuta `AudioManager:update(dt)`.
5. `InputManager:reset()` borra los flancos transitorios y el delta del ratón.

Lee las acciones transitorias durante la actualización de la escena o del sistema, antes del reset final; llamar a `reset()` antes los pierde. La pérdida de foco no restablece el estado mantenido. Solo se sigue el primer mando conectado; los mandos adicionales se ignoran hasta que se retire.

## Ejemplo

El nivel comprueba la acción configurada `exit` durante su actualización:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

En `game/ecs/systems/playerSystem.lua`, `isDown("move_left")` e `isDown("move_right")` controlan el movimiento, mientras que `isJustPressed("jump")` activa un salto y un sonido. Las mismas acciones pueden incluir botones y ejes de mando sin cambiar el código de la escena.
