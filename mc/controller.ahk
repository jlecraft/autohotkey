#Requires AutoHotkey v2.0
#SingleInstance Force

; --- XInput via xinput1_4.dll (Windows 10/11) ---
XInputGetState(userIndex := 0) {
    static dll := "xinput1_4.dll"  ; Works on Win10/11
    state := Buffer(16, 0)         ; XINPUT_STATE is 16 bytes
    result := DllCall(dll "\XInputGetState"
        , "UInt", userIndex
        , "Ptr", state.Ptr
        , "UInt")
    return { ok: (result = 0), raw: state }
}

GetXInputData(userIndex := 0) {
    st := XInputGetState(userIndex)
    if !st.ok
        return false

    buf := st.raw

    ; layout:
    ; 0-3 = dwPacketNumber (UInt)
    ; 4-5 = wButtons (UShort)
    ; 6 = bLeftTrigger (UChar)
    ; 7 = bRightTrigger (UChar)
    ; 8-9 = sThumbLX (Short)
    ; 10-11 = sThumbLY (Short)
    ; 12-13 = sThumbRX (Short)
    ; 14-15 = sThumbRY (Short)

    buttons := NumGet(buf, 4, "UShort")
    lt := NumGet(buf, 6, "UChar")
    rt := NumGet(buf, 7, "UChar")
    lx := NumGet(buf, 8, "Short")
    ly := NumGet(buf, 10, "Short")
    rx := NumGet(buf, 12, "Short")
    ry := NumGet(buf, 14, "Short")

    return { Buttons: buttons, LT: lt, RT: rt, LX: lx, LY: ly, RX: rx, RY: ry }
}

; Button bitmasks
XINPUT_GAMEPAD_A       := 0x1000
XINPUT_GAMEPAD_B       := 0x2000
XINPUT_GAMEPAD_X       := 0x4000
XINPUT_GAMEPAD_Y       := 0x8000
XINPUT_GAMEPAD_START   := 0x0010
XINPUT_GAMEPAD_BACK    := 0x0020
XINPUT_GAMEPAD_LB      := 0x0100
XINPUT_GAMEPAD_RB      := 0x0200
XINPUT_GAMEPAD_DPAD_UP := 0x0001
XINPUT_GAMEPAD_DPAD_DN := 0x0002
XINPUT_GAMEPAD_DPAD_LT := 0x0004
XINPUT_GAMEPAD_DPAD_RT := 0x0008

Loop {
    data := GetXInputData(0) ; controller 1
    if !data {
        ToolTip "No XInput controller detected."
        Sleep 250
        continue
    }

    a := (data.Buttons & XINPUT_GAMEPAD_A) ? 1 : 0
    b := (data.Buttons & XINPUT_GAMEPAD_B) ? 1 : 0
    x := (data.Buttons & XINPUT_GAMEPAD_X) ? 1 : 0
    y := (data.Buttons & XINPUT_GAMEPAD_Y) ? 1 : 0

    ToolTip "XInput Controller OK`n"
        . "A:" a " B:" b " X:" x " Y:" y "`n"
        . "LT:" data.LT " RT:" data.RT "`n"
        . "LX:" data.LX " LY:" data.LY "`n"
        . "RX:" data.RX " RY:" data.RY

    Sleep 16
}
