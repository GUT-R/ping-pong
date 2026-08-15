# The Almighty

**The Almighty** is a compact Cython renderer for terminal-based 2D scenes. It draws colored rectangles using ANSI true-color escape sequences and keeps an incremental pixel buffer, so animations can update only the cells that changed.

It is a good fit for terminal games, visual experiments, and small real-time interfaces where a grid of colored blocks is enough.

## Features

- `Rect`: position, dimensions, palette color, velocity, and rectangle collision checks.
- `Display`: virtual canvas, indexed RGB palette, and change buffers.
- `Scene`: named rectangles with both dictionary and attribute access.
- Full-frame rendering for the first draw and incremental rendering for later frames.
- Cython implementation backed by C structs and manually managed render buffers.

## Requirements

- Python 3
- [Cython](https://cython.org/)
- `setuptools`
- A C compiler supported by your Python installation
- A terminal with ANSI cursor control and 24-bit color support

The renderer writes directly to standard output. It is intended for an interactive terminal, not a notebook or a plain text log.

## Build

From this directory:

```bash
python -m pip install Cython setuptools
python setup.py build_ext --inplace
```

This builds the `main` extension in place. In the parent project, where the extension is available as `almighty.main`, import it as shown below. If you build and run directly from this directory, use `from main import Display, Rect, Scene` instead.

## Quick start

```python
from time import sleep

from almighty.main import Display, Rect, Scene

palette = [
    (15, 23, 42),    # 0: background
    (56, 189, 248),  # 1: player
    (248, 113, 113), # 2: obstacle
]

display = Display(40, 16, background_color=0, colors=palette)
scene = Scene(display, {
    "player": Rect(color=1, x=2, y=6, w=2, h=3),
    "wall": Rect(color=2, x=28, y=3, w=3, h=10),
})

# Draw the whole scene once.
scene.print_scene()

# Move the player, then render only the changed cells.
scene.player.move(x=1)
scene.print_buffer()

sleep(1)
scene.exit()
```

Use `print_scene()` for an initial draw or a complete redraw. After that, change rectangles and call `print_buffer()` each frame. `print_buffer()` clears pixels no longer occupied by moved rectangles, draws their new pixels, and records the new state for the following frame.

## API

### `Rect`

`Rect` represents an axis-aligned, palette-colored rectangle.

```python
Rect(color, *args, **kwargs)
```

The clearest and safest form uses keywords:

```python
ball = Rect(color=1, x=20, y=8, w=1, h=1, sx=1, sy=-1)
```

| Argument | Meaning | Default |
| --- | --- | --- |
| `color` | Index into the display palette | required |
| `x`, `y` | Top-left grid position | `0`, `0` |
| `w`, `h` | Width and height in cells | `1`, `1` |
| `sx`, `sy` | Horizontal and vertical velocity multipliers | `1`, `1` |

Positional forms are supported for compact code, but keywords avoid ambiguity:

```python
Rect(1)                         # 1 × 1 rectangle
Rect(1, 3)                      # 3 × 3 rectangle
Rect(1, 3, 2)                   # 3 × 3; sx = sy = 2
Rect(1, 3, 5, 2)                # w=3, h=5; sx = sy = 2
Rect(1, 10, 4, 3, 5)            # x=10, y=4, w=3, h=5
Rect(1, 10, 4, 3, 5, 2)         # same, with sx = sy = 2
Rect(1, 10, 4, 3, 5, 2, -1)     # same, with sx=2, sy=-1
```

Methods and properties:

- `rect.x`, `rect.y`, `rect.w`, `rect.h`: current position and size.
- `rect.sx`, `rect.sy`: mutable velocity multipliers.
- `rect.set_pos(x, y)`: set an absolute position.
- `rect.sum_pos(x, y)`: add an unscaled displacement.
- `rect.move(x, y)`: add `sx * x` and `sy * y` to the position.
- `rect.set_color(index)`: change the palette color.
- `rect.collision(other) -> bool`: test overlapping area.
- `rect.border_collision(other) -> (top, bottom, left, right)`: report which outer edge(s) `other` touches.

### `Display`

`Display(w, h, background_color, colors)` defines the terminal grid and its palette.

```python
display = Display(
    w=80,
    h=24,
    background_color=0,
    colors=[(0, 0, 0), (255, 255, 255)],
)
```

Each palette entry is an `(red, green, blue)` tuple. Rectangle colors and `background_color` are indices in this list. One grid cell is output as two terminal-space characters, which makes cells appear closer to square in typical monospace terminals.

- `display.reset_buffer()`: discard pending draw and clear operations.
- `display.update_all(rects)`: update internal buffers for an iterable of rectangles. Usually `Scene.print_buffer()` handles this.
- `display.print_buffer()`: emit the buffered terminal updates.
- `display.out_vision_rect(rect) -> (horizontal, vertical)`: report whether a rectangle touches or extends beyond the horizontal and vertical display bounds.

### `Scene`

`Scene(display, rects)` binds a display to a dictionary of named rectangles.

```python
scene = Scene(display, {"hero": hero, "enemy": enemy})

scene["hero"].move(x=1)
scene.enemy.move(y=-1)
```

- `scene.print_scene()`: render a complete frame.
- `scene.print_buffer()`: render changes since the prior buffered frame.
- `scene.exit()`: release renderer buffers and reset the terminal style/cursor position.

Attribute access is a convenience for dictionary keys. Prefer `scene["key"]` if a key could conflict with a `Scene` attribute such as `display`, `rects`, or `exit`.

## Animation loop

```python
from time import sleep

scene.print_scene()
while running:
    player.move(x=1)

    if display.out_vision_rect(player)[0]:
        player.sx *= -1

    scene.print_buffer()
    sleep(1 / 30)

scene.exit()
```

Call `scene.exit()` when the application finishes. If an exception can interrupt the loop, place it in a `finally` block:

```python
try:
    scene.print_scene()
    # game or animation loop
finally:
    scene.exit()
```

## Limits and notes

- Positions are stored as unsigned 16-bit values; use positions from `0` through `65535`.
- Rectangle width and height, palette indexes, and background color are stored as unsigned 8-bit values; keep each in the range `0` through `255`.
- Velocity multipliers `sx` and `sy` are signed 8-bit values, from `-128` through `127`.
- Values outside these ranges are cast to the underlying C storage. Validate input before creating or moving objects when values may be untrusted.
- A rectangle color must refer to an entry in `colors`; keep palette indexes valid.
- `print_scene()` does not reposition the cursor before drawing. Clear or position your terminal before the first full frame if necessary.
- The library does not impose game rules such as clamping objects to the display; use `out_vision_rect()` and your own movement logic.

## Project layout

```text
almighty/
├── src/main.pyx   # Cython implementation
├── main.pyi       # public type declarations
├── setup.py       # extension build configuration
└── README.md
```
