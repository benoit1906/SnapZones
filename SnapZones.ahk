#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force
; SetBatchLines, -1
; SetWinDelay, -1
; SetControlDelay, -1
; listlines off
#Include WinGetPosEx.ahk
#Include Functions.ahk
#Include Classes.ahk

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;ToDo;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; To improve further : improve vertical screens (faire le dual dans Aerosnap, GUIwindow, Half, Snapwindow, WinEventProc, (updateSpacing?), class monitorInfo)

global winStora 	;storage of all known windows
global MonStora 	;storage of all known monitors
global ApplicationName:= "SnapZones"
global EnableHoldKey
global HoldKey
ApplicationDescription := "Window Manager and AeroSnap Replacement"
winStora:= Object()
InitMonitors()

OnMessage(0x007E, "InitMonitors")		; 0x007E WM_DISPLAYCHANGE, from WinUser.h. When display resolution changes (e.g. when a monitors is added/removed), reinitialise the monitors
OnMessage(0x0011, "restoreAll") 	; 0x0011 WM_QUERYENDSESSION : when Shutdown or log-off, restore snapped windows to their original positions

; DllCall("SetWinEventHook", Uint, 0x000A, Uint, 0x000B, Ptr, 0, Ptr, RegisterCallBack("WinEventProc", "",7), Uint, 0, Uint, 0, UInt, 0x0002)
DllCall("SetWinEventHook", Uint, 0x000A, Uint, 0x000A, Ptr, 0, Ptr, RegisterCallBack("WinEventProc", "",7, 1), Uint, 0, Uint, 0, UInt, 0x0002)
DllCall("SetWinEventHook", Uint, 0x000B, Uint, 0x000B, Ptr, 0, Ptr, RegisterCallBack("WinEventProc", "",7, 0), Uint, 0, Uint, 0, UInt, 0x0002)
; SetWinEventHook https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwineventhook
; 0x000A corresponds to EVENT_SYSTEM_MOVESIZESTART and is the event of a window being moved or resized
; 0x000B EVENT_SYSTEM_MOVESIZEEND
; 0x0002 ignores this process

DllCall("SetWinEventHook", Uint, 0x0016, Uint, 0x0017, Ptr, 0, Ptr, RegisterCallBack("WinGetsMinimized", ""), Uint, 0, Uint, 0, UInt, 0x0002)
; When the window is minimized, we don't want it to restore with the snapped position. This allows that wia the function WinGetsMinimized
; 0x0016 EVENT_SYSTEM_MINIMIZESTART
; 0x0017 EVENT_SYSTEM_MINIMIZEEND

listlines off
Menu, Tray, DeleteAll
Menu, Tray, NoStandard
Menu, Tray, Add, %applicationname%, ABOUT
Menu, Tray, Default, %applicationname%
Menu, Tray, Add,
Menu, Tray, Add, More zones, MoreZones
Menu, Tray, Add, Less zones, LessZones
Menu, Tray, Add,
Menu, Tray, Add, Settings, Settings
Menu, Tray, Add, Reload, Restart
Menu, Tray, Add, Help, Help
Menu, Tray, Add, About...,ABOUT
Menu, Tray, Add, Exit, Exit
Menu, Tray, Tip, %applicationname%
Menu, Tray, Icon, Icon.ico

IfNotExist, %ApplicationName%.ini 
{
	msgbox,,% ApplicationName " - Introduction",% "Hello there !`n`nWelcome to " ApplicationName ", the " ApplicationDescription ".`n`nThis program is aimed to be a replacement for the default AeroSnap while providing other options to manage windows. AeroSnap is a feature of Windows 10 that allows to place easily two windows on each side of the screen.`n`n" ApplicationName " expands the concept further by increasing the maximum number of snapped windows. This is done by providing zones in which the user drop any window by dragging or by using the original Windows key combinations.`n`nAfter this message, you will be greeted with a tutorial followed by the settings, both of which you can find in the tray icon at any time or by running this .exe file."
	FileAppend, % ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;`n", %ApplicationName%.ini
	FileAppend, % ";; Make sure to reload " ApplicationName " after editing this file directly (right-click tray menu > Reload, or by double clicking on " ApplicationName ".exe).`n", %ApplicationName%.ini
	FileAppend, % ";; Note that it is best to change the settings via the menu (right-click tray menu > Settings).`n", %ApplicationName%.ini
	FileAppend, % ";; You can find a list of compatible holdkeys on https://www.autohotkey.com/docs/KeyList.htm but support is not guaranteed.`n", %ApplicationName%.ini
	FileAppend, % ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;`n`n", %ApplicationName%.ini
	FileAppend, [ResolutionSpecificDivider], %ApplicationName%.ini
	FileAppend, % "`n;; In this section, you can set the default divider according to your display's resolution. For this, write a new key as followed ""widthxheight = value"" (e.g. 2560x1440=4).`n;; Be careful as widthxheight is different to heightxwidth !`n;; The default number of zones in the settings menu will still be ""DefaultDivider"" as in the ""settings"" section.`n`n", %ApplicationName%.ini
}

