# Play music and overlapping effects

## Goal and prerequisites

Start looping music, trigger an effect, and pause or restart the music. Start from [Your First Project](/getting-started/first-project), including its engine setup. Supply your own LÖVE-compatible audio files at `game/assets/guide-music.ogg` and `game/assets/guide-effect.wav`; a new project does not include them.

## 1. Register sounds and actions

Create `game/resources/definitions.lua` and its parent directory if they do not exist; start the file with `return {}`. Add these entries inside the returned table:

```lua
guide_music = { type = "sound", path = "game/assets/guide-music.ogg", soundType = "stream" },
guide_effect = { type = "sound", path = "game/assets/guide-effect.wav", soundType = "static" },
```

Add these entries to `game/inputMaps.lua`, keeping any existing entries in both tables:

```lua
guide_effect = { keys = { "space" } },
guide_music_pause = { keys = { "m" } },
guide_music_restart = { keys = { "r" } },
```

These snippets are table entries. Ensure `Engine.new` receives `resourceDefinitions = require("game.resources.definitions")` and `inputMaps = require("game.inputMaps")`; set `initialScene = "guideAudio"`. The engine defaults all three audio volumes to `1.0`. Optionally replace the existing `audio` table in the engine configuration with `audio = { masterVolume = 1.0, musicVolume = 0.5, sfxVolume = 0.8 }`.

## 2. Create the audio scene

Create `game/scenes/guideAudio.lua`:

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

## 3. Run and control playback

Run `love .` from the project root. Music loops; each Space press can overlap an earlier effect. Press M to pause/resume or R to restart music. `playSound` returns an instance ID: retain it if you want to call `audio:stopSound(soundId)` or `audio:isSoundPlaying(soundId)` later.

The example game's `game/scenes/mainMenu.lua` loops its `music` resource, and `game/ecs/systems/playerSystem.lua` plays its `jump` effect. Those IDs and files belong to that game, not a new project.

## Playback lifecycle and ownership

Music uses the cached source itself; only one music track is current, and starting a different one stops the previous track. Effects clone their source so they can overlap. The engine's audio update releases finished clones; `stopSound` releases one early. There is no public effect pause/resume API.

The audio manager, not the requesting scene, is the resource consumer. This scene intentionally leaves music playing across scene transitions. `stopMusic` stops playback but does not release the cached resource; audio keeps its interests until `shutdown()`. On normal engine quit, scenes are destroyed, audio shuts down and releases its interests, and remaining resources are force-released.

## Errors and limitations

- Missing IDs, invalid sound definitions or unreadable files fail when playback first loads them. Use `stream` for the music and `static` for the short effect; both require a valid LÖVE audio file.
- A naturally finished track remains current. Calling `playMusic` again with the same ID does not restart it or change its loop setting; if paused it resumes. Call `stopMusic` first to restart or change looping. Looping is enabled only by `loop = true`.
- Music shares its cached source with other consumers. Do not force-release an audio resource while it is in use. Stopping or finishing an effect releases its clone, not the cached original.
- Volume is applied when a source starts: `masterVolume * musicVolume` for music and `masterVolume * sfxVolume` for effects. No volume setter or automatic update of playing sources is implemented. Direct `AudioManager.new` callers must supply all three numeric volumes.

## Further reading

[AudioManager architecture](/architecture/modules/audio-manager) · [ResourceManager architecture](/architecture/modules/resource-manager) · [AudioManager API](/api/audio-manager).
