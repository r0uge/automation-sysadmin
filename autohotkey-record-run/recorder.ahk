;-----------------------------------
;  Macro Recorder v2.1+  By FeiYue  (modified by Speedmaster) (modified by AlexanderMV for AHK v2)
;
;  Description: This script records the mouse
;  and keyboard actions and then plays back.
;
;  F1  -->  Record(Screen) (CoordMode, Mouse, Screen)
;  F2  -->  Record(Window) (CoordMode, Mouse, Window)
;  F3  -->  Stop   Record/Play
;  F4  -->  Play   LogFile
;  F5  -->  Edit   LogFile
;  F6  -->  Pause  Record/Play
;  F9  -->  More Options
;  F10  --> Hide/Show Panel Buttons
;
;  Note:
;  1. press the Ctrl button individually
;     to record the movement of the mouse.
;  2. Shake the mouse on the Pause button,
;     you can pause recording or playback.
;-----------------------------------

#Requires AutoHotkey v2
#SingleInstance force
Thread "NoTimers", true
CoordMode "ToolTip"
SetTitleMatchMode 2
DetectHiddenWindows "On"

;--------------------------
logkeys := ""
playspeed := 2                           ; Set default playing speed here
EditorPath := "Notepad.exe"              ; set default editor path here
;~ EditorPath:=StrReplace(a_ahkpath, "autohotkey.exe") . "SciTE\SciTE.exe"     ; actvate if you have installed SciTE
global LogFile := A_Temp . "\~Record.ahk"
UsedKeys := "F1,F2,F3,F4,F5,F6,F9"
Play_Title := RegExReplace(LogFile, ".*\\") " ahk_class AutoHotkey"
global playspeed
global Recording := false, Playing := false, Coord := "", OptionsEditing := false, isPaused := -1, hideButtonsV := false
global LogArr := []

global oldid := ""
global bak := "", idx := 0
;--------------------------

gui1 := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000 +Owner")
gui2 := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000 +Owner")
global guiTip := Gui("+LastFound +AlwaysOnTop +ToolWindow -Caption +E0x08000020")

gui1.MarginX := 0
gui1.MarginY := 0
gui1.SetFont("S11")
s := "[F1]Rec (Scr),[F2]Rec (Win),"
  . "[F3]Stop,[F4]Play,[F5]Edit,[F6]Pause,[F9]Options"
For i, v in StrSplit(s, ",")
{
  j := i = 1 ? "" : "x+0"
  j := j . (InStr(v, "Pause") ? " vPause" : "")
  gctrl := gui1.Add("Button", j, v)
}
gui1.Add("Button", "x+0 w0 Hidden vMyText")
gui1.Show("NA y0") ; , Macro Recorder
FNC(thisGui, info) {
  MsgBox "click"
}

gui1["Scr"].OnEvent("Click", RecordScreen)
gui1["Win"].OnEvent("Click", RecordWindow)
gui1["Stop"].OnEvent("Click", Stop)
gui1["Play"].OnEvent("Click", Play)
gui1["Edit"].OnEvent("Click", EditF)
gui1["Pause"].OnEvent("Click", PauseM)
gui1["Options"].OnEvent("Click", Options)

gui2.Add("groupbox", "r6 w140", "Record")
ch1 := gui2.Add("Checkbox", "y25 xp+10 Checked1 vTLogkey", "Log keys")
ch2 := gui2.Add("Checkbox", "Checked1 vTLogmouse", "Log mouse")
ch3 := gui2.Add("Checkbox", "Checked1 vTLogWindow", "Log window")
ch4 := gui2.Add("Checkbox", "Checked0 vTLogWindowTitle", "Log window title")
ch5 := gui2.Add("Checkbox", "Checked1 vTLogWindowClass", "Log window class")
ch6 := gui2.Add("Checkbox", "Checked1 vTLogWindowExe", "Log window exe")
ch1.OnEvent("Click", hcheck)
ch2.OnEvent("Click", hcheck)
ch3.OnEvent("Click", hcheck)
ch4.OnEvent("Click", hcheck)
ch5.OnEvent("Click", hcheck)
ch6.OnEvent("Click", hcheck)

