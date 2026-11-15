# API de AudioManager

Módulo: `require("engine.audio.audioManager")`. Reproduce una fuente de música actual y clones de efectos superpuestos. Consulta la [arquitectura](../architecture/modules/audio-manager.md), la [guía de audio](../guides/audio.md) y [tu primer proyecto](../getting-started/first-project.md).

## Configuración y dependencias

`AudioManager.new(config)` devuelve un gestor; `config` es una tabla opcional pero debe contener un `resourceManager` verdadero o falla una aserción. Copia `masterVolume`, `musicVolume` y `sfxVolume` sin valores por defecto ni validación. Quien lo construya directamente debe proporcionar números para reproducir; [Engine](engine.md) asigna `1.0` por defecto a cada uno. La música nueva usa `masterVolume * musicVolume`; los efectos nuevos usan `masterVolume * sfxVolume`. Cambiar los campos no actualiza las fuentes existentes.

Los IDs deben resolverse mediante [ResourceManager](resource-manager.md) a fuentes LÖVE compatibles. El cargador de sonido predeterminado requiere `path` como cadena y `soundType = "static"` o `"stream"`. Se propagan los errores de carga y de las fuentes LÖVE.

## Métodos

`resourceId` es una clave de definición de recurso; `soundId` es el ID numérico de instancia devuelto por `playSound`. Salvo que se indique un resultado, los métodos **no devuelven valores**.

| Firma | Resultado y efectos |
| --- | --- |
| `audio:playMusic(resourceId, config)` | Obtiene la fuente en caché antes de detener otra pista actual, configura repetición y volumen y la reproduce. El `config.loop` opcional activa la repetición solo si es exactamente `true`. Si el ID ya es el actual, reanuda si está marcado como pausado; si no, no hace nada, incluso ignora la nueva configuración de repetición. |
| `audio:playSound(resourceId)` | Clona la fuente en caché, ajusta el volumen, la reproduce y devuelve un `soundId` numérico creciente. |
| `audio:stopMusic()` | Detiene y olvida la música actual; no hace nada si no hay. |
| `audio:stopSound(soundId)` | Detiene y libera el clon; ignora IDs desconocidos. |
| `audio:pauseMusic()` / `audio:resumeMusic()` | Pausan o reanudan la música actual; no hacen nada si no corresponde. |
| `audio:isMusicPlaying()` | Booleano: hay música actual, no está marcada como pausada y su fuente indica que reproduce. |
| `audio:isSoundPlaying(soundId)` | Booleano: el clon conocido no está marcado como pausado y su fuente indica que reproduce; false para IDs desconocidos. |
| `audio:isMusicPaused()` | Booleano: hay música actual y está marcada como pausada. |
| `audio:getCurrentMusic()` | ID del recurso actual o `nil`. |
| `audio:update(dt)` | Libera y elimina clones de efectos terminados y no pausados; `dt` (segundos transcurridos) no se usa actualmente. |
| `audio:shutdown()` | Detiene la música, detiene y libera todos los clones de efectos y libera los intereses de este gestor mediante `resourceManager:releaseAll(self)`. |

## Propiedad y limpieza

La música usa la propia fuente en caché, por lo que comparte estado de reproducción, volumen y repetición; los efectos usan clones y pueden superponerse. No hay API pública para pausar/reanudar efectos. Los clones de efectos se liberan en `stopSound`, en un `update` posterior a su finalización o en `shutdown`. Detener o cambiar música y limpiar efectos **no** libera los intereses del gestor en recursos en caché; estos permanecen hasta `shutdown` o una liberación externa del gestor de recursos. Los originales solo se liberan cuando el último consumidor los deja, salvo liberación forzada.

Una pista que termina naturalmente sigue siendo la actual: `isMusicPlaying()` es false y `getCurrentMusic()` sigue devolviendo su ID. Llamar a `playMusic` con ese ID no la reinicia; llama antes a `stopMusic()` para reiniciar o cambiar la repetición. Liberar recursos por la fuerza puede invalidar fuentes en uso. Engine actualiza audio después de las escenas y lo cierra después de limpiarlas pero antes de liberar recursos por la fuerza; los errores pueden interrumpir esta secuencia.

## Ejemplo

```lua
-- Con las definiciones de recursos del repositorio:
self.context.audioManager:playMusic("music", { loop = true })
local soundId = self.context.audioManager:playSound("jump")
-- Opcionalmente: self.context.audioManager:stopSound(soundId)
```
