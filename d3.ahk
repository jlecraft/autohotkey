#SingleInstance Force

SetTimer, Click, 100

; Help
; --------------------------------------------------------------------
; F8 exits the script
; XButton1 turns on auto left-clicking, and is turned off by manually left clicking
; F4 brings up the UI for options
; Hotkeys Enabled will force keys 1-4 to automatically queue 5 clicks in an attempt to
; interrupt the current set of actions already being read by the game client.  Without this,
; some keys may be unresponsive while rapidly firing off commands for abilities.
;
; Right click options:
;  normal
;  right (queued)
;  toggle Right
;  toggle left/Right
;  autofire
;  auto button


; Globals
; --------------------------------------------------------------------
LLock := False
LHold := False
RHold := False
Autofire := 0

AutoButtonEnabled := 0
AutoButton := 0

CommandQueue := ""

KeyPress1 := 0
KeyPress1 := 0
KeyPress1 := 0
KeyPress1 := 0
ClickType := 0

; Load GUI
; --------------------------------------------------------------------
IniRead, SavedVar1, d3.ini, Hotkeys, KeyPress1
IniRead, SavedVar2, d3.ini, Hotkeys, KeyPress2
IniRead, SavedVar3, d3.ini, Hotkeys, KeyPress3
IniRead, SavedVar4, d3.ini, Hotkeys, KeyPress4
IniRead, ClickType, d3.ini, Mouse, ClickType
IniRead, AutoState, d3.ini, General, AutoButtonEnabled

Gui, +AlwaysOnTop -SysMenu +Owner  ; +Owner avoids a taskbar button.
Gui, Add, Checkbox, Checked%SavedVar1% vKeyPress1, &1
Gui, Add, Checkbox, Checked%SavedVar2% vKeyPress2, &2
Gui, Add, Checkbox, Checked%SavedVar3% vKeyPress3, &3
Gui, Add, Checkbox, Checked%SavedVar4% vKeyPress4, &4
GroupBox("GB1", "Hotkeys Enabled", 10, 10, "KeyPress1|KeyPress2|KeyPress3|KeyPress4", 180)


RadioState1 := 0
RadioState2 := 0
RadioState3 := 0
RadioState4 := 0
RadioState5 := 0

if ClickType = 2
	RadioState2 := 1
Else if ClickType = 3
	RadioState3 := 1
Else if ClickType = 4
	RadioState4 := 1
Else if ClickType = 5
	RadioState5 := 1
Else
	RadioState1 := 1

Gui, Add, GroupBox, w180 x+5 r5.25, Right Click

Gui, Add, Radio, Checked%RadioState1% vClickType xp+10 yp+20, &Normal
Gui, Add, Radio, Checked%RadioState2%, &Right (Queued)
Gui, Add, Radio, Checked%RadioState3%, &Toggle Right
Gui, Add, Radio, Checked%RadioState4%, Toggle &Left/Right
Gui, Add, Radio, Checked%RadioState5%, &Autofire

Gui, Add, Checkbox, Checked%AutoState% vAutoButtonEnabled x+5, Auto Button

Gui, Add, Button, w50 x270 y+20, Cancel
Gui, Add, Button, w50 x+5 +Default, OK

Gui, Add, StatusBar,, Press F8 to exit application.

return

F8::ExitApp
F9::Reload
Pause::Pause
F10::
F4::Gui, Show, w390 h190, Options

#IfWinActive ahk_class D3 Main Window Class

~*1::		
	if KeyPress1
		Queue("1", 5, True)
	Return

~*2::
	if KeyPress2
		Queue("2", 5, True)
	Return

~*3::
	if KeyPress3
		Queue("3", 4, True)
	Return

~*4::
	if KeyPress4
		Queue("4", 5, True)
	Return

RButton::
	if ClickType <= 1
	{
		Click down right
		; Queue("1", 1, true)
	}

	if ClickType = 2
	{
		Queue("r", 3, True)
	}

	if (ClickType = 3)
	{
		if RHold
		{
			RHold := False
			Click up right
		}
		Else
		{
			RHold := True
			Click down right
		}
	}

	if ClickType = 4
	{
		; Left/Right
		if (not LHold) or RHold
		{
			Click up Right
			RHold := False
			LHold := True

			Send {k down}
			Click down Left

			LToggle := True
		}
		else
		{
			Send {k up}
			Click up Left
			Click down Right
			RHold := True
			LHold := False
		}
	}

	if ClickType = 5
	{
		; Autofire
		Send {k down}
		LHold := True
		LToggle := True
	}

	Return

~Esc::
~t::
	if AutoButtonEnabled
	{
		Send {f up}
	}

	Return

RButton up::
	if ClickType <= 1
		Click right up
	return

;----------------------------------
; Left Button
;----------------------------------
; Turns off right-click hold if active, otherwise turns off auto left-click.
*LButton::
	Click down

	if LHold
	{
		Send {k up}
		LHold := False
		return
	}

	if RHold
	{
		Click up right
		RHold := False
		return
	}

	ClearQueue()
	LToggle := False

	return

*LButton up::Click up

;----------------------------------
; Side Mouse Buttons
;----------------------------------
; Activates auto left-clicking.  Disable right-click hold.
~*XButton1::
	if AutoButtonEnabled
	{
		; Send {f down}
	}

	ClearQueue()
	Send {k up}

	if LHold
	{
		Send {k up}
		Click up Left
		LHold := False
	}

	LToggle := True

	if RHold
	{
		Click up right
		Click
		RHold := False
	}