hsbtn := gui2.Add("Button", " vTbuttons y+20 w130", "Hide Panel Buttons F10")
hsbtn.OnEvent("Click", HideButtons)
importFile := gui2.Add("Button", "wp", "Import Macro")
importFile.OnEvent("Click", Open)
saveButton := gui2.Add("Button", "wp", "Export Macro")
saveButton.OnEvent("Click", FileSaveAs)
exitButton := gui2.Add("Button", "wp", "Exit Macro Recorder")
exitButton.OnEvent("Click", exitM)
gui2.Submit()


if !InStr(FileExist("Macros"), "D") {
  DirCreate "Macros"
}

OnMessage(0x0200, WM_MOUSEMOVE)
;--------------------------


Options(thisGui, info) {
  global OptionsEditing
  if OptionsEditing {
    gui2.Hide()
    OptionsEditing := false
  } else {
    gui2.Show("Y100")
    gui2.Title := "Macro Recorder"
    gui2.Submit(false)
    OptionsEditing := true
  }
  return
}

#SuspendExempt true
F9:: {
  Options(gui1["Options"], "")
}
#SuspendExempt false


#SuspendExempt true
F1:: {
  RecordScreen(gui1["Scr"], 0)
}
#SuspendExempt false

#SuspendExempt true
F2:: {
  RecordWindow(gui1["Win"], 0)
}
#SuspendExempt false

RecordScreen(thisGui, info) {
  global Recording, Playing, LogArr, oldid, Coord
  if (Recording or Playing)
    return
  else {
    Coord := "Screen"
    LogArr := [], oldid := "", Log(), Recording := 1, SetHotkey(1)
    ShowTip("Recording")
  }
}

RecordWindow(thisGui, info) {
  global Recording, Playing, LogArr, oldid, Coord
  if (Recording or Playing)
    return
  else {
    Coord := "Window"
    LogArr := [], oldid := "", Log(), Recording := 1, SetHotkey(1)
    ShowTip("Recording")
  }
}

;~ F7::
#SuspendExempt true
F3:: {
  Stop(gui1["Stop"], 0)
}
#SuspendExempt false

Stop(thisGui, info) {
  global Recording, Playing, LogArr, LogFile
  if Recording {
    if (LogArr.Length > 0)
    {
      s := "`nPlayspeed:=" playspeed " `n`nLoop 1`n{`n`n    SetTitleMatchMode 2"
        . "`n    CoordMode `"Mouse`", `"" Coord "`"`n"
      For k, v in LogArr {
        s .= "`n" v "`n"
        ; MsgBox v
      }
      ;~ s.="`nSleep 1000`n`n}`n"
      s .= "`n    Sleep 1000  //PlaySpeed `n`n}`n"
      s := RegExReplace(s, "\R", "`n")
      ; MsgBox LogFile
      try {
        FileDelete LogFile
      } catch as e {
        MsgBox "File not found"
      }
      FileAppend s, LogFile
      s := ""
    }
    SetHotkey(0), Recording := false, LogArr := ""
  }
  else if Playing
  {
    flog("winfpt" . Play_Title)
    flog("winfsc" . A_ScriptHwnd)
    list := WinGetList(Play_Title)
    For v in list 
    {
      flog("winf" . v)
      if WinExist("ahk_id " v) != A_ScriptHwnd
        {
          pid := WinGetPID("ahk_id " v)
          WinClose , 3
          if WinExist("ahk_id " v) {
            ProcessClose pid
          }
          
          gui1.Show()
        }
    }
    SetTimer CheckPlay, 0
    Playing := 0
  }
  ShowTip()
  Suspend 0
  Pause 0
  gui1["Pause"].Text := "[F6] Pause "
  isPaused := false
}

