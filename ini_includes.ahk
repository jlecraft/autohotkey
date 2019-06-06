; Read a whole .ini file and creates variables like this:
; %Section%%Key% = %value%
ReadIni()
{
	Local s, c, p, key, k

	filename := SubStr(A_ScriptName, 1, -3) . "ini"

	FileRead, s, %filename%

	Loop, Parse, s, `n`r, %A_Space%%A_Tab%
	{
		c := SubStr(A_LoopField, 1, 1)

		if (c = "[")
			key := SubStr(A_LoopField, 2, -1)
		else if (c = ";")
			continue
		else
		{
			p := InStr(A_LoopField, "=")

			if p
			{
				k := SubStr(A_LoopField, 1, p - 1)
				%key%%k% := SubStr(A_LoopField, p + 1)
			}
		}
	}
}

; updates a whole .ini file 
; %Section%%Key% = %value%
WriteIni()
{
	Local s, c, p, key, k, write

	filename := SubStr(A_ScriptName, 1, -3) . "ini"

	FileRead, s, %filename%

	Loop, Parse, s, `n`r, %A_Space%%A_Tab%
	{
		c := SubStr(A_LoopField, 1, 1)

		if (c = "[")
			key := SubStr(A_LoopField, 2, -1)
		else if (c = ";")
			continue
		else
		{
			p := InStr(A_LoopField, "=")

			if p
			{
				k := SubStr(A_LoopField, 1, p-1)
				write := %key%%k%
				IniWrite, %write%, %filename%, %key%, %k% 
			}
		}
	}
}