; Minecraft AutoHotkey v2 Script
#Requires AutoHotkey v2.0
#SingleInstance Force

; Constants
class Config {
    ; Scanning
    static SCAN_INTERVAL_MS        := 2000

    ; Beep tones and durations
    static BEEP_FOUND_FREQ         := 800
    static BEEP_FOUND_DURATION     := 150
    static BEEP_FOUND_PAUSE        := 100
    static BEEP_INVALID_FREQ       := 400
    static BEEP_INVALID_DURATION   := 200

    ; Click timing
    static CLICK_HOLD_MS           := 50
    static CLICK_BETWEEN_MS_MIN    := 100
    static CLICK_BETWEEN_MS_MAX    := 150

    ; Special sequence (every Nth click)
    static SPECIAL_SEQ_INTERVAL    := 9
    static SPECIAL_KEY_HOLD_MS     := 450
    static SPECIAL_POST_PAUSE_MS   := 500

    ; Cast time validity window (ms)
    static CAST_TIME_MIN_MS        := 1000
    static CAST_TIME_MAX_MS        := 15000

    ; Reset tooltip duration (ms)
    static RESET_TOOLTIP_MS        := 2000

    ; How long to flash the last cast time in the avg column (ms)
    static LAST_CAST_FLASH_MS      := 1000

    ; How often to poll for counter color + rain timer updates (ms)
    static OVERLAY_POLL_MS         := 100

    ; Rain timer duration (ms)
    static RAIN_TIMER_MS           := 16 * 60 * 1000   ; 16 minutes

    ; Overlay appearance
    static OVERLAY_BG_COLOR        := "1A1A2E"   ; dark navy
    static OVERLAY_DIV_COLOR       := "3A3A5E"   ; divider color
    static OVERLAY_LAST_COLOR      := "44FF88"   ; green flash for last cast
    static OVERLAY_WARN_COLOR      := "FF4444"   ; red counter when discard state
    static OVERLAY_ALPHA           := 210         ; 0-255
    static OVERLAY_FONT_LARGE      := 40          ; cast count
    static OVERLAY_FONT_SMALL      := 13          ; stats values
    static OVERLAY_FONT_LABEL      := 11          ; muted sub-labels
    static OVERLAY_WIDTH           := 280
    static OVERLAY_MARGIN_RIGHT    := 20
    static OVERLAY_MARGIN_TOP      := 20
    static OVERLAY_PAD             := 12          ; top/bottom padding
}

; ── Global state ──────────────────────────────────────────────────────────────

global mcHandle      := 0
global clickCounter  := 0    ; Track total calls to PerformClickSequence

global TotalCasts    := 0    ; Valid recorded casts
global TotalCastTime := 0    ; Sum of all valid CastTimes (ms)
global LastCastTime  := 0    ; Most recent valid CastTime (ms)
global LastCastTick  := 0    ; A_TickCount at last PerformClickSequence call (0 = unset)

global RainStartTick := 0    ; A_TickCount when rain timer was started (0 = inactive)

global overlayGui    := 0
global overlayVisible := true
global flashActive   := false   ; true while the last-cast green flash is showing
global prevPOV       := -2      ; previous POV value for D-pad edge detection

; ── Bootstrap ─────────────────────────────────────────────────────────────────

SetTimer(ScanMinecraft, Config.SCAN_INTERVAL_MS)
SetTimer(PollOverlay, Config.OVERLAY_POLL_MS)
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
    global flashActive

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
            flashActive   := true
            UpdateOverlay()
            SetTimer(EndFlash, -Config.LAST_CAST_FLASH_MS)
        }
    }

    ; ── Click logic ─────────────────────────────────────────────────────────
    if (Mod(clickCounter, Config.SPECIAL_SEQ_INTERVAL) = 0) {
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

; Called after LAST_CAST_FLASH_MS to restore avg display
EndFlash() {
    global flashActive
    flashActive := false
    UpdateOverlay()
}

; ── Rain timer ────────────────────────────────────────────────────────────────

StartRainTimer() {
    global RainStartTick, mcHandle

    if (!ValidateMinecraftHandle())
        return

    ControlSend("{F9}", , "ahk_id " mcHandle)
    RainStartTick := A_TickCount
}

; ── Overlay ───────────────────────────────────────────────────────────────────

BuildOverlay() {
    global overlayGui

    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "FishTracker")
    overlayGui.BackColor := Config.OVERLAY_BG_COLOR
    WinSetTransparent(Config.OVERLAY_ALPHA, overlayGui)

    p := Config.OVERLAY_PAD
    w := Config.OVERLAY_WIDTH

    ; y positions
    yCastNum   := p
    yCastLabel := yCastNum + 46
    yDiv1      := yCastLabel + 19
    yStats     := yDiv1 + 8

    ; Large cast count — starts white, may turn red via PollOverlay
    overlayGui.SetFont("s" Config.OVERLAY_FONT_LARGE " cWhite bold", "Segoe UI")
    overlayGui.AddText("x0 y" yCastNum " vCastCount w" w " Center", "0")

    ; "TOTAL CASTS" label
    overlayGui.SetFont("s" Config.OVERLAY_FONT_LABEL " cSilver norm", "Segoe UI")
    overlayGui.AddText("x0 y" yCastLabel " vCastLabel w" w " Center", "TOTAL CASTS")

    ; Divider
    overlayGui.SetFont("s6", "Segoe UI")
    overlayGui.AddText("x10 y" yDiv1 " w" (w - 20) " h1 0x10")

    ; Stats row: Avg | Total | Rain  (three equal columns, two pipe separators)
    innerW := w - 20
    colW   := (innerW - 20) // 3
    sepX1  := 10 + colW
    sepX2  := sepX1 + 10 + colW

    overlayGui.SetFont("s" Config.OVERLAY_FONT_SMALL " cWhite norm", "Segoe UI")
    overlayGui.AddText("x10 y" yStats " vAvgVal w" colW " Center", "--")
    overlayGui.AddText("x" sepX1 " y" yStats " w10 Center", "|")
    overlayGui.AddText("x" (sepX1 + 10) " y" yStats " vTotalVal w" colW " Center", "--:--")
    overlayGui.AddText("x" sepX2 " y" yStats " w10 Center", "|")
    overlayGui.AddText("x" (sepX2 + 10) " y" yStats " vRainVal w" colW " Center", "--:--")

    guiH := yStats + 18 + p

    xPos := A_ScreenWidth - w - Config.OVERLAY_MARGIN_RIGHT
    overlayGui.Show("x" xPos " y" Config.OVERLAY_MARGIN_TOP
        . " w" w " h" guiH " NoActivate")
}

