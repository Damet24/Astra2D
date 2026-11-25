# Architecture Overview

Astra 2D is organized as a small set of independent modules that are wired
together by a single `Engine` object. The engine provides the mechanisms (the frame loop, the scene stack, resource management, input, audio, and rendering), while each scene manages its own cameras and world.

This page explains how the modules relate to each other. It documents what the
engine actually does today, so the module reference and the guides can build on a
shared mental model.

## The engine at a glance

At the top, `main.lua` creates one `Engine` and forwards LÖVE's callbacks to it.
The engine constructs the shared services, loads scenes through the scene
manager. Game scenes coordinate their own behavior and may create a `World`,
cameras, and rendering components as needed.

```text
                          main.lua
     forwards LÖVE load / update / draw / quit
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│ Engine                                                             │
│   frame lifecycle · window · viewport (Shove)                      │
│                                                                    │
│   owns ──▶ ResourceManager   GameContext   SceneLoader             │
│            SceneManager      AudioManager  InputManager            │
└──────────────────────────────┬────────────────────────────────────┘
                               │ Engine:load() pushes the initial scene
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneManager               stack of { id, scene }                  │
│   push · pop · replace · clear · clearAndPush   (deferred)         │
└──────────────────────────────┬────────────────────────────────────┘
                               │ loads through
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneLoader        scenesPath .. "." .. sceneName  →  Scene.new()  │
└──────────────────────────────┬────────────────────────────────────┘
                               │ builds
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ Scene                  lifecycle + one part of the game            │
│   may use ──▶ World (ECS + physics)   CameraManager                │
│               RenderPipeline          TilemapRender                │
└───────────────────────────────────────────────────────────────────┘

Shared services reachable from a scene through its GameContext:
  GameContext ──▶ resourceManager · audioManager · sceneManager
                  inputManager · viewport
  ResourceManager ── shared by ──▶ AudioManager and Scenes (consumers)
```

Two ideas make the rest of the architecture easier to follow:

- **The engine builds, the game describes.** `Engine.new(config)` receives
  descriptions (an initial scene, resource definitions, input maps, resolutions)
  and turns them into live objects. Scenes use these shared services through the
  context, while they can create their own worlds and cameras.
- **Scenes see a `GameContext`, not the engine.** Everything a scene needs is
  handed to it through the context, which keeps scenes decoupled from how the
  engine is assembled.

## The frame lifecycle

Astra 2D does not replace LÖVE's main loop. `main.lua` forwards the lifecycle callbacks, and each one maps to an engine method:

| LÖVE callback | Engine method | What happens |
| --- | --- | --- |
| `love.load` | `Engine:load()` | Applies window settings and the background color, creates the viewport, pushes `initialScene`, processes the pending transition, and installs the input callbacks. |
| `love.update(dt)` | `Engine:update(dt)` | Dispatches events, updates gamepad axis edges, updates the scene stack, then audio, then clears transient input state and mouse delta. |
| `love.draw` | `Engine:draw()` | Draws the scene stack inside the virtual-resolution viewport. |
| `love.quit` | `Engine:quit()` | Destroys the scene stack, stops audio, and releases all resources. |