IniRead, noTrayIcon, %ApplicationName%.ini, Settings, noTrayIcon ,0
IniRead, runOnStartUp, %ApplicationName%.ini, Settings, runOnStartUp ,1
IniRead, HoldKey, %ApplicationName%.ini, Settings, HoldKey , Shift
IniRead, EnableholdKey, %ApplicationName%.ini, Settings, EnableholdKey ,1
IniRead, EnableShortcutKeys, %ApplicationName%.ini, Settings, EnableShortcutKeys ,1
IniRead, defaultDivider, %ApplicationName%.ini, Settings, DefaultDivider ,3

; AltTab windows
GroupAdd AltTabWindow, ahk_class MultitaskingViewFrame  ; Windows 10
GroupAdd AltTabWindow, ahk_class TaskSwitcherWnd  ; Windows Vista, 7, 8.1
GroupAdd AltTabWindow, ahk_class #32771  ; Older, or with classic alt-tab enabled


if (notrayIcon)
	Menu, Tray, NoIcon

if (runOnStartUp){
	IfNotExist, % A_Startup "\" ApplicationName ".lnk"
		FileCreateShortcut, % A_ScriptFullPath, % A_Startup "\" ApplicationName ".lnk", % A_ScriptDir, -skipIntro, % ApplicationDescription
}
Else
	FileDelete, % A_Startup "\" ApplicationName ".lnk"

; Hotkey, If, DesktopUnderMouse() && EnableHoldKey
; Hotkey, If, ;EnableHoldKey
; Hotkey, ~%holdKey% & RButton, menumenu	;doesn't work
Hotkey, ~%holdKey%, ZonePositioning ;, T1
Hotkey, ~%holdKey% Up, ZoneDestroy ;, T1

for n, param in A_Args  ; For each parameter
{
    if (param = "-skipIntro"){
    	return
    }
}

; Return 		;for testing to not get the windows each time
Gosub, Help

Settings:
	Gui, Font, s18 bold
	Gui, Add, GroupBox, xm ym w340 h230, Settings 				; starts at y = 15
	Gui, Margin, 0, 20
	Gui, Font
	Gui, Font, s10
	Gui, Add, text, x190 y51 w31
	Gui, Add, UpDown, vdefaultDivider Range2-15, %defaultDivider%, w20
	Gui, Add, text, x30 y50 , Default number of zones : 
	Gui, Add, CheckBox, % "vEnableHoldKey" (EnableHoldkey ? " checked" : ""), % "Hold " (holdKey ? holdkey : "Shift") " to enable zone positioning"
	Gui, Add, Checkbox, % "vEnableShortcutKeys" (EnableShortcutKeys ? " checked" : ""), Enable shortcut keys
	Gui, Add, CheckBox, % "vRunOnStartUp " (runOnStartUp ? " checked " : ""), Start %applicationName% on startup
	Gui, Add, CheckBox, % "vNoTrayIcon " (noTrayIcon ? " checked " : ""), No tray icon
	Gui, Add, Link, gAboutSettings x320 y+10, <a>About</a>
	Gui, Add, Link, gOpenIni x230 y221, <a href="">Open .ini file</a>
	Gui, Add,Button,x208 y+15 w75 Default gSETTINGSOK vOKButton,OK
	Gui, Add,Button,x+5 yp w75 gSETTINGSCANCEL,Cancel
	Gui, show, w385 h285, %applicationName% - Settings
	GuiControl, Focus, OKButton
	return


SETTINGSOK:
	gui, submit
	SettingsWrite(RunOnStartUp, NoTrayIcon, defaultDivider, EnableShortcutKeys)
	Gui, Destroy

	if (NoTrayIcon)
		Menu, Tray, NoIcon
	else 
		Menu, Tray, Icon

	if (runOnStartUp){
		IfNotExist, % A_Startup "\" ApplicationName ".lnk"
			FileCreateShortcut, % A_ScriptFullPath, % A_Startup "\" ApplicationName ".lnk", % A_ScriptDir, -skipIntro, % ApplicationDescription
	}
	Else
		FileDelete, % A_Startup "\" ApplicationName ".lnk"
	return

SETTINGSCANCEL:
	Gui, Destroy
	return

OpenIni:
	Run, % "notepad.exe " ApplicationName ".ini"
	Gui, Destroy
	return

AboutSettings:
	Gui, Destroy
About:
	; msgbox,,% ApplicationName " - About", % "Created by Benoît Vidotto via Autohotkey 1.1.32, 2021`n`nContact : bevidotto@gmail.com"
	Gui, Font, s15 bold
	Gui, Add, GroupBox, xm ym w340 h145, About this program
	Gui, Margin, 0, 8
	Gui, Font
	Gui, Font, s10
	Gui, add, text, x30 y55, Created by Benoît Vidotto via AutoHotkey 1.1.32, 2021
	Gui, add, link, , Access the GitHub page <a href="https://github.com/benoit1906/SnapZones">here</a>.
	Gui, Add, Link, , Also, if you want like my work, you can donate <a href="https://www.paypal.com/donate?hosted_button_id=9J2QNP7FWP2GJ">here</a>.
	Gui, show, w373 h168, %applicationName% - About

	return

