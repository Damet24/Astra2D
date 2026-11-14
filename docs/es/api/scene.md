# API de Scene

Módulo: `require("engine.scene.scene")`. Interfaz base de escena sin gestión automática de mundo, cámara o recursos. Consulta la [arquitectura](../architecture/modules/scene.md), la [guía de escenas](../guides/scenes.md) y [tu primer proyecto](../getting-started/first-project.md).

## Construcción y campos

`Scene.new()` no recibe argumentos y devuelve una escena con `updateBelow = false` y `drawBelow = false`. No guarda un contexto. Los módulos de escena cargados por [SceneLoader](scene-loader.md) deben, en cambio, exponer `new(context)` y pueden guardar el contexto compartido.

Cada opción verdadera permite a [SceneManager](scene-manager.md) continuar bajando por la pila para la pasada correspondiente de update o draw; las escenas seleccionadas se ejecutan de abajo arriba. Las opciones son independientes.

## Métodos

Estos hooks base no hacen nada y **no devuelven valores**. Sobrescríbelos según sea necesario; el gestor los llama sin protegerse contra errores.

| Firma | Invocación / uso previsto |
| --- | --- |
| `scene:onLoad()` | Una vez por instancia construida normalmente, antes de insertarla y entrar. Adquiere aquí los recursos propios de la escena. |
| `scene:onEnter()` | Cuando pasa a ser la cima, también al quedar descubierta tras un pop. |
| `scene:onExit()` | Cuando se cubre o elimina; clear-and-push también sale de escenas ya cubiertas. |
| `scene:onDestroy()` | Cuando se descarta. Libera aquí los recursos propios; la implementación base no los libera. |
| `scene:update(dt)` | Durante las actualizaciones seleccionadas; `dt` son los segundos transcurridos. |
| `scene:draw()` | Durante los dibujos seleccionados, dentro del viewport del motor cuando Engine lo dirige. |

Consulta el [orden del ciclo de vida y la cola](scene-manager.md#ciclo-de-vida-y-cola): `onEnter`/`onExit` pueden repetirse; un error puede interrumpir callbacks y limpieza. Una escena retenida bajo otra no se destruye solo por quedar cubierta.

## Ejemplo

```lua
local Scene = require("engine.scene.scene")
local Overlay = {}
Overlay.__index = Overlay
setmetatable(Overlay, { __index = Scene })
function Overlay.new(context)
    local self = setmetatable(Scene.new(), Overlay)
    self.context = context
    self.drawBelow = true
    return self
end
function Overlay:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
return Overlay
```

Esta superposición dibuja las escenas inferiores pero, con el `updateBelow` predeterminado, no las actualiza.
