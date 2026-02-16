#Requires AutoHotkey v2.0
#SingleInstance Force

msg := ""
Loop 16 {
    n := A_Index
    name := GetKeyState("JoyName", n)
    if (name != "")
        msg .= "Joy" n ": " name "`n"
}
MsgBox msg = "" ? "No joysticks detected by AHK." : msg
