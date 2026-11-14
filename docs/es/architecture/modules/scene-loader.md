# SceneLoader

`engine/scene/sceneLoader.lua` convierte un identificador de escena en una instancia. Se ocupa de resolver el módulo y construirlo, no de la pila ni del ciclo de vida; eso corresponde a [SceneManager](scene-manager.md). [Engine](engine.md) construye el loader con el [GameContext](game-context.md) compartido. Consulta la [descripción general de la arquitectura](../overview.md).

## Interfaz pública y configuración

- `SceneLoader.new(config)` acepta una tabla de configuración. `config.context` es obligatorio y debe ser verdadero en Lua; `config.scenesPath` vale `"game.scenes"` por defecto si es nil o false. El propio loader no valida la ruta ni la interfaz del contexto. Al construirlo a través de `Engine`, `scenesPath` debe ser una cadena no vacía.
- `loader:load(sceneName, dependencies)` requiere que `sceneName` sea una cadena, construye `scenesPath .. "." .. sceneName` y llama a `require` dentro de `pcall`. Si `require` falla, vuelve a lanzar el error con el nombre de la escena y el error original. El módulo cargado debe devolver una tabla con una función `new`; el loader devuelve `SceneClass.new(context)`.
- `dependencies` se **ignora** actualmente, aunque el gestor pasa una tabla combinada. No se reenvía ningún argumento adicional al constructor. Usa el contexto para los servicios compartidos.

`require` utiliza la caché normal de módulos de Lua: el código del módulo suele cargarse una vez, mientras que cada `load` vuelve a llamar a `new`. El loader no valida el valor devuelto por el constructor ni llama a `onLoad`/`onEnter`; el gestor lo hace después de construir la escena. El `pcall` del loader no envuelve errores del constructor ni del ciclo de vida.

## Ejemplo: resolución y construcción de una escena

Con el prefijo predeterminado, `levels.level01` se resuelve al módulo Lua `game.scenes.levels.level01`, normalmente `game/scenes/levels/level01.lua`. Un módulo de escena puede seguir este patrón:

```lua
local Scene = require("engine.scene.scene")
local Example = {}
Example.__index = Example
setmetatable(Example, { __index = Scene })

function Example.new(context)
    local self = Scene.new()
    setmetatable(self, Example)
    self.context = context
    return self
end

function Example:update(dt)
    if self.context.inputManager:isJustPressed("exit") then
        self.context.sceneManager:pop()
    end
end

return Example
```

Sitúa este ejemplo en un módulo accesible bajo el prefijo configurado y proporciona una asignación de entrada `exit`. La [Scene](scene.md) base aporta los métodos de ciclo de vida y dibujo que llama el gestor. Si falta el módulo o `.new`, el fallo ocurre al procesar la carga encolada, no al solicitar la transición. Esta implementación no tiene registro ni factoría de escenas.
