; Minecraft Auto-Walk Script with Timer
#Requires AutoHotkey v2.0
#SingleInstance Force

; Include the timer library
#Include timer_lib.ahk

; Global variables
global WALK_TIME := 130
global mcHandle := 0
global isWalking := False

; Initialize the timer on monitor 1, position (50, 50)
Timer_Initialize(1, 50, 50)

; Set up the timer expiration callback
Timer_SetOnExpire(OnTimerExpire)
Timer_Show()

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Callback function when timer expires
OnTimerExpire() {
    global WALK_TIME

    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }

    Sleep(1000)

    ControlSend("{F2}", , "ahk_id " handle)
    SoundBeep(200, 150)

    Sleep(1000)

    ControlSend("{F7}", , "ahk_id " handle)

    Sleep(1000)

    ControlSend("{w down}", ,"ahk_id " handle)

    Timer_Start(WALK_TIME)
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
    global WALK_TIME, isWalking

    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }

    if isWalking {
        ControlSend("{w up}", ,"ahk_id " handle)
        isWalking := False
        Timer_Stop()
        ToolTip("Stop walking")
        SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds
    } else {
        ControlSend("{w down}", ,"ahk_id " handle)
        isWalking := True
        Timer_Start(WALK_TIME)
        ToolTip("Walking...")
        SetTimer(() => ToolTip(), -2000)  ; Clear tooltip after 2 seconds
    }
}

; F1 to toggle timer GUI visibility
F3:: {
    Timer_ToggleVisibility()
}

; F8 to exit script safely
F8:: {
    handle := GetMinecraftHandle()
    if (handle) {
        ControlSend("{w up}", ,"ahk_id " handle)
    }

    ExitApp()
}
