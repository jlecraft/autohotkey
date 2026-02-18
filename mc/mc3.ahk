#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Minecraft Java: find window once, store HWND, then stop scan
; UI: shows current state + status bar (now shows state + fishing avg)
; States: Normal / Fishing / Bow
; Hotkeys:
;   Ctrl+N -> Normal
;   Ctrl+F -> Fishing (resets fishing timing stats)
;   Ctrl+B -> Bow
;   Ctrl+WheelUp / Ctrl+WheelDown -> cycle states (optional)
;   F8 -> Exit script
; ============================================================

; ----------------------------
; Globals: Minecraft handle
; ----------------------------
global storedHwnd := 0

; Start scanning on launch (stops after found)F
SetTimer ScanMinecraft, 200

; ----------------------------
; Globals: State system
; ----------------------------
global States := Map(
    "Normal",  {},
    "Fishing", {},
    "Bow",     {},
    "Sword",   {}
)

; Order matters for cycling
global StateOrder := ["Normal", "Fishing", "Bow", "Sword"]

; Current state (string key)
global CurrentState := "Normal"

; ----------------------------
; Fishing timing stats (XButton1 in Fishing mode)
; ----------------------------
global FishingIntervals := []   ; stores each delta in ms
global FishingSumMs := 0        ; running sum
global FishingLastTick := 0     ; last A_TickCount
global FishingAvgMs := 0        ; cached average (rounded)
global FishingCasts := 0        ; total casts

; ----------------------------
; Fishing timing stats (XButton1 in Fishing mode)
; ----------------------------
global swordCount := 0

; ----------------------------
; Globals: UI
; ----------------------------
global gGui := 0
global lblState := 0
global sb := 0

BuildUI()
UpdateUI()               ; initial paint
; gGui.Show("NA")          ; open automatically, don't steal focus

; ==========================
;  XInput Button Callback System (AHK v2)
;  - polls controller 0
;  - calls bound functions on button press (edge)
; ==========================

; global XInput_Bindings := Map()       ; mask -> Func/Closure
; global XInput_PrevButtons := 0
; global XInput_ControllerIndex := 0    ; 0 = first controller
; global XInput_PollMs := 16            ; 16ms = ~60Hz (use 33 for ~30Hz)

; ; --- Button bitmasks ---
; global XBTN := Map(
;     "DPAD_UP",    0x0001,
;     "DPAD_DOWN",  0x0002,
;     "DPAD_LEFT",  0x0004,
;     "DPAD_RIGHT", 0x0008,
;     "START",      0x0010,
;     "BACK",       0x0020,
;     "LS",         0x0040, ; Left stick click
;     "RS",         0x0080, ; Right stick click
;     "LB",         0x0100,
;     "RB",         0x0200,
;     "A",          0x1000,
;     "B",          0x2000,
;     "X",          0x4000,
;     "Y",          0x8000
; )

; ; --- Call once to bind a button press to a function ---
; XInput_OnPress(btnName, callback) {
;     global XInput_Bindings, XBTN
;     if !XBTN.Has(btnName)
;         throw Error("Unknown XInput button name: " btnName)
;     XInput_Bindings[XBTN[btnName]] := callback
; }

; ; --- Start polling (call once after you set bindings) ---
; XInput_Start() {
;     global XInput_PollMs
;     SetTimer XInput_Poll, XInput_PollMs
; }

; ; --- Stop polling if needed ---
; XInput_Stop() {
;     SetTimer XInput_Poll, 0
; }

; ; --- Read XInput state (buttons only) ---
; XInput_GetButtons(userIndex := 0) {
;     static dll := "xinput1_4.dll"   ; Win10/11
;     state := Buffer(16, 0)
;     res := DllCall(dll "\XInputGetState", "UInt", userIndex, "Ptr", state.Ptr, "UInt")
;     if (res != 0)
;         return false
;     return NumGet(state, 4, "UShort") ; wButtons
; }

