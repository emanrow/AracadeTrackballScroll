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
scrollMultiplier := Number(env.Get("BASE_MULTIPLIER", 3.0))
accelerationExponent := Number(env.Get("ACCELERATION_EXPONENT", 2.5))
smoothingFactor := Number(env.Get("SMOOTHING_FACTOR", 8))

AHI := AutoHotInterception()
AHI.SubscribeMouseMoveRelative(trackballHandle, true, TrackballToScroll)

MsgBox "Subscribed to Trackball Movements"

TrackballToScroll(x, y) {
    ; Target v_x should be x ** accelerationExponent, but since
    ; x is discrete and usually small, we don't want v_x to abruptly change
    ; every time x changes. So we instead have v_x move closer towards
    ; the target velocity each tick.

    ; Current velocity
    static v_x := 0
    static v_y := 0

    ; We do need to track time a bit, because if it's been a while
    ; since the last tick, we shouldn't honor the previous velocity.
    static lastTick := 0
    d_t := A_TickCount - lastTick
    lastTick := A_TickCount

    if (d_t > 100) {
        v_x := 0
        v_y := 0
    }

    ; Target velocity
    v_x_target := (Abs(x) ** accelerationExponent) * (x > 0 ? 1 : -1)
    v_y_target := (Abs(y) ** accelerationExponent) * (y > 0 ? 1 : -1)

    ; Update velocity
    v_x := v_x + (v_x_target - v_x) / smoothingFactor
    v_y := v_y + (v_y_target - v_y) / smoothingFactor

    ; Send events; apply scroll multiplier here so it doesn't carry over
    ; from the last tick.   
    deltaX := Integer(v_x * scrollMultiplier)
    deltaY := Integer(v_y * scrollMultiplier)

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