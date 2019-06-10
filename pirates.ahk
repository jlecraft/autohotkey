; !Alt
; ^Control
; +Shift
; <Left Key
; >Right Key

#SingleInstance, force

SetTimer, Timer, 1000

;------------------------------------------------
; Variables
;------------------------------------------------
global MAX_TIMER := 3600
global totalTime := 0
global timerCount := MAX_TIMER * 100
global antiIdle := False

global myTimers := [-1, -1, -1, -1]
global mySounds := ["start_cooking01", "start_cooking02", "start_cooking03", "start_cooking04", "cooking_done01", "cooking_done02", "cooking_done03", "cooking_done04", "cooking_done05", "cooking_done06", "idle"]

global timerSounds := []

Loop, Files, sounds2\*.wav
{
	fp := RegexMatch(A_LoopFileName, "timer(?<Seconds>(\d+))\.wav", subPat)

	if subPatSeconds
	{
		subPatSeconds := subPatSeconds + 0
		timerSounds[subPatSeconds] := A_LoopFileName
	}

	; allSounds.Push(A_LoopFileName)
}


;---------------------------------
; Script hotkeys
;---------------------------------
Pause::Pause
F8::ExitApp

;----------------------------------
; Hotkeys
;----------------------------------
; #IfWinActive, Sea of Thieves

; Anti-idle
F5::
	antiIdle := not antiIdle

	if antiIdle
		speakPirate(11)
return

~*Esc::
~*LButton::
~*RButton::
	antiIdle := False
return

$!w::Send {w down}

~*s::
	if GetKeyState("w")
		Send {w up}
return

;----------------------------------
; Cooking timers
;----------------------------------
F1::resetTimer(45, 1)
F2::resetTimer(65, 2)
F3::resetTimer(95, 3)
F4::resetTimer(125, 4)

F9::startLap(0, true)
F10::startLap(1, true)

; ^F9::startLap(0, true)
; ^F10::startLap(1, true)
F12::speakTime(totalTime)

^c::
	SoundBeep, 400, 100
	timerCount := MAX_TIMER * 100
return

;----------------------------------
; Side Mouse Buttons
;----------------------------------
*XButton2::
	antiIdle := False
	Click down
return

;----------------------------------
; Timer Function (10/sec)
;----------------------------------
Timer:
	totalTime++
	timerCount--

	if (timerCount <= 0)
	{
		speakPirate(Rand(5, 10))
		timerCount := MAX_TIMER * 100
	}

	if antiIdle
	{
		if WinActive("Sea of Thieves") or true
		{
			if (mod(totalTime, 8) = 0)
			{
				Click
				SoundBeep, 100, 100
			}
		}
	}

return

startLap(timerIndex, resetLap = false) {
	elapsedTimer := totalTime - myTimers[timerIndex]

	if (resetLap)
	{
		speakTime(elapsedTimer, "reset at ")
		myTimers[timerIndex] := totalTime
	}
	else if (myTimers[timerIndex] >= 0)
	{
		speakTime(elapsedTimer)
		; MsgBox %elapsedTimer%
	}
	else
	{
		myTimers[timerIndex] := totalTime		
		SoundBeep, 200, 250
	}
}

resetTimer(duration, pirateIndex := -1) {
	if (timerCount > MAX_TIMER)
	{
		timerCount := duration
		speakPirate(pirateIndex)
	}
	else
	{
		; speakTime(timerCount)
		speakPirateTime(timerCount)
	}
}

speakTime(t, prefixText = "") {
	tMinutes := floor(t / 60)
	tSeconds := mod(t, 60)

	spokenTime := prefixText
	secondText := " seconds"
	minuteText := " minutes"

	if (tSeconds = 1)
		secondText := " second"

	if (tMinutes = 1)
		minuteText := " minute"

	if (t < 60)
		spokenTime := spokenTime . tSeconds . secondText
	else
	{
		if (timerSeconds = 0)
			spokenTime := spokenTime . tMinutes . minuteText . " exactly"
		else
			spokenTime := spokenTime . tMinutes . minuteText . tSeconds . secondText
	}

	ComObjCreate("SAPI.SpVoice").Speak(spokenTime)
}

speakPirate(idx) {
	if (idx > 0)
	{
		soundFile := "sounds2/" . mySounds[idx] . ".wav"
		SoundPlay %soundFile%
	}
}

speakPirateTime(t) {
	fileName := false

	for k, v in timerSounds
	{
		if (t <= k)
		{
			fileName = sounds2/%v%
			SoundPlay, %fileName%
			break
		}
	}

	if fileName
		SoundPlay, %fileName%
	else
		SoundBeep, 400, 150
}

Rand(a, b) {
	Random, r, a, b
	return r
}
