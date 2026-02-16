#Requires AutoHotkey v2.0
#SingleInstance Force

F1::
{
    ; Save current mouse position
    MouseGetPos &originalX, &originalY
    
    Loop 3 {
        Send "{F2}"
        Sleep 200
        Click "Right"
        Sleep 200
        MouseMove A_ScreenWidth * 0.59, A_ScreenHeight * 0.52
        Send "+{Click}"
        MouseMove originalX, originalY
        Sleep 200
        Send "{Escape}"
        Sleep 200
    }
}

F8::ExitApp
