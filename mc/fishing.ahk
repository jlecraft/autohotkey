; Minecraft AutoHotkey v2 Script
#Requires AutoHotkey v2.0
#SingleInstance Force

; Constants
class Config {
    ; Scanning
    static SCAN_INTERVAL_MS      := 2000

    ; Beep tones and durations
    static BEEP_FOUND_FREQ       := 800
    static BEEP_FOUND_DURATION   := 150
    static BEEP_FOUND_PAUSE      := 100
    static BEEP_INVALID_FREQ     := 400
    static BEEP_INVALID_DURATION := 200

    ; Click timing
    static CLICK_HOLD_MS         := 50
    static CLICK_BETWEEN_MS_MIN  := 100
    static CLICK_BETWEEN_MS_MAX  := 150

    ; Special sequence (every Nth click)
    static SPECIAL_SEQ_INTERVAL  := 9
    static SPECIAL_KEY_HOLD_MS   := 450
    static SPECIAL_POST_PAUSE_MS := 500

    ; Cast time validity window (ms)
    static CAST_TIME_MIN_MS      := 1000
    static CAST_TIME_MAX_MS      := 15000

    ; Reset tooltip duration (ms)
    static RESET_TOOLTIP_MS      := 2000

    ; Overlay appearance
    static OVERLAY_BG_COLOR      := "1A1A2E"   ; dark navy
    static OVERLAY_DIV_COLOR     := "3A3A5E"   ; divider color
    static OVERLAY_LAST_COLOR    := "44FF88"   ; green flash for last cast
    static OVERLAY_ALPHA         := 210         ; 0-255
    static OVERLAY_FONT_LARGE    := 40          ; cast count
    static OVERLAY_FONT_SMALL    := 13          ; stats labels
    static OVERLAY_FONT_LABEL    := 11          ; muted sub-labels
    static OVERLAY_WIDTH         := 280
    static OVERLAY_MARGIN_RIGHT  := 20
    static OVERLAY_MARGIN_TOP    := 20
    static OVERLAY_PAD           := 12          ; top/bottom padding
}

; Global variables
global mcHandle      := 0
global clickCounter  := 0   ; Track total calls to PerformClickSequence

global TotalCasts    := 0   ; Valid recorded casts
global TotalCastTime := 0   ; Sum of all valid CastTimes (ms)
global LastCastTime  := 0   ; Most recent valid CastTime (ms)
global LastCastTick  := 0   ; A_TickCount at last PerformClickSequence call (0 = unset)

global overlayGui    := 0
global overlayVisible := true

; ── Bootstrap ────────────────────────────────────────────────────────────────

SetTimer(ScanMinecraft, Config.SCAN_INTERVAL_MS)
BuildOverlay()
UpdateOverlay()

; ── Window scanning ───────────────────────────────────────────────────────────

ScanMinecraft() {
    global mcHandle

    if (mcHandle && WinExist("ahk_id " mcHandle))
        return

    newHandle := WinExist("Minecraft ahk_exe javaw.exe")
    if (!newHandle)
        newHandle := WinExist("Minecraft ahk_exe java.exe")
    if (!newHandle)
        newHandle := WinExist("ahk_exe Minecraft.Windows.exe")

    if (newHandle && !mcHandle) {
        mcHandle := newHandle
        SoundBeep(Config.BEEP_FOUND_FREQ, Config.BEEP_FOUND_DURATION)
        Sleep(Config.BEEP_FOUND_PAUSE)
        SoundBeep(Config.BEEP_FOUND_FREQ, Config.BEEP_FOUND_DURATION)
        SetTimer(ScanMinecraft, 0)
    }
}

; ── Handle validation ─────────────────────────────────────────────────────────

ValidateMinecraftHandle() {
    global mcHandle

    if (mcHandle && WinExist("ahk_id " mcHandle))
        return true

    SoundBeep(Config.BEEP_INVALID_FREQ, Config.BEEP_INVALID_DURATION)
    return false
}

; ── Click sequence ────────────────────────────────────────────────────────────

PerformClickSequence() {
    global mcHandle, clickCounter
    global TotalCasts, TotalCastTime, LastCastTime, LastCastTick

    if (!ValidateMinecraftHandle())
        return

    clickCounter += 1

    ; ── Cast time tracking ──────────────────────────────────────────────────
    now := A_TickCount

    if (LastCastTick = 0) {
        ; First call — seed the timestamp, do not record a cast
        LastCastTick := now
    } else {
        CastTime     := now - LastCastTick
        LastCastTick := now

        if (CastTime >= Config.CAST_TIME_MIN_MS && CastTime <= Config.CAST_TIME_MAX_MS) {
            TotalCasts    += 1
            TotalCastTime += CastTime
            LastCastTime  := CastTime
            UpdateOverlay()
        }
    }

    ; ── Click logic ─────────────────────────────────────────────────────────
    if (Mod(clickCounter, Config.SPECIAL_SEQ_INTERVAL) = 0) {
        ; Special sequence with "d" key
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA D")
        Sleep(Config.CLICK_HOLD_MS)
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA U")

        ControlSend("{d down}", , "ahk_id " mcHandle)
        Sleep(Config.SPECIAL_KEY_HOLD_MS)
        ControlSend("{d up}", , "ahk_id " mcHandle)

        Sleep(Config.SPECIAL_POST_PAUSE_MS)

        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA D")
        Sleep(Config.CLICK_HOLD_MS)
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA U")
    } else {
        ; Normal double-click sequence
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA D")
        Sleep(Config.CLICK_HOLD_MS)
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA U")

        randomWait := Random(Config.CLICK_BETWEEN_MS_MIN, Config.CLICK_BETWEEN_MS_MAX)
        Sleep(randomWait)

        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA D")
        Sleep(Config.CLICK_HOLD_MS)
        ControlClick(, "ahk_id " mcHandle, , "Right", 1, "NA U")
    }
}

