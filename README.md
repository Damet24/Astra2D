# Astra 2D

Astra 2D is a modular engine for building 2D games with Lua and [LÖVE](https://love2d.org/). It provides tools to organize scenes, entities, resources, and rendering, while each game defines its own rules and content in its scenes and systems.

The repository includes the engine source in `engine/`, a demo game in `game/`, and a standalone example in `examples/collect/`.

## Features

- **Scenes:** scene stack, deferred transitions, and lifecycle callbacks.
- **Entities and systems (ECS):** components, queries, ordered systems, and events.
- **Resources:** loading, reuse, and per-consumer release of images, sounds, and fonts.
- **Input:** configurable actions for the keyboard, mouse, and gamepad (buttons and axes), with held, pressed, and released state queries.
- **Audio:** music and sound-effect playback through a shared manager.
- **Cameras and rendering:** world views, logical resolution, scaling, and layered drawing.
- **Physics:** `love.physics` integration through bodies, rectangular colliders, and ECS systems.
- **Tiled maps:** rendering of tile layers exported to Lua; collisions are created separately.

## Requirements

- [LÖVE 11.5](https://love2d.org/), the version used in the project's documentation and tests. Other versions have not been verified.
- The repository source, including `engine/lib/` and, to run the demo game, the `game/` directory with its assets.
- [Tiled](https://www.mapeditor.org/) is optional for editing maps. Node.js and npm are required to develop or build the documentation site; they are not needed to run the game.

LÖVE bundles the Lua runtime, so no separate Lua installation is needed to run the examples.

## Run the demo game

From the root of a repository checkout:

```sh
love .
```

If `love` is not on your `PATH`, run the installed LÖVE executable and pass it the repository folder. The current `main.lua` starts in `levels.level01`.

Demo controls: the left and right arrows (or the d-pad and left stick) move, **Space** or gamepad **A** jumps, and **Esc** or gamepad **Start** pauses. To run the standalone Collect example, see its [instructions](docs/examples/index.md).

To use the engine in another LÖVE project, copy the complete `engine/` directory, including `engine/lib/`, into the game source directory next to its `main.lua`. The [Your First Project](docs/getting-started/first-project.md) guide shows a complete setup and scene.

## Documentation

The full documentation is published on [GitHub Pages](https://damet24.github.io/Astra2D/); it is also available in [Spanish](https://damet24.github.io/Astra2D/es/). The site sources live in `docs/`.

- [Installation](docs/getting-started/installation.md)
- [Your First Project](docs/getting-started/first-project.md)
- [Architecture](docs/architecture/overview.md)
- [Guides](docs/guides/index.md)
- [API reference](docs/api/index.md)
- [Examples](docs/examples/index.md)

## Licenses and credits

Astra 2D's own code is released under the [MIT license](LICENSE).

The camera uses [HUMP](https://github.com/vrld/hump) by Matthias Richter through an adapter; its copyright and license notice is in `engine/lib/hump/camera.lua`. The viewport uses Shove, whose license is in `engine/lib/shove/LICENSE`. Third-party libraries and assets may have their own terms: keep their notices and verify asset permissions before redistributing them.
