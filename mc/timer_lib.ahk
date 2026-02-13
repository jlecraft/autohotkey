; ============================================================================
; Timer Library for AutoHotkey v2
; ============================================================================
; This library provides a reusable countdown/countup timer with GUI display
;
; USAGE:
; 1. Include this file in your script: #Include timer_lib.ahk
; 2. Call Timer_Initialize() once at script startup
; 3. Call Timer_Start(seconds) to start a countdown
; 4. Call Timer_ToggleVisibility() to show/hide the GUI
; 5. Optionally set Timer_OnExpire to a custom callback function
;
; EXAMPLE:
;   #Include timer_lib.ahk
;   Timer_Initialize(2, 50, 50)  ; Monitor 2, x=50, y=50
;   Timer_OnExpire := MyCustomFunction
;   F1::Timer_ToggleVisibility()
;   F2::Timer_Start(90)
; ============================================================================

; Timer state variables
global Timer_CountdownSeconds := 0
global Timer_Running := false
global Timer_CountingUp := false
global Timer_Gui := ""
global Timer_GuiVisible := false
global Timer_OnExpire := ""  ; User-defined callback function

; ============================================================================
; Timer_Initialize(monitor := 1, xPos := 50, yPos := 50, width := 300, height := 100)
; ============================================================================
; Initializes the timer GUI. Call this once at script startup.
;
; Parameters:
;   monitor - Which monitor to display on (1 = primary, 2 = secondary, etc.)
;   xPos    - X position offset from left edge of monitor
;   yPos    - Y position offset from top edge of monitor
;   width   - Width of the timer GUI window
;   height  - Height of the timer GUI window
; ============================================================================
Timer_Initialize(monitor := 1, xPos := 50, yPos := 50, width := 300, height := 100) {
    global Timer_Gui
    
    Timer_Gui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Timer")
    Timer_Gui.BackColor := "0x000000"
    Timer_Gui.SetFont("s48 cFF8800 Bold", "Arial")  ; Orange color for inactive state
    
    ; Add text control for the timer display
    Timer_Gui.Add("Text", "w" width " h" (height - 20) " Center vTimerText", "00")
    
    ; Position on specified monitor
    MonitorGet(monitor, &Left, &Top, &Right, &Bottom)
    Timer_Gui.Show("x" (Left + xPos) " y" yPos " w" width " h" height " NoActivate Hide")
    
    WinSetTransColor("0x000000 200", Timer_Gui)
}

; ============================================================================
; Timer_Start(seconds)
; ============================================================================
; Starts a countdown timer for the specified number of seconds.
; When the timer reaches zero, it will:
;   1. Play a sound (if Timer_PlaySound is defined)
;   2. Call Timer_OnExpire callback (if defined)
;   3. Begin counting up in orange to show elapsed time
;
; Parameters:
;   seconds - Number of seconds to count down from
; ============================================================================
Timer_Start(seconds) {
    global Timer_CountdownSeconds, Timer_Running, Timer_CountingUp
    
    Timer_CountdownSeconds := seconds
    Timer_Running := true
    Timer_CountingUp := false
    Timer_UpdateDisplay()
    
    ; Start the countdown timer (updates every second)
    SetTimer(Timer_Tick, 1000)
}

; ============================================================================
; Timer_Stop()
; ============================================================================
; Stops the timer completely and resets to inactive state (orange "00")
; ============================================================================
Timer_Stop() {
    global Timer_CountdownSeconds, Timer_Running, Timer_CountingUp
    
    Timer_Running := false
    Timer_CountingUp := false
    Timer_CountdownSeconds := 0
    SetTimer(Timer_Tick, 0)
    Timer_UpdateDisplay()
}

; ============================================================================
; Timer_Pause()
; ============================================================================
; Pauses the timer at its current value
; ============================================================================
Timer_Pause() {
    global Timer_Running
    
    if (Timer_Running) {
        Timer_Running := false
        SetTimer(Timer_Tick, 0)
    }
}

; ============================================================================
; Timer_Resume()
; ============================================================================
; Resumes a paused timer
; ============================================================================
Timer_Resume() {
    global Timer_Running, Timer_CountdownSeconds
    
    if (!Timer_Running && Timer_CountdownSeconds >= 0) {
        Timer_Running := true
        SetTimer(Timer_Tick, 1000)
    }
}

