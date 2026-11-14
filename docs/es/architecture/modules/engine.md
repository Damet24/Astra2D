# Engine

`engine/engine.lua` es la raíz de composición y el coordinador del ciclo de vida expuesto a LÖVE. El juego describe las escenas y los servicios; `Engine` ensambla los servicios compartidos y los dirige, sin sustituir el bucle de LÖVE. Consulta la [descripción general de la arquitectura](../overview.md).

## Responsabilidades y relaciones

`Engine.new(config)` normaliza y valida la configuración y luego construye [ResourceManager](resource-manager.md), [AudioManager](audio-manager.md), [GameContext](game-context.md), [SceneLoader](scene-loader.md), [SceneManager](scene-manager.md) e [InputManager](input-manager.md). El gestor de audio comparte el gestor de recursos. El contexto se crea antes del gestor de escenas, se entrega al loader y se completa con los gestores de escenas y entrada. `load` añade el viewport de Shove a ese mismo contexto antes de cargar la escena inicial; consulta [renderizado](rendering.md). Las escenas reciben el contexto, no el motor.

## Configuración

`config` debe ser una tabla. Los valores predeterminados se aplican a campos ausentes, no a valores inválidos. El motor copia la configuración de nivel superior y las tablas `window`, `rendering` y `audio`; no es una copia profunda.

| Campo | Valor predeterminado / requisito | Significado |
| --- | --- | --- |
| `initialScene` | **Obligatorio**, cadena no vacía | Identificador de la escena inicial, resuelto respecto de `scenesPath`. |
| `scenesPath` | `"game.scenes"`; cadena no vacía | Prefijo de módulos Lua para las escenas. |
| `inputMaps` | Tabla **obligatoria**; `{}` es válida | Los nombres de acciones se asignan a arrays contiguos no vacíos de cadenas de teclas no vacías, sin duplicados dentro de una acción. Los nombres deben ser cadenas no vacías. Lo valida `InputManager.new`, no el validador de configuración del motor. |
| `resourceDefinitions` | `{}`; tabla | Definiciones indexadas por ID de recurso. |
| `resourceLoaders` | `engine.resources.loaders.loaders`; tabla | Cargadores indexados por tipo de recurso; el predeterminado incluye `image`, `sound` y `font`. Una tabla suministrada lo reemplaza. |
| `window` | Si se omite: no se llama a `love.window.setMode` | Si se proporciona, debe ser una tabla con `width` y `height` enteros positivos finitos (ambos obligatorios). `fullscreen` vale `false`, `resizable` `true` y `vsync` `true` por defecto; cada uno debe ser booleano. |
| `rendering` | Tabla, `{}` por defecto | Configuración del viewport lógico descrita abajo. |
| `rendering.width`, `rendering.height` | `1280`, `720` | Enteros positivos finitos, independientes de las dimensiones de ventana. |
| `rendering.pixelPerfect` | `false`; booleano | Selecciona el método de ajuste `pixel` de Shove si es verdadero, `aspect` en caso contrario. |
| `rendering.backgroundColor` | `{ 0, 0, 0, 1 }` | Array RGB o RGBA contiguo con números en `[0, 1]`; RGB se normaliza a RGBA con alfa `1`. |
| `audio` | Tabla, `{}` por defecto | Volúmenes iniciales entregados al gestor de audio. |
| `audio.masterVolume`, `audio.musicVolume`, `audio.sfxVolume` | `1.0` cada uno | El motor no valida sus tipos ni rangos; al reproducir, audio multiplica el volumen maestro por el de música o efectos. |

`Engine.new(nil)` parte de una tabla vacía, pero no puede terminar correctamente sin `initialScene` e `inputMaps`. Las definiciones y cargadores se usan al solicitar recursos; un ID o tipo desconocido falla en ese momento.

## Ciclo de vida público

| Método | Comportamiento |
| --- | --- |
| `Engine.new(config)` | Crea los servicios y devuelve un motor; no carga una escena. |
| `engine:load()` | Configura opcionalmente la ventana, establece el fondo, configura el viewport, encola `initialScene` y procesa un lote pendiente. Rechaza un motor ya cargado o cerrado. |
| `engine:update(dt)` | Actualiza escenas y procesa sus transiciones pendientes, actualiza audio y finalmente limpia los indicadores de entrada recién pulsada/soltada. No hace nada antes de cargar o después de cerrar. |
| `engine:draw()` | Envuelve el dibujo de escenas con `beginDraw`/`endDraw` del viewport. No hace nada antes de cargar o después de cerrar. |
| `engine:keypressed(key)`, `engine:keyreleased(key)` | Reenvían la tecla de LÖVE a `InputManager`; estos métodos no comprueban si el motor está cargado o cerrado. |
| `engine:quit()` | Encola `clear`, procesa un lote pendiente, apaga audio, libera los recursos restantes y marca el motor como cerrado. Una llamada posterior tras un cierre exitoso no hace nada. |

La entrada se limpia después de actualizar todas las escenas seleccionadas, que pueden consultar `isJustPressed` e `isJustReleased` durante esa actualización. Al cerrar, las operaciones ya encoladas se ejecutan **antes** del vaciado. Este llama a `onExit` solo en la escena superior y después a `onDestroy` en todas, de arriba hacia abajo. Las operaciones encoladas por callbacks del ciclo de vida durante el procesamiento permanecen en el siguiente lote; `quit` no lo vacía. Las fases no están protegidas contra errores: un fallo puede impedir la limpieza posterior y dejar el motor sin marcar como cerrado. Consulta el orden preciso en [SceneManager](scene-manager.md).

## Ejemplo: punto de entrada de LÖVE

Los identificadores siguientes existen en el juego del repositorio. Sin una tabla `window`, se conserva el modo de ventana existente de LÖVE.

```lua
local Engine = require("engine.engine")
local engine = Engine.new({
    initialScene = "levels.level01",
    inputMaps = require("game.inputMaps"),
    resourceDefinitions = require("game.resources.definitions"),
    rendering = { width = 256, height = 240, pixelPerfect = true },
})

function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.keypressed(key) engine:keypressed(key) end
function love.keyreleased(key) engine:keyreleased(key) end
function love.quit() engine:quit() end
```

Reenvía **ambos** callbacks de teclado: de lo contrario, el estado de tecla mantenida o soltada puede ser incorrecto. `load` y `quit` no son transaccionales; un error en un callback de escena puede interrumpir cualquiera de las operaciones.
