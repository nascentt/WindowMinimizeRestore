# Window Minimize/Restore

**Move and arrange windows across screens independently of minimizing or maximizing them.**

This app separates two jobs into distinct, customizable shortcut groups:

- **Window placement:** cycle through left/right or upper/lower screen halves and move between screens in that direction.
- **Window state:** minimize, restore, or maximize a window without cycling through screen halves.

By default, **Ctrl+Alt+Arrow** controls placement and **Ctrl+Shift+Up/Down** controls window state. You can change every shortcut in Settings, and enable horizontal and vertical placement independently.

## Quick start

1. Install **AutoHotkey v1.x** and run `WindowMinimizeRestore.ahk`.
2. Press **Ctrl+Alt+Left/Right** to arrange the active window horizontally.
3. Press **Ctrl+Alt+S** to open Settings. Enable vertical snapping if wanted, and record your preferred shortcuts.
4. Save to apply changes immediately and persist them in `WindowMinimizeRestore.ini`.

To stop the app, end its/AutoHotkey process in Task Manager. 

## Default shortcuts

| Function                  | Default shortcut      | Enabled by default? |
| ------------------------- | --------------------- | ------------------- |
| Place/cycle left or right | Ctrl+Alt+Left / Right | Yes                 |
| Place/cycle up or down    | Ctrl+Alt+Up / Down    | Yes                 |
| Restore, then minimize    | Ctrl+Shift+Down       | Yes                 |
| Restore, then maximize    | Ctrl+Shift+Up         | Yes                 |
| Open Settings             | Ctrl+Alt+S            | Yes                 |

These are defaults, not fixed bindings. Changing a placement shortcut does not change a window-state shortcut.

## Window placement: halves and multiple screens

Left/Right uses the left and right halves of screens arranged horizontally. Up/Down uses the upper and lower halves of screens arranged vertically. Each snapped window fills the selected half of its destination screen.

- From an unsnapped window, the first press selects the requested half of its current screen.
- Moving toward the other half of the current screen takes **one restored step**, then a second press in that direction snaps to that half (for example, Left from the right half).
- Once on the outward half for that direction, the next press moves to the adjacent screen (for example, Left from the left half).
- Entering an adjacent screen uses its **near-edge half**: Left enters the right half, Right enters the left half, Up enters the lower half, and Down enters the upper half.
- The restored step uses the window's saved size and relative position **on the screen being cycled**, rather than jumping back to its original screen.
- At the outermost screen, the cycle **wraps directly** to the opposite half of the farthest screen in the other direction. There is no restored step before that wrap.

### Example: two screens side by side

With screen A on the left and screen B on the right, start on **B's right half** and repeatedly press Left:

**B right → restored on B → B left → A right → restored on A → A left → B right (wrap)**

Vertical cycling follows the same pattern for screens positioned above/below one another. Holding a placement shortcut does not repeatedly advance the cycle; release the key between steps.

### Maximize between halves instead of restoring

Set `SnapIntermediateState=maximize` in `[Settings]` and restart the app to use a maximized window between halves, on the screen being cycled. This applies to horizontal and vertical placement. For example:

**B right → maximized on B → B left → A right → maximized on A → A left → B right (wrap)**

Use `SnapIntermediateState=restore` (default) for the restored behavior described above. Invalid values fall back to `restore`. This option is INI-only, independent of `SkipRestore`, and does not add a step before wrapping.

## Window state: minimize, restore, maximize

The app provides a simple three-stage cycle—minimized, restored, and maximized—similar to the familiar behavior in Windows 7–10. These actions are separate from directional placement:

- **Ctrl+Shift+Down:** maximized → restored → minimized.
- **Ctrl+Shift+Up:** minimized → restored → maximized.

With `SkipRestore=1`, these shortcuts jump directly between minimized and maximized instead. The most recently minimized window is remembered so it can be restored after it loses focus.

**`SkipRestore` affects only these window-state actions. It does not remove the restored step between screen halves in the placement cycle.** Disabling horizontal or vertical placement also leaves the window-state shortcuts available.

## Customization

### Settings dialog: configure all seven shortcuts

Open Settings with **Ctrl+Alt+S** by default. It lets you:

