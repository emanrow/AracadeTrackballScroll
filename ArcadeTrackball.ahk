#Requires AutoHotkey v2.0
Persistent
#SingleInstance force
#include Lib\AutoHotInterception.ahk

; === Load ENV Configuration ===
scriptDir := A_ScriptDir
envPath := scriptDir "\.env"
if !FileExist(envPath) {
    MsgBox("Missing .env file! Create one with TRACKBALL_VID and TRACKBALL_PID specified.")
    ExitApp()
}

env := LoadEnv(envPath)

trackballVID := Integer(env["TRACKBALL_VID"])
trackballPID := Integer(env["TRACKBALL_PID"])
scrollMultiplier := Number(env.Get("BASE_MULTIPLIER", 3.0))
accelerationExponent := Number(env.Get("ACCELERATION_EXPONENT", 2.5))
smoothingFactor := Number(env.Get("SMOOTHING_FACTOR", 8))

AHI := AutoHotInterception()
currentDeviceId := 0

; Initialize device monitoring
SetTimer(CheckDeviceConnection, 30000)  ; Check every 30 seconds
CheckDeviceConnection()  ; Initial check

CheckDeviceConnection() {
    global AHI, trackballVID, trackballPID, currentDeviceId
    
    ; Get current device list
    deviceList := AHI.GetDeviceList()
    
    ; Look for our trackball
    foundDeviceId := 0
    for id, device in deviceList {
        if (device.IsMouse && device.VID = trackballVID && device.PID = trackballPID) {
            foundDeviceId := id
            break
        }
    }
    
    ; If device not found and we were previously connected
    if (!foundDeviceId && currentDeviceId != 0) {
        MsgBox("Trackball disconnected! Will attempt to reconnect when available.")
        currentDeviceId := 0
        return
    }
    
    ; If device found and it's different from our current device
    if (foundDeviceId && foundDeviceId != currentDeviceId) {
        ; Unsubscribe from old device if we were connected
        if (currentDeviceId != 0) {
            AHI.UnsubscribeMouseMoveRelative(currentDeviceId)
        }
        
        ; Subscribe to new device
        currentDeviceId := foundDeviceId
        AHI.SubscribeMouseMoveRelative(currentDeviceId, true, TrackballToScroll)
        MsgBox("Trackball reconnected! Handle: " currentDeviceId)
    }
}

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