flog(params*){
  logfile := "f:\AutoHotkeyLog.log"
  ts := FormatTime(, "yyyy-MM-dd HH:mm:ss.") substr(A_TickCount,-3)
  ; s := A_TickCount
  ; ts := substr(s,-6,3) "." substr(s,-3)
  for param in params
    message .= param . " "
  FileAppend ts " " message "`n", logfile
}


#SuspendExempt true
F4:: {
  Play(gui1["Play"], 0)
}
#SuspendExempt false

#SuspendExempt true 
F5:: {
  EditF(gui1["Edit"], 0)
}
#SuspendExempt false 

#SuspendExempt true
F6:: {
  PauseM(gui1["Pause"], 0)
}
#SuspendExempt false


Play(thisGui, info) {
  if (Recording or Playing)
    Send "{F3}"  ; Stop
  ahk := A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe" : A_AhkPath
  if not FileExist(ahk)
  {
    MsgBox "Error Can't Find " ahk "!"
    Exit
  }
  Run ahk "  " LogFile
  SetTimer CheckPlay, 500
  CheckPlay()
  return
}


CheckPlay() {
  global Playing
  Check_OK := 0
  list := WinGetList(Play_Title)
  For v in list {
    if (v != A_ScriptHwnd)
      Check_OK := 1
  }
  if Check_OK {
    Playing := 1, ShowTip("Playing")
  } else if Playing {
    SetTimer CheckPlay, 0
    Playing := 0
    ShowTip()
  }
}


HideButtons(thisGui, info) {
  global hideButtonsV 
  hideButtonsV := !hideButtonsV
  if hideButtonsV {
    thisGui.Text := "Show Panel Buttons F10"
    gui1.Hide()
  }
  else {
    thisGui.Text := "Hide Panel Buttons F10"
    gui1.Show()
  }
}

#SuspendExempt true
F10:: {
  HideButtons(gui2["Tbuttons"], "")
}
#SuspendExempt false


EditF(thisGui, info) {
  Stop(thisGui, info)
  Run EditorPath " " LogFile
}

PauseM(thisGui, info) {
  global Recording, isPaused
  if Recording {
    Suspend
    Pause A_IsSuspended ? True : False
    isPaused := A_IsSuspended
    Log()
  } else if Playing {
    if isPaused = 1 {
      isPaused := 0
    } else {
      isPaused := 1
    }
    list := WinGetList(Play_Title)
    For v in list {
      if WinExist("ahk_id " v) != A_ScriptHwnd
        PostMessage 0x111, 65306
    }
  } else {
    return
  }

  if isPaused = 1 {
    gui1["Pause"].Text := "[F6]<Pause>"
  } else {
    gui1["Pause"].Text := "[F6]Pause"
  }
}


hcheck(thisGui, info) {
  gui2.Submit(0)
  return
}


Open(thisGui, info) {
  OutputVar := FileSelect(1, "Macros", "Import File", "AHK Macro File (*.ahk; *.txt)")
  if (OutputVar) {
    FileCopy OutputVar, LogFile, 1
  }
}


exitM(thisGui, info) {
  MsgBox "Macro recorder, `nGoodbye", , "T2"
  exitapp
}


FileSaveAs(thisGui, info) {
  gui2.Opt("+OwnDialogs")   ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
  SelectedFileName := FileSelect("S16", "Macros", "Save File", "AHK File (*.ahk)")
  if not SelectedFileName ; No file selected.
    return
  CurrentFileName := SelectedFileName

  if FileExist(CurrentFileName)
  {
    try
      FileDelete CurrentFileName
    catch as e {
      MsgBox "The attempt to overwrite " CurrentFileName " failed."
      return
    }
  }

  SplitPath CurrentFileName, , , &OutExtension

  if (OutExtension)
    FileCopy LogFile, CurrentFileName, 1
  else
    FileCopy LogFile, CurrentFileName ".ahk", 1
  return
}


WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
  static OK_Time := 0
  ListLines False
  ; if (A_Gui=1) and (A_GuiControl="Pause")
  ;   and (t:=A_TickCount)>OK_Time
  ; {
  ;   OK_Time:=t+500
  ;   Gosub, Pause
  ; }
}


ShowTip(s := "", pos := "y35", color := "Red|00FFFF") {

  global bak, idx, guiTip
  if (bak = color "," pos "," s)
    return
  bak := color "," pos "," s
  SetTimer ShowTip_ChangeColor, 0
  guiTip.Destroy()
  if (s = "")
    return
  ; WS_EX_NOACTIVATE:=0x08000000, WS_EX_TRANSPARENT:=0x20

  guiTip := Gui("+LastFound +AlwaysOnTop +ToolWindow -Caption +E0x08000020")
  guiTip.BackColor := "FFFFF0"
  WinSetTransColor("FFFFF0", guiTip)
  guiTip.MarginX := 10
  guiTip.MarginY := 5
  guiTip.SetFont("Q3 W700 S20")
  guiTip.AddText("", s)
  guiTip.Show("NA " pos)
  SetTimer ShowTip_ChangeColor, 1000

}
ShowTip_ChangeColor() {
  global bak, idx
  guiTip.Opt("+AlwaysOnTop")
  r := StrSplit(SubStr(bak, 1, InStr(bak, ",") - 1), "|")
  guiTip.SetFont("Q3 c" r[idx := Mod(Round(idx), r.Length) + 1], "Static1")
  return
}

;============ Functions =============


SetHotkey(f := 0) {
  ; These keys are already used as hotkeys
  global UsedKeys
  f := f ? "On" : "Off"
  Loop 254 {
    k := GetKeyName(vk := Format("vk{:X}", A_Index))
    if k != "" && !("Control" = k) && !("Alt" = k) && !("Shift" = k) &&
      !("F1" = k) && !("F2" = k) && !("F3" = k) && !("F4" = k) &&
        !("F5" = k) && !("F6" = k) && !("F9" = k) {
      try {
        Hotkey "~*" vk, LogKey, f
      } catch as e {
      }
    }

  }
  For i, k in StrSplit("NumpadEnter|Home|End|PgUp"
    . "|PgDn|Left|Right|Up|Down|Delete|Insert", "|")
  {
    sc := Format("sc{:03X}", GetKeySC(k))
    if not k = "" && !("Control" = k) && !("Alt" = k) && !("Shift" = k) &&
      !("F1" = k) && !("F2" = k) && !("F3" = k) && !("F4" = k) &&
        !("F5" = k) && !("F6" = k) && !("F9" = k) {
      try {
        Hotkey "~*" sc, LogKey, f
      } catch as e {
      }
    }
  }
  if f = "On" {
    f := 16
  } else {
    f := 0
  }
  SetTimer TLogWindowF, f
  if (f = "On")
    TLogWindowF()
}


LogKey(thisKey) {
  Critical
  k := GetKeyName(vksc := SubStr(A_ThisHotkey, 3))
  k := StrReplace(k, "Control", "Ctrl"), r := SubStr(k, 2)
  if r = "Alt" or r = "Ctrl" or r = "Shift" or r = "Win"
    (gui2["TLogkey"].Value) && LogKey_Control(k)
  else if k = "LButton" or k = "RButton" or k = "MButton"
    (gui2["TLogmouse"].Value) && LogKey_Mouse(k)
  else
  {
    if (!gui2["TLogkey"].Value)
      return
    if (k = "NumpadLeft" or k = "NumpadRight") and !GetKeyState(k, "P")
      return
    k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"
    Log(k, 1)
  }
}


TLogWindowF() {
  (gui2["TLogWindow"].Value) && LogWindow()
  return
}