; ============================================================================
; Timer_Show()
; ============================================================================
; Shows the timer GUI
; ============================================================================
Timer_Show() {
    global Timer_Gui, Timer_GuiVisible
    
    if (Timer_Gui) {
        Timer_Gui.Show("NoActivate")
        Timer_GuiVisible := true
    }
}

; ============================================================================
; Timer_Hide()
; ============================================================================
; Hides the timer GUI
; ============================================================================
Timer_Hide() {
    global Timer_Gui, Timer_GuiVisible
    
    if (Timer_Gui) {
        Timer_Gui.Hide()
        Timer_GuiVisible := false
    }
}

; ============================================================================
; Timer_ToggleVisibility()
; ============================================================================
; Toggles the timer GUI between shown and hidden
; ============================================================================
Timer_ToggleVisibility() {
    global Timer_GuiVisible
    
    if (Timer_GuiVisible) {
        Timer_Hide()
    } else {
        Timer_Show()
    }
}

; ============================================================================
; Timer_GetSeconds()
; ============================================================================
; Returns the current timer value in seconds
; ============================================================================
Timer_GetSeconds() {
    global Timer_CountdownSeconds
    return Timer_CountdownSeconds
}

; ============================================================================
; Timer_IsRunning()
; ============================================================================
; Returns true if the timer is currently running
; ============================================================================
Timer_IsRunning() {
    global Timer_Running
    return Timer_Running
}

; ============================================================================
; Timer_IsCountingUp()
; ============================================================================
; Returns true if the timer is in count-up mode (past expiration)
; ============================================================================
Timer_IsCountingUp() {
    global Timer_CountingUp
    return Timer_CountingUp
}

; ============================================================================
; Timer_SetOnExpire(callbackFunction)
; ============================================================================
; Sets a custom callback function to be called when the timer expires
;
; Parameters:
;   callbackFunction - Function to call when timer reaches zero
;
; Example:
;   MyCallback() {
;       MsgBox("Timer expired!")
;   }
;   Timer_SetOnExpire(MyCallback)
; ============================================================================
Timer_SetOnExpire(callbackFunction) {
    global Timer_OnExpire
    Timer_OnExpire := callbackFunction
}

; ============================================================================
; Timer_PlaySound(soundFile)
; ============================================================================
; Plays a sound file. Call this from your script or set as the expire callback.
;
; Parameters:
;   soundFile - Full path to the sound file to play
; ============================================================================
Timer_PlaySound(soundFile) {
    if FileExist(soundFile) {
        SoundPlay soundFile
    }
}

; ============================================================================
; INTERNAL FUNCTIONS (Do not call directly)
; ============================================================================

; Internal function to update the GUI display
Timer_UpdateDisplay() {
    global Timer_Gui, Timer_CountdownSeconds, Timer_Running, Timer_CountingUp
    
    if (Timer_Gui) {
        if (Timer_CountingUp) {
            ; Counting up mode - orange text
            Timer_Gui["TimerText"].Opt("cFF8800")
            Timer_Gui["TimerText"].Value := Timer_CountdownSeconds
        } else if (Timer_Running && Timer_CountdownSeconds > 0) {
            ; Active countdown - white text
            Timer_Gui["TimerText"].Opt("cWhite")
            Timer_Gui["TimerText"].Value := Timer_CountdownSeconds
        } else {
            ; Inactive timer - orange "00"
            Timer_Gui["TimerText"].Opt("cFF8800")
            Timer_Gui["TimerText"].Value := "00"
        }
    }
}

; Internal function called every second to update the countdown
Timer_Tick() {
    global Timer_CountdownSeconds, Timer_Running, Timer_CountingUp, Timer_OnExpire
    
    if (!Timer_Running) {
        SetTimer(Timer_Tick, 0)
        return
    }
    
    if (Timer_CountingUp) {
        ; Count up mode - increment
        Timer_CountdownSeconds += 1
        Timer_UpdateDisplay()
    } else {
        ; Count down mode - decrement
        Timer_CountdownSeconds -= 1
        
        ; Check if countdown has reached zero
        if (Timer_CountdownSeconds <= 0) {
            Timer_CountdownSeconds := 0
            Timer_CountingUp := true
            Timer_UpdateDisplay()
            
            ; Call user-defined callback if set
            if (Timer_OnExpire && IsObject(Timer_OnExpire)) {
                Timer_OnExpire.Call()
            }
            
            ; Continue running to count up
        } else {
            Timer_UpdateDisplay()
        }
    }
}
