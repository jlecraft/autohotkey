#Requires AutoHotkey v2.0
#SingleInstance Force

; F8 to exit the script
F8::ExitApp

; Check if XButton1 is held down when R is pressed
#HotIf GetKeyState("XButton1", "P")
r::
{
    Send "{Blind}{r up}"
    Send "{Blind}{r down}"
}
e::
{
    Send "{Blind}{e up}"
    Send "{Blind}{e down}"
}
#HotIf
