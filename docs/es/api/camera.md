# Cámaras

`require("engine.camera.cameraManager")` gestiona cámaras con nombre; `require("engine.camera.camera")` construye una de forma independiente. La cámara pública envuelve un adaptador a la cámara HUMP vendorizada; los detalles internos de HUMP no son API del motor. No se selecciona ni adjunta ninguna cámara automáticamente.

## Gestor de cámaras

`CameraManager.new()` devuelve un gestor vacío. Los IDs deben ser cadenas no vacías. Salvo donde se indique, los métodos no devuelven valores.

| Método | Efecto y retorno |
| --- | --- |
| `add(id, config)` | Crea y devuelve una cámara; falla si el ID es inválido o duplicado, o la configuración es inválida. No la selecciona. |
| `get(id)` | Devuelve la cámara; falla si el ID es inválido o no existe. |
| `setActive(id)` | Selecciona una cámara existente; falla si el ID es inválido o no existe. |
| `getActive()` | Devuelve la cámara seleccionada o `nil`. |
| `remove(id)` | Elimina una cámara existente; si estaba activa, borra la selección. Falla si el ID es inválido o no existe. |

## Cámara

`Camera.new(config)` devuelve una cámara. `config` puede omitirse: `x`, `y` valen 0, `zoom` vale 1 y `rotation` vale 0 radianes por defecto. La posición es el punto del mundo en el centro del viewport. El constructor usa `config.zoom or 1`, por lo que `nil` y `false` seleccionan el valor predeterminado; cualquier otro valor debe ser un número positivo. A diferencia del constructor, `setZoom(false)` no supera la validación. El `viewport = { x, y, width, height, clip }` opcional usa coordenadas lógicas; x/y valen 0 por defecto y una tabla suministrada requiere width y height numéricos positivos. Sin tabla se usan las dimensiones del destino de dibujo actual de LÖVE, no necesariamente la resolución lógica del motor. La tabla suministrada se conserva, no se copia.

| Método | Parámetros, retorno y efecto |
| --- | --- |
| `setPosition(x, y)`, `move(dx, dy)` | Establecen o desplazan la posición en el mundo. |
| `getPosition()` | Devuelve `x, y`. |
| `setZoom(zoom)`, `getZoom()` | Establecen o devuelven el zoom; al establecerlo se exige un número positivo. |
| `setRotation(radians)`, `getRotation()` | Establecen o devuelven la rotación en radianes. |
| `setViewport(viewport)` | Establece la tabla o `nil` para reiniciar; valida tipo y dimensiones y falla si está adjunta. |
| `getViewport()` | Devuelve `x, y, width, height`. |
| `cameraCoords(worldX, worldY)` | Devuelve coordenadas lógicas del viewport. |
| `worldCoords(logicalX, logicalY)` | Devuelve coordenadas del mundo. Ninguna conversión comprueba límites ni incluye la transformación de la ventana física. |
| `attach()`, `detach()` | Aplican y restauran el estado gráfico de la cámara. No se puede adjuntar la misma cámara dos veces ni desadjuntarla si no está adjunta. |
| `draw(callback)` | Exige una función, adjunta, la llama sin argumentos y desadjunta. No devuelve el resultado del callback. |

Con `clip = true`, la adjunción intersecta el scissor existente y requiere una transformación exterior alineada con los ejes. Si falla la adjunción, deshace sus pushes. `draw` vuelve a lanzar errores del callback tras desadjuntar y deshace pushes extra, siempre que el callback no haya retirado los frames propios de la cámara. Un pop prematuro puede hacer fallar `detach`; sus errores no están protegidos y pueden reemplazar al error del callback.

## Ejemplo

```lua
local Manager = require("engine.camera.cameraManager")
local cameras = Manager.new()
cameras:add("world", { x = 160, y = 90, viewport = { width = 320, height = 180 } })
cameras:setActive("world")
local camera = cameras:getActive()
camera:draw(function() love.graphics.rectangle("fill", 150, 80, 20, 20) end)
local worldX, worldY = camera:worldCoords(160, 90)
```

Para el ratón, primero convierte las coordenadas físicas con `context.viewport.screenToViewport` y comprueba su resultado `inside`; comprueba también los límites del viewport de cámara cuando sea necesario. Consulta la [arquitectura de cámaras](../architecture/modules/camera-manager.md), la [guía de cámaras](../guides/cameras.md) y [renderizado](rendering.md).
