#Requires AutoHotkey v2.0

; ============================================================================
; CONFIGURATION
; ============================================================================

; Beat duration in milliseconds (1 Beat = 100ms)
global BEAT_DURATION := 100

; Hotkey to trigger/stop the command sequence
global TRIGGER_KEY := "XButton1"

; Number of times to repeat the queue when triggered
global REPEAT_COUNT := 3

; ============================================================================
; SEQUENCE STATE
; ============================================================================

global commandQueue := []
global currentCommandIndex := 0
global waitBeatsRemaining := 0
global isSequenceRunning := false
global savedMouseX := 0
global savedMouseY := 0
global currentRepetition := 0
global totalRepetitions := 0

; ============================================================================
; COMMAND QUEUE DEFINITION
; ============================================================================
; Define your command sequence here as an array of maps
; Each command has a "type" and optional parameters

global commandQueueTemplate := [
    {type: "SaveMousePos"},
    {type: "SendKey", key: "{F4}"},
    {type: "Wait", beats: 2},
    {type: "RightClick"},
    {type: "Wait", beats: 2},
    {type: "MoveMousePercent", x: 56, y: 50},
    {type: "SendKey", key: "+{Click}"}, ; Shift+Left Click
    {type: "Wait", beats: 1},
    {type: "RestoreMousePos"},
    {type: "Wait", beats: 2},
    {type: "SendKey", key: "{Esc}"},
    {type: "Wait", beats: 2}
]

; ============================================================================
; COMMAND FUNCTIONS
; ============================================================================

SaveMousePos() {
    global savedMouseX, savedMouseY
    MouseGetPos(&savedMouseX, &savedMouseY)
}

RestoreMousePos() {
    global savedMouseX, savedMouseY
    MouseMove(savedMouseX, savedMouseY)
}

SendKey(key) {
    Send(key)
}

SendText(text) {
    SendText(text)
}

RightClick() {
    Click("Right")
}

LeftClick() {
    Click("Left")
}

MiddleClick() {
    Click("Middle")
}

DoubleClick() {
    Click(2)
}

MoveMousePercent(x, y) {
    ; Get screen dimensions
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    
    ; Calculate pixel coordinates
    targetX := Round(screenWidth * x / 100)
    targetY := Round(screenHeight * y / 100)
    
    MouseMove(targetX, targetY)
}

MoveMousePixels(x, y) {
    MouseMove(x, y)
}

MoveMouseRelative(deltaX, deltaY) {
    global savedMouseX, savedMouseY
    MouseGetPos(&currentX, &currentY)
    MouseMove(currentX + deltaX, currentY + deltaY)
}

ScrollWheel(amount) {
    ; Positive = scroll up, negative = scroll down
    if (amount > 0) {
        Click("WheelUp " . Abs(amount))
    } else if (amount < 0) {
        Click("WheelDown " . Abs(amount))
    }
}

; ============================================================================
; COMMAND EXECUTION
; ============================================================================

ExecuteCommand(cmd) {
    ; Execute command based on type and return true if it's a Wait command
    switch cmd.type {
        case "SaveMousePos":
            SaveMousePos()
            return false
        case "RestoreMousePos":
            RestoreMousePos()
            return false
        case "SendKey":
            SendKey(cmd.key)
            return false
        case "SendText":
            SendText(cmd.text)
            return false
        case "RightClick":
            RightClick()
            return false
        case "LeftClick":
            LeftClick()
            return false
        case "MiddleClick":
            MiddleClick()
            return false
        case "DoubleClick":
            DoubleClick()
            return false
        case "MoveMousePercent":
            MoveMousePercent(cmd.x, cmd.y)
            return false
        case "MoveMousePixels":
            MoveMousePixels(cmd.x, cmd.y)
            return false
        case "MoveMouseRelative":
            MoveMouseRelative(cmd.deltaX, cmd.deltaY)
            return false
        case "ScrollWheel":
            ScrollWheel(cmd.amount)
            return false
        case "Wait":
            return true ; Signal that this is a wait command
        default:
            MsgBox("Unknown command type: " cmd.type)
            StopSequence("Error: Unknown command type")
            return false
    }
}

; ============================================================================
; TIMER CALLBACK - EXECUTES EVERY BEAT
; ============================================================================

OnBeatTimer() {
    global currentCommandIndex, waitBeatsRemaining, commandQueue, isSequenceRunning
    global currentRepetition, totalRepetitions, commandQueueTemplate
    
    ; If we're waiting, decrement the counter
    if (waitBeatsRemaining > 0) {
        waitBeatsRemaining--
        return
    }
    
    ; Execute commands until we hit a Wait or finish the queue
    while (true) {
        ; If we've finished all commands in this repetition
        if (currentCommandIndex > commandQueue.Length) {
            currentRepetition++
            
            ; Check if we need to repeat
            if (currentRepetition < totalRepetitions) {
                ; Reset for next repetition
                commandQueue := commandQueueTemplate.Clone()
                currentCommandIndex := 1
                continue ; Continue executing from the start of the next repetition
            } else {
                ; All repetitions complete
                StopSequence("Command sequence completed! (" . totalRepetitions . " repetition" . (totalRepetitions > 1 ? "s" : "") . ")")
                return
            }
        }
        
        ; Get the current command
        cmd := commandQueue[currentCommandIndex]
        currentCommandIndex++
        
        ; Execute the command
        isWaitCommand := ExecuteCommand(cmd)
        
        ; If it's a Wait command, set up the wait timer and exit the loop
        if (isWaitCommand) {
            waitBeatsRemaining := cmd.beats - 1 ; Subtract 1 because this beat is already consumed
            break
        }
        
        ; Otherwise, continue to the next command immediately
    }
}

; ============================================================================
; SEQUENCE CONTROL
; ============================================================================

StartSequence() {
    global isSequenceRunning, currentCommandIndex, waitBeatsRemaining
    global commandQueue, commandQueueTemplate, BEAT_DURATION
    global currentRepetition, totalRepetitions, REPEAT_COUNT
    
    ; Don't start if already running
    if (isSequenceRunning) {
        return
    }
    
    ; Initialize sequence state
    commandQueue := commandQueueTemplate.Clone()
    currentCommandIndex := 1
    waitBeatsRemaining := 0
    currentRepetition := 0
    totalRepetitions := REPEAT_COUNT
    isSequenceRunning := true
    
    ; Start the timer
    SetTimer(OnBeatTimer, BEAT_DURATION)
    
    repetitionText := REPEAT_COUNT > 1 ? " (x" . REPEAT_COUNT . ")" : ""
    ToolTip("Command sequence started!" . repetitionText)
    SetTimer(() => ToolTip(), -1000)
}

StopSequence(message := "Command sequence stopped!") {
    global isSequenceRunning, BEAT_DURATION
    
    ; Stop the timer
    SetTimer(OnBeatTimer, 0)
    
    ; Reset state
    isSequenceRunning := false
    
    ; Show message
    ToolTip(message)
    SetTimer(() => ToolTip(), -2000)
}

ToggleSequence() {
    global isSequenceRunning
    
    if (isSequenceRunning) {
        StopSequence("Command sequence stopped!")
    } else {
        StartSequence()
    }
}

; ============================================================================
; HOTKEYS
; ============================================================================

; Toggle the command sequence (start/stop)
Hotkey(TRIGGER_KEY, (*) => ToggleSequence())

; Exit the script
F8::ExitApp

; Reload the script
F9::Reload

; ============================================================================
; STARTUP
; ============================================================================

ToolTip("Script loaded! Press " TRIGGER_KEY " to start/stop sequence.")
SetTimer(() => ToolTip(), -3000)