During `Engine:load()`, the engine also installs its own handlers for `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `mousemoved`, `gamepadpressed`, `gamepadreleased`, `gamepadaxis`, `joystickadded`, and `joystickremoved`. Games do not forward those events; each handler calls the matching engine method, which updates the `InputManager`.

The order inside `Engine:update` is significant:

1. `EventManager:dispatch()` delivers queued events, including gamepad connections.
2. `InputManager:update()` recomputes gamepad axis states and their press/release edges.
3. `SceneManager:update(dt)` updates the active scenes and, at the end,
   processes the transitions requested during the frame.
4. `AudioManager:update(dt)` releases sounds that finished playing.
5. `InputManager:reset()` clears the "just pressed" and "just released" state
   and the mouse delta after the scenes have read them.

Input is cleared last on purpose: a scene reads `isJustPressed` while it runs,
and the flag is discarded only after the selected scenes have had the chance to react. Gamepad axes are already resolved before the scene update, so an axis binding reports its edges in the same frame.

On shutdown, `Engine:quit()` queues a scene stack clear and processes pending
scene operations. Operations already in the queue run before the clear. The
clear calls `onExit` only on the top scene, then calls `onDestroy` on every
scene from top to bottom. Afterward, the engine shuts down audio and releases
any remaining resources.

These phases are not protected against errors: if one fails, later phases are
not guaranteed to run.

## Module guides

The following pages describe each module’s responsibilities, configuration,
interfaces, and relationships. The separate [API reference](/api/) provides
method details for quick lookup.

| Module | Role |
| --- | --- |
| [Engine](modules/engine.md) | Assembles services and drives the LÖVE lifecycle. |
| [GameContext](modules/game-context.md) | Gives scenes access to shared services. |
| [SceneManager](modules/scene-manager.md) | Manages the scene stack and deferred transitions. |
| [SceneLoader](modules/scene-loader.md) | Constructs scene instances from module names. |
| [Scene](modules/scene.md) | Defines scene lifecycle and update/draw policies. |
| [World](modules/world.md) | Holds ECS state, systems, events, and physics. |
| [ResourceManager](modules/resource-manager.md) | Loads and shares resources among consumers. |
| [InputManager](modules/input-manager.md) | Maps keyboard, mouse, and gamepad actions to named actions. |
| [AudioManager](modules/audio-manager.md) | Coordinates music and sound effects. |
| [CameraManager](modules/camera-manager.md) | Manages scene cameras and world views. |
| [Rendering](modules/rendering.md) | Connects the viewport, camera, pipeline, and renderers. |

## How the modules work together

- **Deferred transitions.** Scenes never mutate the stack directly. They call
  `sceneManager:push/pop/replace/...`, and the `SceneManager` applies the
  requests at the end of the scene update. This keeps the running scene intact
  while it finishes its frame.
- **Consumers share resources.** `ResourceManager` is the only place resources
  are loaded. Scenes and the `AudioManager` are consumers; a resource stays
  loaded while any consumer needs it and is released when the last one lets go.
- **Update and draw are separate policies.** `updateBelow` and `drawBelow`
  decide, per scene, whether the scenes underneath keep simulating or keep
  rendering. A pause menu can draw the level beneath it while stopping its
  simulation, and a scene can be updated without being drawn.
- **One coordinate chain.** Physical window → logical viewport → camera world →
  pipeline. Conversions happen only at the boundaries:
  `screenToViewport` (physical → logical) and `worldCoords` (logical → world).

## Where the game plugs in

Your game provides descriptions and content; the engine provides the mechanisms.

| Your game provides | The engine turns it into |
| --- | --- |
| `initialScene` | The first scene pushed onto the stack. |
| `scenesPath` | The module prefix used to load scenes (default `game.scenes`). |
| `resourceDefinitions` / `resourceLoaders` | The definitions and loaders used by the `ResourceManager`. |
| `inputMaps` | The action table used by the `InputManager`, including keyboard, mouse, and gamepad bindings. |
| `window` / `rendering` / `audio` | Window mode, logical resolution, background, and volumes. |
| Scene modules | Instances created by the `SceneLoader` and driven by the `SceneManager`. |
| Worlds, systems, cameras, pipelines | Created by scenes as needed, commonly in `onLoad`. |

## Design notes

`engine/scenes.md` is a design document that describes the intended direction of
the scene system. Some of its ideas are not implemented yet, including a
`SceneRegistry`/`SceneFactory`, transition rules owned by the game, source-context
validation for pending requests, and a `GameState`. Where this page and that
document disagree, this page describes the current implementation.

The [GameContext guide](modules/game-context.md) explains how shared services
are assembled and passed to scenes.

## Next steps

- [Introduction](/getting-started/introduction) for the core concepts.
- [Your First Project](/getting-started/first-project) to build a scene with
  input, movement, and a resource.
- The [module guides](#module-guides) for the architecture and interfaces of each module.
