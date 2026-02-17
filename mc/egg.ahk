#Requires AutoHotkey v2.0
#SingleInstance Force

autoLoopCounter := 0

XButton1:: {
    ; Save current mouse position
    MouseGetPos &originalX, &originalY
    
    Loop 3 {
        Send "{F4}"
        Sleep 250
        Click "Right"
        Sleep 250
        ; Home
        ; MouseMove A_ScreenWidth * 0.59, A_ScreenHeight * 0.52

        ; Work
        MouseMove A_ScreenWidth * 0.56, A_ScreenHeight * 0.50

        Send "+{Click}"
        MouseMove originalX, originalY
        Sleep 250
        Send "{Escape}"
        Sleep 250
    }
}

AutoLoop() {
    return
}


F8::ExitApp
F9::Reload()