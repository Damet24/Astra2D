# Utilidades gráficas

`require("engine.graphics.utils")` exporta dos funciones para dividir una imagen de LÖVE existente en quads. Llaman a `image:getDimensions()` y `love.graphics.newQuad`; no cargan imágenes ni gestionan su ciclo de vida.

## API

| Función | Parámetros, retorno y efecto |
| --- | --- |
| `loadQuads(image, width, height)` | Devuelve `{ image = image, quads = quads }`, con un quad por celda completa. Es apto para [renderizar tilemaps](tilemap.md). |
| `loadAnimation(image, frameWidth, frameHeight, frameDuration)` | Devuelve `{ image = image, frames = frames, frameDuration = frameDuration }`. Es apto para `Sprite.animations`. La duración se guarda sin cambios. |

Ambas enumeran de izquierda a derecha y de arriba abajo, usando las dimensiones completas de la imagen como referencia del quad; se ignoran los bordes incompletos derecho e inferior. Si no cabe ninguna celda completa, el array está vacío. Proporciona dimensiones de celda numéricas positivas y una imagen válida; las utilidades no validan explícitamente la entrada y pueden propagarse errores de Lua o LÖVE. `loadAnimation` no valida la duración, pero `AnimationSystem` exige un `frameDuration` numérico positivo cuando se reproduce la animación seleccionada.

## Ejemplo

```lua
local Utils = require("engine.graphics.utils")
local image = love.graphics.newImage("sprites.png")
local animation = Utils.loadAnimation(image, 32, 32, 0.1)
local tileset = Utils.loadQuads(image, 16, 16)
-- animation.frames y tileset.quads son arrays indexados desde 1.
```

Consulta [renderizado](rendering.md), [World](world.md), la [arquitectura de renderizado](../architecture/modules/rendering.md) y la [guía de Tiled](../guides/tiled.md).
