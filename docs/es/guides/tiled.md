# Mapas de Tiled: renderizado y colisiones

## Prerrequisitos

Usa el repositorio con LÖVE y Tiled instalados. [Tu primer proyecto](/es/getting-started/first-project) explica las escenas y el punto de entrada; este ejemplo utiliza el recurso `terrain` existente en el repositorio y la resolución lógica `256 × 240`. Ejecútalo desde la raíz del proyecto. Carga únicamente mapas Lua de confianza: `require` ejecuta código Lua.

## 1. Preparar y exportar un mapa

1. Abre `game/tiled/maps/vIllage.tmx` en Tiled y usa **File → Save As…** para crear una copia en `game/tiled/maps/tutorial.tmx`; no modifiques el original. Es un mapa ortogonal finito con tiles de 16 × 16 y el tileset `Terrain (16x16)`. También puedes crear un mapa ortogonal finito nuevo con ese tileset, tiles de 16 × 16 y al menos 16 × 15 celdas.
2. Conserva o pinta una capa de tiles visible. Reutiliza las capas de nivel superior `walls` y `objects` de la copia en vez de añadir duplicados; en un mapa nuevo, créalas. Pon a cero los desplazamientos en tiles y píxeles de ambas capas. En `walls`, edita el rectángulo de suelo existente a `x=0, y=208, width=256, height=32, rotation=0` y elimina los demás objetos de pared de la copia, dejando exactamente un suelo. En `objects`, mueve el **punto** existente llamado `playerSpawn` a `(80, 32)` y asegúrate de que sea el único punto `playerSpawn`. En un mapa nuevo, crea ese rectángulo y ese punto. El mapa original ya tiene un suelo y un spawn aproximadamente en `(45.6364, 193.273)`; añadir otro suelo lo solaparía, y ese spawn casi toca el suelo en lugar de caer visiblemente.
3. Usa **File → Export As…**, selecciona **Lua files** y exporta la copia o el mapa nuevo a `game/maps/tutorial.lua`. El mapa original puede tener un destino de exportación existente: elige explícitamente esta ruta nueva en vez de sobrescribir `game/maps/village.lua`. Conserva el `.tmx` copiado o nuevo como fuente editable y vuelve a exportar tras cada cambio. La exportación debe devolver una tabla Lua con `layers`, `tilesets` y `data` de tiles en un array plano. Comprueba el nombre exacto del tileset en esa tabla. La imagen se carga por separado, no desde el nombre del TSX exportado.
4. En la capa de tiles exportada, la propiedad personalizada entera `layer` controla el orden del pipeline. Por ejemplo, usa `10` para el fondo y `50` para el primer plano. Si se omite, se usa la posición de la capa en `map.layers`, empezando en 1 y contando también las capas de objetos.

## 2. Crear una escena

Crea `game/scenes/tiled_tutorial.lua`. La definición existente del recurso `terrain` apunta a `game/assets/images/Terrain/Terrain (16x16).png`; la imagen es una cuadrícula regular sin márgenes ni separación. El ejemplo crea cuerpos estáticos para las paredes **y** un cuerpo dinámico de prueba, y dibuja sus contornos verdes:

