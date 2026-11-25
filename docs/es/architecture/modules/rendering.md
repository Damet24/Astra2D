# Renderizado

El renderizado combina piezas independientes: el viewport de resolución lógica del motor, una transformación de cámara opcional y un orden de dibujo opcional mediante un pipeline. Una escena puede dibujar directamente sin mundo, cámara ni pipeline. El nivel de `game/scenes/levels/level.lua` dibuja un fondo en espacio lógico y después un tilemap, sprites y geometría de depuración física a través de su cámara activa.

```text
Ventana de LÖVE (coordenadas físicas)
  └─ viewport de Shove (coordenadas lógicas)
       ├─ fondo / interfaz en espacio lógico
       └─ Camera opcional (transformación de mundo)
            └─ RenderPipeline opcional (orden de capas)
```

## Viewport del motor

`Engine:load()` configura Shove usando `rendering.width` y `rendering.height` (enteros positivos, por defecto `1280 × 720`). `rendering.pixelPerfect` es falso por defecto: falso ajusta conservando la proporción, verdadero usa escalado entero y filtrado nearest. Una ventana menor que la resolución lógica recorta el viewport en modo entero. `rendering.backgroundColor` es un array RGB o RGBA entre 0 y 1, por defecto negro opaco. `window.width` / `window.height`, cuando se proporciona configuración de ventana, establecen la ventana física de forma independiente. El bucle normal de LÖVE limpia con el color de fondo; los bucles personalizados deben hacerlo por su cuenta.

`Engine:draw()` llama a `viewport.beginDraw()`, dibuja la pila de escenas y después llama a `viewport.endDraw()`. Una escena puede llamar a `context.viewport.getViewportDimensions()` y a `context.viewport.screenToViewport(screenX, screenY)`, que devuelve `inside, logicalX, logicalY`. Shove es compartido; solo un motor debería renderizar a la vez. El dibujo del motor no está protegido contra errores: un fallo en una escena puede impedir que se ejecute `endDraw()`.

## API y orden del pipeline

`RenderPipeline.new()` crea una lista vacía. `pipeline:add(layer, draw)` añade un callback sin argumentos con una capa numérica (si es nil, 0); los tipos inválidos de capa o callback producen un error. `pipeline:draw()` ordena por capa ascendente y después por orden de inserción en capas iguales, y ejecuta los callbacks. No vacía la lista; los callbacks se ejecutan de nuevo en el siguiente dibujo. `pipeline:clear()` descarta todos los elementos. Los callbacks no están protegidos; un error interrumpe el dibujo. El orden determinista de capas iguales depende de que el orden de envío también lo sea.

## Tilemaps y sprites ECS

`TilemapRender.new(map, tilesets)` conserva el mapa tipo Tiled y una tabla indexada por nombre de tileset, con `image` y `quads` en cada entrada. `engine.graphics.utils.loadQuads(image, tileWidth, tileHeight)` construye esa estructura en orden de filas. `submit(pipeline)` añade un elemento por cada `tilelayer` visible, usando `layer.properties.layer` o, si no existe, la posición de la capa en `map.layers` desde 1 (incluidas las capas que no son de tiles). `render()` dibuja las capas visibles directamente en orden de mapa, sin intercalarlas mediante el pipeline; `renderLayer(layer)` dibuja directamente una capa.

El renderizador lee `layer.data` como array plano por filas, el ancho y alto de la capa o del mapa, `tilewidth`/`tileheight` del mapa, los desplazamientos de capa en tiles `x`/`y`, en píxeles `offsetx`/`offsety` y la opacidad (por defecto 1). Selecciona un tileset usando los rangos ascendentes de `firstgid` en `map.tilesets` y busca `quads[gid - firstgid + 1]`; omite tilesets o quads inexistentes. No decodifica los flags de volteo de GID de Tiled, ni dibuja capas de objetos, grupos o imágenes, ni admite datos infinitos o por chunks, ni implementa culling. Proporciona capas finitas y tilesets compatibles.

`RenderSystem.submit(world, pipeline)` consulta `Transform` + `Sprite`, ordena los ID de las entidades coincidentes de menor a mayor antes de enviarlas y usa `Sprite.layer` (por defecto 0). Por tanto, los sprites de igual capa siguen el orden de ID, pero su orden respecto a las capas de tiles depende del orden de envío. Usa `Transform.x`, `y`, `rotation` opcional, `Sprite.image`, `origin.x/y` opcional y `flipH`/`flipV`. Si `Animation` selecciona un `Sprite.animations[current].frames[frame]` válido, dibuja ese quad con la imagen de la animación; en otro caso dibuja `Sprite.image`. `RenderSystem.draw(world)` crea un pipeline temporal separado; registrarlo como sistema de dibujo del mundo es cómodo, pero no intercala los sprites con un tilemap renderizado por separado. `World` no lo registra automáticamente.

Una escena típica con mundo y cámara opcional puede enviar ambos tipos juntos:

```lua
local RenderPipeline = require("engine.graphics.RenderPipeline")
local RenderSystem = require("engine.ecs.systems.renderSystem")
-- En la preparación: self.pipeline = RenderPipeline.new()
-- self.tilemapRender, self.world y, opcionalmente, self.cameraManager pertenecen a la escena.
function Level:draw()
    self.pipeline:clear()
    self.tilemapRender:submit(self.pipeline)
    RenderSystem.submit(self.world, self.pipeline)
    local camera = self.cameraManager and self.cameraManager:getActive()
    if camera then
        camera:draw(function() self.pipeline:draw() end)
    else
        self.pipeline:draw() -- política explícita: dibujar sin transformación de mundo
    end
    -- Dibuja aquí la interfaz en espacio lógico.
end
```

Usa otra alternativa si el renderizado del mundo requiere una cámara. `camera:draw` restaura su estado gráfico ante errores del callback con las restricciones de pila descritas en [Gestor de cámaras](camera-manager.md); no protege el viewport exterior del motor. Consulta [World](world.md) y [Scene](scene.md) para la actualización y la propiedad.
