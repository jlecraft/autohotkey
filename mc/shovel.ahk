; Minecraft AutoHotkey v2 Script
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global variable to store Minecraft window handle
global mcHandle := 0

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Function to scan for Minecraft window
ScanMinecraft() {
    global mcHandle
    ; Try to find Minecraft window by title (adjust if needed)
    newHandle := WinExist("Minecraft ahk_exe javaw.exe")
    if (!newHandle) {
        newHandle := WinExist("Minecraft ahk_exe java.exe")
    }
    if (!newHandle) {
        newHandle := WinExist("ahk_exe Minecraft.Windows.exe")
    }
    
    ; If we found Minecraft and didn't have it before, play sound
    if (newHandle && !mcHandle) {
        soundFile := A_ScriptDir . "\minecraft_found.mp3"
        SoundPlay soundFile
    }
    
    mcHandle := newHandle
}

; Function to validate and get Minecraft window handle
GetMinecraftHandle() {
    global mcHandle
    
    ; Check if current handle is still valid
    if (mcHandle && WinExist("ahk_id " mcHandle)) {
        return mcHandle
    }
    
    ; Try to find it again
    ScanMinecraft()
    
    ; Return the handle (could be 0 if not found)
    return mcHandle
}

; Function to release all held keys
ReleaseAllKeys() {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Blindly release w, d, and left mouse button
    ControlSend "{w up}", , "ahk_id " handle
    ControlSend "{d up}", , "ahk_id " handle
    ControlClick , "ahk_id " handle, , "L", 1, "U"
}

; XButton1 function - sends w down, d down, left click down
XButton1:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Only work if Minecraft is active
    if (!WinActive("ahk_id " handle)) {
        return
    }
    
    ; Send keys directly to Minecraft window with 100ms delays
    ControlSend "{w down}", , "ahk_id " handle
    Sleep 100
    ControlSend "{d down}", , "ahk_id " handle
    Sleep 100
    ControlClick , "ahk_id " handle, , "L", 1, "D"
}

; XButton2 function - holds down left click
XButton2:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Only work if Minecraft is active
    if (!WinActive("ahk_id " handle)) {
        return
    }
    
    ; Hold down left click
    ControlClick , "ahk_id " handle, , "L", 1, "D"
}

; Auto-release function for escape only
~Escape:: {
    handle := GetMinecraftHandle()
    if (!handle || !WinActive("ahk_id " handle)) {
        return
    }
    
    ReleaseAllKeys()
}

; F8 to exit script safely
F8:: {
    ReleaseAllKeys()
    ExitApp
}