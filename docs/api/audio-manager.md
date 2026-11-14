# AudioManager API

Module: `require("engine.audio.audioManager")`. Plays one current music source and overlapping effect clones. See [architecture](../architecture/modules/audio-manager.md), the [audio guide](../guides/audio.md) and [first project](../getting-started/first-project.md).

## Configuration and dependencies

`AudioManager.new(config)` returns a manager; `config` is an optional table but must contain a truthy `resourceManager` or an assertion fails. It copies `masterVolume`, `musicVolume` and `sfxVolume` without defaults or validation. Direct callers must supply numbers for playback; [Engine](engine.md) defaults each to `1.0`. New music uses `masterVolume * musicVolume`; new effects use `masterVolume * sfxVolume`. Changing fields does not update existing sources.

Resource IDs must resolve through [ResourceManager](resource-manager.md) to compatible LÖVE sources. The default sound loader requires a string `path` and `soundType = "static"` or `"stream"`. Loading and LÖVE source errors propagate.

## Methods

`resourceId` is a resource definition key; `soundId` is the numeric instance ID returned by `playSound`. Unless a result is stated, methods return **no values**.

| Signature | Result and effects |
| --- | --- |
| `audio:playMusic(resourceId, config)` | Gets the cached source before stopping a different current track, then sets looping and volume and plays it. Optional `config.loop` enables looping only when exactly `true`. If the ID is already current, resumes if marked paused; otherwise does nothing, including ignoring new loop settings. |
| `audio:playSound(resourceId)` | Clones the cached source, sets volume, plays it and returns a monotonically increasing numeric `soundId`. |
| `audio:stopMusic()` | Stops and forgets current music; no-op if none. |
| `audio:stopSound(soundId)` | Stops and releases the clone; unknown IDs are ignored. |
| `audio:pauseMusic()` / `audio:resumeMusic()` | Pause or resume current music; no-op if inapplicable. |
| `audio:isMusicPlaying()` | Boolean: current music exists, is not marked paused and its source reports playing. |
| `audio:isSoundPlaying(soundId)` | Boolean: the known clone is not marked paused and reports playing; false for unknown IDs. |
| `audio:isMusicPaused()` | Boolean: current music exists and is marked paused. |
| `audio:getCurrentMusic()` | Current resource ID or `nil`. |
| `audio:update(dt)` | Releases and removes finished, non-paused effect clones; `dt` (elapsed seconds) is currently unused. |
| `audio:shutdown()` | Stops music, stops and releases all effect clones, and releases this manager's interests via `resourceManager:releaseAll(self)`. |

## Ownership and cleanup

Music uses the cached source itself, so playback state, volume and looping are shared; effects use clones and can overlap. There is no public effect pause/resume API. Effect clones are released by `stopSound`, a later `update` after completion, or `shutdown`. Stopping or switching music and cleaning effects do **not** release the manager's cached-resource interests; these remain until `shutdown` or an external resource-manager release. Original resources are released only after the last consumer lets go, unless forcibly released.

A naturally finished track remains current: `isMusicPlaying()` is false and `getCurrentMusic()` still returns its ID. Calling `playMusic` with that ID does not restart it; call `stopMusic()` first to restart or change looping. Forced resource release can invalidate sources in use. Engine updates audio after scenes and shuts it down after clearing scenes but before forced resource release; errors can interrupt this sequence.

## Example

```lua
-- With the repository's resource definitions:
self.context.audioManager:playMusic("music", { loop = true })
local soundId = self.context.audioManager:playSound("jump")
-- Optionally: self.context.audioManager:stopSound(soundId)
```