- Record shortcuts for all four placement directions, both window-state actions, and opening Settings itself.
- Enable or disable horizontal and vertical snapping independently.
- **Skip the restored window stage** in minimize/maximize actions, if preferred.

Click the field beside an action, then press the key combination you want to assign. You can configure Horizontal Left, Horizontal Right, Vertical Up, Vertical Down, Minimize / Restore, Restore / Maximize, and Open Settings. This includes changing the shortcut that opens this dialog.

Select a shortcut-capture field and press the desired combination. Duplicate combinations are rejected. Saving applies changes immediately and writes them to the INI; Cancel discards edits.

The dialog exposes all seven shortcuts, horizontal/vertical enable toggles, and SkipRestore. **SnapIntermediateState and DebugSnapGeometry are configured only in the INI.**

### Complete INI reference

The following shows the application's defaults:

```ini
[Settings]
SkipRestore=0
EnableHorizontalSnap=1
EnableVerticalSnap=1
SnapIntermediateState=restore
DebugSnapGeometry=0

[Hotkeys]
HorizontalLeft=^!Left
HorizontalRight=^!Right
VerticalUp=^!Up
VerticalDown=^!Down
MinimizeRestore=^+Down
RestoreMaximize=^+Up
Settings=^!s
```

| Setting                 | Controls                                                        | Values                              |
| ----------------------- | --------------------------------------------------------------- | ----------------------------------- |
| `EnableHorizontalSnap`  | Horizontal placement/cycling                                    | `1` enabled (default); `0` disabled |
| `EnableVerticalSnap`    | Vertical placement/cycling                                      | `1` enabled (default); `0` disabled |
| `SnapIntermediateState` | State between halves in horizontal/vertical placement; INI-only | `restore` (default) or `maximize`   |
| `SkipRestore`           | Restored step in minimize/maximize actions only                 | `0` keep it (default); `1` skip it  |
| `DebugSnapGeometry`     | Troubleshooting log; INI-only option                            | `0` off (default); `1` on           |

Every `[Hotkeys]` entry can also be edited through the Settings dialog:

| INI key           | Action                                    | Default   |
| ----------------- | ----------------------------------------- | --------- |
| `HorizontalLeft`  | Place/cycle left                          | `^!Left`  |
| `HorizontalRight` | Place/cycle right                         | `^!Right` |
| `VerticalUp`      | Place/cycle up                            | `^!Up`    |
| `VerticalDown`    | Place/cycle down                          | `^!Down`  |
| `MinimizeRestore` | Restore/minimize; affected by SkipRestore | `^+Down`  |
| `RestoreMaximize` | Restore/maximize; affected by SkipRestore | `^+Up`    |
| `Settings`        | Open the key configuration dialog         | `^!s`     |

The `[Hotkeys]` entries set each action's key combination separately. In AutoHotkey notation, `^` means Ctrl, `!` means Alt, `+` means Shift, and `#` means Win. For example, `^!Left` is Ctrl+Alt+Left.

If editing the INI manually, stop the app first, edit `WindowMinimizeRestore.ini`, then restart. Use the settings window for changes while the app is running.

## Troubleshooting and implementation notes

- **Vertical shortcuts do nothing:** enable vertical snapping in Settings or set `EnableVerticalSnap=1` and restart. Ctrl+Shift+Up/Down are window-state actions, not vertical placement shortcuts by default.
- **Changes are not taking effect:** check that you are running the latest `.ahk`, not the older compiled `.exe`. Rerunning the app replaces its existing instance (`#singleinstance force`).
- **Different display scaling:** the app uses per-monitor DPI-aware coordinates. Cross-screen placement moves the window first, waits **75 ms** for its DPI transition, then applies the final destination size. Same-screen placement does not have this pause.
- **Restoring before placement:** minimized/maximized windows are restored before applying placement bounds. Windows already in their normal state do not receive redundant restore commands.
- **Geometry diagnostics:** set `DebugSnapGeometry=1` and restart to log requested and actual bounds immediately and at 100, 300, 600, and 1200 ms after snap/restore operations. The log is `WindowMinimizeRestore-debug.log` beside the script; rows include window handles and tick counts. Set the option back to `0` and restart when finished.
