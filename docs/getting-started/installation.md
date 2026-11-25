# Installation

Astra 2D runs as Lua source inside a [LÖVE](https://love2d.org/) game. This repository does not provide a package installation step.

## Requirements

- **LÖVE 11.5**, the version used for this guide. Other versions have not been verified here. Install it from [love2d.org](https://love2d.org/) and make sure the `love` command is available, or use the path to your LÖVE executable.
- **The repository source**, including `engine/lib/` and, for the sample, `game/` and its assets. Git is optional if you download the repository as an archive.

LÖVE includes the Lua runtime. The engine's Lua libraries are bundled in `engine/lib/`; no separate Lua installation or package manager is needed for the examples.

## Run the sample project

Clone the repository and run LÖVE with the repository root as the game source:

```sh
git clone https://github.com/Damet24/Astra2D.git
cd Astra2D
love .
```

Documentation and code should come from the same revision: the branch tip can change, and the documentation you are reading may not yet be published on the remote branch. Use the revision corresponding to your documentation, whether using a checkout or downloading an archive; do not assume a fresh clone already contains these pages. An existing checkout can be inspected with `git rev-parse HEAD`.

On Windows you can instead drag the project folder onto the LÖVE executable. If `love` is not on your `PATH`, invoke the installed executable with the project directory as its argument.

The current `main.lua` starts in `mainMenu`. The bindings in `game/config/inputMaps.lua` use the left and right arrows (or the d-pad and left stick) to move, `Space` or gamepad `A` to jump, and `Escape` or gamepad `Start` to pause. `Return`, `Space`, a left click, or gamepad `A` accepts menu entries.

## Use the engine in another project

Copy the complete `engine/` directory, including `engine/lib/`, into the **game source directory** alongside `main.lua`. Keep the name `engine`: its modules import one another using the `engine.` prefix. LÖVE's virtual filesystem must be able to read those files; a sibling directory outside the game source or a local Lua search path is not a portable installation.

The smallest layout used in [Your First Project](/getting-started/first-project) is:

```text
my-game/                  # LÖVE game source
  main.lua
  engine/                 # complete copy, including engine/lib/
  game/
    config/
      inputMaps.lua
    scenes/
      hello.lua
```

The guide provides every file needed for this layout. A resource definitions file is optional; the example does not need assets. Run `love .` from `my-game/`, or pass that directory to LÖVE from elsewhere.

## Engine configuration

`Engine.new(config)` constructs the services; it does not load the scene. The required fields are `initialScene`, a non-empty string, and `inputMaps`, a table of actions (which can be `{}`; the engine forwards it without validating the action shapes). The remaining fields are optional:

| Field | Default and behavior |
| --- | --- |
| `scenesPath` | `"game.scenes"`; a non-empty Lua module prefix. |
| `resourceDefinitions` | `{}`; definitions keyed by resource ID. |
| `resourceLoaders` | Built-in loaders for `image`, `sound`, and `font`; a supplied table replaces the defaults. |
| `window` | If omitted, the engine leaves LÖVE's window mode unchanged. If supplied, positive integer `width` and `height` are required; `fullscreen = false`, `resizable = true`, and `vsync = true` by default. |
| `rendering` | Logical `width = 1280`, `height = 720`, `pixelPerfect = false`, `backgroundColor = { 0, 0, 0, 1 }` by default. Dimensions are positive integers. |
| `audio` | `masterVolume`, `musicVolume`, and `sfxVolume` each default to `1.0`. |

`backgroundColor` is a contiguous RGB or RGBA array with components from `0` to `1`; omitted alpha is `1`. `pixelPerfect = true` uses integer scaling and nearest filtering; a window smaller than the logical resolution can be cropped. See the [Engine architecture](/architecture/modules/engine) for validation and lifecycle details.

With the default `scenesPath`, `initialScene = "hello"` loads `game/scenes/hello.lua`; `levels.level01` loads `game/scenes/levels/level01.lua`. The module must return a table with a `new(context)` function returning a scene with the lifecycle methods used by `SceneManager`. The [first project](/getting-started/first-project) supplies a complete example; the engine installs the LÖVE input callbacks when the game calls `Engine:load()`.

## Package the game

A `.love` file is a ZIP archive whose **root** contains `main.lua`, `engine/`, and the game files—not an enclosing `my-game/` folder. Use a new filename for each build: updating an existing ZIP can retain entries deleted from the source. For example, from `my-game/` with the `zip` command available:

```sh
if [ -e my-game.love ] || [ -L my-game.love ]; then
    printf '%s\n' 'my-game.love already exists; choose a new filename.' >&2
else
    zip -r my-game.love main.lua engine game && love my-game.love
fi
```

The check also rejects dangling symbolic links. If the name is taken, choose a different filename in both commands; this example does not delete or overwrite the existing path.

Include any other files the game uses (for example `conf.lua` or assets) at their correct paths. Do not rely on an `engine/` directory outside the archive. See LÖVE's [game distribution guide](https://love2d.org/wiki/Game_Distribution) for platform-specific packaging.

## Licenses

Astra 2D's own code is distributed under the MIT license in the repository's root `LICENSE`. Bundled libraries have their own notices, including `engine/lib/shove/LICENSE` and the notice in `engine/lib/hump/camera.lua`; retain and follow applicable third-party terms. Verify the permissions for third-party assets before redistributing them.

## Troubleshooting

- **`module 'engine.engine' not found`:** pass LÖVE the directory or `.love` archive containing both `main.lua` and `engine/`; preserve `engine/lib/`.
- **Input queries fail:** pass `inputMaps` to `Engine.new`, even if it is `{}`. The engine forwards the table without validating it; each action is a table with optional `keys`, `mouse`, and `gamepad` sections, and unknown action names return `false`.
- **`Failed to load scene '...'`:** check the `scenesPath` prefix, scene identifier, exact filename and capitalization, and that its module returns a table with `new`. The error may also contain an error from inside the scene module.
- **Window creation fails:** check the requested mode and graphical environment. Headless systems need a suitable offscreen graphics backend; a normal window is not available there.

## Next steps

Continue with [Your First Project](/getting-started/first-project) to build a complete scene with input and movement.
