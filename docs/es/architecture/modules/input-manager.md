# InputManager

[Descripción general de la arquitectura](/es/architecture/overview) · [ResourceManager](./resource-manager) · [AudioManager](./audio-manager)

## Propósito y relaciones

`engine/input/inputManager.lua` asigna acciones con nombre a nombres de teclas y registra teclas mantenidas, recién pulsadas y recién soltadas. `Engine` lo construye a partir de `inputMaps`, lo expone como `context.inputManager` y le reenvía los callbacks de teclado de LÖVE. Las escenas consultan el contexto; sistemas como `PlayerSystem` reciben el gestor directamente. La implementación solo procesa eventos de teclado; no se suscribe a callbacks de ratón ni de mando.

## Configuración

`InputManager.new(inputMaps)` requiere una tabla, también obligatoria como `inputMaps` de `Engine.new`. Se admite una tabla vacía. Cada nombre de acción debe ser una cadena no vacía y su valor un array contiguo no vacío, desde el índice 1, con cadenas de asignación únicas y no vacías. Una misma tecla puede pertenecer a acciones distintas. Los mapas inválidos provocan aserciones al construir el gestor; los nombres de tecla no se contrastan con la lista de LÖVE. Se conserva la tabla original, sin copiarla.

Por ejemplo, `game/inputMaps.lua` contiene:

```lua
return {
    accept = { "return" },
    exit = { "escape" },
    move_left = { "left", "a" },
    move_right = { "right", "e" },
    jump = { "space" },
}
```

## API pública y ciclo del frame

| Método | Comportamiento |
| --- | --- |
| `InputManager.new(inputMaps)` | Valida el mapa y crea estados de teclas vacíos. |
| `keypressed(key)` | Marca una tecla que no estaba mantenida como mantenida y recién pulsada. Las repeticiones mientras sigue pulsada no generan otro flanco. |
| `keyreleased(key)` | Deja de marcar la tecla como mantenida y la marca como recién soltada; ignora las liberaciones de teclas que no estaban mantenidas. |
| `isDown(action)` | Devuelve `true` si alguna tecla asignada está mantenida. |
| `isJustPressed(action)` | Devuelve `true` si alguna tecla asignada se pulsó desde el último `update`. |
| `isJustReleased(action)` | Devuelve `true` si alguna tecla asignada se soltó desde el último `update`. |
| `update()` | Sustituye las tablas transitorias de recién pulsadas y soltadas por tablas vacías; las teclas mantenidas siguen estándolo. |

Las acciones desconocidas devuelven `false`. Los flancos se registran **por tecla** y se combinan con OR para una acción: soltar una asignación puede activar `isJustReleased` mientras otra mantiene `isDown` en `true`. Una pulsación y liberación entre actualizaciones puede hacer que ambas consultas de flanco devuelvan `true`. Las consultas no consumen los flancos, por lo que varios sistemas pueden leerlos. Ambos métodos de evento imprimen actualmente la tecla, incluso en eventos repetidos o ignorados.

`main.lua` reenvía `love.keypressed` y `love.keyreleased` a `Engine`. En cada frame cargado, `Engine:update(dt)` actualiza las escenas (incluidas las transiciones pendientes), actualiza audio y finalmente borra los flancos de input. Lee las acciones transitorias durante la actualización de la escena o del sistema, antes de esa limpieza; llamar a `update()` prematuramente pierde los flancos. El estado mantenido no se reinicia automáticamente al perder el foco.

## Ejemplo

El nivel comprueba la acción configurada `exit` durante su actualización:

```lua
if self.context.inputManager:isJustPressed("exit") then
    self.context.sceneManager:push("pause")
end
```

En `game/ecs/systems/playerSystem.lua`, `isDown("move_left")` e `isDown("move_right")` controlan el movimiento, mientras que `isJustPressed("jump")` activa un salto y un sonido.