```lua
local Scene = require("engine.scene.scene")
local World = require("engine.ecs.world")
local C = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.PhysicsFactory")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local PhysicsSync = require("engine.ecs.systems.physicsSyncSystem")
local PhysicsDebug = require("engine.ecs.systems.physicsDebugSystem")
local TilemapRender = require("engine.tilemap.tilemaprender")
local Pipeline = require("engine.graphics.RenderPipeline")
local utils = require("engine.graphics.utils")
local map = require("game.maps.tutorial")

local Tutorial = {}
Tutorial.__index = Tutorial
setmetatable(Tutorial, { __index = Scene })

function Tutorial.new(context)
    local self = Scene.new()
    setmetatable(self, Tutorial)
    self.context = context
    return self
end

function Tutorial:onLoad()
    local image = self.context.resourceManager:get(self, "terrain")
    self.renderer = TilemapRender.new(map, {
        ["Terrain (16x16)"] = utils.loadQuads(image, 16, 16),
    })
    self.pipeline = Pipeline.new()
    self.world = World.new(0, 640, true)
    self.world:addSystem(PhysicsSystem)
    self.world:addSystem(PhysicsSync)

    local spawn = { x = 80, y = 32 }
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.name == "walls" then
            local ox = (layer.x or 0) * map.tilewidth + (layer.offsetx or 0)
            local oy = (layer.y or 0) * map.tileheight + (layer.offsety or 0)
            for _, object in ipairs(layer.objects) do
                assert(object.shape == "rectangle", "walls must contain only rectangles")
                local angle = math.rad(object.rotation or 0)
                local cos, sin = math.cos(angle), math.sin(angle)
                local entity = self.world:createEntity()
                self.world:addComponent(entity, C.Transform, {
                    x = ox + object.x + cos * object.width / 2 - sin * object.height / 2,
                    y = oy + object.y + sin * object.width / 2 + cos * object.height / 2,
                    rotation = angle,
                })
                self.world:addComponent(entity, C.RigidBody, { type = "static" })
                self.world:addComponent(entity, C.Collider, {
                    shape = "rectangle", width = object.width, height = object.height,
                })
                PhysicsFactory.create(self.world, entity)
            end
        elseif layer.type == "objectgroup" and layer.name == "objects" then
            for _, object in ipairs(layer.objects) do
                if object.name == "playerSpawn" and object.shape == "point" then
                    spawn = { x = object.x + (layer.offsetx or 0),
                              y = object.y + (layer.offsety or 0) }
                    break
                end
            end
        end
    end

    local player = self.world:createEntity()
    self.world:addComponent(player, C.Transform, { x = spawn.x, y = spawn.y })
    self.world:addComponent(player, C.RigidBody, { type = "dynamic" })
    self.world:addComponent(player, C.Collider, { shape = "rectangle", width = 18, height = 28 })
    local body = PhysicsFactory.create(self.world, player)
    body:setFixedRotation(true)
end

function Tutorial:update(dt)
    self.world:update(dt)
end

function Tutorial:draw()
    self.pipeline:clear()
    self.renderer:submit(self.pipeline)
    self.pipeline:draw()
    PhysicsDebug.draw(self.world)
end

function Tutorial:onDestroy()
    self.world.physics:destroy()
    self.context.resourceManager:releaseAll(self)
end

return Tutorial
```

Establece `initialScene = "tiled_tutorial"` en `main.lua` y ejecuta `love .`. La caja debería caer sobre una pared; si la atraviesa, comprueba el nombre de la capa, la posición del rectángulo y el archivo exportado. Esta escena dibuja en coordenadas lógicas sin cámara, así que solo se ven los `256 × 240` superiores izquierdos. La fórmula del centro de la pared tiene en cuenta que Tiled rota el rectángulo alrededor de su esquina superior izquierda. Como en el nivel suministrado, los desplazamientos del spawn usan `offsetx`/`offsety`, no `x`/`y` de la capa de objetos; mantén el desplazamiento en tiles de la capa de spawn en cero.

## 3. Qué es automático y qué no

- `TilemapRender` dibuja las capas de tiles visibles de nivel superior; no crea física. `game/scenes/levels/level.lua` del repositorio implementa las convenciones `walls` y `objects`, incluido el spawn alternativo, independientemente del motor. Una pared llamada `leftWall` también tiene un comportamiento especial de seguimiento de cámara en ese nivel del juego, no en este tutorial. Las formas de colisión de los tiles de Tiled, las capas de paredes ocultas y la visibilidad de los objetos no controlan automáticamente la física: este bucle procesa todos los objetos de una capa coincidente.
- El renderer usa rangos `firstgid` ascendentes y quads indexados por GID; los nombres de tileset deben coincidir con la tabla suministrada. `loadQuads` supone una cuadrícula de imagen regular. Los quads inexistentes o incompatibles se omiten. No decodifica flags de GID para volteos/rotaciones, separación/márgenes de tilesets, animaciones de tiles, colecciones de imágenes, capas de grupo/imagen/objetos, chunks infinitos ni culling. Usa capas de tiles ortogonales finitas sin volteos y tilesets de cuadrícula simples.
- `submit` ordena las capas mediante el pipeline; `render()` dibuja las capas de tiles visibles directamente en orden de mapa. Limpia y vuelve a enviar cada frame cuando mezcles capas con sprites ECS. Las capas del pipeline se ordenan de menor a mayor y los empates por orden de envío.
- `PhysicsFactory.create` solo admite rectángulos de tamaño positivo y es necesario tras añadir `Transform`, `RigidBody` y `Collider`. Añadir componentes por sí solo no crea una fixture. `Collider.layer` y `Collider.mask` asignan categorías de colisión (1-16); Tiled no las deduce de las capas, así que indícalas explícitamente si las necesitas. La física necesita `world:update(dt)` y un `PhysicsSystem` registrado; la escena es dueña del mundo físico y es la consumidora de la imagen.

Consulta la [arquitectura de renderizado](/es/architecture/modules/rendering), la [arquitectura de World](/es/architecture/modules/world) y las referencias de API de [tilemap](/es/api/tilemap), [renderizado](/es/api/rendering) y [world](/es/api/world). Continúa con [cámaras](/es/guides/cameras) o [ECS](/es/guides/ecs).
