#NoEnv
#NoTrayIcon
#singleinstance force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

settingsFile := A_ScriptDir . "\WindowMinimizeRestore.ini"
IniRead, skipRestore, %settingsFile%, Settings, SkipRestore, 0
skipRestore := (skipRestore = 1 || skipRestore = "true" || skipRestore = "True")

; Ctrl+Shift+Down: follow the native Windows 10 down sequence.
^+Down::
    WinGet, window, ID, A
    if (!window)
        return

    WinGet, state, MinMax, ahk_id %window%
    lastWindow := window

    if (state = 1 && !skipRestore)
        WinRestore, ahk_id %window%
    else
        WinMinimize, ahk_id %window%
return

; Ctrl+Shift+Up: restore a minimized window, then maximize it.
^+Up::
    window := 0
    if (lastWindow && WinExist("ahk_id " . lastWindow))
        window := lastWindow
    else
        WinGet, window, ID, A

    if (!window)
        return

    WinGet, state, MinMax, ahk_id %window%
    if (state = -1) {
        if (skipRestore)
            WinMaximize, ahk_id %window%
        else
            WinRestore, ahk_id %window%
        WinActivate, ahk_id %window%
    } else if (state = 0) {
        WinMaximize, ahk_id %window%
        WinActivate, ahk_id %window%
    }
return

Menu, Tray, Tip, Window Minimize/Restore
return
