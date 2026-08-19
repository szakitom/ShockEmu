# ShockEmu

Use a keyboard, mouse, or trackpad to play PS4/PS5 **Remote Play** on a Mac, by
presenting an emulated DualShock 4 to the Remote Play app and translating your
input according to a mapping file you control.

Originally by [daeken](https://github.com/daeken) and
[suzukiplan](https://github.com/suzukiplan/gamepad-osx); this fork updates it to
run on current macOS (Apple Silicon, hardened runtime) and adds a proper
mouse/trackpad look implementation with two aiming modes.

> **Scope:** works on macOS with `/Applications/RemotePlay.app` installed. The
> mouse-look and gyro features are what this fork focuses on.

---

## How it works

Remote Play is launched with a small library injected into it
(`iohid_wrap.dylib`). That library does two things:

1. **Emulates a DualShock 4** by intercepting the IOHID calls Remote Play makes
   to enumerate and read a controller, feeding it synthesized controller
   reports instead of a real device.
2. **Captures your keyboard and mouse** inside the Remote Play window and turns
   them into button presses, stick movement, or gyro motion according to your
   `.se` mapping file.

A helper process, `gpad-daemon`, is also started so a _real_ physical gamepad
can be passed through at the same time if you have one.

### Why the app has to be re-signed

Remote Play ships with the macOS **hardened runtime**, which makes the system
strip `DYLD_INSERT_LIBRARIES` at launch — so injection is silently ignored. To
work around this **without touching Apple's/Sony's installed copy**,
`resign.sh` makes a **local copy** of the app and re-signs _that_ copy ad-hoc
with entitlements that permit injection. `/Applications/RemotePlay.app` is left
completely untouched.

The copy has a different code signature, so in principle it could have its own
keychain identity and ask you to sign in to PSN again — but in practice the
existing session is usually carried over and no re-login is needed. If it does
prompt you, signing in once is enough. To undo everything, just delete the copy:

```bash
rm -rf ./RemotePlay-ShockEmu.app
```

---

## Requirements

- macOS with [PS Remote Play](https://remoteplay.dl.playstation.net/remoteplay/lang/en/index.html)
  installed at `/Applications/RemotePlay.app`.
- Xcode Command Line Tools (`xcode-select --install`).
- `python3` (ships with the Command Line Tools).

---

## Quick start

```bash
# 1. Build the daemon + injection library from a mapping file
./build.sh example.se          # keyboard + mouse (right stick look)
#   or
./build.sh example_gyro.se     # keyboard + mouse (gyro look, needs a gyro game)

# 2. Make the injectable local copy of Remote Play (one time; re-run after an update)
./resign.sh

# 3. Run it
./run.sh
```

`run.sh` launches the patched local copy with the library injected and starts
`gpad-daemon`. Quit Remote Play (or Ctrl-C the terminal) to clean up.

> **Rebuild after every mapping change.** The `.se` file is compiled into the
> library at build time — editing it does nothing until you re-run `./build.sh`.

### Files produced by the build

| File                      | What it is                                            |
| ------------------------- | ----------------------------------------------------- |
| `gpad-daemon`             | helper for passing a real gamepad through             |
| `iohid_wrap.dylib`        | the injected library (contains your compiled mapping) |
| `mapKeys.h`, `mapMeta.h`  | generated from your `.se` file — do not edit by hand  |
| `RemotePlay-ShockEmu.app` | the re-signed local copy (from `resign.sh`)           |

---

## Mouse capture

Mouse look only works while the pointer is **captured** by the window —
otherwise the cursor wanders off and motion stops. Capture is **off by
default** so you can still use the cursor to sign in.

- **Press the capture key** (`0` in the sample files) to capture; press again to
  release.
- Capture **auto-releases** whenever Remote Play loses focus, so you can never
  get stuck without a pointer.

---

## Aiming modes

Set `mouseLook.mode` in the mapping file.

### `stick` (default) — mouse drives the right stick

Works in every game, no in-game setting required. The catch is physics: a
thumbstick has a maximum turn rate, so a very fast flick can't rotate as far as
the same motion on a real mouse. Tune with `sensitivity` / `drain` / `maxGlide`.

### `gyro` — mouse drives the controller's gyro _(experimental)_

Reports mouse motion as controller **angular velocity**, which the console
integrates into rotation. Because there's no stick-deflection ceiling, fast and
slow swipes covering the same distance turn the same amount — the closest thing
to true 1:1 mouse aim.

**Requirements & caveats:**

- The **game must support motion/gyro aiming**, and it usually must be **enabled
  in that game's own options**. If it isn't, nothing will move.
- Whether motion survives the Remote Play link is game/setup dependent.
- The axis routing and direction differ between games — expect to flip
  `gyroYawSign` / `gyroPitchSign` and possibly swap the byte offsets (below).

Sticks and buttons work identically in both modes; only the mouse-look target
changes.

---

## Mapping file (`.se`) format

One assignment per line; `#` starts a comment. Two kinds of lines:

```
<key> = <button-or-axis>      # input mapping
mouseLook.<setting> = <value> # mouse-look configuration
```

A key you map is taken over **exclusively** — Remote Play's own built-in
mapping for that key is suppressed, so there's no double-input. Keys you don't
map pass through to Remote Play untouched.

> **Side effect:** a mapped key is swallowed everywhere, including text fields.
> If you map `enter`/`delete`, they won't work for typing (e.g. a PSN login
> box) while that mapping is active.

### Valid keys

```
letters   a … z
digits    0 … 9
named     space enter delete tab escape capslock shift control option command
          up down left right
          backtick comma period slash backslash
```

(`delete` is the **Backspace** key.)

### Valid targets

```
buttons   X O square triangle
          L1 L2 R1 R2 L3 R3
          dpadUp dpadDown dpadLeft dpadRight
          PS touchpad options share
axes      leftX-  leftX+  leftY-  leftY+
          rightX- rightX+ rightY- rightY+
mouse     leftMouse rightMouse   (used on the left of '=', e.g. leftMouse = L1)
```

**Movement on a stick** is done with the four axis directions, e.g.
`w = leftY-`, `s = leftY+`, `a = leftX-`, `d = leftX+`.

---

## `mouseLook` knobs

### Common (both modes)

| Setting       | Default  | What it does                                                                                                                                                                                            |
| ------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mode`        | `stick`  | `stick` or `gyro`. Chooses what the mouse drives.                                                                                                                                                       |
| `stick`       | `right`  | Which stick receives look in **stick mode** (`left`/`right`).                                                                                                                                           |
| `deadZone`    | `.05`    | Below this stick deflection, output is treated as zero.                                                                                                                                                 |
| `multY`       | `1`      | `-1` inverts vertical look.                                                                                                                                                                             |
| `multX`       | `1`      | `-1` inverts horizontal look (stick mode).                                                                                                                                                              |
| `captureMode` | `lock`   | `lock` pins the pointer (best for a real **mouse**). `recenter` lets the pointer move and warps it back to centre (needed for **trackpads**, which only report motion when the pointer actually moves). |
| `captureKey`  | `escape` | Key that toggles capture. The samples use `0`.                                                                                                                                                          |

### Stick mode only

| Setting       | Default | What it does                                                                                                                                                                                                                            |
| ------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sensitivity` | `.15`   | How quickly the stick reaches full deflection — i.e. **snappiness**. Does _not_ change how far you turn.                                                                                                                                |
| `drain`       | `400`   | **The turn-distance knob.** Pixels consumed per second of full stick. **Lower = more rotation per swipe.** Total turn ≈ `(pixels moved / drain)` seconds of stick, so fast and slow swipes over the same distance turn the same amount. |
| `maxGlide`    | `.1`    | Seconds the view may keep turning after you lift your finger. A swipe faster than the stick can physically turn banks up motion; this caps the bank. Raise for more distance-fidelity on fast swipes, lower for a snappier stop.        |

**Tuning stick mode:** if flicks feel weak, lower `drain`. If aim overshoots,
raise `drain`. Use `sensitivity` only to change how _immediate_ the response
feels, not its range.

### Gyro mode only

| Setting             | Default | What it does                                                                                                                                                                                           |
| ------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gyroSensitivity`   | `30`    | Raw gyro units per pixel of movement. **Raise to turn more per swipe.** (The sample `example_gyro.se` uses `200`.)                                                                                     |
| `gyroYawSign`       | `1`     | `-1` reverses horizontal aim.                                                                                                                                                                          |
| `gyroPitchSign`     | `1`     | `-1` reverses vertical aim.                                                                                                                                                                            |
| `gyroYawOffset`     | `15`    | Report byte carrying yaw (`13`/`15`/`17`). Swap with `gyroPitchOffset` if your game has yaw and pitch transposed.                                                                                      |
| `gyroPitchOffset`   | `13`    | Report byte carrying pitch.                                                                                                                                                                            |
| `gyroTimestampStep` | `750`   | How fast the DS4 motion timestamp advances per report (units of ~5.33 µs; 750 ≈ 4 ms, the real DS4 rate). Leave unless turning is globally too fast/slow and `gyroSensitivity` alone can't balance it. |

**Tuning gyro mode:** get the **direction** right first (`gyroYawSign` /
`gyroPitchSign`; swap the offsets if yaw/pitch are crossed), then set **speed**
with `gyroSensitivity`.

---

## The sample mappings

Both sample files use the same buttons and only differ in the four face-button
keys and the look mode.

### Shared layout

| Input           | DualShock 4                          |
| --------------- | ------------------------------------ |
| `W` `A` `S` `D` | left stick (move)                    |
| Arrow keys      | d-pad                                |
| Mouse move      | look (right stick or gyro, per mode) |
| Left mouse      | L1                                   |
| Right mouse     | L2                                   |
| `G`             | R1                                   |
| `H`             | R2                                   |
| `P`             | PS                                   |
| `T`             | touchpad                             |
| `0`             | toggle mouse capture                 |

### Face buttons

| Button     | `example.se` (stick) | `example_gyro.se` |
| ---------- | -------------------- | ----------------- |
| X          | `Y`                  | `Enter`           |
| square     | `U`                  | `Q`               |
| O (circle) | `I`                  | `Backspace`       |
| triangle   | `O`                  | `E`               |

**Not mapped by default** (free to add): `L3`, `R3`, `options`, `share`, and
most letters/space/tab. `options` is the pause/menu button in most games and is
a common thing to add, e.g. `tab = options`.

---

## Reverting / cleanup

- Switch mapping/mode: edit or pick a different `.se`, then `./build.sh <file>`.
- Restore Remote Play's original signature: `rm -rf ./RemotePlay-ShockEmu.app`
  (the `/Applications` copy was never modified).

---

## Debugging

Run with mouse-motion logging to see exactly what's being captured and emitted:

```bash
SHOCKEMU_DEBUG_MOUSE=1 ./run.sh
```

- `ShockEmu mouse: … using (dx, dy)` — a mouse/trackpad delta reached ShockEmu.
- `ShockEmu stick: (x, y)` — stick deflection being sent (stick mode).
- `ShockEmu gyro: yaw=… pitch=… ts=…` — gyro values and the advancing motion
  timestamp being sent (gyro mode).

If you see input `mouse:` lines but the camera doesn't move: in **gyro mode**
that points at the game (motion aim not supported/enabled) or the Remote Play
link, not at ShockEmu. In **stick mode** confirm the pointer is captured
(press the capture key).

---

## Credits

- Original work: <https://github.com/daeken> and
  <https://github.com/suzukiplan/gamepad-osx>
- Catalina/Mojave-era packaging: [MiCkSoftware](https://github.com/MiCkSoftware/ShockEmu)
