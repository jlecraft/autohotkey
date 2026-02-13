; Example script showing how to use the Timer Library
#Requires AutoHotkey v2.0
#SingleInstance Force

storedHwnd := False

; Include the timer library
#Include timer_lib.ahk

; Initialize the timer
; Parameters: Timer_Initialize(monitor, xPos, yPos, width, height)
Timer_Initialize(1, 100, 100, 300, 100)

; Optional: Set up a callback function when timer expires
Timer_SetOnExpire(MyTimerExpiredFunction)

; Show the timer GUI on startup (optional)
Timer_Show()

; Example callback function
MyTimerExpiredFunction() {
    ; Play a sound when timer expires
    ; soundFile := A_ScriptDir . "\coin.wav"
    ; Timer_PlaySound(soundFile)
    
    ; You can do anything else here, like:
    ; - Show a message box
    ; - Run other code
    ; - Start another timer
    ; MsgBox("Timer has expired!")
}

CaptureWindow() {
    global storedHwnd

    if storedHwnd && WinExist("ahk_id " storedHwnd)
        return True

    ; Get window handle and control under the mouse
    MouseGetPos ,, &storedHwnd, &control

    ; Get the window title and class for that hwnd
    ; targettitle := WinGetTitle("ahk_id " storedHwnd)
    targetclass := WinGetClass("ahk_id " storedHwnd)
     ; storedHwnd := WinGetID("A")  ; "A" = active window

    if InStr(targetclass, "GLFW30") {
        ToolTip "Stored window handle: " storedHwnd
        SetTimer () => ToolTip(), -1000  ; hide tooltip after 1s
    } else {
        return False
    }
}

; Hotkey examples:

; F1 - Start a 60 second countdown
F1:: {
    Timer_ToggleVisibility()
}


F2:: {
    global storedHwnd

    if CaptureWindow() {
        ControlSend("{w down}", ,"ahk_id " storedHwnd)
        Timer_Start(1000)
    }
}

; ; F2 - Start a 90 second countdown
; F2:: {
;     Timer_Start(90)
; }

; ; F3 - Toggle timer visibility
; F3:: {
; }

; ; F4 - Pause the timer
; F4:: {
;     Timer_Pause()
; }

; ; F5 - Resume the timer
; F5:: {
;     Timer_Resume()
; }

; ; F6 - Stop and reset the timer
; F6:: {
;     Timer_Stop()
; }

; F7 - Show current timer value
; F7:: {
;     seconds := Timer_GetSeconds()
;     isRunning := Timer_IsRunning()
;     isCountingUp := Timer_IsCountingUp()
    
;     status := isRunning ? "Running" : "Stopped"
;     mode := isCountingUp ? " (Counting Up)" : ""
    
;     MsgBox("Timer: " seconds " seconds`nStatus: " status mode)
; }

; F8 - Exit script
F8:: {
    ExitApp()
}
