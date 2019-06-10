#SingleInstance, force

SetTimer, Click, 100

;---------------------------------
; Globals
;---------------------------------
MinCycleTime := 30
MaxCycleTime := 36

ClickLocX := 0
ClickLocY := 0

Cycle := MinCycleTime

;---------------------------------
; Script hotkeys
;---------------------------------
Pause::Pause
F8::ExitApp

;----------------------------------
; Side Mouse Buttons
;----------------------------------
; Activates auto left-clicking at current location
*XButton1::
	MouseGetPos, x, y

	ClickLocX := x
	ClickLocY := y

	Random, Cycle, MinCycleTime, MaxCycleTime
Return

~*Esc::
	ClickLocX := 0
	ClickLocY := 0
	
Return

;----------------------------------
; Timer Function (10/sec)
;----------------------------------
Click:
	Cycle := Cycle - 1

	if (ClickLocY > 0)
	{
		if (Cycle < 1)
		{
			Click StartX, StartY		
			Random, Cycle, MinCycleTime, MaxCycleTime
		}
	}
Return