; Format milliseconds as MM:SS (minutes unbounded)
FormatMmSs(ms) {
    totalSec := ms // 1000
    mins     := totalSec // 60
    secs     := Mod(totalSec, 60)
    return Format("{:d}:{:02d}", mins, secs)
}

; Full overlay update — called after a new cast is recorded or on reset
UpdateOverlay() {
    global overlayGui, TotalCasts, TotalCastTime, flashActive, LastCastTime

    if (!IsObject(overlayGui))
        return

    overlayGui["CastCount"].Value := TotalCasts

    ; Avg column: show last cast (green) during flash, otherwise show average
    if (flashActive && LastCastTime > 0) {
        lastSec := Round(LastCastTime / 1000, 1)
        overlayGui["AvgVal"].Opt("c" Config.OVERLAY_LAST_COLOR)
        overlayGui["AvgVal"].Value := lastSec "s"
    } else if (TotalCasts > 0) {
        avgSec := Round(TotalCastTime / TotalCasts / 1000, 1)
        overlayGui["AvgVal"].Opt("cWhite")
        overlayGui["AvgVal"].Value := avgSec "s"
    } else {
        overlayGui["AvgVal"].Opt("cWhite")
        overlayGui["AvgVal"].Value := "--"
    }

    ; Total cast time
    if (TotalCasts > 0)
        overlayGui["TotalVal"].Value := FormatMmSs(TotalCastTime)
    else
        overlayGui["TotalVal"].Value := "--:--"
}

; Lightweight poll — runs every OVERLAY_POLL_MS for counter color, rain timer, and D-pad
PollOverlay() {
    global overlayGui, LastCastTick, RainStartTick, prevPOV, mcHandle

    if (!IsObject(overlayGui))
        return

    ; ── Counter color ────────────────────────────────────────────────────────
    discardState := (LastCastTick = 0)
        || (A_TickCount - LastCastTick > Config.CAST_TIME_MAX_MS)

    overlayGui["CastCount"].Opt(discardState
        ? "c" Config.OVERLAY_WARN_COLOR
        : "cWhite")

    ; ── Rain timer ───────────────────────────────────────────────────────────
    if (RainStartTick > 0) {
        elapsed   := A_TickCount - RainStartTick
        remaining := Config.RAIN_TIMER_MS - elapsed
        overlayGui["RainVal"].Value := (remaining > 0) ? FormatMmSs(remaining) : "0:00"
    }

    ; ── D-pad via POV hat (leading-edge only) ────────────────────────────────
    pov := GetKeyState("JoyPOV")

    if (pov != prevPOV) {
        prevPOV := pov
        if (pov = 0 && mcHandle && WinExist("ahk_id " mcHandle)) {
            ; D-pad UP — open chat and type clipboard character by character
            ControlSend("t", , "ahk_id " mcHandle)
            Sleep(150)
            loop parse, A_Clipboard
                ControlSend("{raw}" A_LoopField, , "ahk_id " mcHandle)
        } else if (pov = 18000 && mcHandle && WinExist("ahk_id " mcHandle)) {
            ; D-pad DOWN — send Enter
            ControlSend("{Enter}", , "ahk_id " mcHandle)
        }
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

; Fishing trigger
XButton1:: PerformClickSequence()
Joy1::     PerformClickSequence()

; Rain timer trigger
F9::   StartRainTimer()
Joy2:: StartRainTimer()

; Toggle overlay
F7:: ToggleOverlay()

; Reset stats
^f:: {
    global TotalCasts, TotalCastTime, LastCastTime, LastCastTick
    global clickCounter, flashActive
    TotalCasts    := 0
    TotalCastTime := 0
    LastCastTime  := 0
    LastCastTick  := 0
    clickCounter  := 0
    flashActive   := false
    UpdateOverlay()
    ToolTip("Stats reset.")
    SetTimer(() => ToolTip(), -Config.RESET_TOOLTIP_MS)
}

; Exit
F8:: ExitApp()