; ── Overlay ───────────────────────────────────────────────────────────────────

BuildOverlay() {
    global overlayGui

    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "FishTracker")
    overlayGui.BackColor := Config.OVERLAY_BG_COLOR
    WinSetTransparent(Config.OVERLAY_ALPHA, overlayGui)

    p   := Config.OVERLAY_PAD
    w   := Config.OVERLAY_WIDTH
    ; y positions (all measured from top of window)
    yCastNum   := p              ; large count number
    yCastLabel := yCastNum + 46  ; "TOTAL CASTS" label
    yDiv1      := yCastLabel + 19 ; divider
    yStats     := yDiv1 + 8      ; single stats row: Last | Avg | Total
    ; bottom padding = p (matched to top)

    ; Large cast count
    overlayGui.SetFont("s" Config.OVERLAY_FONT_LARGE " cWhite bold", "Segoe UI")
    overlayGui.AddText("x0 y" yCastNum " vCastCount w" w " Center", "0")

    ; "TOTAL CASTS" label
    overlayGui.SetFont("s" Config.OVERLAY_FONT_LABEL " cSilver norm", "Segoe UI")
    overlayGui.AddText("x0 y" yCastLabel " vCastLabel w" w " Center", "TOTAL CASTS")

    ; Divider
    overlayGui.SetFont("s6 c" Config.OVERLAY_DIV_COLOR, "Segoe UI")
    overlayGui.AddText("x10 y" yDiv1 " w" (w - 20) " h1 0x10")

    ; Stats row: Last | Avg | Total  (three equal columns, two pipe dividers)
    innerW := w - 20            ; usable width between left/right margins
    colW   := (innerW - 20) // 3  ; 20px reserved for two "|" separators (10px each)
    sepX1  := 10 + colW
    sepX2  := sepX1 + 10 + colW

    overlayGui.SetFont("s" Config.OVERLAY_FONT_SMALL " c" Config.OVERLAY_LAST_COLOR " norm", "Segoe UI")
    overlayGui.AddText("x10 y" yStats " vLastVal w" colW " Center", "--")
    overlayGui.SetFont("s" Config.OVERLAY_FONT_SMALL " cWhite norm", "Segoe UI")
    overlayGui.AddText("x" sepX1 " y" yStats " w10 Center", "|")
    overlayGui.AddText("x" (sepX1 + 10) " y" yStats " vAvgVal w" colW " Center", "--")
    overlayGui.AddText("x" sepX2 " y" yStats " w10 Center", "|")
    overlayGui.AddText("x" (sepX2 + 10) " y" yStats " vTotalVal w" colW " Center", "--:--")

    ; Dynamic height: bottom of stats row + bottom padding
    guiH := yStats + 18 + p

    ; Position: top-right corner of primary monitor
    xPos := A_ScreenWidth - w - Config.OVERLAY_MARGIN_RIGHT
    overlayGui.Show("x" xPos " y" Config.OVERLAY_MARGIN_TOP
        . " w" w " h" guiH " NoActivate")
}

; Format milliseconds as MM:SS (minutes can exceed 60)
FormatMmSs(ms) {
    totalSec := ms // 1000
    mins     := totalSec // 60
    secs     := Mod(totalSec, 60)
    return Format("{:d}:{:02d}", mins, secs)
}

UpdateOverlay() {
    global overlayGui, TotalCasts, TotalCastTime, LastCastTime

    if (!IsObject(overlayGui))
        return

    overlayGui["CastCount"].Value := TotalCasts

    if (LastCastTime > 0) {
        lastSec := Round(LastCastTime / 1000, 1)
        overlayGui["LastVal"].Opt("c" Config.OVERLAY_LAST_COLOR)
        overlayGui["LastVal"].Value := lastSec "s"
    } else {
        overlayGui["LastVal"].Opt("cWhite")
        overlayGui["LastVal"].Value := "--"
    }

    if (TotalCasts > 0) {
        avgSec := Round(TotalCastTime / TotalCasts / 1000, 1)
        overlayGui["AvgVal"].Value   := avgSec "s"
        overlayGui["TotalVal"].Value := FormatMmSs(TotalCastTime)
    } else {
        overlayGui["AvgVal"].Value   := "--"
        overlayGui["TotalVal"].Value := "--:--"
    }
}

ToggleOverlay() {
    global overlayGui, overlayVisible

    overlayVisible := !overlayVisible
    if (overlayVisible)
        overlayGui.Show("NoActivate")
    else
        overlayGui.Hide()
}

; ── Hotkeys ───────────────────────────────────────────────────────────────────

; XButton1 / joystick trigger
XButton1:: PerformClickSequence()
Joy1::     PerformClickSequence()

; Toggle overlay
F7:: ToggleOverlay()

; Reset stats
^f:: {
    global TotalCasts, TotalCastTime, LastCastTime, LastCastTick, clickCounter
    TotalCasts    := 0
    TotalCastTime := 0
    LastCastTime  := 0
    LastCastTick  := 0
    clickCounter  := 0
    UpdateOverlay()
    ToolTip("Stats reset.")
    SetTimer(() => ToolTip(), -Config.RESET_TOOLTIP_MS)
}

; Exit
F8:: ExitApp()
