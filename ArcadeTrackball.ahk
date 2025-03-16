#Requires AutoHotkey v2.0
Persistent
#SingleInstance force
#include Lib\AutoHotInterception.ahk

; === Load ENV Configuration ===
scriptDir := A_ScriptDir
envPath := scriptDir "\.env"
if !FileExist(envPath) {
    MsgBox("Missing .env file! Create one with TRACKBALL_HANDLE specified.")
    ExitApp()
}

env := LoadEnv(envPath)

trackballHandle := Integer(env["TRACKBALL_HANDLE"])
baseMultiplier := Number(env.Get("BASE_MULTIPLIER", 1))
accelerationExponent := Number(env.Get("ACCELERATION_EXPONENT", 2.5))
sensitivity := Number(env.Get("SENSITIVITY", 5.0))

AHI := AutoHotInterception()
AHI.SubscribeMouseMoveRelative(trackballHandle, true, TrackballToScroll)

MsgBox "Subscribed to Trackball Movements"

TrackballToScroll(x, y) {
    static scrollMultiplier := 3.0       ; Adjust for comfortable scrolling speed
    static accelerationExponent := 2.5   ; Exponent for acceleration (2.0 recommended)

    ; Calculate velocity preserving direction
    v_x := (Abs(x) ** accelerationExponent) * (x >= 0 ? 1 : -1)
    v_x := v_x * scrollMultiplier

    v_y := (Abs(y) ** accelerationExponent) * (y >= 0 ? 1 : -1) * scrollMultiplier
    v_x := (Abs(x)**accelerationExponent) * (x > 0 ? 1 : -1) * scrollMultiplier

    deltaY := Integer(v_y)
    deltaX := Integer(v_x)

    if (deltaY != 0)
        SendWheelEvent(-deltaY, "vertical")

    if (deltaX != 0)
        SendWheelEvent(deltaX, "horizontal")
}


SendWheelEvent(delta, direction := "vertical") {
    ; Windows high-precision scrolling via mouse_event API
    static MOUSEEVENTF_WHEEL := 0x0800, MOUSEEVENTF_HWHEEL := 0x01000

    DllCall("mouse_event",
        "UInt", (direction = "vertical") ? MOUSEEVENTF_WHEEL : MOUSEEVENTF_HWHEEL,
        "UInt", 0,
        "UInt", 0,
        "UInt", delta,
        "UPtr", 0)
}

LoadEnv(filePath) {
    env := Map()
    loop read filePath {
        line := Trim(A_LoopReadLine)
        if (line = "" || SubStr(line, 1, 1) = "#")
            continue
        splitPos := InStr(line, "=")
        if splitPos {
            key := Trim(SubStr(line, 1, splitPos - 1))
            val := Trim(SubStr(line, splitPos + 1))
            env[key] := val := StrReplace(val, "`r", "")
        }
    }
    return env
}