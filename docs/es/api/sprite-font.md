# Fuentes de sprites

`require("engine.graphics.spriteFont")` exporta `SpriteFont.new(config)`, una fuente de mapa de bits que dibuja texto glifo a glifo desde una imagen preparada. Cada carácter es un quad de la hoja; la fuente se encarga de posicionar y escalar esos quads.

A diferencia del tipo de recurso `font`, que crea una fuente de LÖVE a partir de un tamaño numérico, una fuente de sprites usa una hoja de glifos y un mapa de carácter a quad. No carga imágenes, no divide hojas ni se registra en `ResourceManager`. Carga la hoja mediante un recurso o directamente, crea los quads con [`loadQuads`](graphics-utils.md) y construye el mapa con [`createGlyphMap`](graphics-utils.md) o a mano.

## Constructor

`SpriteFont.new(config)` devuelve una fuente. Solo comprueba que `config.image`, `config.quads` y `config.glyphs` estén presentes; no valida sus tipos ni su contenido.

| Campo | Tipo | Valor predeterminado | Significado |
| --- | --- | --- | --- |
| `image` | imagen de LÖVE | obligatorio | Hoja usada para todos los glifos. |
| `quads` | array de quads | obligatorio | Quads indexados desde 1 que se dibujan para los glifos. |
| `glyphs` | tabla | obligatorio | Asigna una clave de carácter a un índice de `quads`. |
| `glyphWidth` | número | `8` | Avance horizontal por carácter, antes del escalado. |
| `glyphHeight` | número | `8` | Solo es el valor predeterminado de `lineHeight`; no escala los glifos. |
| `spacing` | número | `0` | Distancia horizontal adicional después de cada carácter. |
| `lineHeight` | número | `glyphHeight` | Avance vertical por línea, antes del escalado. |
| `fallback` | string | `nil` | Clave de glifo usada cuando un carácter no tiene asignación. |
| `uppercase` | booleano | `false` | Convierte cada carácter a mayúsculas antes de buscarlo. |

`glyphWidth` debe coincidir con el ancho de celda de la hoja. `draw` coloca cada quad en el cursor y avanza `glyphWidth + spacing`; las dimensiones propias del quad determinan los píxeles dibujados, así que un ancho de celda distinto produce huecos o solapamientos. `glyphHeight` no se usa al dibujar, solo para deducir `lineHeight` cuando se omite ese campo.

## Métodos

| Método | Parámetros, retorno y efecto |
| --- | --- |
| `getWidth(text)` | Devuelve el ancho de la línea más ancha en píxeles, usando `glyphWidth + spacing` por carácter y restando el último espaciador. El texto vacío devuelve `0`. No recibe escala, así que multiplica el resultado si dibujas escalado. |
| `getHeight(text)` | Devuelve `líneas * lineHeight`, donde las líneas son `1` más el número de caracteres `"\n"`. El texto vacío es una línea; un salto final añade una línea vacía. No recibe escala. |
| `draw(text, x, y, scale)` | Dibuja el texto con su esquina superior izquierda en `x, y`; `scale` es uniforme y vale `1` por defecto. `"\n"` devuelve el cursor a `x` y avanza `y` en `lineHeight * scale`. No devuelve ningún valor. |

`draw` usa el estado gráfico actual de LÖVE: no establece color, modo de mezcla, shader ni fuente, y no guarda ni restaura el estado. Aísla los cambios con `love.graphics.push("all")` y `love.graphics.pop()`. Toda la medición y el dibujo son inmediatos; no se encola nada para un [pipeline de renderizado](rendering.md).

## Búsqueda de glifos y limitaciones

La clave de búsqueda es el propio carácter o `char:upper()` cuando `uppercase = true`. Si falta la clave, se usa `glyphs[config.fallback]`; si esa clave tampoco existe, no se dibuja ningún quad. Un glifo ausente aun así avanza el cursor con el ancho fijo, y el espacio es un carácter normal: si `" "` no tiene asignación, se dibuja el glifo de respaldo en cada espacio. Asigna `" "` explícitamente y ten en cuenta que una búsqueda fallida no lanza un error: simplemente no dibuja nada.

Solo `"\n"` recibe un tratamiento especial. Otros caracteres de control, como `"\r"` y `"\t"`, se buscan como caracteres normales y necesitan glifo o respaldo. La iteración es byte a byte (`gmatch(".")`), por lo que los caracteres UTF-8 de varios bytes se dividen en bytes separados y no pueden asignarse como un solo glifo.

La fuente supone glifos de ancho fijo. No implementa kerning, anchos por carácter, ajuste de línea, alineación ni texto enriquecido; constrúyelos sobre `getWidth`, `getHeight` y `draw`. Los índices de glifo que no existen en `quads` se omiten pero el cursor avanza igualmente. Proporcionar tablas inválidas o un `text` que no sea string puede provocar errores de Lua o LÖVE.

## Ejemplo

```lua
local GraphicsUtils = require("engine.graphics.utils")
local SpriteFont = require("engine.graphics.spriteFont")

-- Divide celdas de 8x10. El orden de los glifos debe coincidir con la hoja.
local sheet = GraphicsUtils.loadQuads(love.graphics.newImage("text.png"), 8, 10)

local font = SpriteFont.new({
    image = sheet.image,
    quads = sheet.quads,
    glyphs = GraphicsUtils.createGlyphMap({
        "h", "e", "l", "o", "w", "r", "d", " ", "?",
    }),
    glyphWidth = 8,
    glyphHeight = 10,
    lineHeight = 10,
    spacing = 0,
    fallback = "?",
    uppercase = false,
})

local text = "hello\nworld"
local width = font:getWidth(text) -- sin escalar
local height = font:getHeight(text)

-- En el método draw de una escena:
love.graphics.push("all")
love.graphics.setColor(1, 1, 1, 1)
font:draw(text, (1280 - width) / 2, (720 - height) / 2)
love.graphics.pop()
```

Las escenas `game/scenes/mainMenu.lua` y `game/scenes/pause.lua` del repositorio usan el mismo patrón con la hoja `menu_text_white` y la lista completa de caracteres.

Consulta [utilidades gráficas](graphics-utils.md), [renderizado](rendering.md), el [gestor de recursos](resource-manager.md) y la [guía de recursos](../guides/resources.md). Para el tipo de recurso de fuente de LÖVE, que es independiente, consulta el [gestor de recursos](resource-manager.md).
