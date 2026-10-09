# love-mcraft

A deliberately small Minecraft-like voxel sandbox for [LÖVE](https://love2d.org) 11.5.
Fly around a pre-built world, break blocks and place dirt. See [design.md](design.md) for scope.

## Run

```sh
love .                         # loads assets/worlds/test.vox
love . /path/to/world.vox      # loads any MagicaVoxel file
love . --touch                 # on-screen touch controls (the left mouse button acts as a finger)
```

| Input | Action |
|---|---|
| Mouse | Look around |
| W A S D | Fly forward / left / back / right |
| Space / Left Shift | Up / down |
| Left Ctrl (hold) | Move faster |
| Left click | Break block |
| Right click | Place dirt |
| G | Toggle fullscreen |
| Esc | Quit (in a browser: release the mouse) |

Phones and tablets use on-screen touch controls instead: Android, iOS, and touch-first devices in a browser.
Everything else uses mouse & keyboard. The mode is fixed for the session.

| Touch | Action |
|---|---|
| Drag on the left half | Move (joystick appears under your thumb) |
| Drag on the right half | Look around |
| Up / Down (hold) | Fly up / down |
| Break / Place (tap) | Break block / place dirt at the crosshair |
| Top-right button (tap) | Toggle fullscreen (browser; native Android/iOS are always fullscreen) |

Edits live in memory only; the world file is never written.

## Web build

The game also runs in the browser via [love.js](https://github.com/Davidobot/love.js) (LÖVE 11.4 compiled to WebAssembly):

```sh
tools/build_web.sh                     # writes a static site to build/web (needs node + zip)
python3 -m http.server -d build/web    # then open http://localhost:8000
```

To host it on GitHub Pages, push to `master` and set **Settings → Pages → Source** to **GitHub Actions**;
`.github/workflows/pages.yml` builds and deploys it. Alternatively, upload the contents of `build/web` to any static host.

The build uses a [fork of love.js](https://github.com/cptobakhmut925-glitch/love.js) compiled with WebGL 2 support,
which the renderer needs for array textures.
Browser differences: Esc releases the mouse instead of quitting; worlds can only be loaded from the bundled `assets/`.

## Editing the world

Worlds are [MagicaVoxel `.vox`](https://github.com/ephtracy/voxel-model/blob/master/MagicaVoxel-file-format-vox.txt)
files. Edit them with [Goxel](https://goxel.xyz) (open source) or MagicaVoxel. Z is up.

In Goxel, `.vox` is an import/export format, not a native one:

- Open: `goxel assets/worlds/test.vox`, or **File → Import → MagicaVoxel (.vox)**
- Save: **File → Export → MagicaVoxel (.vox)** (plain *Save* writes Goxel's own `.gox` format)

Block types come from voxel **colors**: each voxel becomes the block with the nearest reference color.

| Block | Paint with RGB |
|---|---|
| Stone | 125, 125, 125 |
| Dirt | 121, 85, 58 |
| Grass | 95, 159, 53 |

Only the first model in the file is loaded, and it must fit in 256×256×256.
To regenerate the bundled test world: `luajit tools/make_test_world.lua`.

## Development

```sh
luajit tests/run.lua    # unit tests (pure Lua, no LÖVE needed)
luacheck .              # lint, if luacheck is installed
tools/check_types.sh    # type check with lua-language-server (set $LUALS if it's not on PATH)
```

Type annotations use [LuaCATS](https://luals.github.io/wiki/annotations/) (`--- @param`, `--- @return`);
every lua-language-server diagnostic enabled in `.luarc.json` is an error, and CI (`.github/workflows/check.yml`) fails on any.

| Path | Purpose |
|---|---|
| `main.lua` | Loads the world; wires camera, renderer, input and HUD together |
| `src/vox.lua` | `.vox` parser |
| `src/world.lua` | Fixed-size block grid |
| `src/blocks.lua` | Block types, textures, color mapping |
| `src/mesher.lua` | Builds chunk meshes with hidden-face culling |
| `src/renderer.lua` | Shader, array texture, chunk mesh cache |
| `src/camera.lua` | Free-flying camera |
| `src/math/` | `Vec3` (positions, directions), `Extent3` (grid sizes), `Mat4` (matrices) |
| `src/raycast.lua` | Voxel ray traversal for block picking |
| `src/input.lua` | Mouse & keyboard or touch input; turns LÖVE events into per-frame movement, look and actions |
| `src/touch_controls.lua` | Touch gestures: floating joystick, look drag, held buttons |
| `src/hud.lua` | Crosshair, touch joystick and buttons: layout, hit testing, drawing |
| `src/config.lua` | Tunables and key bindings |
| `tools/` | Test-world generator, `.vox` writer, web build (`build_web.sh`, `web/index.html`, icons) |

## Credits

Block textures: [Kenney Voxel Pack](https://kenney.nl/assets/voxel-pack), CC0 — see
`assets/textures/LICENSE-kenney.txt`. The web favicon is rendered from the same textures.
