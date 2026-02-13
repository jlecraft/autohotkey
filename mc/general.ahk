#Requires AutoHotkey v2.0
#SingleInstance Force

; Will hold the window handle we "bind" our macro to
storedHwnd := 0
fishingMode := False
fightMode := False
cookieMode := False

SetTimer(FindMinecraft, 2000)

ResetKeys() {
    if GetKeyState("LButton")
        Send "{LButton up}"

    if GetKeyState("RButton")
        Send "{RButton up}"
}

; --- Exit script with F8 ---
F8:: {
    ResetKeys()
    ExitApp()
}

; -----------------------------------------
; F1  →  Capture the current active window
; -----------------------------------------
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
        SetTimer(FindMinecraft, 0)
    } else {
        return False
    }

}

F1:: {
    CaptureWindow()
}

FindMinecraft() {
    CaptureWindow()
}

; -------------------------------------------------------
; XButton1  →  Send a right-click to that stored window
;              WITHOUT activating/changing focus
; -------------------------------------------------------

; XButton1 → send background right-click to that window
XButton1:: {
    global storedHwnd

    if CaptureWindow() {
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")

        ; ControlSend("{w down}", ,"ahk_id " storedHwnd)
        ; Sleep 100
        ; ControlSend("{d down}", ,"ahk_id " storedHwnd)        
        ; Sleep 100
    }
}

XButton2:: {
    global storedHwnd

    if CaptureWindow() {
        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")

        ; ControlSend("{w down}", ,"ahk_id " storedHwnd)        
        ; Sleep 100
        ; ControlSend("{d down}", ,"ahk_id " storedHwnd)        
        ; Sleep 100
    }
}

~*Escape:: {
    ResetKeys()
}