Exit:
	restoreAll()
	ExitApp

Help:
	MsgBox, 32, %ApplicationName% - Tutorial, % "Zone Positioning:`n`nHold " (holdKey ? holdkey : "Shift") " while dragging a window to snap it into a zone.`nWith this technique, you can snap a window on up to three zones at once !`n`nHold "(holdKey ? holdkey : "Shift")" while holding the left, right, top or bottom edge of a snapped window to change its size according to the zones.`n`n`nShortcut Keys: `n`nWin + Left/Right `nSnap or move a window to left or right.`n`nWin + Up/Down`nIncrease/Decrease the width of a snapped window.`n`nWin + PageUp/PageDown`nIncrease/Decrease the number of zones on the current monitor.`n`nWin + Shift + PageUp/PageDown `nDivide the height of a snapped window by 2.`n`nWin + Right Click on the desktop`nOpen the menu."
	return

Restart:
	restoreAll()
	Run, %A_ScriptFullPath% /restart -skipIntro
	return

ZonePositioning:
	if (GetKeyState("LButton", "P") = 1){ 				; can't work while the window is unsnapped with the mouse (see WinEventProc, b4 the first else if) because autohotkey doesn't support multiple threads
		CoordMode Mouse, Screen 					; otherwise, "P" should be added to GetKeyState()
		MouseGetPos, mouseAbsPosX, mouseAbsPosY
		SendMessage 0x84,, ( mouseAbsPosY << 16 )|mouseAbsPosX & 0xFFFF,, A ; explained in WinEventProc()
		HitTest:=ErrorLevel
		WinGet, winID, ID, A
		if (winStora[winID].snapped = 0 && (HitTest = 2)){
			click down 								;thanks to this, the comment above is irrelevant, kinda (sometimes, windows have weird layout and it then doesn't work, hence the condition hittest=2)
			GUIWindow(winID, holdKey)
		}
		else if (winStora[winID].snapped = 1 ){
			if (HitTest = 10 || HitTest = 11)
				GuiSections(monstora[winStora[winID].mon])
			else if (HitTest = 12 || HitTest = 15){
				mon:=monstora[winStora[winID].mon]
				Gui, Section1: +ToolWindow -Caption -DPIScale +AlwaysOnTop
				Gui, Section1: Color, B00B13
				Gui, Section1: Show, % "x" mon.position[winStora[winID].snapPos].x "y" mon.position[winStora[winID].snapPos].y + mon.box.h/2 "w" winStora[winID].snapWidth * mon.box.w "h" 5 "NA" ; NoActivate
			}
		}
	}
	return 

; menumenu:
#Rbutton::
	Menu, Tray, show
	return

ZoneDestroy:
	GUIDestroy()
	return

#If
!F4::
~Lbutton:: 				
	WinGetsMaxOrClosed() 		; restore the original position of the window if it is snapped when ...
	return



#If  (EnableShortcutKeys)
#Left::SnapWindow(-1, 0)
#Right::SnapWindow(1, 0)

+#Left::
+#Right::
	WinGet, winID, id, A
	if(winStora[winID].snapped=1){
		winStora[winID].snapped:=0
		SetRestoreWindowPlacement(winID)
		WinGet, MinMaxState, MinMax, ahk_id %winID%
		if MinMaxState!=1
			winRestore, A
	}
	send % A_ThisHotkey = "+#Left" ? "+#{left}" : "+#{right}"
	return

#Up::winMinimized:=SnapWindow(0, 1, WinMinimized)
#Down::winMinimized:=SnapWindow(0, -1)

#+Up::winMinimized := miniMaxi(1, WinMinimized)
#+Down::winMinimized := miniMaxi(-1)

~LWin Up::
~RWin Up::
	winMinimized:=""		;when the win key is released, cancel winMinimized
	GUIDestroy()
	if (A_PriorHotkey = "#Left" || A_PriorHotkey = "#Right" || A_PriorHotkey = "#Up" || A_PriorHotkey = "#Down"  && A_TimeSincePriorHotkey < 5000){ ;|| A_PriorHotkey = "#PgDn"|| A_PriorHotkey = "#PgUp"
		AeroSnap()
	}
	return

#+PgUp::Half(+1)
#+PgDn::Half(-1)

#PgUp::
MoreZones:
	UpdateSpacing(+1)
	return
#PgDn::
LessZones:
	UpdateSpacing(-1)
	return

#IfWinExist ahk_group AltTabWindow
~*Esc::		; Send {Alt up}  ; When the menu is cancelled, release the Alt key automatically.
	CoordMode Mouse, Screen 		; Releasing Altkey selects the current window
	MouseGetPos, MouseX, MouseY 	; This method really cancels the menu without activating another window
	SetDefaultMouseSpeed 0
	click 1 1
	click %MouseX% %MouseY% 0
	return

; #If DesktopUnderMouse() && EnableHoldKey
#If EnableHoldKey