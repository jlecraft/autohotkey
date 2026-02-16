; Minecraft Auto-Walk Script with Timer
#Requires AutoHotkey v2.0
#SingleInstance Force

; Include the timer library
#Include timer_lib.ahk

; Global variables
global mcHandle := 0

; Initialize the timer on monitor 1, position (50, 50)
Timer_Initialize(1, 50, 50)

; Set up the timer expiration callback
Timer_SetOnExpire(OnTimerExpire)
Timer_Show()

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Callback function when timer expires
OnTimerExpire() {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }

    return
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

F1:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }

    ControlClick , "ahk_id " handle, , "L", 1, "D"

    if Timer_IsRunning()
        Timer_Resume()
    else
        Timer_Start(0)

    ; Timer_Stop()
    ; ControlSend("{w up}", ,"ahk_id " handle)

    ToolTip("Start")
    SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds

    ; ControlSend("{w down}", ,"ahk_id " handle)
    ; Timer_Start(WALK_TIME)

    ; ToolTip("Walking...")
    ; SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds
}

; F1 to toggle timer GUI visibility
F3:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }

    ControlClick , "ahk_id " handle, , "L", 1, "U"

    Timer_Pause()
}

; F8 to exit script safely
F8:: {
    handle := GetMinecraftHandle()
    if (handle) {
        ControlClick , "ahk_id " handle, , "L", 1, "U"
    }

    ExitApp()
}
