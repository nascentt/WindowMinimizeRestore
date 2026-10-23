# Window Minimize/Restore

Provide configurable window state transitions: classic three-stage behavior by default, or direct minimize/maximize with `SkipRestore=1`.

Unlike the native Win + Down, and Win + Up shortcuts that cycle through 4 different states (minimized, restored, maximized, upper horizontal) this app brings back simple 3 stage allows simple minimization and maximization of application windows from classic Versions of Windows (such as Windows 7-10).

## Hotkeys

- **Ctrl + Shift + Down** — Follow the native Windows classic down sequence:
  maximized → restored → minimized.
- **Ctrl + Shift + Up** — Follow the native Windows classic up sequence:
  minimized → restored → maximized.

## Settings

Edit `WindowMinimizeRestore.ini` while the script is stopped:

```ini
[Settings]
SkipRestore=0
```

- `SkipRestore=0` — Classic three-stage behavior (default).
- `SkipRestore=1` — Skip the restored stage. Windows jump directly between minimized and maximized.

Restart the script after changing the setting.

## Usage

1. Double-click `WindowMinimizeRestore.ahk` to start the utility.
2. Use the hotkeys above from any application.
3. To stop it, close the AutoHotkey script using Task Manager or temporarily remove `#NoTrayIcon` and restart the script to access its tray menu.

## Requirements

- AutoHotkey v1.x

## Notes

- The most recently minimized window is remembered so it can be restored even after it loses focus.
- `#NoTrayIcon` keeps the utility from adding an icon to the notification area.
- `#singleinstance force` prevents multiple copies from running simultaneously.
