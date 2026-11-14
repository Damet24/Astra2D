# Examples

## Collect

A small top-down collection game: move around a larger field, collect the three yellow dots, and restart when finished. It uses Astra2D's `Engine`, scene stack, input actions, ECS entities and movement system, following camera, and resource-managed font. The pause scene draws over the field while stopping its updates. Everything is drawn with LÖVE primitives; no external assets are needed.

Source: `examples/collect/`. The source directory alone is **not** a runnable LÖVE project: LÖVE must also find `engine/` inside its source filesystem. The runner below assembles both in a temporary project, without changing or permanently copying the engine in the repository.

### Run on Linux or macOS

Install LÖVE 11.5 and make `love` available on your `PATH`. From the repository root:

```sh
sh examples/run.sh collect
```

To use a particular executable, set `LOVE_BIN` to its path. For example, on Linux with an AppImage that cannot mount itself:

```sh
APPIMAGE_EXTRACT_AND_RUN=1 LOVE_BIN=/path/to/love.AppImage sh examples/run.sh collect
```

The POSIX shell runner also works from another working directory when given the path to `examples/run.sh`. It requires `mktemp` and `cp`; it creates a fresh directory under `TMPDIR` (or `/tmp`) and removes only that directory when LÖVE exits. Set `LOVE_BIN` similarly on macOS if LÖVE is not on `PATH`.

### Controls

- **WASD** or **arrow keys**: move (diagonal speed is limited).
- **Esc**: pause or resume.
- **R**: restart the field, when not paused.
- Close the window to quit.

### Manual project or `.love` package

Alternatively, from the repository root, create a **new** directory named `my-astra-collect` (the command stops if it already exists), copy the engine and example into it, and run it:

```sh
mkdir my-astra-collect && cp -R engine my-astra-collect/engine && cp -R examples/collect/. my-astra-collect/ && love my-astra-collect
```

To create a distributable archive, with the `zip` utility installed, use a new filename (this command refuses an existing file or symlink):

```sh
[ ! -e collect.love ] && [ ! -L collect.love ] && (cd my-astra-collect && zip -r ../collect.love .) && love collect.love
```

`main.lua`, `conf.lua`, `scenes/`, and `engine/` must be at the archive root, not inside an extra parent directory. On Windows, create a new folder using a file manager, copy the contents of `examples/collect/` and the `engine/` folder into it, and drag the folder onto LÖVE. To package it, zip those contents and rename the archive with a `.love` extension. Only remove the manual directory or archive if you no longer need them.

### Headless smoke test

The smoke test drives movement, all three pickups, pause/resume, drawing, restart, and resource cleanup, then exits automatically with status 0 on success or nonzero on failure. On Linux, with an SDL build supporting the `offscreen` video driver and software OpenGL:

```sh
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy LIBGL_ALWAYS_SOFTWARE=1 sh examples/smoke.sh
```

Set `LOVE_BIN` and, for an AppImage if needed, `APPIMAGE_EXTRACT_AND_RUN=1` as above. The example disables audio and the test needs no display server. For an external time limit on Linux, run:

```sh
timeout 60s env SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy LIBGL_ALWAYS_SOFTWARE=1 sh examples/smoke.sh
```

On macOS, GNU coreutils provides `gtimeout` instead of `timeout`. Offscreen support depends on the local SDL/OpenGL installation.
