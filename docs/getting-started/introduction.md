# Introduction

Astra 2D is a modular 2D game engine built with Lua and [LÖVE](https://love2d.org/).
It provides the structure for scenes, entities, resources, input, audio, cameras,
and tilemaps, while leaving the rules of your game in your own code.

If you are new to Astra 2D, this page explains what the engine offers and how its
pieces fit together. The [Installation](/getting-started/installation) page gets
the sample project running, and [Your First Project](/getting-started/first-project)
walks you through creating a small game from scratch.

## What Astra 2D provides

- **Scenes with a managed lifecycle.** Scenes are stacked, replaced, and cleared
  through a `SceneManager`, with `onLoad`, `onEnter`, `onExit`, and `onDestroy`
  callbacks.
- **An Entity Component System (ECS).** Entities are plain identifiers, while
  components and systems hold the data and behavior of your game.
- **Centralized resources.** Images, sounds, and fonts are loaded on demand and
  released when their consumers no longer need them.
- **Action-based input.** Define named actions such as `jump` or `move_left`
  once, then query them from any scene.
- **Scene cameras.** Each scene can create its own camera manager and active
  camera, with support for multiple viewports.
- **Audio management.** Music and sound effects share the resource manager and
  support separate master, music, and sound-effect volumes.
- **Tilemap rendering.** Tiled maps and tilesets can be rendered through the
  render pipeline.
- **Physics.** The ECS integrates LÖVE's physics module through a set of physics
  and collision systems.

## How the engine is organized

The repository separates the engine from the game that uses it:

```text
engine/   Engine modules and third-party libraries in engine/lib
game/     The example game: scenes, resources, input maps, and assets
main.lua  Entry point that creates the engine and forwards LÖVE callbacks
```

Your game keeps its own scenes, resource definitions, input maps, and assets.
The engine only needs to know where those live.

## Core concepts

| Concept | Responsibility |
| --- | --- |
| `Engine` | Creates managers and, when loaded, optionally configures the window, sets up the viewport, and loads the initial scene. |
| `GameContext` | Passes shared services, such as the resource, scene, input, and audio managers, to scenes. |
| `SceneManager` | Maintains the scene stack and processes transitions. |
| `Scene` | Coordinates one self-contained part of the game, such as a menu or level. |
| `World` | Stores entities, components, and systems for a scene. |
| `ResourceManager` | Loads resources on demand and releases them when unused. |
| `InputManager` | Maps keys to named actions and exposes their state. |
| `AudioManager` | Plays music and sound effects through the resource manager. |
| `CameraManager` | Creates and selects the cameras used by a scene. |

Scenes receive a `GameContext`, not the engine itself. This keeps scenes focused
on game behavior and lets the engine control how services are created.

## The frame lifecycle

Astra 2D does not replace LÖVE's main loop. Your `main.lua` creates an `Engine` and forwards the LÖVE callbacks to it. For a complete entry point and scene, see [Your First Project](/getting-started/first-project).

At startup, `Engine:load()` optionally configures the window, sets up the
logical-resolution viewport, and pushes the initial scene.

During each frame, `Engine:update(dt)` updates the selected scenes, processes
pending transitions, updates audio, and clears transient input state. Then
`Engine:draw()` draws the scene stack inside the virtual-resolution viewport.

On shutdown, `Engine:quit()` clears the scenes, stops audio, and releases
remaining resources.

The engine is built around a few principles:

- Systems have a single, clear responsibility.
- The engine provides mechanisms; your game defines its own rules.
- Scenes stay independent of the scene manager implementation.
- Resources are shared and released centrally.
- Features are added only when the game actually needs them.

## Next steps

1. [Install Astra 2D and run the sample project](/getting-started/installation).
2. [Create your first project](/getting-started/first-project) with a scene,
   input, and movement.
3. Read the [architecture overview](/architecture/overview) to learn how the
   engine modules interact.
