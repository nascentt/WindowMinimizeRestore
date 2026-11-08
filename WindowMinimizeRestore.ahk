#NoEnv
#NoTrayIcon
#singleinstance force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

; Keep monitor enumeration and window sizing in the same physical, per-monitor DPI coordinate space.
dpiAwarenessContext := DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")

settingsFile := A_ScriptDir . "\WindowMinimizeRestore.ini"
IniRead, skipRestore, %settingsFile%, Settings, SkipRestore, 0
skipRestore := (skipRestore = 1 || skipRestore = "true" || skipRestore = "True")
IniRead, enableHorizontalSnap, %settingsFile%, Settings, EnableHorizontalSnap, 1
enableHorizontalSnap := (enableHorizontalSnap = 1 || enableHorizontalSnap = "true" || enableHorizontalSnap = "True")
IniRead, enableVerticalSnap, %settingsFile%, Settings, EnableVerticalSnap, 0
enableVerticalSnap := (enableVerticalSnap = 1 || enableVerticalSnap = "true" || enableVerticalSnap = "True")
IniRead, enableQuarterSnap, %settingsFile%, Settings, EnableQuarterSnap, 1
enableQuarterSnap := (enableQuarterSnap = 1 || enableQuarterSnap = "true" || enableQuarterSnap = "True")
quarterPlacementRevision := 0
IniRead, snapIntermediateState, %settingsFile%, Settings, SnapIntermediateState, restore
snapIntermediateState := (snapIntermediateState = "maximize" ? "maximize" : "restore")
IniRead, debugSnapGeometry, %settingsFile%, Settings, DebugSnapGeometry, 0
debugSnapGeometry := (debugSnapGeometry = 1 || debugSnapGeometry = "true" || debugSnapGeometry = "True")
debugLogFile := A_ScriptDir . "\WindowMinimizeRestore-debug.log"
IniRead, hotkeyHorizontalLeft, %settingsFile%, Hotkeys, HorizontalLeft, ^!Left
IniRead, hotkeyHorizontalRight, %settingsFile%, Hotkeys, HorizontalRight, ^!Right
IniRead, hotkeyVerticalUp, %settingsFile%, Hotkeys, VerticalUp, ^!Up
IniRead, hotkeyVerticalDown, %settingsFile%, Hotkeys, VerticalDown, ^!Down
IniRead, hotkeyMinimizeRestore, %settingsFile%, Hotkeys, MinimizeRestore, ^+Down
IniRead, hotkeyRestoreMaximize, %settingsFile%, Hotkeys, RestoreMaximize, ^+Up
IniRead, hotkeySettings, %settingsFile%, Hotkeys, Settings, ^!s
RegisterAppHotkeys()
return

DoHorizontalLeft:
    if (enableHorizontalSnap) {
        CycleWindow(-1)
        WaitForSnapKeyRelease(A_ThisHotkey)
    }
return

DoHorizontalRight:
    if (enableHorizontalSnap) {
        CycleWindow(1)
        WaitForSnapKeyRelease(A_ThisHotkey)
    }
return

DoVerticalUp:
    if (enableVerticalSnap) {
        CycleWindowVertical(-1)
        WaitForSnapKeyRelease(A_ThisHotkey)
    }
return

DoVerticalDown:
    if (enableVerticalSnap) {
        CycleWindowVertical(1)
        WaitForSnapKeyRelease(A_ThisHotkey)
    }
return

DoMinimizeRestore:
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

DoRestoreMaximize:
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

OpenSettings:
    ShowSettingsDialog()
return

SettingsSave:
    SaveSettingsDialog()
return

SettingsQuit:
    ExitApp
return

SettingsCancel:
SettingsGuiClose:
SettingsGuiEscape:
    Gui, Settings:Destroy
return

Menu, Tray, Tip, Window Minimize/Restore
return

WaitForSnapKeyRelease(hotkey) {
    keyName := RegExReplace(hotkey, "^[^A-Za-z0-9]+")
    if (keyName != "")
        KeyWait, %keyName%
}

