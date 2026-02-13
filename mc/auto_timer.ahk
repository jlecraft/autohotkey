; Minecraft AutoHotkey v2 Script with Countdown Timer
#Requires AutoHotkey v2.0
#SingleInstance Force

; Include the timer library
#Include timer_lib.ahk

; Global variable to store Minecraft window handle
global mcHandle := 0

; Initialize the timer on monitor 1, position (50, 50)
Timer_Initialize(1, 50, 50)

; Set up the timer expiration callback to play coin.wav
Timer_SetOnExpire(OnTimerExpire)

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Callback function when timer expires
OnTimerExpire() {
    soundFile := A_ScriptDir . "\coin.wav"
    Timer_PlaySound(soundFile)
}

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
        if FileExist(soundFile) {
            SoundPlay soundFile
        }
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

; Centralized function for right-click action and timer start
PerformMinecraftAction() {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Send command to Minecraft even if it's in the background
    ControlClick , "ahk_id " handle, , "R", 1, "D"
    Sleep 400
    ControlClick , "ahk_id " handle, , "R", 1, "U"

    ; Start the countdown timer for 120 seconds
    Timer_Start(120)
}

; XButton2 hotkey - calls centralized function
XButton2:: {
    PerformMinecraftAction()
}

; Joy1 hotkey - calls centralized function
Joy1:: {
    PerformMinecraftAction()
}

; F4 hotkey - calls centralized function
F4:: {
    PerformMinecraftAction()
}

; F1 to toggle timer GUI visibility
F1:: {
    Timer_ToggleVisibility()
}

; F8 to exit script safely
F8:: {
    ExitApp()
}
