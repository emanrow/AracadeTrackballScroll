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
accelerationExponent := Number(env.Get("ACCELERATION_EXPONENT", 1.8))
sensitivity := Number(env.Get("SENSITIVITY", 5.0))

AHI := AutoHotInterception()
AHI.SubscribeMouseMoveRelative(trackballHandle, true, TrackballToScroll)

MsgBox "Subscribed to Trackball Movements"

TrackballToScroll(x, y) {
	static accumX := 0.0, accumY := 0.0, lastTick := A_TickCount

    ; Calculate speed (velocity)
    elapsedMs := A_TickCount - lastTick
    lastTick := A_TickCount

    speed := Sqrt(x**2 + y**2) / (elapsedMs + 1) ; pixels per millisecond
    dynamicMultiplier := baseMultiplier + sensitivity * (speed**accelerationExponent)

    accumX += x * dynamicMultiplier
    accumY += y * dynamicMultiplier

    ; Vertical Scroll
    if (Abs(accumY) >= 1) {
        deltaY := Integer(accumY)
        SendWheelEvent(-deltaY, "vertical")
        accumY -= deltaY
    }

    ; Horizontal Scroll
    if (Abs(accumX) >= 1) {
        deltaX := Integer(accumX)
        SendWheelEvent(deltaX, "horizontal")
        accumX -= deltaX
    }
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