ScheduleSnapGeometryTrace(window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH) {
    logger := Func("RecordSnapGeometry").Bind("after-100ms", window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH)
    SetTimer, %logger%, -100
    logger := Func("RecordSnapGeometry").Bind("after-300ms", window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH)
    SetTimer, %logger%, -300
    logger := Func("RecordSnapGeometry").Bind("after-600ms", window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH)
    SetTimer, %logger%, -600
    logger := Func("RecordSnapGeometry").Bind("after-1200ms", window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH)
    SetTimer, %logger%, -1200
}

RecordSnapGeometry(stage, window, axis, side, targetMonitor, expectedX, expectedY, expectedW, expectedH) {
    global debugLogFile
    WinGetPos, actualX, actualY, actualW, actualH, ahk_id %window%
    if (axis != "RESTORE")
        GetVisibleWindowBounds(window, actualX, actualY, actualW, actualH)
    actualMonitor := MonitorForWindow(actualX, actualY, actualW, actualH)
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    tick := A_TickCount
    line := timestamp . "|tick=" . tick . "|" . stage . "|window=" . window . "|" . axis . "|side=" . side . "|target=" . targetMonitor . "|expected=" . expectedX . "," . expectedY . "," . expectedW . "," . expectedH . "|actualMonitor=" . actualMonitor . "|actual=" . actualX . "," . actualY . "," . actualW . "," . actualH
    FileAppend, %line%`n, %debugLogFile%
}

RegisterAppHotkeys() {
    global enableHorizontalSnap, enableVerticalSnap
    global hotkeyHorizontalLeft, hotkeyHorizontalRight, hotkeyVerticalUp, hotkeyVerticalDown
    global hotkeyMinimizeRestore, hotkeyRestoreMaximize, hotkeySettings

    Hotkey, %hotkeySettings%, OpenSettings, On
    Hotkey, %hotkeyHorizontalLeft%, DoHorizontalLeft, On
    Hotkey, %hotkeyHorizontalRight%, DoHorizontalRight, On
    Hotkey, %hotkeyVerticalUp%, DoVerticalUp, On
    Hotkey, %hotkeyVerticalDown%, DoVerticalDown, On
    Hotkey, %hotkeyMinimizeRestore%, DoMinimizeRestore, On
    Hotkey, %hotkeyRestoreMaximize%, DoRestoreMaximize, On
}

UnregisterAppHotkeys() {
    global hotkeyHorizontalLeft, hotkeyHorizontalRight, hotkeyVerticalUp, hotkeyVerticalDown
    global hotkeyMinimizeRestore, hotkeyRestoreMaximize, hotkeySettings

    Hotkey, %hotkeySettings%, Off
    Hotkey, %hotkeyHorizontalLeft%, Off
    Hotkey, %hotkeyHorizontalRight%, Off
    Hotkey, %hotkeyVerticalUp%, Off
    Hotkey, %hotkeyVerticalDown%, Off
    Hotkey, %hotkeyMinimizeRestore%, Off
    Hotkey, %hotkeyRestoreMaximize%, Off
}

ShowSettingsDialog() {
    global enableHorizontalSnap, enableVerticalSnap, skipRestore
    global hotkeyHorizontalLeft, hotkeyHorizontalRight, hotkeyVerticalUp, hotkeyVerticalDown
    global hotkeyMinimizeRestore, hotkeyRestoreMaximize, hotkeySettings
    global cfgHorizontalLeft, cfgHorizontalRight, cfgVerticalUp, cfgVerticalDown
    global cfgMinimizeRestore, cfgRestoreMaximize, cfgSettings
    global cfgEnableHorizontalSnap, cfgEnableVerticalSnap, cfgSkipRestore
    global enableQuarterSnap, snapIntermediateState, debugSnapGeometry
    global cfgEnableQuarterSnap, cfgSnapIntermediateState, cfgDebugSnapGeometry

    if WinExist("Window Minimize/Restore Settings") {
        Gui, Settings:Show
        return
    }

    checkHorizontal := (enableHorizontalSnap ? "Checked" : "")
    checkVertical := (enableVerticalSnap ? "Checked" : "")
    checkSkipRestore := (skipRestore ? "Checked" : "")
    checkQuarter := (enableQuarterSnap ? "Checked" : "")
    checkDebug := (debugSnapGeometry ? "Checked" : "")
    intermediateChoice := (snapIntermediateState = "maximize" ? 2 : 1)
    Gui, Settings:New, +LabelSettingsGui +AlwaysOnTop, Window Minimize/Restore Settings
    Gui, Settings:Margin, 10, 8
    Gui, Settings:Add, Text, x10 y10 w210, Horizontal Left
    Gui, Settings:Add, Hotkey, x230 y8 w180 vcfgHorizontalLeft, %hotkeyHorizontalLeft%
    Gui, Settings:Add, Text, x10 y40 w210, Horizontal Right
    Gui, Settings:Add, Hotkey, x230 y38 w180 vcfgHorizontalRight, %hotkeyHorizontalRight%
    Gui, Settings:Add, Text, x10 y70 w210, Vertical Up
    Gui, Settings:Add, Hotkey, x230 y68 w180 vcfgVerticalUp, %hotkeyVerticalUp%
    Gui, Settings:Add, Text, x10 y100 w210, Vertical Down
    Gui, Settings:Add, Hotkey, x230 y98 w180 vcfgVerticalDown, %hotkeyVerticalDown%
    Gui, Settings:Add, Text, x10 y130 w210, Minimize / Restore
    Gui, Settings:Add, Hotkey, x230 y128 w180 vcfgMinimizeRestore, %hotkeyMinimizeRestore%
    Gui, Settings:Add, Text, x10 y160 w210, Restore / Maximize
    Gui, Settings:Add, Hotkey, x230 y158 w180 vcfgRestoreMaximize, %hotkeyRestoreMaximize%
    Gui, Settings:Add, Text, x10 y190 w210, Open this settings window
    Gui, Settings:Add, Hotkey, x230 y188 w180 vcfgSettings, %hotkeySettings%
    Gui, Settings:Add, Checkbox, x10 y225 vcfgEnableHorizontalSnap %checkHorizontal%, Enable horizontal snapping
    Gui, Settings:Add, Checkbox, x10 y250 vcfgEnableVerticalSnap %checkVertical%, Enable vertical snapping
    Gui, Settings:Add, Checkbox, x10 y275 vcfgSkipRestore %checkSkipRestore%, Skip the restored window stage (minimize/maximize)
    Gui, Settings:Add, Checkbox, x10 y300 w405 vcfgEnableQuarterSnap %checkQuarter%, Enable quarter-screen snapping
    Gui, Settings:Add, Text, x10 y330 w210, Between screen halves:
    Gui, Settings:Add, DropDownList, x230 y327 w180 vcfgSnapIntermediateState Choose%intermediateChoice%, Restore|Maximize
    Gui, Settings:Add, Checkbox, x10 y365 w405 vcfgDebugSnapGeometry %checkDebug%, Enable geometry diagnostics (troubleshooting)
    Gui, Settings:Add, Button, x10 y405 w75 gSettingsQuit, Quit
    Gui, Settings:Add, Button, x250 y405 w75 Default gSettingsSave, Save
    Gui, Settings:Add, Button, x335 y405 w75 gSettingsCancel, Cancel
    Gui, Settings:Show, w425 h440
}

SaveSettingsDialog() {
    global settingsFile, enableHorizontalSnap, enableVerticalSnap, skipRestore
    global hotkeyHorizontalLeft, hotkeyHorizontalRight, hotkeyVerticalUp, hotkeyVerticalDown
    global hotkeyMinimizeRestore, hotkeyRestoreMaximize, hotkeySettings
    global cfgHorizontalLeft, cfgHorizontalRight, cfgVerticalUp, cfgVerticalDown
    global cfgMinimizeRestore, cfgRestoreMaximize, cfgSettings
    global cfgEnableHorizontalSnap, cfgEnableVerticalSnap, cfgSkipRestore
    global enableQuarterSnap, snapIntermediateState, debugSnapGeometry
    global cfgEnableQuarterSnap, cfgSnapIntermediateState, cfgDebugSnapGeometry

    Gui, Settings:Submit, NoHide
    hotkeys := [cfgHorizontalLeft, cfgHorizontalRight, cfgVerticalUp, cfgVerticalDown, cfgMinimizeRestore, cfgRestoreMaximize, cfgSettings]
    seen := {}
    for index, key in hotkeys {
        if (key = "") {
            MsgBox, 48, Invalid shortcut, Every function needs a key combination.
            return
        }
        if (seen.HasKey(key)) {
            MsgBox, 48, Shortcut conflict, Assign a different key combination to each function.
            return
        }
        seen[key] := true
    }

    UnregisterAppHotkeys()
    hotkeyHorizontalLeft := cfgHorizontalLeft
    hotkeyHorizontalRight := cfgHorizontalRight
    hotkeyVerticalUp := cfgVerticalUp
    hotkeyVerticalDown := cfgVerticalDown
    hotkeyMinimizeRestore := cfgMinimizeRestore
    hotkeyRestoreMaximize := cfgRestoreMaximize
    hotkeySettings := cfgSettings
    enableHorizontalSnap := cfgEnableHorizontalSnap
    enableVerticalSnap := cfgEnableVerticalSnap
    skipRestore := cfgSkipRestore
    enableQuarterSnap := cfgEnableQuarterSnap
    snapIntermediateState := (cfgSnapIntermediateState = "Maximize" ? "maximize" : "restore")
    debugSnapGeometry := cfgDebugSnapGeometry

    IniWrite, %skipRestore%, %settingsFile%, Settings, SkipRestore
    IniWrite, %enableQuarterSnap%, %settingsFile%, Settings, EnableQuarterSnap
    IniWrite, %snapIntermediateState%, %settingsFile%, Settings, SnapIntermediateState
    IniWrite, %debugSnapGeometry%, %settingsFile%, Settings, DebugSnapGeometry
    IniWrite, %enableHorizontalSnap%, %settingsFile%, Settings, EnableHorizontalSnap
    IniWrite, %enableVerticalSnap%, %settingsFile%, Settings, EnableVerticalSnap
    IniWrite, %hotkeyHorizontalLeft%, %settingsFile%, Hotkeys, HorizontalLeft
    IniWrite, %hotkeyHorizontalRight%, %settingsFile%, Hotkeys, HorizontalRight
    IniWrite, %hotkeyVerticalUp%, %settingsFile%, Hotkeys, VerticalUp
    IniWrite, %hotkeyVerticalDown%, %settingsFile%, Hotkeys, VerticalDown
    IniWrite, %hotkeyMinimizeRestore%, %settingsFile%, Hotkeys, MinimizeRestore
    IniWrite, %hotkeyRestoreMaximize%, %settingsFile%, Hotkeys, RestoreMaximize
    IniWrite, %hotkeySettings%, %settingsFile%, Hotkeys, Settings
    RegisterAppHotkeys()
    Gui, Settings:Destroy
    MsgBox, 64, Settings saved, Settings were saved and the shortcuts updated.
}

CycleWindow(direction) {
    global debugSnapGeometry, quarterPlacementRevision
    static lastQuarterRevision := 0
    static currentWindow := 0
    static restoreX := 0, restoreY := 0, restoreW := 0, restoreH := 0, restoreMonitor := 0
    static snappedSide := 0, snappedMonitor := 0
    static pendingSide := 0, pendingDirection := 0, pendingMonitor := 0

    WinGet, window, ID, A
    if (!window)
        return

    if (lastQuarterRevision != quarterPlacementRevision) {
        snappedSide := 0, snappedMonitor := 0, pendingSide := 0
        lastQuarterRevision := quarterPlacementRevision
    }
    if (window != currentWindow) {
        ; Keep valid restore geometry even when this axis first sees a quarter transition.
        WinGetPos, restoreX, restoreY, restoreW, restoreH, ahk_id %window%
        restoreMonitor := MonitorForWindow(restoreX, restoreY, restoreW, restoreH)
    }
    if (TryQuarterSnap(window, "H", direction, quarterHalf, quarterMonitor)) {
        currentWindow := window
        snappedSide := quarterHalf, snappedMonitor := quarterMonitor, pendingSide := 0
        lastQuarterRevision := quarterPlacementRevision
        return
    }
    WinGet, state, MinMax, ahk_id %window%
    if (state != 0)
        RestoreWindowBeforeMove(window)
    WinGetPos, x, y, w, h, ahk_id %window%
    if (!w || !h)
        return
    monitorIndex := MonitorForWindow(x, y, w, h)
    if (window != currentWindow) {
        currentWindow := window
        restoreX := x, restoreY := y, restoreW := w, restoreH := h, restoreMonitor := monitorIndex
        snappedSide := 0, snappedMonitor := 0, pendingSide := 0
    }
    ; If the user moved this window to another monitor, discard stale snap tracking.
    if (!pendingSide && snappedSide && monitorIndex != snappedMonitor) {
        snappedSide := 0
        snappedMonitor := 0
    }
    side := (direction < 0 ? -1 : 1)
    if (pendingSide && pendingDirection = direction) {
        side := pendingSide
        pendingSide := 0
        targetMonitor := pendingMonitor
    } else {
        if (pendingSide)
            pendingSide := 0
        targetMonitor := monitorIndex
        if (snappedSide) {
            if (snappedSide != side) {
                ; Show the configured intermediate state on the monitor being cycled.
                ShowSnapIntermediateState(window, restoreX, restoreY, restoreW, restoreH, restoreMonitor, snappedMonitor)
                pendingSide := side, pendingDirection := direction, pendingMonitor := snappedMonitor
                snappedSide := 0
                return
            }
            nextMonitor := AdjacentMonitor(snappedMonitor, direction)
            if (nextMonitor) {
                targetMonitor := nextMonitor
                ; Enter an adjacent monitor through its near-edge half.
                side := (direction < 0 ? 1 : -1)
            } else {
                ; Wrap directly to the opposite half on the farthest monitor.
                targetMonitor := ExtremeMonitor(snappedMonitor, -direction)
                side := -side
            }
        }
    }
    SysGet, mon, MonitorWorkArea, %targetMonitor%
    left := monLeft, top := monTop
    width := monRight - monLeft, height := monBottom - monTop
    RestoreWindowBeforeMove(window)
    halfWidth := Floor(width / 2)
    if (side < 0) {
        snapX := left, snapY := top, snapW := halfWidth, snapH := height
    } else {
        snapX := left + halfWidth, snapY := top, snapW := width - halfWidth, snapH := height
    }
    MoveWindowToBounds(window, targetMonitor, snapX, snapY, snapW, snapH, true)
    if (debugSnapGeometry) {
        RecordSnapGeometry("immediate", window, "H", side, targetMonitor, snapX, snapY, snapW, snapH)
        ScheduleSnapGeometryTrace(window, "H", side, targetMonitor, snapX, snapY, snapW, snapH)
    }
    snappedSide := side
    snappedMonitor := targetMonitor
}

CycleWindowVertical(direction) {
    global debugSnapGeometry, quarterPlacementRevision
    static lastQuarterRevision := 0
    static currentWindow := 0
    static restoreX := 0, restoreY := 0, restoreW := 0, restoreH := 0, restoreMonitor := 0
    static snappedSide := 0, snappedMonitor := 0
    static pendingSide := 0, pendingDirection := 0, pendingMonitor := 0

    WinGet, window, ID, A
    if (!window)
        return

    if (lastQuarterRevision != quarterPlacementRevision) {
        snappedSide := 0, snappedMonitor := 0, pendingSide := 0
        lastQuarterRevision := quarterPlacementRevision
    }
    if (window != currentWindow) {
        ; Keep valid restore geometry even when this axis first sees a quarter transition.
        WinGetPos, restoreX, restoreY, restoreW, restoreH, ahk_id %window%
        restoreMonitor := MonitorForWindow(restoreX, restoreY, restoreW, restoreH)
    }
    if (TryQuarterSnap(window, "V", direction, quarterHalf, quarterMonitor)) {
        currentWindow := window
        snappedSide := quarterHalf, snappedMonitor := quarterMonitor, pendingSide := 0
        lastQuarterRevision := quarterPlacementRevision
        return
    }
    WinGet, state, MinMax, ahk_id %window%
    if (state != 0)
        RestoreWindowBeforeMove(window)
    WinGetPos, x, y, w, h, ahk_id %window%
    if (!w || !h)
        return
    monitorIndex := MonitorForWindow(x, y, w, h)
    if (window != currentWindow) {
        currentWindow := window
        restoreX := x, restoreY := y, restoreW := w, restoreH := h, restoreMonitor := monitorIndex
        snappedSide := 0, snappedMonitor := 0, pendingSide := 0
    }
    if (!pendingSide && snappedSide && monitorIndex != snappedMonitor) {
        snappedSide := 0
        snappedMonitor := 0
    }
    side := (direction < 0 ? -1 : 1)
    if (pendingSide && pendingDirection = direction) {
        side := pendingSide
        pendingSide := 0
        targetMonitor := pendingMonitor
    } else {
        if (pendingSide)
            pendingSide := 0
        targetMonitor := monitorIndex
        if (snappedSide) {
            if (snappedSide != side) {
                ShowSnapIntermediateState(window, restoreX, restoreY, restoreW, restoreH, restoreMonitor, snappedMonitor)
                pendingSide := side, pendingDirection := direction, pendingMonitor := snappedMonitor
                snappedSide := 0
                return
            }
            nextMonitor := AdjacentMonitorVertical(snappedMonitor, direction)
            if (nextMonitor) {
                targetMonitor := nextMonitor
                ; Enter an adjacent monitor through its near-edge half.
                side := (direction < 0 ? 1 : -1)
            } else {
                targetMonitor := ExtremeMonitorVertical(snappedMonitor, -direction)
                side := -side
            }
        }
    }
    SysGet, mon, MonitorWorkArea, %targetMonitor%
    left := monLeft, top := monTop
    width := monRight - monLeft, height := monBottom - monTop
    RestoreWindowBeforeMove(window)
    halfHeight := Floor(height / 2)
    if (side < 0) {
        snapX := left, snapY := top, snapW := width, snapH := halfHeight
    } else {
        snapX := left, snapY := top + halfHeight, snapW := width, snapH := height - halfHeight
    }
    MoveWindowToBounds(window, targetMonitor, snapX, snapY, snapW, snapH, true)
    if (debugSnapGeometry) {
        RecordSnapGeometry("immediate", window, "V", side, targetMonitor, snapX, snapY, snapW, snapH)
        ScheduleSnapGeometryTrace(window, "V", side, targetMonitor, snapX, snapY, snapW, snapH)
    }
    snappedSide := side
    snappedMonitor := targetMonitor
}

; Infer halves/corners from actual bounds, not the other axis's private cycle state.
TryQuarterSnap(window, axis, direction, ByRef resultHalf, ByRef resultMonitor) {
    global enableQuarterSnap, quarterPlacementRevision, debugSnapGeometry
    if (!enableQuarterSnap)
        return false
    WinGet, state, MinMax, ahk_id %window%
    if (state != 0)
        return false
    GetVisibleWindowBounds(window, x, y, w, h)
    monitor := MonitorForWindow(x, y, w, h)
    SysGet, mon, MonitorWorkArea, %monitor%
    fullW := monRight - monLeft, fullH := monBottom - monTop
    halfW := Floor(fullW / 2), halfH := Floor(fullH / 2)
    horizontal := 0, vertical := 0
    if (Abs(x - monLeft) <= 12 && Abs(w - halfW) <= 12)
        horizontal := -1
    else if (Abs(x - monLeft - halfW) <= 12 && Abs(w - (fullW - halfW)) <= 12)
        horizontal := 1
    if (Abs(y - monTop) <= 12 && Abs(h - halfH) <= 12)
        vertical := -1
    else if (Abs(y - monTop - halfH) <= 12 && Abs(h - (fullH - halfH)) <= 12)
        vertical := 1
    fullWidth := Abs(x - monLeft) <= 12 && Abs(w - fullW) <= 12
    fullHeight := Abs(y - monTop) <= 12 && Abs(h - fullH) <= 12
    if (axis = "H") {
        if (!vertical || (!horizontal && !fullWidth))
            return false
        if (horizontal = direction) {
            vertical := 0 ; Existing outer edge: expand back to the horizontal half.
        } else if (horizontal) {
            horizontal := 0 ; Opposite corner: visit the shared upper/lower half first.
        } else {
            horizontal := direction
        }
        resultHalf := (vertical ? 0 : horizontal)
    } else {
        if (!horizontal || (!vertical && !fullHeight))
            return false
        if (vertical = direction) {
            horizontal := 0 ; Existing outer edge: expand back to the vertical half.
        } else if (vertical) {
            vertical := 0 ; Opposite corner: visit the shared left/right half first.
        } else {
            vertical := direction
        }
        resultHalf := (horizontal ? 0 : vertical)
    }
    targetX := monLeft + (horizontal > 0 ? halfW : 0)
    targetY := monTop + (vertical > 0 ? halfH : 0)
    targetW := (!horizontal ? fullW : (horizontal < 0 ? halfW : fullW - halfW))
    targetH := (!vertical ? fullH : (vertical < 0 ? halfH : fullH - halfH))
    MoveWindowToBounds(window, monitor, targetX, targetY, targetW, targetH, true)
    resultMonitor := monitor
    quarterPlacementRevision += 1
    if (debugSnapGeometry) {
        RecordSnapGeometry("quarter-immediate", window, axis, direction, monitor, targetX, targetY, targetW, targetH)
        ScheduleSnapGeometryTrace(window, axis, direction, monitor, targetX, targetY, targetW, targetH)
    }
    return true
}

MoveWindowToBounds(window, targetMonitor, x, y, width, height, alignVisible := false) {
    WinGetPos, oldX, oldY, oldW, oldH, ahk_id %window%
    sourceMonitor := MonitorForWindow(oldX, oldY, oldW, oldH)
    if (sourceMonitor != targetMonitor) {
        ; Moving and resizing together lets the app's WM_DPICHANGED handling
        ; rescale the requested size. Move first; size only after that transition.
        WinMove, ahk_id %window%,, %x%, %y%
        Sleep, 75
    }
    if (alignVisible) {
        ; WinMove uses outer bounds; DWM excludes the invisible resize margins.
        WinGetPos, outerX, outerY, outerW, outerH, ahk_id %window%
        if (GetVisibleWindowBounds(window, visibleX, visibleY, visibleW, visibleH)) {
            x -= visibleX - outerX
            y -= visibleY - outerY
            width += outerW - visibleW
            height += outerH - visibleH
        }
    }
    WinMove, ahk_id %window%,, %x%, %y%, %width%, %height%
}

GetVisibleWindowBounds(window, ByRef x, ByRef y, ByRef width, ByRef height) {
    WinGetPos, x, y, width, height, ahk_id %window%
    VarSetCapacity(frame, 16, 0)
    result := DllCall("Dwmapi\DwmGetWindowAttribute", "Ptr", window, "UInt", 9, "Ptr", &frame, "UInt", 16, "Int")
    if (result != 0)
        return false
    left := NumGet(frame, 0, "Int"), top := NumGet(frame, 4, "Int")
    right := NumGet(frame, 8, "Int"), bottom := NumGet(frame, 12, "Int")
    if (right <= left || bottom <= top)
        return false
    x := left, y := top, width := right - left, height := bottom - top
    return true
}

RestoreWindowBeforeMove(window) {
    WinGet, state, MinMax, ahk_id %window%
    if (state != 0) {
        WinRestore, ahk_id %window%
        ; Wait for Windows to finish restoring its saved normal rectangle before overriding it.
        Loop, 40 {
            Sleep, 25
            WinGet, state, MinMax, ahk_id %window%
            if (state = 0)
                break
        }
        Sleep, 100
    }
}

ShowSnapIntermediateState(window, restoreX, restoreY, restoreW, restoreH, originMonitor, targetMonitor) {
    global snapIntermediateState
    if (snapIntermediateState = "maximize") {
        ; The snapped window is already on the intended monitor.
        WinMaximize, ahk_id %window%
    } else {
        RestoreWindowOnMonitor(window, restoreX, restoreY, restoreW, restoreH, originMonitor, targetMonitor)
    }
}

RestoreWindowOnMonitor(window, restoreX, restoreY, restoreW, restoreH, originMonitor, targetMonitor) {
    global debugSnapGeometry
    SysGet, target, Monitor, %targetMonitor%
    SysGet, origin, Monitor, %originMonitor%
    x := targetLeft + restoreX - originLeft
    y := targetTop + restoreY - originTop
    RestoreWindowBeforeMove(window)
    MoveWindowToBounds(window, targetMonitor, x, y, restoreW, restoreH)
    if (debugSnapGeometry) {
        RecordSnapGeometry("restore-immediate", window, "RESTORE", "-", targetMonitor, x, y, restoreW, restoreH)
        ScheduleSnapGeometryTrace(window, "RESTORE", "-", targetMonitor, x, y, restoreW, restoreH)
    }
}

ExtremeMonitorVertical(index, direction) {
    SysGet, count, MonitorCount
    current := index
    Loop, %count% {
        next := AdjacentMonitorVertical(current, direction)
        if (!next || next = current)
            break
        current := next
    }
    return current
}

AdjacentMonitorVertical(index, direction) {
    SysGet, current, Monitor, %index%
    SysGet, count, MonitorCount
    best := 0, bestDistance := 2147483647
    Loop, %count% {
        candidate := A_Index
        if (candidate = index)
            continue
        SysGet, other, Monitor, %candidate%
        if (direction < 0) {
            if (otherBottom > currentTop || otherRight <= currentLeft || otherLeft >= currentRight)
                continue
            distance := currentTop - otherBottom
        } else {
            if (otherTop < currentBottom || otherRight <= currentLeft || otherLeft >= currentRight)
                continue
            distance := otherTop - currentBottom
        }
        if (distance < bestDistance)
            best := candidate, bestDistance := distance
    }
    return best
}

ExtremeMonitor(index, direction) {
    SysGet, count, MonitorCount
    current := index
    Loop, %count% {
        next := AdjacentMonitor(current, direction)
        if (!next || next = current)
            break
        current := next
    }
    return current
}

AdjacentMonitor(index, direction) {
    SysGet, current, Monitor, %index%
    SysGet, count, MonitorCount
    best := 0, bestDistance := 2147483647
    Loop, %count% {
        candidate := A_Index
        if (candidate = index)
            continue
        SysGet, other, Monitor, %candidate%
        if (direction < 0) {
            if (otherRight > currentLeft || otherBottom <= currentTop || otherTop >= currentBottom)
                continue
            distance := currentLeft - otherRight
        } else {
            if (otherLeft < currentRight || otherBottom <= currentTop || otherTop >= currentBottom)
                continue
            distance := otherLeft - currentRight
        }
        if (distance < bestDistance)
            best := candidate, bestDistance := distance
    }
    return best
}

MonitorForWindow(x, y, w, h) {
    centerX := x + Floor(w / 2), centerY := y + Floor(h / 2)
    SysGet, count, MonitorCount
    Loop, %count% {
        index := A_Index
        SysGet, mon, Monitor, %index%
        if (centerX >= monLeft && centerX < monRight && centerY >= monTop && centerY < monBottom)
            return index
    }
    SysGet, primary, MonitorPrimary
    return primary
}
