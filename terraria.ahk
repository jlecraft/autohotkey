#Include ini_includes.ahk

; # Windows Logo Key
; ! Alt
; ^ Control
; + Shift
; * Fire hotkey even if extra modifiers are held
; ~ Don't block native function

#SingleInstance, force

ReadIni()

SetTimer, ClickTimer, %KeySpeed%

; -------------------------------------------------------------------
; GUI
; -------------------------------------------------------------------
Gui, +AlwaysOnTop -SysMenu +Owner

; Label for text field
Gui, Add, Text, section w65 h20 0x200, Click Speed:
; Text field for key sequence
Gui, Add, Edit, w75 x+10 vText1, 100
; Checkbox for toggled clicking
Gui, Add, Checkbox, w75 x+10 0x200 vCheck1, Toggle Click

; Label for text field
Gui, Add, Text, section w65 h20 xs 0x200, AutoMove:
; Text field for key sequence
Gui, Add, Edit, w75 x+10 vText2, 250

; OK and Cancel buttons
; xm+y where y = WIDTH - 125
Gui, Add, Button, w50 xm+145 y+15, Cancel
Gui, Add, Button, w50 x+5 +Default, OK

; Status Bar
; Gui, Add, StatusBar,, %KeySpeed%ms

; Load saved value into the text field
GuiControl, , Text1, %KeySpeed%
GuiControl, , Text2, %KeyMoveDelay%
GuiControl, , Check1, %KeyClickToggle%

; Show GUI on program load
; Gui, Show, w170, KeyPress

F8::ExitApp

; #IfWinActive, Terraria

F1::
	Gui, Show, w270, Terraria Hotkey
	AutoClickEnabled := False
	Return

!$a::
	GetKeyState, aKey, d

	if aKey = D
		Send {d up}

	Send {a down}
	Return

!$d::
	GetKeyState, aKey, a

	if aKey = D
		Send {a up}

	Send {d down}
	Return

~$a::
	GetKeyState, dKey, d

	if dKey = D
		Send {d up}

	Return

~$d::
	GetKeyState, aKey, a

	if aKey = D
		Send {a up}

	Return

XButton1::
	if KeyClickToggle
		AutoClickEnabled := not AutoClickEnabled
	Else
		Click down

	Return

XButton2::AutoClickEnabled := True

ClickTimer:
	if AutoClickEnabled
		Click

	Return

;--------------------------------------------------------------------
; GUI Control
;--------------------------------------------------------------------
ButtonCancel:
GuiClose:
GuiEscape:
	Gui, Hide
	Return

ButtonOK:
	; Save the input from the user to each control's associated variable.
	Gui, Submit

	if KeySpeed <> Text1
	{
		KeySpeed := Text1
		SetTimer, ClickTimer, %KeySpeed%
	}

	KeyMoveDelay := Text2
	KeyClickToggle := Check1
	WriteIni()
	Return