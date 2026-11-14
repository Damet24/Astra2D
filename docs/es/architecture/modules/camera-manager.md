# Gestor de cámaras y cámaras

`engine/camera/cameraManager.lua` gestiona objetos `Camera` con nombre; `engine/camera/camera.lua` envuelve el adaptador de cámara de Hump. Proporcionan una vista en espacio de mundo, independiente del ECS y de la gestión de escenas. Una escena puede crear su propio gestor, como hace el nivel, pero no está obligada. Ni el motor ni `Scene.new()` seleccionan una cámara automáticamente.

## Implementación y créditos

La `Camera` de Astra 2D delega en `engine/camera/adapters/humpCamera.lua`, que
envuelve la implementación incluida de `hump.camera` en
`engine/lib/hump/camera.lua`. El adaptador añade la interfaz de viewport, recorte
y dibujo de Astra 2D alrededor de la cámara de HUMP.

Créditos a Matthias Richter y al [proyecto HUMP](https://github.com/vrld/hump)
por `hump.camera`. El archivo incluido conserva su aviso de derechos de autor y
licencia.

## API del gestor

`CameraManager.new()` comienza con un registro vacío y sin cámara activa.

| Método | Comportamiento |
| --- | --- |
| `add(id, config)` | Crea y devuelve una cámara; falla si el ID es inválido o duplicado, o la configuración es inválida. No la selecciona. |
| `get(id)` | Devuelve la cámara; falla si el ID es inválido o no existe. |
| `setActive(id)` | Requiere una cámara existente y la selecciona. |
| `getActive()` | Devuelve la cámara seleccionada o `nil` si no hay ninguna. |
| `remove(id)` | Requiere una cámara existente; si elimina la activa, deja la selección vacía. |

Los ID deben ser cadenas no vacías. Quien llama debe decidir qué hacer cuando `getActive()` devuelve `nil`: omitir el dibujo, dibujar sin cámara o verificar una invariante de la aplicación. El nivel incluido selecciona `gameplay` durante `onLoad`; comprueba que exista una cámara activa en la inicialización y el update, y la usa directamente en `draw`, por lo que eliminarla sin seleccionar otra hace fallar ese nivel. Es una suposición específica del nivel, no una garantía general de las escenas.

## Configuración y API de Camera

`Camera.new(config)` también funciona sin el gestor. `config` puede omitirse. Sus campos son:

- `x`, `y`: posición de mundo en el centro del viewport; por defecto `0, 0`.
- `zoom`: número positivo, por defecto `1`; `rotation`: radianes, por defecto `0`.
- `viewport`: tabla opcional `{ x, y, width, height, clip }` en coordenadas lógicas. `x` e `y` valen cero por defecto; si se proporciona la tabla, `width` y `height` deben ser números positivos. Sin tabla se usan las dimensiones del destino de dibujo actual de LÖVE, que pueden no coincidir con la resolución lógica del motor. Define dimensiones explícitas al usar el viewport del motor. `clip = true` intersecta el scissor existente; en otro caso no se recorta.

`setPosition(x, y)`, `getPosition()`, `move(dx, dy)`, `setZoom(zoom)`, `getZoom()`, `setRotation(radians)` y `getRotation()` manipulan la vista. `setZoom` requiere un número positivo. `setViewport(tableOrNil)` cambia o restablece el viewport y `getViewport()` devuelve `x, y, width, height`. No se puede cambiar el viewport mientras la cámara está adjuntada. El adaptador conserva la tabla de viewport proporcionada, sin copiarla.

`cameraCoords(worldX, worldY)` convierte de mundo a coordenadas lógicas de cámara/viewport; `worldCoords(logicalX, logicalY)` hace la conversión inversa. Estas conversiones no incluyen la transformación de ventana física de Shove ni comprueban si el punto está dentro del viewport de la cámara. Para el ratón, convierte primero de coordenadas físicas a lógicas y comprueba el resultado `inside` de Shove; si el viewport de cámara es más pequeño, comprueba también sus límites cuando corresponda:

```lua
local inside, x, y = context.viewport.screenToViewport(love.mouse.getPosition())
local camera = cameraManager:getActive()
if inside and camera then
    local worldX, worldY = camera:worldCoords(x, y)
    -- Usa worldX, worldY.
end
```

## Dibujo y condiciones de fallo

```lua
local CameraManager = require("engine.camera.cameraManager")
local width, height = context.viewport.getViewportDimensions()
local cameras = CameraManager.new()
cameras:add("world", {
    x = width / 2, y = height / 2,
    viewport = { width = width, height = height },
})
cameras:setActive("world")

local camera = cameras:getActive()
if camera then
    camera:draw(function() pipeline:draw() end)
end
-- Dibuja la interfaz en espacio lógico después de la cámara.
```

`draw(callback)` requiere una función, adjunta la cámara, la ejecuta y después la separa. Si el callback falla y no ha extraído los frames de pila de la cámara, la separación deshace los pushes adicionales, restaura el estado gráfico y el scissor y vuelve a lanzar el error del callback. No devuelve el resultado del callback. `attach()` y `detach()` permiten gestión manual; no se puede adjuntar dos veces la misma cámara, separarla sin estar adjuntada ni cambiar su viewport mientras está adjuntada. El callback no debe extraer los frames de la cámara: hacerlo prematuramente puede provocar un fallo de `detach()` y no se garantiza la limpieza. Si falla el propio adjuntado, el adaptador deshace los frames de pila que añadió y propaga el error; el callback no se ejecuta. En particular, un viewport recortado requiere una transformación gráfica exterior alineada con los ejes (se admiten traslación y escalado); de otro modo falla el adjuntado. Los errores durante la separación no están protegidos y pueden sustituir el error del callback.

El gestor no adjunta cámaras automáticamente ni limpia escenas. Consulta [Renderizado](rendering.md) para el viewport y el pipeline de capas, y [Scene](scene.md) para la propiedad.
