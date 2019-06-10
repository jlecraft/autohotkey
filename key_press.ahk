; !Alt, ^Control, +Shift, <Left Key, >Right Key
; T: tab, Q: r(1, 2), L: left-click, R: right-click

#SingleInstance force

global CommandQueue := ""
global Active := False

; --------------------------------------------------------------------
; Load Ini Values
; --------------------------------------------------------------------
IniRead, SavedKeySequence, KeyPress.ini, General, KeySequence
IniRead, SavedSequenceSpeed, KeyPress.ini, General, SequenceSpeed

if (SavedSequenceSpeed <= 0)
	SavedSequenceSpeed := 100

SetTimer, Click, %SavedSequenceSpeed%

; --------------------------------------------------------------------
; GUI
; --------------------------------------------------------------------
Gui, +AlwaysOnTop -SysMenu +Owner

; Text field for key sequence
Gui, Add, Edit, w300 vText1, Enter Key Sequence

; OK and Cancel buttons
Gui, Add, Button, w50 x205 y+10, Cancel
Gui, Add, Button, w50 x+5 +Default, OK

; Status Bar
Gui, Add, StatusBar,, %SavedSequenceSpeed%ms

; Load saved value into the text field
GuiControl, , Text1, %SavedKeySequence%

; Show GUI on program load
Gui, Show, w320, KeyPress

Return


F8::ExitApp
Pause::Pause

F4::
	PauseAction := True
	Gui, Show, w320 h125, KeyPress
	Return

*XButton1::
	if Active
	{
		ClearQueue()
		Active := False
	}
	Else
		Active := True

	Return


Click:
	if (not Active) or ActionPaused
		Return

	; Insert our text as long as it doesn't already exist in our command queue
	Queue(Text1, 1, False, False, True)

	pop := SubStr(CommandQueue, 1, 1)

	; We also check if the character is a literal zero, otherwise our logic check can fail
	if (pop or pop == "0")
	{
		StringTrimLeft, CommandQueue, CommandQueue, 1

		if (pop == "T")
			pop := "{tab}"
		else if (pop == "Q")
		{
			Random, r, 0, 99
			if (r > 50)
				pop := "1"
			Else
				pop := "2"
		}
		else if (pop == "L")
		{
			Click
			pop := "-"
		}
		else if (pop == "R")
		{
			Click Right
			pop := "-"
		}

		if (pop != "-")
		{
			Send %pop%
		}
	}

	Return

;--------------------------------------------------------------------
; Functions
;--------------------------------------------------------------------
Queue(command, times = 1, Prioritize = False, CanDuplicate = False, EmptyOnly = False) {
	if EmptyOnly and CommandQueue
		Return

	if !CanDuplicate
		IfInString, CommandQueue, %command%
			return

	Loop, %times%
		if Prioritize
			CommandQueue := command . CommandQueue
		else
			CommandQueue .= command
}

ClearQueue() {
	CommandQueue := ""
}

;--------------------------------------------------------------------
; GUI Control
;--------------------------------------------------------------------
ButtonCancel:
GuiClose:
GuiEscape:
	Gui, Hide
	PauseAction := False
	Return

ButtonOK:
	Gui, Submit  ; Save the input from the user to each control's associated variable.

	IniWrite, %Text1%, KeyPress.ini, General, KeySequence
	ClearQueue()

	PauseAction := False

	Return