; ; --- Poll loop: detect press edges and fire callbacks ---
; XInput_Poll() {
;     global XInput_ControllerIndex, XInput_PrevButtons, XInput_Bindings

;     buttons := XInput_GetButtons(XInput_ControllerIndex)
;     if (buttons = false)
;         return

;     ; pressed this poll (edge): down now AND was up previously
;     pressed := buttons & ~XInput_PrevButtons

;     for mask, cb in XInput_Bindings {
;         if (pressed & mask)
;             cb.Call()
;     }

;     XInput_PrevButtons := buttons
; }

; ============================================================
; Hotkeys
; ============================================================

; Kill switch
F8::ExitApp

; Direct state selection
^n::SetState("Normal")

^f:: {
    ResetFishingStats()
    SetState("Fishing")
}

^s::SetState("Sword")

^b::SetState("Bow")

; Optional: cycle states with Ctrl+MouseWheel
^WheelUp::CycleState(+1)
^WheelDown::CycleState(-1)

; ============================================================
; UI
; ============================================================
GetMonitorFromPoint(x, y) {
    count := MonitorGetCount()
    Loop count {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (x >= l && x < r && y >= t && y < b)
            return A_Index
    }
    return 1
}

GetOtherMonitorIndex(activeMon) {
    count := MonitorGetCount()
    if (count = 1)
        return 1
    ; choose any monitor that isn't activeMon (first match)
    Loop count {
        if (A_Index != activeMon)
            return A_Index
    }
    return 1
}

BuildUI() {
    global gGui, lblState, sb

    gGui := Gui("+AlwaysOnTop +MinSize320x160", "Minecraft State Controller")
    gGui.MarginX := 12, gGui.MarginY := 12
    gGui.OnEvent("Close", (*) => ExitApp())  ; closing UI exits script

    gGui.AddText("w360", "Current State:")

    ; give more vertical room + vertical centering
    lblState := gGui.AddText("w360 h40 +0x200", "")
    lblState.SetFont("s16 Bold")

    btnPrev := gGui.AddButton("w170", "⟵ Prev")
    btnNext := gGui.AddButton("x+10 w170", "Next ⟶")

    btnPrev.OnEvent("Click", (*) => CycleState(-1))
    btnNext.OnEvent("Click", (*) => CycleState(+1))

    sb := gGui.AddStatusBar()
}

UpdateUI() {
    global lblState, sb
    global CurrentState, FishingAvgMs, FishingIntervals

    if IsSet(lblState) && lblState
        lblState.Text := CurrentState

    if IsSet(sb) && sb {
        if (CurrentState = "Fishing") {
            avgText := FishingIntervals.Length ? (FishingAvgMs " ms") : "—"
            sb.SetText("State: " CurrentState " | Avg: " avgText " (" FishingCasts ")")
        } else {
            sb.SetText("State: " CurrentState)
        }
    }
}

ShowGuiOnNonMinecraftMonitor() {
    global gGui, storedHwnd

    ; If Minecraft not found yet, just show on primary
    if !storedHwnd {
        gGui.Show("NA")
        return
    }

    ; Get Minecraft window position
    WinGetPos &x, &y, &w, &h, "ahk_id " storedHwnd
    centerX := x + w//2
    centerY := y + h//2

    mcMon := GetMonitorFromPoint(centerX, centerY)
    targetMon := GetOtherMonitorIndex(mcMon)

    ; Get the target monitor work area (excludes taskbar)
    MonitorGetWorkArea(targetMon, &l, &t, &r, &b)

    ; Place GUI near top-left of that monitor (with padding)
    gx := l + 30
    gy := t + 30

    gGui.Show("NA x" gx " y" gy)
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
            ShowGuiOnNonMinecraftMonitor()
            ; Refresh UI (optional)
            ; UpdateUI()
            break
        }
    }
}

