# Tu primer proyecto

Esta guía crea un proyecto mínimo de Astra 2D: una escena, unas pocas acciones de entrada y un cuadrado que se mueve. No necesita assets, cámaras ni ECS. Instala LÖVE 11.5 y obtén el código fuente del motor como se describe en [Instalación](/es/getting-started/installation).

Puedes generar esta estructura automáticamente con la [CLI del proyecto](/es/getting-started/cli) opcional en lugar de escribir los archivos a mano:

```sh
npm install -g astra2d-cli
astra2d init my-game
cd my-game
love .
```

Los pasos siguientes construyen la misma estructura manualmente, así que también funcionan sin Node.js.

## Estructura del proyecto

Crea una carpeta para el juego y copia el motor dentro:

```text
my-game/
  engine/               # copia completa, incluido engine/lib/
  game/
    config/
      inputMaps.lua
    scenes/
      hello.lua
  main.lua
```

La carpeta debe llamarse `engine`, porque los módulos del motor se importan entre sí con el prefijo `engine.`. Debe estar dentro del directorio fuente del juego LÖVE, junto a `main.lua`, también al [empaquetar un archivo `.love`](/es/getting-started/installation#empaquetar-el-juego). Mantener la configuración del juego en `game/config/` coincide con el juego de ejemplo y la plantilla del CLI; `resourceDefinitions.lua` y `collisionLayer.lua` pueden añadirse después como archivos opcionales.

## 1. Configurar el punto de entrada

Crea `main.lua`. Construye el motor una vez y reenvía los callbacks de ciclo de
vida. `Engine:load()` instala por sí mismo los callbacks de entrada, así que
`main.lua` no reenvía eventos de teclado, ratón, mando ni joystick:

```lua
local Engine = require("engine.engine")

local engine = Engine.new({
    initialScene = "hello",
    inputMaps = require("game.config.inputMaps"),

    audio = {
        masterVolume = 1.0,
        musicVolume = 0.8,
        sfxVolume = 1.0,
    },
    window = {
        width = 960,
        height = 540,
        fullscreen = false,
        resizable = true,
        vsync = true,
    },
    rendering = {
        width = 320,
        height = 180,
        pixelPerfect = true,
        backgroundColor = { 0.10, 0.14, 0.20 },
    },
})

function love.load()
    engine:load()
end

function love.update(dt)
    engine:update(dt)
end

function love.draw()
    engine:draw()
end

function love.quit()
    engine:quit()
end
```

Aquí se proporcionan los campos obligatorios `initialScene` e `inputMaps`; `scenesPath` tiene por defecto `game.scenes` y `resourceDefinitions` es `{}`. La resolución lógica es `320 x 180`, mientras que la ventana es `960 x 540`. Con `pixelPerfect = true`, el motor usa escalado entero y filtrado nearest-neighbor. Consulta [Configuración del motor](/es/getting-started/installation#configuracion-del-motor) para ver todos los valores predeterminados.

## 2. Definir las acciones de entrada

Crea `game/config/inputMaps.lua`. Cada acción es una tabla con secciones opcionales `keys`, `mouse` y `gamepad`:

```lua
return {
    move_left = {
        keys = { "left", "a" },
        gamepad = { "dpleft", axes = { leftx = -1 } },
    },
    move_right = {
        keys = { "right", "d" },
        gamepad = { "dpright", axes = { leftx = 1 } },
    },
    move_up = { keys = { "up", "w" } },
    move_down = { keys = { "down", "s" } },
}
```

Cada sección lista nombres de asignación de LÖVE o, para `mouse`, números de botón; la tabla opcional `gamepad.axes` asigna un nombre de eje a `-1` o `1`. Las acciones no necesitan todas las secciones y el motor no valida los nombres: las acciones desconocidas devuelven `false` y los errores tipográficos nunca coinciden. Consulta la [guía de entrada](/es/guides/input) para ratón, mando y comportamiento de los flancos.

## 3. Crear la primera escena

Crea `game/scenes/hello.lua`. La ruta de escenas predeterminada e `initialScene = "hello"` se resuelven en este archivo. Esta escena extiende la clase `Scene` del motor y guarda el `GameContext` que recibe en su constructor:

```lua
local Scene = require("engine.scene.scene")

local Hello = {}
Hello.__index = Hello

setmetatable(Hello, { __index = Scene })

function Hello.new(context)
    local self = Scene.new()
    setmetatable(self, Hello)

    self.context = context
    self.x = 160
    self.y = 90
    self.speed = 100

    return self
end

function Hello:onLoad()
    self.width, self.height = self.context.viewport.getViewportDimensions()
end

function Hello:update(dt)
    local input = self.context.inputManager
    local dx, dy = 0, 0

    if input:isDown("move_left") then dx = dx - 1 end
    if input:isDown("move_right") then dx = dx + 1 end
    if input:isDown("move_up") then dy = dy - 1 end
    if input:isDown("move_down") then dy = dy + 1 end

    -- Mantiene la velocidad del movimiento diagonal.
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt

    -- Mantiene el cuadrado dentro del viewport lógico.
    self.x = math.max(8, math.min(self.width - 8, self.x))
    self.y = math.max(8, math.min(self.height - 8, self.y))
end

function Hello:draw()
    love.graphics.push("all")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Muevete con las flechas o WASD", 8, 8)

    love.graphics.setColor(1, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)

    love.graphics.pop()
end

return Hello
```

No hace falta sobrescribir `onDestroy` aquí porque esta escena no adquiere recursos. Una escena que sí lo haga debería liberarlos; consulta la [arquitectura de ResourceManager](/es/architecture/modules/resource-manager).

## 4. Ejecutar el juego

Desde la raíz del proyecto:

```sh
love .
```

Deberías ver una escena lógica de `320 x 180` con instrucciones y un cuadrado que se mueve con las flechas o WASD dentro de la pantalla. Cierra la ventana para ejecutar `engine:quit()`. Para ejecutarlo desde otro lugar, pasa `my-game/` como argumento en lugar de `.`.

## ¿Qué acaba de pasar?

Cuando LÖVE llama a `love.load`, `Engine:load()`:

1. Aplica la configuración de la ventana y el color de fondo.
2. Crea el viewport de resolución virtual.
3. Apila `initialScene` en la pila de escenas.
4. Llama a los callbacks `onLoad` y `onEnter` de la escena.
5. Instala los callbacks de teclado, ratón, mando y joystick de LÖVE.

En cada frame, `Engine:update()` despacha los eventos encolados, recalcula los
flancos de los ejes del mando, actualiza la escena, actualiza el audio y por
último borra los flancos transitorios de entrada y el delta del ratón.
`InputManager:isDown(action)` comprueba todas las asignaciones de esa acción,
provengan del teclado, el ratón o el mando.

`Engine:draw()` dibuja la pila de escenas a través del viewport, que escala la
resolución lógica a la ventana.

Los cambios de escena se encolan. Si una escena llama a
`sceneManager:replace(...)` o `sceneManager:push(...)`, la transición se procesa
al final de la actualización del gestor de escenas, después de que la escena
actual haya terminado de actualizarse.

## Siguientes pasos

- [ResourceManager](/es/architecture/modules/resource-manager) explica cómo definir, cargar y liberar recursos.
- [SceneManager](/es/architecture/modules/scene-manager) explica cómo añadir escenas y realizar transiciones.
- La [descripción general de la arquitectura](/es/architecture/overview) muestra cómo encajan los sistemas.
- [Instalación](/es/getting-started/installation#empaquetar-el-juego) explica cómo empaquetar el juego y el motor juntos.

## Errores comunes

- **La clase de escena no tiene una función `new`.** Cada módulo de escena debe
  devolver una tabla con un constructor `new`.
- **No se encuentra la escena.** Revisa el identificador `initialScene` y el
  prefijo `scenesPath`. Los puntos se traducen a separadores de carpeta.
- **La entrada no hace nada.** Confirma que el nombre de la acción coincide con
  `game/config/inputMaps.lua`. El motor instala los callbacks de entrada de LÖVE durante
  `Engine:load()`; no reenvíes `love.keypressed` ni los demás callbacks de entrada.
- **Se espera una transición inmediata.** Las transiciones solicitadas durante una actualización se difieren hasta el final de la actualización del gestor de escenas; no esperes que la pila cambie a mitad de `update`.
- **Los recursos permanecen cargados.** Libera cada consumidor en `onDestroy` con
  `resourceManager:releaseAll(self)`.
