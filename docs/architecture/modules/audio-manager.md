# AudioManager

[Architecture overview](/architecture/overview) · [ResourceManager](./resource-manager) · [InputManager](./input-manager)

## Purpose and relationships

`engine/audio/audioManager.lua` plays one current music track and overlapping sound effects. `Engine` creates it with the shared `ResourceManager`, exposes it as `context.audioManager`, calls `update(dt)` after scene updates and calls `shutdown()` on quit. Scenes and systems can request audio; for example, `PlayerSystem` receives the manager directly. AudioManager itself is the resource consumer, independent of the scene that requested a sound.

## Configuration and sound resources

`AudioManager.new(config)` requires `config.resourceManager`. It copies `masterVolume`, `musicVolume` and `sfxVolume` from the configuration. When constructed by `Engine.new`, these come from `audio` and each defaults to `1.0`; direct construction supplies no volume defaults, so provide numbers for all three. No volume validation, clamping or volume-setting API is implemented. A new music source receives `masterVolume * musicVolume`; a new effect clone receives `masterVolume * sfxVolume`. Changing these fields does not update sources already playing.

Resource IDs must resolve to compatible LÖVE audio sources. The default sound loader requires a string `path` and `soundType = "static"` or `"stream"`. In `game/config/resourceDefinitions.lua`, `music` uses `stream`, while `jump` uses `static`. `playMusic(id, { loop = true })` enables looping only when `loop` is exactly `true`; omitted or other values mean no loop when starting a new track.

## Public API

| Method | Behavior |
| --- | --- |
| `AudioManager.new(config)` | Creates a manager with the required resource manager and volume fields. |
| `playMusic(resourceId, config)` | Gets the shared source, stops any different current track and starts this one. If the ID is already current, resumes it if paused; otherwise does nothing. Returns no sound ID. |
| `stopMusic()` | Stops and forgets the current track; no-op if none. |
| `pauseMusic()` / `resumeMusic()` | Pause or resume the current track; no-op when the operation does not apply. |
| `isMusicPlaying()` | True only if a current track exists, is not marked paused and its source reports playing. |
| `isMusicPaused()` | True if the current track is marked paused. |
| `getCurrentMusic()` | Returns the current resource ID or `nil`. |
| `playSound(resourceId)` | Clones the cached source, starts the clone and returns a monotonically increasing numeric `soundId`. |
| `stopSound(soundId)` | Stops and releases that clone; ignores unknown IDs. |
| `isSoundPlaying(soundId)` | True if the known clone is not marked paused and reports playing; false for unknown IDs. |
| `update(dt)` | Releases and removes finished, non-paused effect clones; `dt` is currently unused. |
| `shutdown()` | Stops music, stops and releases all active effect clones, and calls `resourceManager:releaseAll(self)`. |

## Playback and ownership

- Music uses the cached source itself, not a clone. Its playback state, looping and volume are therefore shared with anyone else using that source. Effects use separate clones, so instances can overlap; there is no public effect pause/resume API.
- Stopping music or an effect, switching tracks, and cleaning up finished effects do **not** release AudioManager's interest in the cached resource. All resource IDs it requested remain registered until `shutdown()` (or explicit external resource-manager release). A clone is released on `stopSound`, cleanup or shutdown; the original is released by its loader only after the last resource consumer releases it.
- A naturally finished music track remains `currentMusic`: `isMusicPlaying()` is false, but `getCurrentMusic()` still returns its ID. Calling `playMusic` with that same ID does not restart it or apply new loop settings, unless it was marked paused (in which case it resumes). Call `stopMusic()` first to start it again or change its loop setting.
- `playMusic` obtains the new resource before stopping the previous track. Missing IDs, missing loaders and loader errors propagate. Forced resource releases can invalidate sources that audio is still using; shut down audio before forcing resource cleanup.

## Example

The main menu starts the defined music with looping; the player system plays the defined jump effect:

```lua
self.context.audioManager:playMusic("music", { loop = true })
local soundId = self.context.audioManager:playSound("jump")
-- Optionally: self.context.audioManager:stopSound(soundId)
```

`game/scenes/levels/level.lua` instead calls `playMusic("music")` without looping. The engine cleans up finished effects each frame; its quit sequence clears scenes, shuts down audio and then forces release of remaining resources. An error in an earlier phase can prevent later cleanup.
