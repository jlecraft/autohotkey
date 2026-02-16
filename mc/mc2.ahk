#Requires AutoHotkey v2.0
#SingleInstance Force

; ----------------------------
; Global state model
; ----------------------------
global States := ["Idle", "Running", "Paused", "Combat"]
global StateIndex := 1

; ----------------------------
; UI
; ----------------------------
global gGui := Gui("+AlwaysOnTop", "State Controller")
gGui.MarginX := 12, gGui.MarginY := 12

gGui.AddText("w260", "Current State:")
global lblState := gGui.AddText("w260 r1 +0x200", "")  ; +0x200 = SS_CENTERIMAGE-ish vertical align
lblState.SetFont("s14 Bold")

btnPrev := gGui.AddButton("w120", "⟵ Prev")
btnNext := gGui.AddButton("x+10 w120", "Next ⟶")

btnPrev.OnEvent("Click", (*) => ChangeState(-1))
btnNext.OnEvent("Click", (*) => ChangeState(+1))

gGui.OnEvent("Close", (*) => ExitApp())

UpdateStateUI()
gGui.Show()

; ----------------------------
; Hotkeys
; ----------------------------
; Change these to taste
F1::SetStateByIndex(1)       ; jump to first state
F2::ChangeState(-1)          ; previous
F3::ChangeState(+1)          ; next

; Mouse wheel example (optional):
; #HotIf WinActive("ahk_exe whatever.exe") ; scope hotkeys to a specific app if you want
; WheelUp::ChangeState(+1)
; WheelDown::ChangeState(-1)
; #HotIf

; ----------------------------
; Functions
; ----------------------------
ChangeState(delta) {
    global States, StateIndex
    len := States.Length

    StateIndex += delta
    if (StateIndex < 1)
        StateIndex := len
    else if (StateIndex > len)
        StateIndex := 1

    UpdateStateUI()
    OnStateChanged()
}

SetStateByIndex(index) {
    global States, StateIndex
    if (index < 1 || index > States.Length)
        return
    StateIndex := index
    UpdateStateUI()
    OnStateChanged()
}

GetState() {
    global States, StateIndex
    return States[StateIndex]
}

UpdateStateUI() {
    global lblState
    lblState.Text := GetState()
}

OnStateChanged() {
    ; Hook point: add behavior when the state changes.
    ; Example:
    ; ToolTip "State changed to: " GetState()
    ; SetTimer () => ToolTip(), -800
}