LogKey_Control(key) {
  global LogArr, Coord
  k := InStr(key, "Win") ? key : SubStr(key, 2)
  if (k = "Ctrl")
  {
    CoordMode "Mouse", Coord
    MouseGetPos &X, &Y
  }
  Log("{" k " Down}", 1)
  Critical "Off"
  KeyWait key
  Critical
  Log("{" k " Up}", 1)
  if (k = "Ctrl")
  {
    i := LogArr.Length, r := i > 0 ? LogArr[i] : ""
    if InStr(r, "{Blind}{Ctrl Down}{Ctrl Up}")
      LogArr[i] := "MouseMove, " X ", " Y
  }
}

LogWindow() {
  global oldid, LogArr
  static oldtitle
  id := WinExist("A")
  title := gui2["TLogWindowTitle"].Value ? WinGetTitle("A") : ""
  class := WinGetClass("A")
  executable := WinGetProcessName("A")
  if (title = "" and class = "" and executable = "")
    return
  if (id = oldid and title = oldtitle)
    return
  oldid := id, oldtitle := title
  title := SubStr(title, 1, 50)
  if (!StrLen(Chr(0xFFFF)))
  {
    gui1["MyText"].Text = title
    s := gui1["MyText"].Text
    if (s != title)
      title := SubStr(title, 1, -1)
  }
  title .= gui2["TLogWindowClass"].Value && class ? " ahk_class " class : ""
  title .= gui2["TLogWindowExe"].Value && executable ? " ahk_exe " executable : ""
  title := RegExReplace(Trim(title), "[``%;]", "``$0")
  ;~ s:="tt = " title "`nWinWait, %tt%"
  ;~ . "`nIfWinNotActive, %tt%,, WinActivate, %tt%"
  s := "    tt := `"" title "`"`n    WinWait tt"
    . "`n    HotIfWinNotActive tt"
    . "`n    WinActivate tt"
  i := LogArr.Length, r := i > 0 ? LogArr[i] : ""
  if InStr(r, "tt = ") = 1
    LogArr[i] := s, Log()
  else
    Log(s)
}

LogKey_Mouse(key) {
  global LogArr, Coord
  k := SubStr(key, 1, 1)
  CoordMode "Mouse", Coord
  MouseGetPos &X, &Y, &id
  if (id = gui1.Hwnd)
    return
  Log("    MouseClick `"" k "`", " X ", " Y ",,, D")
  CoordMode "Mouse", "Screen"
  MouseGetPos &X1, &Y1
  t1 := A_TickCount
  Critical "Off"
  KeyWait key
  Critical
  t2 := A_TickCount
  if (t2 - t1 <= 200)
    X2 := X1, Y2 := Y1
  else
    MouseGetPos &X2, &Y2
  i := LogArr.Length, r := i > 0 ? LogArr[i] : ""
  if InStr(r, ",,, D") and Abs(X2 - X1) + Abs(Y2 - Y1) < 5
    LogArr[i] := SubStr(r, 1, -5), Log()
  else
    Log("    MouseClick `"" k "`", " (X + X2 - X1) ", " (Y + Y2 - Y1) ",,, U")
}


;;;;
Log(str := "", Keyboard := 0) {
  global LogArr
  static LastTime := 0
  t := A_TickCount, Delay := (LastTime ? t - LastTime : 0), LastTime := t
  if str = "" {
    return
  }
  i := LogArr.Length
  r := i > 0 ? LogArr[i] : ""
  if (Keyboard and InStr(r, "Send,") and Delay < 1000)
  {
    LogArr[i] := r . str
    return
  }

  if (Delay > 200)
    ;~ LogArr.Push("Sleep, " (Delay//2))
    LogArr.Push("    Sleep " (Delay) " //playspeed")
  LogArr.Push(Keyboard ? "    Send `"{Blind}" str "`"" : str)
}