; ============================================================
; Fishing timing helpers
; ============================================================
ResetFishingStats() {
    global FishingIntervals, FishingSumMs, FishingLastTick, FishingAvgMs, FishingCasts
    FishingIntervals := []
    FishingSumMs := 0
    FishingLastTick := 0
    FishingAvgMs := 0
    FishingCasts := 0
    UpdateUI()
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

    ; Optional /all on-screen feedback
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

; ============================================================
; Existing hotkeys / logic (unchanged)
; ============================================================

<!$w:: {
    Send "{w}"
    Sleep(15)
    Send "{w down}"
}

*~s:: {
    if GetKeyState("w")
        Send "{w up}"
}


~XButton2:: {
    Send "{Click Right Down}"
}


XButtonLogic() {
    global FishingLastTick, FishingIntervals, FishingSumMs, FishingAvgMs, FishingCasts
    global swordCounter

    if IsState("Fishing") {
        FishingCasts += 1
        ; --- Timing: track ms between XButton1 presses in Fishing mode ---
        now := A_TickCount
        if (FishingLastTick) {
            delta := now - FishingLastTick
            FishingIntervals.Push(delta)
            FishingSumMs += delta
            FishingAvgMs := Round(FishingSumMs / FishingIntervals.Length)
            ; FishingAvgMs := delta
            UpdateUI()
        }
        FishingLastTick := now

        ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")

        ; ControlSend("{d down}", ,"ahk_id " storedHwnd)
        ; Sleep(25)
        ; ControlSend("{d up}", ,"ahk_id " storedHwnd)

        Sleep Random(750, 1000)

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

    if IsState("Sword") {
        swordCounter := 4
        SetTimer(SwordTimer, 100)
        SoundBeep(200, 100)
        return
    }

    Send "{LButton down}"
}

~$RButton:: {
    global bowMode

    if IsState("Bow") {
        bowMode := False
        SetTimer(Bowtimer, 0)
    }
}


~$LButton:: {
    if IsState("Sword") {
        SetTimer(SwordTimer, 0)
    }
}

XButton1:: {
    XButtonLogic()
}

BowTimer() {
    if !IsState("Bow")
        return

    ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
    ; SoundBeep(100, 50)
    Sleep 200
    ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")
    Sleep 50
}

SwordTimer() {
    global swordCounter

    if !IsState("Sword") {
        SetTimer(SwordTimer, 0)
        return
    }

    swordCounter -= 1

    if (swordCounter <= 0) {
        ControlClick(, "ahk_id " storedHwnd, , "Left", 1, "NA D")
        Sleep 50
        ControlClick(,"ahk_id " storedHwnd, , "Left", 1, "NA U")

        swordCounter := Random(3, 5)
    }
}

QuickTooltip(txt) {
    ToolTip txt
    SetTimer () => ToolTip(), -1000  ; hide tooltip after 1s    
}


; 1 = square, 2 = X, 3 = circle, 4 = triangle
; 5/6 top triggers
; 7/8 bottom triggerseeee

; XInput_OnPress("A", XButtonLogic)
; XInput_Start()


Joy1:: {
    XButtonLogic()
}
;     ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
;     Sleep 50
;     ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")    

;     Sleep 200

;     ControlClick(, "ahk_id " storedHwnd, , "Right", 1, "NA D")
;     Sleep 50
;     ControlClick(,"ahk_id " storedHwnd, , "Right", 1, "NA U")    
; }

; Joy2:: {
;     SoundBeep(150, 150)
; }

; Joy4:: {
;     ControlSend "/", , "ahk_id " storedHwnd
;     Sleep 100
;     ControlSend "a", , "ahk_id " storedHwnd
;     ControlSend "h", , "ahk_id " storedHwnd
;     Sleep 100
;     ControlSend "{Enter}", , "ahk_id " storedHwnd
; }

; Joy7:: {
;     ControlSend "{Escape}", , "ahk_id " storedHwnd
; }

; Joy8:: {
;     ControlSend "{Esca[e]}", , "ahk_id " storedHwnd
; }

; XButton1 → send background right-click to that window
