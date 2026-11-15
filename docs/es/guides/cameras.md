# Cámaras y espacios de coordenadas

## Prerrequisitos

Empieza con [Tu primer proyecto](/es/getting-started/first-project) y LÖVE. Esta escena independiente usa su resolución lógica de `320 × 180` y las acciones `move_left`, `move_right`, `move_up` y `move_down`. El motor ya envuelve el dibujo de escenas en el viewport lógico; la escena es dueña de su cámara.

## 1. Crear una cámara de seguimiento

Crea `game/scenes/camera_tutorial.lua`, establece `initialScene = "camera_tutorial"` en `main.lua` y ejecuta `love .`. Muévete con las flechas o WASD y apunta al mundo con el ratón. El cuadrado naranja permanece centrado; el marcador blanco sigue el puntero en espacio de mundo.

```lua
local Scene = require("engine.scene.scene")
local CameraManager = require("engine.camera.cameraManager")

local Tutorial = {}
Tutorial.__index = Tutorial
setmetatable(Tutorial, { __index = Scene })

function Tutorial.new(context)
    local self = Scene.new()
    setmetatable(self, Tutorial)
    self.context = context
    self.x, self.y = 160, 90
    return self
end

function Tutorial:onLoad()
    local width, height = self.context.viewport.getViewportDimensions()
    self.cameras = CameraManager.new()
    self.cameras:add("gameplay", {
        x = self.x, y = self.y, zoom = 2,
        viewport = { x = 0, y = 0, width = width, height = height, clip = true },
    })
    self.cameras:setActive("gameplay")
end

function Tutorial:update(dt)
    local input = self.context.inputManager
    local dx, dy = 0, 0
    if input:isDown("move_left") then dx = dx - 1 end
    if input:isDown("move_right") then dx = dx + 1 end
    if input:isDown("move_up") then dy = dy - 1 end
    if input:isDown("move_down") then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end
    self.x, self.y = self.x + dx * 100 * dt, self.y + dy * 100 * dt
    local camera = self.cameras:getActive()
    if camera then camera:setPosition(self.x, self.y) end
end

function Tutorial:draw()
    local camera = self.cameras:getActive()
    if camera then
        local inside, x, y = self.context.viewport.screenToViewport(love.mouse.getPosition())
        local vx, vy, width, height = camera:getViewport()
        local worldX, worldY
        if inside and x >= vx and x < vx + width and y >= vy and y < vy + height then
            worldX, worldY = camera:worldCoords(x, y)
        end
        camera:draw(function()
            love.graphics.setColor(0.3, 0.6, 0.9)
            for x = -1000, 1000, 32 do
                love.graphics.line(x, -1000, x, 1000)
                love.graphics.line(-1000, x, 1000, x)
            end
            love.graphics.setColor(1, 0.7, 0.2)
            love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)
            if worldX then
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", worldX, worldY, 2)
            end
        end)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Move: arrows / WASD", 8, 8)
end

return Tutorial
```

`add` no selecciona una cámara; `setActive` es explícito. `getActive()` puede devolver `nil`, incluso después de eliminarla. En ese caso el ejemplo omite el dibujo del mundo. La interfaz se dibuja después de `camera:draw`, por lo que permanece en el espacio lógico de pantalla. Una cámara no es un objeto físico y no se actualiza sola.

## 2. Convertir coordenadas y cambiar el zoom

La cadena es **ventana física → viewport lógico → mundo**. `screenToViewport` devuelve `inside, x, y`; descarta los puntos fuera del viewport lógico y, para un viewport de cámara más pequeño, comprueba también su rectángulo lógico como arriba. Después, `camera:worldCoords(x, y)` incluye posición, zoom, rotación y desplazamiento del viewport de la cámara. La inversa es `camera:cameraCoords(worldX, worldY)`, que devuelve coordenadas lógicas, no píxeles físicos de ventana. Ninguna conversión de cámara comprueba los límites.

Shove redondea hacia abajo los desplazamientos de centrado y las coordenadas lógicas devueltas por `screenToViewport`. En los modos de escalado `aspect` y `pixel`, la conversión también usa las dimensiones calculadas a partir de esos márgenes redondeados, que pueden diferir ligeramente de las dimensiones del dibujo escalado. Tras redimensionar, la posición convertida —y por tanto el marcador o una prueba de selección— puede quedar ligeramente desplazada respecto al dibujo, sobre todo cerca de los bordes. Trátala como una conversión aproximada, no como una selección exacta por píxel.

La posición configurada de la cámara es el punto del mundo en el centro del viewport. Con `zoom = 2`, un viewport sin rotación de `320 × 180` muestra `160 × 90` unidades de mundo; el zoom debe ser positivo (`camera:setZoom(1)` restablece una vista 1:1). El escalado de ventana es independiente: la ventana `960 × 540` del primer proyecto escala el viewport lógico, no el zoom de la cámara. Para pixel art, el escalado entero del viewport y un zoom entero evitan escalados fraccionarios, aunque las posiciones subpíxel de la cámara pueden seguir afectando a los píxeles.

Para limitar una cámara **sin rotación** a un mapa que comienza en `(0, 0)`, usa como semiextensiones `width / (2 * zoom)` y `height / (2 * zoom)`. Limita el centro entre cada semiextensión y el tamaño del mapa menos esa semiextensión; si el mapa es más pequeño que la vista, centra ese eje. Con rotación se necesitan otros límites. El nivel suministrado del juego también impide retroceder horizontalmente a la cámara y usa una altura fija de `240`; son políticas del juego, no comportamiento de la cámara.

## Limitaciones y referencias

Se recomienda un viewport explícito: sin él la cámara usa las dimensiones del destino de dibujo actual de LÖVE, que pueden no coincidir con el tamaño lógico. `clip = true` intersecta el scissor existente y requiere una transformación exterior alineada con los ejes; de lo contrario el recorte está desactivado. No cambies el viewport mientras la cámara esté adjunta ni hagas pop de su pila gráfica dentro de `draw`. Consulta la [arquitectura de cámara](/es/architecture/modules/camera-manager), la [arquitectura de renderizado](/es/architecture/modules/rendering) y las API de [cámara](/es/api/camera) y [renderizado](/es/api/rendering). Para mapas y entidades, consulta [Tiled](/es/guides/tiled) y [ECS](/es/guides/ecs).
