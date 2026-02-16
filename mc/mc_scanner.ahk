#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Minecraft Java: find window once, store HWND, then stop scan
; UI: shows current state + status bar with storedHwnd
; States: Normal / Fishing / Bow
; Hotkeys:
;   Ctrl+N -> Normal
;   Ctrl+F -> Fishing
;   Ctrl+B -> Bow
;   Ctrl+WheelUp / Ctrl+WheelDown -> cycle states (optional)
;   F8 -> Exit script
; ============================================================

; ----------------------------
; Globals: Minecraft handle
; ----------------------------
global storedHwnd := 0

; Start scanning on launch (stops after found)
SetTimer ScanMinecraft, 200

; ----------------------------
; Globals: State system
; ----------------------------
global States := Map(
    "Normal",  {},
    "Fishing", {},
    "Bow",     {}
)
global StateOrder := ["Normal", "Fishing", "Bow"]
global CurrentState := "Normal"

; ----------------------------
; Globals: UI
; ----------------------------
global gGui := 0
global lblState := 0
global sb := 0

BuildUI()
UpdateUI()               ; initial paint
; gGui.Show("NA")          ; open automatically, don't steal focus

; ============================================================
; Hotkeys
; ============================================================

; Kill switch
F8::ExitApp

; Direct state selection
^n::SetState("Normal")
^f::SetState("Fishing")
^b::SetState("Bow")

; Optional: cycle states with Ctrl+MouseWheel
^WheelUp::CycleState(+1)
^WheelDown::CycleState(-1)

; ============================================================
; UI
; ============================================================

BuildUI() {
    global gGui, lblState, sb

    gGui := Gui("+AlwaysOnTop +MinSize320x160", "Minecraft State Controller")
    gGui.MarginX := 12, gGui.MarginY := 12
    gGui.OnEvent("Close", (*) => ExitApp())

    gGui.AddText("w300", "Current State:")

    ; FIXED: more vertical room + vertical centering
    lblState := gGui.AddText("w300 h40 +0x200", "")
    lblState.SetFont("s16 Bold")

    btnPrev := gGui.AddButton("w140", "⟵ Prev")
    btnNext := gGui.AddButton("x+10 w140", "Next ⟶")

    btnPrev.OnEvent("Click", (*) => CycleState(-1))
    btnNext.OnEvent("Click", (*) => CycleState(+1))

    sb := gGui.AddStatusBar()
}


UpdateUI() {
    global lblState, sb, storedHwnd

    if IsSet(lblState) && lblState {
        lblState.Text := GetState()
    }

    if IsSet(sb) && sb {
        sb.SetText("HWND: " (storedHwnd ? storedHwnd : "Not found"))
    }
}

; ============================================================
; One-time Minecraft window finder
; ============================================================
ScanMinecraft() {
    global storedHwnd

    for hwnd in WinGetList("ahk_exe javaw.exe") {
        title := WinGetTitle("ahk_id " hwnd)
        if InStr(title, "Minecraft") {
            storedHwnd := hwnd

            ; Stop scanning forever once found
            SetTimer ScanMinecraft, 0

            ; Refresh UI to show the found HWND
            UpdateUI()
            break
        }
    }
}

; ============================================================
; State API (use these everywhere)
; ============================================================
ArrayIndexOf(arr, needle) {
    for i, v in arr
        if (v = needle)
            return i
    return 0
}

GetState() {
    global CurrentState
    return CurrentState
}

IsState(name) {
    global CurrentState
    return CurrentState = name
}

SetState(name) {
    global States, CurrentState
    if States.Has(name) {
        CurrentState := name
        OnStateChanged()
    }
}

CycleState(direction := 1) {
    global StateOrder, CurrentState

    idx := ArrayIndexOf(StateOrder, CurrentState)
    if !idx
        return

    idx += direction
    if (idx < 1)
        idx := StateOrder.Length
    else if (idx > StateOrder.Length)
        idx := 1

    CurrentState := StateOrder[idx]
    OnStateChanged()
}

; ============================================================
; Hook: runs whenever state changes
; Put per-state logic/timers here.
; ============================================================
OnStateChanged() {
    ; Update UI label immediately
    UpdateUI()

    ; Optional small on-screen feedback
    ToolTip "State: " GetState()
    SetTimer () => ToolTip(), -500

    ; Example branching (fill in later)
    switch GetState() {
        case "Normal":
            ; normal logic
        case "Fishing":
            ; fishing logic
        case "Bow":
            ; bow logic
    }
}


<!$w:: {
    Send "{w}"
    Sleep(15)
    Send "{w down}"
}

*~s:: {
    if GetKeyState("w")
        Send "{w up}"
}

; XButton1 → send background right-click to that window
XButton1:: {
    if IsState("Fishing") {
        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")

        ControlSend("{d down}", ,"ahk_id " storedHwnd)
        Sleep(150)
        ControlSend("{d up}", ,"ahk_id " storedHwnd)        

        Sleep Random(100, 150)

        ; ControlClick(Control-or-Pos, WinTitle, WinText, WhichButton, ClickCount, Options, ExcludeTitle, Excld)
        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")

        return
    }

    if IsState("Bow") {
        bowMode := True
        ; ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")
        SetTimer(BowTimer, 50)
        return
    }

    Send "{LButton down}"
}

~$RButton:: {
    if IsState("Bow") {
        bowMode := False
        SetTimer(Bowtimer, 0)
    }
}

BowTimer() {
    if !IsState("Bow")
        return

    ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
    SoundBeep(100, 50)
    Sleep 1000
    ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")
    SoundBeep(300, 75)
    SoundBeep(300, 75)        
}