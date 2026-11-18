# API de Engine

Módulo: `require("engine.engine")`. Compone los servicios compartidos y conecta los callbacks de LÖVE. Consulta la [arquitectura](../architecture/modules/engine.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y dependencias

`Engine.new(config)` acepta una tabla (`nil` se convierte en `{}`, que sigue incumpliendo los campos obligatorios). Copia superficialmente el nivel superior y las tablas `window`, `rendering` y `audio`; en general no copia los valores anidados.

| Campo | Contrato |
| --- | --- |
| `initialScene` | Cadena no vacía obligatoria, relativa a `scenesPath`. |
| `scenesPath` | Cadena no vacía; por defecto `"game.scenes"`. |
| `inputMaps` | Tabla obligatoria; `{}` es válida. Cada acción es una tabla con secciones opcionales `keys`, `mouse` y `gamepad`. Se pasa a [InputManager](input-manager.md) sin validarla. |
| `resourceDefinitions` | Tabla por ID; por defecto `{}`. |
| `resourceLoaders` | Tabla por tipo; por defecto el registro integrado. Una tabla suministrada lo reemplaza; consulta [ResourceManager](resource-manager.md). |
| `window` | Tabla opcional; si se proporciona, `width` y `height` deben ser enteros positivos finitos; `fullscreen`, `resizable`, `vsync` son booleanos con valores por defecto `false`, `true`, `true`. Si falta, no cambia el modo de ventana. |
| `rendering` | Tabla con valor por defecto `{}`: `width = 1280`, `height = 720` (enteros positivos finitos), `pixelPerfect = false` (booleano), `backgroundColor = {0, 0, 0, 1}` (números RGB/RGBA contiguos en `[0, 1]`; RGB recibe alfa 1). Pixel-perfect selecciona el ajuste `pixel` de Shove; si no, `aspect`. |
| `audio` | Tabla con valor por defecto `{}`; `masterVolume`, `musicVolume`, `sfxVolume` valen `1.0` por defecto. No se validan tipos ni rangos. |

Construye ResourceManager, AudioManager, GameContext, EventManager, SceneLoader, SceneManager e InputManager. El contexto recibe los gestores de escenas, eventos y entrada durante la construcción y el viewport de Shove durante `load`. La carga y el dibujo requieren LÖVE y Shove.

## Métodos

Salvo indicación contraria, los métodos **no devuelven valores**; se propagan errores de callbacks, cargadores, LÖVE y limpieza.

| Firma | Resultado y efectos |
| --- | --- |
| `Engine.new(config)` | Devuelve un motor sin cargar escenas. Una configuración o mapas de entrada inválidos provocan aserciones. |
| `engine:load()` | Exige que no esté cargado ni cerrado; configura opcionalmente la ventana (exige éxito), el fondo y el viewport, encola la escena inicial, procesa un lote, marca el motor como cargado e instala los callbacks de entrada de LÖVE. |
| `engine:update(dt)` | `dt`: segundos transcurridos. Si está cargado y abierto, despacha los eventos encolados, recalcula los flancos de los ejes del mando, actualiza escenas y su lote pendiente, actualiza audio y después borra los flancos de entrada y el delta del ratón; en caso contrario no hace nada. |
| `engine:draw()` | Si está activo, dibuja escenas entre `beginDraw` y `endDraw` del viewport; si no, no hace nada. |
| `engine:keypressed(key)`, `engine:keyreleased(key)`, `engine:mousepressed(...)`, `engine:mousereleased(...)`, `engine:mousemoved(...)`, `engine:gamepadpressed(...)`, `engine:gamepadreleased(...)`, `engine:gamepadaxis(...)`, `engine:joystickadded(...)`, `engine:joystickremoved(...)` | Reenvían el evento de entrada de LÖVE al gestor de entrada, incluso antes de cargar o después de cerrar. |
| `engine:quit()` | Si no está cerrado, encola la limpieza, procesa un lote, cierra audio, fuerza la liberación de recursos restantes y marca el motor como cerrado. Las llamadas posteriores a una ejecución exitosa no hacen nada. |

`load` y `quit` no son transaccionales. Las transiciones previamente encoladas se ejecutan antes de la limpieza de `quit`; los callbacks pueden encolar otro lote que `quit` no procesa. Los errores pueden interrumpir la limpieza e impedir marcar el motor como cerrado. Consulta [SceneManager](scene-manager.md).

## Ejemplo

```lua
local Engine = require("engine.engine")
local engine = Engine.new({
    initialScene = "levels.level01",
    inputMaps = require("game.inputMaps"),
    resourceDefinitions = require("game.resources.definitions"),
})
function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.quit() engine:quit() end
```

`Engine:load()` instala los callbacks de teclado, ratón, mando y joystick de LÖVE, sustituyendo los manejadores definidos antes de `load`. No los reenvíes desde `main.lua`; define manejadores personalizados después de `engine:load()` y llama tú mismo al método correspondiente del motor.
