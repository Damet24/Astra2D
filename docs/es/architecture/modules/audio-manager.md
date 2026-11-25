# AudioManager

[Descripción general de la arquitectura](/es/architecture/overview) · [ResourceManager](./resource-manager) · [InputManager](./input-manager)

## Propósito y relaciones

`engine/audio/audioManager.lua` reproduce una pista de música actual y efectos de sonido solapados. `Engine` lo crea con el `ResourceManager` compartido, lo expone como `context.audioManager`, llama a `update(dt)` después de actualizar las escenas y llama a `shutdown()` al salir. Las escenas y los sistemas pueden solicitar audio; por ejemplo, `PlayerSystem` recibe el gestor directamente. El propio AudioManager es el consumidor del recurso, independientemente de la escena que solicitó el sonido.

## Configuración y recursos de sonido

`AudioManager.new(config)` requiere `config.resourceManager`. Copia `masterVolume`, `musicVolume` y `sfxVolume` de la configuración. Cuando lo construye `Engine.new`, estos valores proceden de `audio` y cada uno vale `1.0` por defecto; la construcción directa no establece valores predeterminados, por lo que hay que proporcionar los tres números. No se implementan validación o limitación de volumen ni una API para cambiarlo. Una fuente nueva de música recibe `masterVolume * musicVolume`; un clon nuevo de efecto recibe `masterVolume * sfxVolume`. Cambiar esos campos no actualiza las fuentes que ya se están reproduciendo.

Los IDs deben resolver a fuentes de audio LÖVE compatibles. El cargador predeterminado de sonido requiere un `path` de tipo cadena y `soundType = "static"` o `"stream"`. En `game/config/resourceDefinitions.lua`, `music` utiliza `stream` y `jump` utiliza `static`. `playMusic(id, { loop = true })` activa el bucle solo cuando `loop` es exactamente `true`; si se omite o tiene otro valor, no hay bucle al iniciar una pista nueva.

## API pública

| Método | Comportamiento |
| --- | --- |
| `AudioManager.new(config)` | Crea un gestor con el gestor de recursos obligatorio y los campos de volumen. |
| `playMusic(resourceId, config)` | Obtiene la fuente compartida, detiene cualquier pista actual distinta e inicia la nueva. Si el ID ya es el actual, la reanuda si está pausada; de lo contrario no hace nada. No devuelve un ID de sonido. |
| `stopMusic()` | Detiene y olvida la pista actual; no hace nada si no hay ninguna. |
| `pauseMusic()` / `resumeMusic()` | Pausan o reanudan la pista actual; no hacen nada cuando la operación no corresponde. |
| `isMusicPlaying()` | Es `true` solo si existe una pista actual, no está marcada como pausada y su fuente indica que se reproduce. |
| `isMusicPaused()` | Es `true` si la pista actual está marcada como pausada. |
| `getCurrentMusic()` | Devuelve el ID del recurso actual o `nil`. |
| `playSound(resourceId)` | Clona la fuente en caché, inicia el clon y devuelve un `soundId` numérico creciente. |
| `stopSound(soundId)` | Detiene y libera ese clon; ignora IDs desconocidos. |
| `isSoundPlaying(soundId)` | Es `true` si el clon conocido no está marcado como pausado y comunica que se reproduce; `false` para IDs desconocidos. |
| `update(dt)` | Libera y elimina los clones de efectos terminados que no estén pausados; `dt` no se usa actualmente. |
| `shutdown()` | Detiene la música, detiene y libera todos los clones de efectos activos y llama a `resourceManager:releaseAll(self)`. |

## Reproducción y propiedad

- La música utiliza la propia fuente en caché, no un clon. Por tanto, su estado de reproducción, bucle y volumen se comparten con cualquiera que use esa fuente. Los efectos utilizan clones separados, de modo que pueden solaparse; no hay una API pública para pausar o reanudar efectos.
- Detener música o efectos, cambiar de pista y limpiar efectos terminados **no** libera el interés de AudioManager en el recurso en caché. Todos los IDs solicitados permanecen registrados hasta `shutdown()` (o una liberación externa explícita en el gestor de recursos). Cada clon se libera en `stopSound`, la limpieza o el cierre; el original solo lo libera su cargador cuando lo hace el último consumidor del recurso.
- Una pista que termina de forma natural sigue siendo `currentMusic`: `isMusicPlaying()` devuelve `false`, pero `getCurrentMusic()` sigue devolviendo su ID. Llamar a `playMusic` con ese mismo ID no la reinicia ni aplica una nueva configuración de bucle, salvo que estuviera marcada como pausada (en cuyo caso se reanuda). Llama primero a `stopMusic()` para iniciarla de nuevo o cambiar su bucle.
- `playMusic` obtiene el nuevo recurso antes de detener la pista anterior. Se propagan los errores por IDs o cargadores ausentes y los errores de carga. Las liberaciones forzadas de recursos pueden invalidar fuentes que audio aún esté usando; cierra audio antes de forzar la limpieza de recursos.

## Ejemplo

El menú principal inicia la música definida en bucle; el sistema del jugador reproduce el efecto de salto definido:

```lua
self.context.audioManager:playMusic("music", { loop = true })
local soundId = self.context.audioManager:playSound("jump")
-- Opcionalmente: self.context.audioManager:stopSound(soundId)
```

En cambio, `game/scenes/levels/level.lua` llama a `playMusic("music")` sin bucle. El motor limpia los efectos terminados en cada frame; al salir vacía las escenas, cierra audio y después fuerza la liberación de los recursos restantes. Un error en una fase anterior puede impedir la limpieza posterior.
