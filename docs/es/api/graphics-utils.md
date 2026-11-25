# Utilidades gráficas

`require("engine.graphics.utils")` exporta utilidades para dividir una imagen de LÖVE existente en quads, para construir el mapa de caracteres que usan las [fuentes de sprites](sprite-font.md) y para convertir colores RGBA al rango normalizado de LÖVE. Las funciones de división llaman a `image:getDimensions()` y `love.graphics.newQuad`; no cargan imágenes ni gestionan su ciclo de vida.

## API

| Función | Parámetros, retorno y efecto |
| --- | --- |
| `loadQuads(image, width, height)` | Devuelve `{ image = image, quads = quads }`, con un quad por celda completa. Es apto para [renderizar tilemaps](tilemap.md). |
| `loadAnimation(image, frameWidth, frameHeight, frameDuration)` | Devuelve `{ image = image, frames = frames, frameDuration = frameDuration }`. Es apto para `Sprite.animations`. La duración se guarda sin cambios. |
| `createGlyphMap(characters)` | Devuelve una tabla que asigna cada string del array `characters` (indexado desde 1) a su índice. Es apta para el campo `glyphs` de `SpriteFont`. |
| `rgba(r, g, b, a)` | Devuelve `{ r / 255, g / 255, b / 255, a / 255 }` a partir de componentes en el rango 0-255. `a` vale 255 por defecto. |

`loadQuads` y `loadAnimation` enumeran de izquierda a derecha y de arriba abajo, usando las dimensiones completas de la imagen como referencia del quad; se ignoran los bordes incompletos derecho e inferior. Si no cabe ninguna celda completa, el array está vacío. Proporciona dimensiones de celda numéricas positivas y una imagen válida; las utilidades no validan explícitamente la entrada y pueden propagarse errores de Lua o LÖVE. `loadAnimation` no valida la duración, pero `AnimationSystem` exige un `frameDuration` numérico positivo cuando se reproduce la animación seleccionada.

`createGlyphMap` itera con `ipairs`, así que la lista debe ser un array denso que empiece en 1; no valida los tipos. Los caracteres repetidos conservan su último índice, lo que resulta cómodo para rellenar posiciones, pero un carácter real repetido no puede apuntar a dos quads. Los valores resultantes indexan el array `quads` y deben coincidir con la disposición de la hoja.

`rgba` devuelve un array de 4 elementos apto para `love.graphics.setColor(color)` o para `rendering.backgroundColor`. Cada componente debe ser un número entre 0 y 255; si no, se lanza un error. Si `a` es `nil`, se usa 255 (opaco). A diferencia del resto de utilidades, valida la entrada porque un resultado fuera de rango sería rechazado por la [configuración del motor](engine.md).

## Ejemplo

```lua
local Utils = require("engine.graphics.utils")
local image = love.graphics.newImage("sprites.png")
local animation = Utils.loadAnimation(image, 32, 32, 0.1)
local tileset = Utils.loadQuads(image, 16, 16)
local glyphs = Utils.createGlyphMap({ "a", "b", " " })
local background = Utils.rgba(46, 64, 87)
local translucent = Utils.rgba(255, 128, 0, 128)
-- animation.frames y tileset.quads son arrays indexados desde 1.
-- glyphs.a == 1, glyphs.b == 2, glyphs[" "] == 3.
-- background == { 46 / 255, 64 / 255, 87 / 255, 1 }
-- love.graphics.setColor(translucent)
```

Consulta [fuentes de sprites](sprite-font.md), [renderizado](rendering.md), [World](world.md), la [arquitectura de renderizado](../architecture/modules/rendering.md) y la [guía de Tiled](../guides/tiled.md).
