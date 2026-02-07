; Minecraft AutoHotkey v2 Script with Countdown Timer
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global variable to store Minecraft window handle
global mcHandle := 0

; Countdown timer variables
global countdownSeconds := 0
global timerRunning := false
global countingUp := false  ; New variable to track if we're counting up
global timerGui := ""
global guiVisible := false

; Create the GUI
CreateTimerGui()

; Continuously scan for Minecraft window
SetTimer(ScanMinecraft, 2000)

; Function to create the countdown timer GUI
CreateTimerGui() {
    global timerGui
    
    timerGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Timer")
    timerGui.BackColor := "0x000000"
    timerGui.SetFont("s48 cFF8800 Bold", "Arial")  ; Orange color for inactive state
    
    ; Add text control for the timer display
    timerGui.Add("Text", "w300 h80 Center vTimerText", "00")
    
    ; Position in top-right corner (adjust as needed)
    timerGui.Show("x" (A_ScreenWidth - 350) " y50 w300 h100 NoActivate Hide")
    
    WinSetTransColor("0x000000 200", timerGui)
}

; Function to update the GUI display
UpdateTimerDisplay() {
    global timerGui, countdownSeconds, timerRunning, countingUp
    
    if (timerGui) {
        if (countingUp) {
            ; Counting up mode - orange text
            timerGui["TimerText"].Opt("cFF8800")
            timerGui["TimerText"].Value := countdownSeconds
        } else if (timerRunning && countdownSeconds > 0) {
            ; Active countdown - white text
            timerGui["TimerText"].Opt("cWhite")
            timerGui["TimerText"].Value := countdownSeconds
        } else {
            ; Inactive timer - orange "00"
            timerGui["TimerText"].Opt("cFF8800")
            timerGui["TimerText"].Value := "00"
        }
    }
}

; Function to show/hide the GUI
ToggleTimerGui() {
    global timerGui, guiVisible
    
    if (guiVisible) {
        timerGui.Hide()
        guiVisible := false
    } else {
        timerGui.Show("NoActivate")
        guiVisible := true
    }
}

; Function to start the countdown timer
StartCountdown() {
    global countdownSeconds, timerRunning, countingUp
    
    countdownSeconds := 90
    timerRunning := true
    countingUp := false  ; Reset counting up state
    UpdateTimerDisplay()
    
    ; Start the countdown timer (updates every second)
    SetTimer(CountdownTick, 1000)
}

; Function called every second to update the countdown
CountdownTick() {
    global countdownSeconds, timerRunning, countingUp
    
    if (!timerRunning) {
        SetTimer(CountdownTick, 0)  ; Stop the timer
        return
    }
    
    if (countingUp) {
        ; Count up mode - increment
        countdownSeconds += 1
        UpdateTimerDisplay()
    } else {
        ; Count down mode - decrement
        countdownSeconds -= 1
        
        ; Check if countdown has reached zero
        if (countdownSeconds <= 0) {
            countdownSeconds := 0
            countingUp := true  ; Switch to counting up mode
            UpdateTimerDisplay()  ; Show orange "00"
            PlayTimerSound()
            ; Don't stop the timer - keep it running to count up
        } else {
            UpdateTimerDisplay()
        }
    }
}

; Function to play sound when timer expires
PlayTimerSound() {
    ; Play coin.wav from the script directory
    soundFile := A_ScriptDir . "\coin.wav"
    if FileExist(soundFile) {
        SoundPlay soundFile
    }
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


; XButton2 function - holds down left click AND starts countdown timer
XButton2:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Send command to Minecraft even if it's in the background
    ControlClick , "ahk_id " handle, , "R", 1, "D"
    Sleep 400
    ControlClick , "ahk_id " handle, , "R", 1, "U"

    ; Start the countdown timer
    StartCountdown()
}

; Joy1 function - same functionality as XButton2
Joy1:: {
    handle := GetMinecraftHandle()
    if (!handle) {
        return
    }
    
    ; Send command to Minecraft even if it's in the background
    ControlClick , "ahk_id " handle, , "R", 1, "D"
    Sleep 400
    ControlClick , "ahk_id " handle, , "R", 1, "U"

    ; Start the countdown timer
    StartCountdown()
}

; F1 to toggle timer GUI visibility
F1:: {
    ToggleTimerGui()
}

; F8 to exit script safely
F8:: {
    ExitApp
}
