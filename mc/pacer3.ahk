; Minecraft Auto-Walk Script with Timer
#Requires AutoHotkey v2.0
#SingleInstance Force

; Include the timer library
#Include timer_lib.ahk

; Global variables
global REVERSE_TIMER := 130
global mcHandle := 0
global autoWalkActive := false
global currentDirection := ""  ; "forward" or "backward"

; Initialize the timer on monitor 1, position (50, 50)
Timer_Initialize(1, 50, 50)

; Set up the timer expiration callback
Timer_SetOnExpire(OnTimerExpire)

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Callback function when timer expires
OnTimerExpire() {
    global autoWalkActive, currentDirection, REVERSE_TIMER
    
    if (!autoWalkActive) {
        return
    }
    
    handle := GetMinecraftHandle()
    if (!handle) {
        StopAutoWalk()
        return
    }
    
    ; Switch directions
    if (currentDirection = "forward") {
        ; Stop forward, start backward
        ControlSend("{w up}", ,"ahk_id " handle)
        Sleep(50)
        ControlSend("{s down}", ,"ahk_id " handle)
        currentDirection := "backward"
    } else if (currentDirection = "backward") {
        ; Stop backward, start forward
        ControlSend("{s up}", ,"ahk_id " handle)
        Sleep(50)
        ControlSend("{w down}", ,"ahk_id " handle)
        currentDirection := "forward"
    }
    
    ; Start next timer cycle
    Timer_Start(REVERSE_TIMER)
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

; Function to start auto-walk
StartAutoWalk() {
    global autoWalkActive, currentDirection, REVERSE_TIMER
    
    handle := GetMinecraftHandle()
    if (!handle) {
        MsgBox("Minecraft window not found!")
        return
    }
    
    autoWalkActive := true
    currentDirection := "forward"
    
    ; Send "w down" to start forward movement
    ControlSend("{w down}", ,"ahk_id " handle)
    
    ; Start the 16 second timer
    Timer_Start(REVERSE_TIMER)
    
    ; Show the timer
    Timer_Show()
}

; Function to stop auto-walk
StopAutoWalk() {
    global autoWalkActive, currentDirection
    
    handle := GetMinecraftHandle()
    if (handle) {
        ; Release whichever key is currently held
        if (currentDirection = "forward") {
            ControlSend("{w up}", ,"ahk_id " handle)
        } else if (currentDirection = "backward") {
            ControlSend("{s up}", ,"ahk_id " handle)
        }
    }
    
    autoWalkActive := false
    currentDirection := ""
    
    ; Stop the timer
    Timer_Stop()
}

; F2 - Toggle auto-walk on/off
F2:: {
    global autoWalkActive
    
    if (autoWalkActive) {
        StopAutoWalk()
        ToolTip("Auto-walk stopped")
        SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds
    } else {
        StartAutoWalk()
        ToolTip("Auto-walk started")
        SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds
    }
}

; F1 to toggle timer GUI visibility
F1:: {
    Timer_ToggleVisibility()
}

; F8 to exit script safely
F8:: {
    ; Make sure to release keys before exiting
    if (autoWalkActive) {
        StopAutoWalk()
    }
    ExitApp()
}
