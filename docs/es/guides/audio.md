# Reproducir música y efectos simultáneos

## Objetivo y requisitos

Inicia música en bucle, dispara un efecto y pausa o reinicia la música. Parte de [Tu primer proyecto](/es/getting-started/first-project), incluidos sus callbacks de LÖVE. Proporciona tus propios archivos de audio compatibles con LÖVE en `game/assets/guide-music.ogg` y `game/assets/guide-effect.wav`; un proyecto nuevo no los incluye.

## 1. Registrar sonidos y acciones

Crea `game/resources/definitions.lua` y su directorio padre si no existen; comienza el archivo con `return {}`. Añade estas entradas dentro de la tabla devuelta:

```lua
guide_music = { type = "sound", path = "game/assets/guide-music.ogg", soundType = "stream" },
guide_effect = { type = "sound", path = "game/assets/guide-effect.wav", soundType = "static" },
```

Añade estas entradas a `game/inputMaps.lua`, conservando las existentes en ambas tablas:

```lua
guide_effect = { "space" },
guide_music_pause = { "m" },
guide_music_restart = { "r" },
```

Son fragmentos de entradas de tabla. Asegúrate de que `Engine.new` reciba `resourceDefinitions = require("game.resources.definitions")` e `inputMaps = require("game.inputMaps")`; establece `initialScene = "guideAudio"`. El motor usa por defecto `1.0` en los tres volúmenes de audio. Opcionalmente, sustituye la tabla `audio` existente de la configuración del motor por `audio = { masterVolume = 1.0, musicVolume = 0.5, sfxVolume = 0.8 }`.

## 2. Crear la escena de audio

Crea `game/scenes/guideAudio.lua`:

```lua
local Scene = require("engine.scene.scene")
local AudioScene = {}
AudioScene.__index = AudioScene
setmetatable(AudioScene, { __index = Scene })

function AudioScene.new(context)
    local self = setmetatable(Scene.new(), AudioScene)
    self.context = context
    return self
end

function AudioScene:onLoad()
    self.context.audioManager:playMusic("guide_music", { loop = true })
end

function AudioScene:update(dt)
    local input = self.context.inputManager
    local audio = self.context.audioManager
    if input:isJustPressed("guide_effect") then
        audio:playSound("guide_effect")
    end
    if input:isJustPressed("guide_music_pause") then
        if audio:isMusicPaused() then audio:resumeMusic() else audio:pauseMusic() end
    end
    if input:isJustPressed("guide_music_restart") then
        audio:stopMusic()
        audio:playMusic("guide_music", { loop = true })
    end
end

function AudioScene:draw()
    love.graphics.print("Space: effect  M: pause/resume  R: restart", 8, 16)
end

return AudioScene
```

## 3. Ejecutar y controlar la reproducción

Ejecuta `love .` desde la raíz del proyecto. La música se repite; cada pulsación de Espacio puede solaparse con un efecto anterior. Pulsa M para pausar/reanudar o R para reiniciar la música. `playSound` devuelve un ID de instancia: consérvalo si quieres llamar después a `audio:stopSound(soundId)` o `audio:isSoundPlaying(soundId)`.

`game/scenes/mainMenu.lua` del juego de ejemplo reproduce en bucle su recurso `music`, y `game/ecs/systems/playerSystem.lua` reproduce su efecto `jump`. Esos IDs y archivos pertenecen a ese juego, no a un proyecto nuevo.

## Ciclo de reproducción y propiedad

La música usa la propia fuente en caché; solo hay una pista de música actual y, al iniciar otra distinta, se detiene la anterior. Los efectos clonan su fuente para poder solaparse. El update de audio del motor libera los clones terminados; `stopSound` libera uno antes de tiempo. No hay una API pública para pausar/reanudar efectos.

El consumidor del recurso es el gestor de audio, no la escena que lo solicita. Esta escena deja la música sonando intencionadamente entre transiciones de escena. `stopMusic` detiene la reproducción, pero no libera el recurso en caché; audio mantiene sus intereses hasta `shutdown()`. En una salida normal del motor se destruyen las escenas, audio se cierra y libera sus intereses, y se fuerzan a liberar los recursos restantes.

## Errores y limitaciones

- Los IDs ausentes, las definiciones de sonido inválidas o los archivos ilegibles fallan cuando la reproducción los carga por primera vez. Usa `stream` para la música y `static` para el efecto corto; ambos necesitan un archivo de audio válido para LÖVE.
- Una pista que termina de forma natural sigue siendo la actual. Llamar otra vez a `playMusic` con el mismo ID no la reinicia ni cambia el bucle; si está pausada, la reanuda. Llama primero a `stopMusic` para reiniciar o cambiar el bucle. Solo `loop = true` activa la repetición.
- La música comparte su fuente en caché con otros consumidores. No fuerces la liberación de un recurso de audio mientras esté en uso. Detener o terminar un efecto libera su clon, no el original en caché.
- El volumen se aplica al iniciar una fuente: `masterVolume * musicVolume` para música y `masterVolume * sfxVolume` para efectos. No se ha implementado un setter de volumen ni la actualización automática de fuentes en reproducción. Quien construya `AudioManager.new` directamente debe proporcionar los tres volúmenes numéricos.

## Más información

[Arquitectura de AudioManager](/es/architecture/modules/audio-manager) · [Arquitectura de ResourceManager](/es/architecture/modules/resource-manager) · [API de AudioManager](/es/api/audio-manager).
