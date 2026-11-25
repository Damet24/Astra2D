# Changelog

All notable versions of Astra 2D are documented in this file.

## [0.3.0]

### Added

- Collision categories and filters: `Collider.layer` (categories 1-16, default `{ 1 }`) and `Collider.mask` (accepted categories), applied automatically by `PhysicsFactory.create` through the new `engine.physics.collisionFilter` module. Conventional IDs are listed in `game/config/collisionLayer.lua`.
- `World:query2(compA, compB, callback)`, a two-component query that passes both component tables directly to the callback; `physicsSyncSystem` now uses it.
- `rgba` and `hexToRgb` color helpers in `engine.graphics.utils`, and `addImages` / `addSound` definition helpers in `engine.resources.utils`, with English and Spanish API pages.

### Changed

- **Breaking:** engine modules were renamed to PascalCase: `engine.graphics.RenderPipeline`, `engine.physics.PhysicsFactory`, and `engine.physics.PhysicsWorld`. Update all `require` paths.
- **Breaking:** game configuration moved to `game/config/` (`inputMaps.lua`, `resourceDefinitions.lua`, and the new `collisionLayer.lua`). Entry points now require `game.config.inputMaps` and `game.config.resourceDefinitions`.
- The CLI template follows the new configuration layout, creates scenes in `game/scenes/` by default (previously `games/scenes/`), and ships as `astra2d-cli` 1.0.5.
- Installation, first-project, input, scenes, resources, audio, physics, ECS, and reference documentation were updated in English and Spanish.

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
