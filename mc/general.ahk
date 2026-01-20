#Requires AutoHotkey v2.0
#SingleInstance Force

; Will hold the window handle we "bind" our macro to
storedHwnd := 0
fishingMode := False
fightMode := False
cookieMode := False

SetTimer(FindMinecraft, 2000)

XButton2:: {
    Send "{RButton down}"
}

<!$w:: {
    global storedHwnd
    ControlSend("{w down}", ,"ahk_id " storedHwnd)
}

*~s:: {
    if GetKeyState("w")
        Send "{w up}"
}

^f:: {  
    global fishingMode
    msg := "Nothing changed"

    if (fishingMode) {
        fishingMode := False
        msg := "Fishing mode DISABLED"
    } else {
        fishingMode := True
        msg := "Fishing mode ENABLED"
    }

    ToolTip "" msg
    SetTimer () => ToolTip(), -1000  ; hide tooltip after 1s
}

^s:: {
    global fightMode

    if fightMode {
        fightMode := False
        SetTimer(FightTimer, 0)
    } else {
        fightMode := True
        SetTimer(FightTimer, 10000)
    }

    ToolTip "Fight Mode: " fightMode
    SetTimer () => ToolTip(), -1000  ; hide tooltip after 1s
}

; --- Exit script with F8 ---
F8:: {
    ; If left button is physically down, release it
    if GetKeyState("LButton")
        Send "{LButton up}"

    if GetKeyState("RButton")
        Send "{RButton up}"

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
        SoundBeep(400, 75)
        storedHwnd := False
        return False
    }

}

F1:: {
    CaptureWindow()
}

FindMinecraft() {
    CaptureWindow()
}

F2:: {
    global cookieMode

    if cookieMode {
        SetTimer(CookieTimer, 0)
        cookieMode := False
    } else {
        SetTimer(CookieTimer, 500)
        cookieMode := True
    }
}

; -------------------------------------------------------
; XButton1  →  Send a right-click to that stored window
;              WITHOUT activating/changing focus
; -------------------------------------------------------

; XButton1 → send background right-click to that window
XButton1:: {
    global storedHwnd
    global fishingMode

    ; Send w, then d, then left click down
    if True {
        ControlSend("{w down}", ,"ahk_id " storedHwnd)        
        Sleep 100
        ControlSend("{d down}", ,"ahk_id " storedHwnd)        
        Sleep 100
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")

        return
    }

    if !fishingMode
        Send "{LButton down}"
    else {
        ; no stored window or it no longer exists
        if !CaptureWindow() {
            SoundBeep(200, 200)
            return
        }

        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")

        Sleep(150)

        ControlSend("{d down}", ,"ahk_id " storedHwnd)
        Sleep(150)
        ControlSend("{d up}", ,"ahk_id " storedHwnd)        

        Sleep(150)

        ; ControlClick(Control-or-Pos, WinTitle, WinText, WhichButton, ClickCount, Options, ExcludeTitle, Excld)
        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")
    }
}

FightTimer() {
    global storeHwnd

    if storedHwnd && WinExist("ahk_id " storedHwnd) {
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Left", 1, "NA U")
    }
}


CookieTimer() {
    global storedHwnd

    if storedHwnd && WinExist("ahk_id " storedHwnd) {
        MouseMove(1415, 590, 0)
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Left", 1, "NA U")

        Sleep 500

        MouseMove(1615, 590, 0)
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Left", 1, "NA U")
    }
}


; ; ========================
; ; Toggle Repeated E Mode
; ; ========================
; F4:: {
;     SetTimer(PressE, 100)
; }

; F5:: {
;     SetTimer(PressE, 0)
; }

; PressE() {
;     static state := false

;     if state {
;         Send "{e up}"
;         state := false
;         ; Sleep(1100)
;     } else {
;         Send "{e down}"
;         state := true
;         Sleep(500)
;     }
; }