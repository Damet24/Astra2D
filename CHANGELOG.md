# Changelog

All notable versions of Astra 2D are documented in this file.

## [0.2.0] - 2026-11-18

### Added

- Mouse input: buttons with held, pressed, and released state, plus position and per-frame delta (`getMousePosition`, `getMouseDelta`, `isMouseDown`, `isMouseJustPressed`, `isMouseJustReleased`).
- Gamepad input: buttons and axes with a `0.5` threshold; only the first connected gamepad is tracked.
- `gamepad_connected` and `gamepad_disconnected` events with `{ joystick, name }`.
- `context.events` exposes the engine's `EventManager`.
- `astra2d` CLI with the `init` and `scene:create` commands, and a bundled engine copy as an offline fallback.

### Changed

- **Breaking:** input maps are now per-device tables (`keys`, `mouse`, `gamepad`, and `gamepad.axes`) instead of flat key arrays.
- `InputManager.new(inputMaps, events)` takes the event manager and no longer validates maps; unknown actions return `false`.
- `Engine:load()` installs the LÖVE input callbacks; `main.lua` only forwards `load`, `update`, `draw`, and `quit`.
- `Engine:update` order: event dispatch, axis edges, scenes, audio, and final input cleanup.
- The CLI project template and `examples/collect` use the new input format.
- English and Spanish documentation updated for the new input system.

### Fixed

- Documentation deployment on version tags (`on.push.tags`).

### Removed

- Manual forwarding of `love.keypressed` and `love.keyreleased` in templates, examples, and documentation.