return

~*XButton2::
	ClearQueue()

	Send {k up}
	Click up Right

	LToggle := False

	Click down
	LLock := True
return

;----------------------------------
; Timer Function (10/sec)
;----------------------------------
Click:
	; Suppress if the right button is held down.
	GetKeyState, state, RButton
	if state = D
		return

	AutoButton := AutoButton + 1

	if AutoButtonEnabled and LToggle
	{
		if mod(AutoButton, 10) = 0
		{
			Send 1
		}

		if mod(AutoButton, 6) = 0
		{
			
		}

		if mod(AutoButton, 8) = 0
		{
			
		}
	}


	; Suppress if we are simulating a right hold.
	if RHold
		return

	if LToggle
	{
		if LHold and ClickType = 5
			Queue("rrrrrlllllllllllrrrrr", 1, False, False, True)
		Else
			Queue("l", 10)
	}

	pop := SubStr(CommandQueue, 1, 1)

	if pop
	{
		StringTrimLeft, CommandQueue, CommandQueue, 1

		if (pop == "l")
			Click
		else if (pop == "r")
			Click right
		else
			Send %pop%
	}

	return

;--------------------------------------------------------------------
; Functions
;--------------------------------------------------------------------
Queue(command, times = 1, Prioritize = False, CanDuplicate = False, EmptyOnly = False)
{
	global CommandQueue

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

ClearQueue()
{
	global CommandQueue

	CommandQueue := ""

	if AutoButtonEnabled
	{
		; Send {f up}
	}
}


ButtonCancel:
GuiClose:
GuiEscape:
	Gui, Hide
	Return

ButtonOK:
	Gui, Submit  ; Save the input from the user to each control's associated variable.

	IniWrite, %KeyPress1%, d3.ini, Hotkeys, KeyPress1
	IniWrite, %KeyPress2%, d3.ini, Hotkeys, KeyPress2
	IniWrite, %KeyPress3%, d3.ini, Hotkeys, KeyPress3
	IniWrite, %KeyPress4%, d3.ini, Hotkeys, KeyPress4

	IniWrite, %ClickType%, d3.ini, Mouse, ClickType
	return

GroupBox(GBvName, Title, TitleHeight, Margin, Piped_CtrlvNames, FixedWidth="", FixedHeight="")
{
	;GBvName 			Name for GroupBox control variable
	;Title				Title for GroupBox
	;TitleHeight		Height in pixels to allow for the Title
	;Margin				Margin in pixels around the controls
	;Piped_CtrlvNames	Pipe (|) delimited list of Controls
	;FixedWidth=""		Optional fixed width
	;FixedHeight="")	Optional fixed height


	;************************** GroupBox *******************************
	;
	;	Adds and wraps a GroupBox around a group of controls in
	;	the default Gui. Use the Gui Default command if needed.
	;	For instance:
	;
	;		Gui, 2:Default
	;
	;	sets the default Gui to Gui 2.
	;
	;	Add the controls you want in the GroupBox to the Gui using
	;	the "v" option to assign a variable name to each control. *
	;	Then immediately after the last control for the group
	;	is added call this function. It will add a GroupBox and
	;	wrap it around the controls.
	;
	;	Example:
	;
	;	Gui, Add, Text, vControl1, This is Control 1
	;	Gui, Add, Text, vControl2 x+30, This is Control 2
	;	GroupBox("GB1", "Testing", 20, 10, "Control1|Control2")
	;	Gui, Add, Text, Section xMargin, This is Control 3
	;	GroupBox("GB2", "Another Test", 20, 10, "This is Control 3")
	;	Gui, Add, Text, yS, This is Control 4
	;	GroupBox("GB3", "Third Test", 20, 10, "Static4")
	;	Gui, Show, , GroupBox Test
	;
	;	* The "v" option to assign Control ID is not mandatory. You
	;	may also use the ClassNN name or text of the control.
	;
	;********************************************************************

	Local maxX, maxY, minX, minY, xPos, yPos ;all else assumed Global
	minX := 99999
	minY := 99999
	maxX := 0
	maxY := 0

	Loop, Parse, Piped_CtrlvNames, |, %A_Space%
	{
		;Get position and size of each control in list.
		GuiControlGet, GB, Pos, %A_LoopField%
		;creates GBX, GBY, GBW, GBH
		if (GBX < minX) ;check for minimum X
			minX := GBX
		if (GBY < minY) ;Check for minimum Y
			minY := GBY
		if (GBX + GBW > maxX) ;Check for maximum X
			maxX := GBX + GBW
		if (GBY + GBH > maxY) ;Check for maximum Y
			maxY := GBY + GBH

		;Move the control to make room for the GroupBox
		xPos := GBX + Margin
		yPos := GBY + TitleHeight + Margin ;fixed margin
		GuiControl, Move, %A_LoopField%, x%xPos% y%yPos%
	}

	;re-purpose the GBW and GBH variables
	if (FixedWidth)
		GBW := FixedWidth
	else
		GBW := maxX - minX + 2 * Margin ;calculate width for GroupBox

	if (FixedHeight)
		GBH := FixedHeight
	else
		GBH := maxY - MinY + TitleHeight + 2 * Margin ;calculate height for GroupBox ;fixed 2*margin

	;Add the GroupBox
	Gui, Add, GroupBox, v%GBvName% x%minX% y%minY% w%GBW% h%GBH%, %Title%
	return
}
