#Include WinGetPosEx.ahk

AeroSnap(again := 0){					; attempts to replicate the suggestion feature from snapping a window with the original Aero Snap
	WinGet, winID, ID, A
	monitorName:=GetMonitorFromWindow(winID)
	mon:= monStora[monitorName]
	WinGet, minMaxState, MinMax, A
	if(winStora[winID].snapped = 1){
		if (mod(mon.div, 2)=0 && winStora[winID].snapWidth = mon.div/2 && mon.vertical = 0 && again = 0 && (winStora[winID].snapPos = 1 || winStora[winID].snapPos = 1 + mon.div/2)){
			send {LWin up}
			if(winStora[winID].snapPos = 1){
				SetRestoreWindowPlacement(winID)
				winRestore ahk_id %winID%
				Send, #{Left}
			}
			else if (winStora[winID].snapPos = 1 + mon.div/2){
				SetRestoreWindowPlacement(winID)
				winRestore ahk_id %winID%
				Send, #{right}
			}

			WinWaitNotActive, ahk_id %winID% 		; wait for the selection of windows to appear
			Loop 		;for some reason << WinWaitNotActive, ahk_exe "explorer.exe" >> does not work
			{
				; sleep 10		;manage the CPU
				WinWaitActive, A
				WinGet, Proc, ProcessName, A
				WinGetClass, wClass, A
			} until (Proc != "explorer.exe" || wClass = "CabinetWClass")

			WinGet, winID2, ID, A
			if(winID != winID2){
				WinGetPos, x, y, w, h, ahk_id %winID2%
				WinGetPosEx(winID2, , , , , xOffset, yOffset)
				if (!winStora[winID2]){
					winStora[winID2] := new window(winID2)
				}
				GetWindowPlacement(winID2, wp)
				winStora[winID2].restorePos := new SizePosition(wp.rcNormalPosition.left, wp.rcNormalPosition.top, wp.rcNormalPosition.right, wp.rcNormalPosition.bottom)
				winStora[winID2].snapWidth :=  round(mon.div/2)
				winStora[winID2].snapped :=  1
				if (winStora[winID].snapPos = 1 ){
					if(abs(w+2*xoffset - mon.workArea.w/2) < 4 && x - xoffset >(mon.workArea.w/2) - 4){
							winStora[winID2].snapPos := 1 + round(mon.div/2)
					}
					Else
						return
				}
				else if (winStora[winID].snapPos = 1 + mon.div/2){
					if(abs(w+2*xoffset - mon.workArea.w/2)< 4 &&  x<=mon.workArea.l){
							winStora[winID2].snapPos := 1
					}
					Else
						return
				}
				else{
					winStora[winID2].snapped :=  0
					return
				}
				
				GetWindowPlacement(winID2, wp) 		;wp has to be initiated with all its current values before getting injected inside SetWindowPlacement
				wp.rcNormalPosition.left   := mon.position[winStora[winID2].snapPos].x +xOffset
				wp.rcNormalPosition.top    := mon.position[winStora[winID2].snapPos].y
				wp.rcNormalPosition.right  := mon.position[winStora[winID2].snapPos].x +xOffset + winStora[winID2].snapWidth * mon.box.w-2*xoffset
				wp.rcNormalPosition.bottom := mon.position[winStora[winID2].snapPos].y 			+ mon.box.h -xOffset
				SetWindowPlacement(winID2, wp)

				WinRestore ahk_id %winID2%			; with the winrestore, Windows does not consider these windows as snapped by AeroSnap and we can then change their size easily
			}

			WinGetPosEx(winID, , , , , xOffset, yOffset)
			GetWindowPlacement(winID, wp) 		;wp has to be initiated with all its current values before getting injected inside SetWindowPlacement
			wp.rcNormalPosition.left   := mon.position[winStora[winID].snapPos].x +xOffset
			wp.rcNormalPosition.top    := mon.position[winStora[winID].snapPos].y
			wp.rcNormalPosition.right  := mon.position[winStora[winID].snapPos].x +xOffset + winStora[winID].snapWidth * mon.box.w-2*xoffset
			wp.rcNormalPosition.bottom := mon.position[winStora[winID].snapPos].y 		   + mon.box.h -xOffset
			SetWindowPlacement(winID, wp)

			WinRestore ahk_id %winID%
		}
		else{ 			; imitates the suggestion menu with the AltTabAndMenu
			avPos := [] ; available positions (1 = available, 0 = occupied)
			loop % mon.div{
				avPos.push(1)
			}
			for key, win in winStora{
				if (win.mon = monitorName && win.snapped = 1){
					WinGet, minMaxState, MinMax, % "ahk_id" win.id
					if (minMaxState !=0){
						SetRestoreWindowPlacement(win.id)
						win.snapped := 0
						continue
					}
					loop % win.snapWidth{
						avPos[win.snapPos + A_index-1] := 0
					}
				}
			}
			for k in avPos {
				if avPos[k] = 1
					available := 1
			}
			if available != 1
				return
			send {alt down}{tab} 		; show the window suggestions via the alttab menu
			send +{tab}
			WinWaitActive, ahk_group AltTabWindow
			WinWaitNotActive, ahk_group AltTabWindow
			send {Alt Up}
			
			WinGet, winID2, ID, A
			if (winID = winID2)
				return
			if (!winStora[winID2]){
				winStora[winID2] := new window(winID2)
			}

			newPos := 0
			loop % mon.div{
				if (avPos[A_index] = 1){
					if (newPos = 0){
						newPos := A_index
						newWidth := 1
					}
					Else
						NewWidth += 1	
					if avPos[A_index+1] = 0
						break
				}
			}

			WinGet, minMaxState, MinMax, ahk_id %winID2%
			if (minMaxState =1){
				GetWindowPlacement(winID2, wp)		; gives us the positions of the restored window, which we will store if the window is not snapped
				if(winStora[winID2].snapped = 0)
					winStora[winID2].restorePos := new SizePosition(wp.rcNormalPosition.left, wp.rcNormalPosition.top,,, wp.rcNormalPosition.right, wp.rcNormalPosition.bottom)

				wp.rcNormalPosition.left   := mon.position[newPos].x
				wp.rcNormalPosition.top    := mon.position[newPos].y
				wp.rcNormalPosition.right  := newWidth*mon.box.w
				wp.rcNormalPosition.bottom := mon.box.h
				SetWindowPlacement(winID2, wp) ; no flicker between restore and move
				
				WinRestore, ahk_id %winID2%
				
			}
			else if (winStora[winID2].snapped = 1 && winStora[winID2].mon = monitorName){
				loop % winStora[winID2].snapWidth{
					avPos[winStora[winID2].snapPos + A_index-1] := 1
				}

				newPos := 0
				loop % mon.div{
					if (avPos[A_index] = 1){
						if (newPos = 0){
							newPos := A_index
							newWidth := 1
						}
						Else
							NewWidth += 1	
					}
				}		
			}
			else if (winStora[winID2].snapped = 0){
				if (minMaxState =-1)
					WinRestore, ahk_id %winID2%
				WinGetPos, x, y, w, h, ahk_id %winID2%
				winStora[winID2].restorePos:= new SizePosition(x, y,,, w+x, h+y)
			}
			
			newHeight := 1
			if (mon.vertical){
				newHeight := newWidth
				newWidth := 1
			}
			WinGetPosEx(winID2, , , , , xOffset, yOffset)
			WinMove(winID2, mon.position[newPos].x +xOffset, mon.position[newPos].y, newWidth*mon.box.w-2*xoffset, newHeight*mon.box.h -xOffset)
			winStora[winID2].snapped:=1
			winStora[winID2].snapPos:=newPos
			winStora[winID2].snapWidth:=mon.vertical ? newHeight : newWidth
			winStora[winID2].mon:= monitorName
			
			available:=0
			for k in avPos {
				if avPos[k] = 1
					available := 1
			}
			if (available = 1) {
				available:=""
				avPos:=""
				AeroSnap(1)
			}

		}
	}
	return
}

DesktopUnderMouse(){
	CoordMode, mouse, Screen
	MouseGetPos, ,, Id
	WinGet, proc, ProcessName, ahk_id %id%
	WinGetClass, class, ahk_id %id%
	if (proc = "Explorer.EXE" && class = "WorkerW")
		return 1
	else 
		return 0
}


GetDPIfromMonitorName(monitorName){
	hdc := DllCall("CreateDC",Str,monitorName,Ptr,0,Ptr,0,Ptr,0)
	dpiAdjustedScreenHeight := DllCall("GetDeviceCaps",Ptr,hdc,Int,10) ; VERTRES = 10 (Height, in raster lines, of the screen)
	actualScreenHeight := DllCall("GetDeviceCaps",Ptr,hdc,Int,117) ; DESKTOPVERTRES = 117
	DllCall("DeleteDC",PtrType,hdc)
	return actualScreenHeight/dpiAdjustedScreenHeight
}

GetMonitorFromPoint(x,y){
	point := ( ( x := x ) & 0xFFFFFFFF ) | ( ( y := y ) << 32 )
	hMonitor := DllCall("MonitorFromPoint","Int64",point,UInt,2)
	VarSetCapacity(MONITORINFOEX,104)
	NumPut(104,MONITORINFOEX)
	DllCall("GetMonitorInfo",Ptr,hMonitor,Ptr,&MONITORINFOEX)
	return StrGet(&MONITORINFOEX+40)
}

GetMonitorFromWindow(hwnd){
	hMonitor := DllCall("MonitorFromWindow",Ptr,hwnd,UInt,2)
	VarSetCapacity(MONITORINFOEX,104)
	NumPut(104,MONITORINFOEX)
	DllCall("GetMonitorInfo",Ptr,hMonitor,Ptr,&MONITORINFOEX)
	return StrGet(&MONITORINFOEX+40)
}

GetMonitorID(monitorName){
	SysGet, m, MonitorCount
	Loop, %m% 
	{
		SysGet, name, MonitorName, %A_Index%
		if (name = monitorName)
			return A_Index
	} 
	return default
}

GetWindowPlacement(hwnd, ByRef lpwndpl)
{
	ListLines, off
	VarSetCapacity(_lpwndpl, 44)
	NumPut(44, _lpwndpl)
	result := DllCall("GetWindowPlacement", Ptr, hwnd, Ptr, &_lpwndpl)
	runningOffset := 0
	lpwndpl := new WINDOWPLACEMENT(NumGetInc(_lpwndpl, runningOffset, "UInt")
											, NumGetInc(_lpwndpl, runningOffset, "UInt")
											, NumGetInc(_lpwndpl, runningOffset, "UInt")
											, new tagPOINT(NumGetInc(_lpwndpl, runningOffset, "Int")
															, NumGetInc(_lpwndpl, runningOffset, "Int"))
											, new tagPOINT(NumGetInc(_lpwndpl, runningOffset, "Int")
															, NumGetInc(_lpwndpl, runningOffset, "Int"))
											, new _RECT(NumGetInc(_lpwndpl, runningOffset, "Int")
															, NumGetInc(_lpwndpl, runningOffset, "Int")
															, NumGetInc(_lpwndpl, runningOffset, "Int")
															, NumGetInc(_lpwndpl, runningOffset, "Int")))
	ListLines, on
	return result
}

GUIBox(x, y, w, h, name:="rectangle", e:=5, color := "B00B13"){ 		; draw a simple rectange
	Gui, %name%1: +ToolWindow -Caption -DPIScale +AlwaysOnTop
	Gui, %name%1: Color, %color%
	Gui, %name%2: +ToolWindow -Caption -DPIScale +AlwaysOnTop
	Gui, %name%2: Color, %color%
	Gui, %name%3: +ToolWindow -Caption -DPIScale +AlwaysOnTop
	Gui, %name%3: Color, %color%
	Gui, %name%4: +ToolWindow -Caption -DPIScale +AlwaysOnTop
	Gui, %name%4: Color, %color%

	Gui, %name%1: Show, % "x" x 	"y" y 		"w" w 	"h" e "NA"
	Gui, %name%2: Show, % "x" x		"y" h+y-e	"w" w	"h" e "NA"
	Gui, %name%3: Show, % "x" x		"y" y		"w" e	"h" h "NA"
	Gui, %name%4: Show, % "x" x+w-e "y" y		"w" e 	"h" h "NA"
	return
}

GUIDestroy(){
	ProcessPID := DllCall("GetCurrentProcessId")			; this solution has been abandoned because winexist does not work properly
	while (WinExist("ahk_class AutoHotkeyGUI") && WinExist("ahk_pid" ProcessPID)){			;WinExist is bugged AF
		if(A_index<=4){
			Gui, perimeter%A_index%: Destroy
			Gui, box%A_index%: Destroy
		}
		Gui, Section%A_Index%: Destroy
	}

	; WinGet listID, List, % "ahk_class AutoHotkeyGUI"
	; ; ProcessPID := DllCall("GetCurrentProcessId")
	; loop % listID +1 {								; list ID in winget does not always work so "if on processID" is out
	; 	; thisID := ID%A_Index%
	; 	; WinGet, WindowPID, PID, ahk_id %thisID%
	; 	; if (ProcessPID = WindowPID){
	; 		; if (A_index <5 ){
	; 			Gui, perimeter%A_index%: Destroy 			
	; 			Gui, box%A_index%: Destroy
	; 		; }
	; 		Gui, Section%A_Index%: Destroy
	;  	; }	
	; }
	return
}

GUISections(mon, e:=4, color:="B00B13"){ 			; draw the delimitations of each zones
	if (mon.vertical = 0){
		Loop, % mon.div {
			if(A_index != 1){
				Gui, Section%A_index%: +ToolWindow -Caption -DPIScale +AlwaysOnTop
				Gui, Section%A_index%: Color, %color%
				Gui, Section%A_index%: Show, % "x" mon.position[A_index].x "y" mon.position[A_index].y "w" e "h" mon.box.h "NA" ; NoActivate
			}
		}
	}
	; else {
	; 	Loop, % mon.div {
	; 		if(A_index != 1){
	; 			Gui, Section%A_index%: +ToolWindow -Caption -DPIScale +AlwaysOnTop
	; 			Gui, Section%A_index%: Color, %color%
	; 			Gui, Section%A_index%: Show, % "x" mon.position[A_index].x "y" mon.position[A_index].y "w" mon.box.w "h" e "NA" ; NoActivate
	; 		}
	; 	}
	; }
	Return
}

GUIWindow(winID, holdKey := "shift", e:=5){			; draw the frames when positiong window with mouse and shift
	ListLines, Off 				; e is the width of the lines drawed here
	mon := monStora[GetMonitorFromWindow(winID)]
	if mon.vertical
		return
	GUIBox(mon.workArea.l, mon.workArea.t, mon.workArea.w, mon.workArea.h, "perimeter",e, "c1c1c1")
	GuiSections(mon ,e, "c1c1c1")
	curPosL := mon.workArea.r
	Loop{				
		; sleep 10
		MouseGetPos, mouseAbsPosX, mouseAbsPosY
		if (!GetKeyState(holdKey) || !GetKeyState("LButton", "P")){		;if one or the other is released
			GUIDestroy()
			listlines on
			return
		}
		curMon := GetMonitorFromPoint(mouseAbsPosX, mouseAbsPosY)
		if (curMon != mon.name){ 										; if mouse, and thus window, changed monitor, change monitor
			mon:=monStora[curMon]
			GUIDestroy()
			; if mon.vertical{
			; 	GUIDestroy()
			; 	continue
			; }
			GUIBox(mon.workArea.l, mon.workArea.t, mon.workArea.w, mon.workArea.h, "perimeter", e, "c1c1c1")
			GuiSections(mon, e, "c1c1c1")
		}
		if(mouseAbsPosX < curPosL || curPosR < mouseAbsPosX || mouseAbsPosY < curPosB || curPosT < mouseAbsPosY){
			curPosT := mon.workArea.t+75
			curPosB := mon.workArea.b
			loop % mon.div{
				if(mouseAbsPosX > mon.position[A_index].x && mouseAbsPosX < (A_index = mon.div ? mon.WorkArea.r : mon.position[A_index+1].x)){
					if (A_index != 1 && mouseAbsPosX - mon.position[A_index].x < 30){ 	;span on two zones on the right of the border
						GUIBox(mon.position[A_index-1].x + 2*e, mon.position[A_index-1].y + 2*e, 2*mon.box.w - 3*e, mon.box.h -4*e, "box", e)
						curPosL := mon.position[A_index].x-30
						curPosR := mon.position[A_index].x+30
					}
					else if (A_index != mon.div && mon.position[A_index+1].x - mouseAbsPosX < 30){ ;span on two zones on the left of the border
						GUIBox(mon.position[A_index].x + 2*e, mon.position[A_index].y + 2*e, 2*mon.box.w - 3*e, mon.box.h -4*e, "box", e)
						curPosL := mon.position[A_index+1].x-30
						curPosR := mon.position[A_index+1].x+30	
					}
					else{
						if (mouseAbsPosY - mon.position[A_index].y < 75 && A_index != 1 && A_index != mon.div){ 		;span on three zones
							GUIBox(mon.position[A_index-1].x + 2*e, mon.position[A_index].y + 2*e, 3 * mon.box.w - 3*e, mon.box.h -4*e, "box", e)
							curPosT := mon.position[A_index].y
							curPosB := mon.position[A_index].y +75
						}	
						else{ 				; normal window
							if mon.vertical
								break
							GUIBox(mon.position[A_index].x + 2*e, mon.position[A_index].y + 2*e, mon.box.w - 3*e, mon.box.h -4*e, "box", e)
						}
						curPosL := mon.position[A_index].x +30
						curPosR := A_index = mon.div ? mon.WorkArea.r : mon.position[A_index+1].x -30
					}
					break
				}
			}
		}
	}
}

Half(vDiv){ 			; Sets the window height to h/2 or w/2
	WinGet, minMaxState, MinMax, A
	WinGet, winID, ID, A
	WinGetPos,,y,w, h, A
	WinGetPosEx(winID, , , , , xOffset, yOffset)
	monitorName:=GetMonitorFromWindow(winID)
	if !(monStora[monitorName]){
		monitorId:=GetMonitorID(monitorName)
		mon:= new monitorInfo(monitorId)
		monStora[mon.name]:=mon
	}
	else
		mon:= monStora[monitorName]
		
	if (winStora[winID] && minMaxState = 0){
		if (mon.vertical = 0){
			if(winStora[winID].half = 0){ 		; if the snapped window is full size, divide it by two
				WinMove(winID,, (vDiv = 1 ? mon.position[winStora[winID].snapPos].y : mon.position[winStora[winID].snapPos].y + mon.box.h/2),, mon.workArea.h/2 - xoffset)
				winStora[winID].half := 1
			}
			else{ 								; otherwise, set the original position
				WinMove(winID,, mon.position[winStora[winID].snapPos].y,, mon.box.h - xOffset)
				winStora[winID].half := 0
			}
		}
		else{
			if (winStora[winID].half = 0){
				WinMove(winID, (vDiv = 1 ? mon.position[winStora[winID].snapPos].x : mon.position[winStora[winID].snapPos].x + mon.box.w/2),, mon.workArea.w/2 - 2*xoffset)
				winStora[winID].half := 1
			}
			else{
				WinMove(winID, mon.position[winStora[winID].snapPos].x,, mon.box.w - 2*xOffset)
				winStora[winID].half := 0
			}
		}
	}
	return
}

InitMonitors(){
	monStora := Object() 			;Iniates the monStora as an object. When the function is called from OnMessage, it empties monStora. MonStora is the storage of all known monitors
	SysGet, m, MonitorCount 
	; Iterate through all monitors. 
	Loop, %m% 
	{
		mon:= new monitorInfo(A_Index)
		monStora[mon.name]:=mon
	}
	for winID in winStora{
		if (winStora[winID].snapped=1){
			SetRestoreWindowPlacement(winID)
			; WinMaximize, ahk_id %winID%
		}
	}
	return
}

miniMaxi(dir, winMinimized:=false){
    if (winMinimized){
    	WinRestore, ahk_id %winMinimized%
        return
    }
	WinGet, winID, id, A
	if (!winStora[winID] || winStora[winID].snapped = 0){
		if dir = 1
			Send, #+{Up}
		else 
			Send, #+{Down}
	}
	else if (dir = 1) {
		winMaximize ahk_id %winID%
		SetRestoreWindowPlacement(winID)
		winStora[winID].snapped:=0
	}
	else {
		WinMinimize, ahk_id %winID%
		SetRestoreWindowPlacement(winID)
		winStora[winID].snapped:=0
		return winID
	}
	return
}

NumGetInc(ByRef VarOrAddress, ByRef Offset, Type)
{
	value := NumGet(VarOrAddress, Offset, Type)
	Offset := Offset + SizeOf[Type]
	return value
}

NumPutInc(Number, ByRef VarOrAddress, ByRef Offset, Type)
{
	NumPut(Number, VarOrAddress, Offset, Type)
	Offset := Offset + SizeOf[Type]
}

restoreAll(){
	SetBatchLines, -1
	SetWinDelay, -1
	SetControlDelay, -1
	listlines off
	for key, win in winStora{
		if (win.snapped = 1)
			SetRestoreWindowPlacement(win.id)
			WinMove, % "ahk_id" win.id, , winStora[winID].restorePos.x, winStora[winID].restorePos.y, winStora[winID].restorePos.r + winStora[winID].restorePos.x, winStora[winID].restorePos.b + winStora[winID].restorePos.y
	}
	return
}

SetRestoreWindowPlacement(winID){
	GetWindowPlacement(winID, wp) 		;wp has to be initiated with all its current values before getting injected inside SetWindowPlacement
	wp.rcNormalPosition.left   := winStora[winID].restorePos.x
	wp.rcNormalPosition.top    := winStora[winID].restorePos.y
	wp.rcNormalPosition.right  := winStora[winID].restorePos.r
	wp.rcNormalPosition.bottom := winStora[winID].restorePos.b
	SetWindowPlacement(winID, wp)
	return
}

SetWindowPlacement(hwnd, ByRef lpwndpl)
{
	ListLines, off
	VarSetCapacity(_lpwndpl, 44)
	runningOffset := 0
	NumPutInc(lpwndpl.length , _lpwndpl, runningOffset, "UInt")
	NumPutInc(lpwndpl.flags  , _lpwndpl, runningOffset, "UInt")
	NumPutInc(lpwndpl.showCmd, _lpwndpl, runningOffset, "UInt")
	NumPutInc(lpwndpl.ptMinPosition.x, _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.ptMinPosition.y, _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.ptMaxPosition.x, _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.ptMaxPosition.y, _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.rcNormalPosition.left  , _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.rcNormalPosition.top   , _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.rcNormalPosition.right , _lpwndpl, runningOffset, "Int")
	NumPutInc(lpwndpl.rcNormalPosition.bottom, _lpwndpl, runningOffset, "Int")
	result := DllCall("SetWindowPlacement", Ptr, hwnd, Ptr, &_lpwndpl)
	ListLines, on
	return result
}

SettingsApply(){
	IniRead, runOnStartUp, %ApplicationName%.ini, Settings, runOnStartUp
	if (runOnStartUp){
		IfNotExist, % A_Startup "\" ApplicationName ".lnk"
			FileCreateShortcut, % A_ScriptFullPath, % A_Startup "\" ApplicationName ".lnk", % A_ScriptDir, -skipIntro, % ApplicationDescription
	}
	Else
		FileDelete, % A_Startup "\" ApplicationName ".lnk"
	
	IniRead, noTrayIcon, %ApplicationName%.ini, Settings, noTrayIcon
	if (notrayIcon)
		Menu, Tray, NoIcon
	Else
		Menu, Tray, Icon
	
	return
}

SettingsWrite(runOnStartUp, noTrayIcon, div, EnableShortcutKeys){
	IniWrite, %div%, %ApplicationName%.ini, Settings, defaultDivider
	IniWrite, %EnableHoldkey%, %ApplicationName%.ini, Settings, EnableHoldKey
	IniWrite, %holdkey%, %ApplicationName%.ini, Settings, HoldKey
	IniWrite, %EnableShortcutKeys%, %ApplicationName%.ini, Settings, EnableShortcutKeys
	IniWrite, %runOnStartUp%, %ApplicationName%.ini, Settings, runOnStartUp
	IniWrite, %noTrayIcon%, %ApplicationName%.ini, Settings, noTrayIcon
}


SnapWindow(dir, mul, winMinimized:=false){		
    if (winMinimized){
    	WinRestore, ahk_id %winMinimized%
        return
    }

    WinGet, minMaxState, MinMax, A
	WinGet, winID, ID, A

	WinGet, Proc, ProcessName, ahk_id %winID%
	if (Proc = "explorer.exe"){
		WinGetClass, ExpClass, ahk_id %winID%
		if (ExpClass = "WorkerW" || ExpClass = "Shell_TrayWnd" || ExpClass = "NotifyIconOverflowWindow" || ExpClass = "Shell_SecondaryTrayWnd")
			return
	}

	monitorName:=GetMonitorFromWindow(winID)
	if !(monStora[monitorName]){
		monitorId:=GetMonitorID(monitorName)
		mon:= new monitorInfo(monitorId)
		monStora[mon.name]:=mon
	}
	else
		mon:= monStora[monitorName]

	if (!winStora[winID]){
		winStora[winID] := new window(winID)
	}

	if(mon.div = 2 && mon.Vertical = 0){
		winStora[winID].snapped := 0
		WinGetPos, x, , w, , ahk_id %winID%
		WinGetPosEx(winID, , , , , xOffset, yOffset)
		if (dir=1){
			if (monStora.count() != 1 && abs(w+2*xoffset - mon.workArea.w/2) < 4 && x - xoffset >(mon.workArea.w/2) - 4){ 		; if it looks like it is snapped by Windows
				WinRestore, ahk_id %winID%
				Send, #+{Right}
				sleep 10
				SnapWindow(-1, 0)
				return
			}
			Send, {LWin down}{Right}
		}
		else if (dir =-1){
			if (monStora.count() != 1 && abs(w+2*xoffset - mon.workArea.w/2)< 4 &&  x<=mon.workArea.l){
				WinRestore, ahk_id %winID%
				Send, #+{Left}
				sleep 10
				SnapWindow(1, 0)
				return
			}
			Send, {LWin down}{Left}
		}
		else if (mul=1)
			Send, #{Up}
		else if (mul=-1){
			Send, #{Down}
			return winID
		}
		return
	}

	If (minMaxState=1){
		GetWindowPlacement(winID, wp)		; gives us the positions of the restored window, which we will store if the window is not snapped
		if(winStora[winID].snapped = 0)
			winStora[winID].restorePos := new SizePosition(wp.rcNormalPosition.left, wp.rcNormalPosition.top,,, wp.rcNormalPosition.right, wp.rcNormalPosition.bottom)
		if (dir){
			newPos := dir=1 ? mon.div : 1
			newWidth := 1

			wp.rcNormalPosition.left   := mon.position[newPos].x
			wp.rcNormalPosition.top    := mon.position[newPos].y
			wp.rcNormalPosition.right  := mon.box.w
			wp.rcNormalPosition.bottom := mon.box.h
			SetWindowPlacement(winID, wp) ; no flicker between restore and move
			
			WinRestore, ahk_id %winID%

		}
		else if (mul){
			if(winStora[winID].mon=monitorName && winStora[winID].snapped = 1){
				SetRestoreWindowPlacement(winID) ; no flicker between restore and move
			}
			WinRestore, ahk_id %winID%
			winStora[winID].snapped:=0
			return			
		}
	}
	else If (winStora[winID].snapped = 1){
		if (dir){
			if(winStora[winID].snapPos=1){
				if (dir=-1){
					if(winStora[winID].snapWidth=1){
						if (monStora.count()=1){		;if there's only one monitor
							newPos:=mon.div
						}
						else{

							SetRestoreWindowPlacement(winID)
							WinRestore, ahk_id %winID%
							winStora[winID].snapped:=0
							Send, #+{Left}
							; sleep 10
							; if (winStora[winID].mon = GetMonitorFromWindow(winID)){
							; 	Send, #+{Left}
							; 	Send, #+{Left}
							; 	sleep 10
							; }
									 				; with my weird monitor setup (5:4 and 16:9), sometimes the window restores in the wrong monitor
							; SnapWindow(1, 0) 		; the programs must work for everybody so this feature is out
							return
						}
					}
					else 
						NewWidth:=winStora[winID].snapWidth-1
				}
				else{
					NewPos:= winStora[winID].snapPos + dir
				}
			}
			else if(winStora[winID].snapPos = mon.div){
				if (dir=1){
					if (monStora.count()=1){
						newPos:=1
					}
					else{
						SetRestoreWindowPlacement(winID)
						WinRestore, ahk_id %winID%
						winStora[winID].snapped:=0
						Send, #+{Right}
						; sleep 10
						; SnapWindow(-1, 0)
						return
					}
				}
				else{
					NewPos := winStora[winID].snapPos + dir
				}
			}
			else{
				if(winStora[winID].snapPos + winStora[winID].snapWidth = mon.div+1 && dir=1){
					NewPos:= winStora[winID].snapPos + dir
					newWidth:= winStora[winID].snapWidth - 1
				}
				Else
					NewPos:= winStora[winID].snapPos + dir
			}
		}
		else if (mul){
			if (mul=+1){
				if ((winStora[winID].snapWidth=mon.div -1 && winStora[winID].half = 0) || (winStora[winID].half = 1 && winStora[winID].snapWidth=mon.div)){
					WinMaximize, ahk_id %winID%
					SetRestoreWindowPlacement(winID) 
					winStora[winID].snapped:=0
					return
				}
				if (winStora[winID].snapPos+winStora[winID].snapWidth = mon.div+1){
					newWidth := winStora[winID].snapWidth + 1
					newPos := winStora[winID].snapPos - 1
				}
				else
					newWidth := winStora[winID].snapWidth + 1
			}
			if (mul=-1){
				if(winStora[winID].snapWidth=1){
            		WinMinimize, A
					SetRestoreWindowPlacement(winID)
					winStora[winID].snapped:=0
            		return winID
				}
				Else
					newWidth := winStora[winID].snapWidth - 1
			}
		}
	}
	Else{
		if !(mon.div = 2){
			WinGetPos, x, y, w, h, ahk_id %winID%
			winStora[winID].restorePos:= new SizePosition(x, y,,, w+x, h+y)
		}
		if(dir){
			if(dir=1){
				newPos:=mon.div
			}
			else if (dir=-1)
				newPos:=1
			newWidth:=1
		}
		else if (mul){
			if (mul=1){
				WinMaximize, ahk_id %winID%
				return
			}
			else if (mul=-1){
        		WinMinimize, A
        		return winID
			}
		}
	}
	newPos:= newPos ? newPos : winStora[winID].snapPos
	newWidth:= NewWidth  ? NewWidth : ( winStora[winID].snapWidth ? winStora[winID].snapWidth : 1 )
	newHeight := 1
	if (mon.vertical){
		newHeight := newWidth
		newWidth := 1
	}
	if (winStora[winID].half = 1){
		if (winStora[winID].snapped=1){
			if (mon.vertical)
				NewWidth := 1/2
			else
				NewHeight := 1/2
		}
		else 
			winStora[winID].half := 0
	}

	WinGetPosEx(winID, , , , , xOffset, yOffset)
	WinMove(winID, mon.position[newPos].x +xOffset, mon.position[newPos].y, newWidth*mon.box.w-2*xoffset, newHeight*mon.box.h -xOffset)
	winStora[winID].snapped:=1
	winStora[winID].snapPos:=newPos
	winStora[winID].snapWidth:= mon.vertical ? newHeight : newWidth
	winStora[winID].mon:= monitorName
	return
}

UpdateSpacing(newDiv){
	WinActivate
	WinGet, winID, ID, A
	CoordMode Mouse, Screen
	MouseGetPos, x, y
	
	if (A_ThisHotkey = "#RButton"){
		monitorName:=GetMonitorFromPoint(x, y)
	}
	else if (A_ThisHotkey = "#PgDn"|| A_ThisHotkey = "#PgUp"){
		WinGet, Proc, ProcessName, ahk_id %winID%
		if (Proc = "explorer.exe"){
			WinGetClass, ExpClass, ahk_id %winID%
			if (ExpClass = "WorkerW" || ExpClass = "Shell_TrayWnd" || ExpClass = "NotifyIconOverflowWindow" || ExpClass = "Shell_SecondaryTrayWnd")
				monitorName:=GetMonitorFromPoint(x, y)
			else
				monitorName:=GetMonitorFromWindow(winID)
		}
		else 
			monitorName:=GetMonitorFromWindow(winID)
	}
	else{ 		;activated from the menu
		WinGet, listID, List 	;from topmost to bottommost
		loop %listID%{ 			;a loop is necessary to make more zones on secondary monitors according to the last activated window excluding some explorer.exe
			winID := listID%A_Index%
			WinGet, Proc, ProcessName, ahk_id %winID%
			if (Proc = "explorer.exe"){
				WinGetClass, ExpClass, ahk_id %winID%
				if !(ExpClass = "WorkerW" || ExpClass = "Shell_TrayWnd" || ExpClass = "NotifyIconOverflowWindow" || ExpClass = "Shell_SecondaryTrayWnd"){
					monitorName:=GetMonitorFromWindow(winID)
					break
				}
			}
			Else{
				monitorName:=GetMonitorFromWindow(winID)
				break
			}

		}
	}

	WinGetPosEx(winID, , , , , xOffset, yOffset)
	if !(monStora[monitorName]){
		monitorId:=GetMonitorID(MonitorName)
		mon:= new monitorInfo(monitorId)
		monStora[mon.name]:=mon
	}
	else
		mon:= monStora[monitorName]
	
	mon.div := mon.div + newDiv
	
	if (mon.div < 2){
		mon.div := 2
		GuiSections(mon,,"d9d9d9")
		return
	}

	; mon.box := new SizePosition(,,floor(mon.workarea.w/mon.div), mon.WorkArea.h)
	; mon.position := mon.Getpositions(mon.box, mon.div ,mon.workarea)
	mon.box := mon.vertical = 1 ? new SizePosition(,,mon.workarea.w, floor(mon.workarea.h/mon.div)) : new SizePosition(,,floor(mon.workarea.w/mon.div), mon.WorkArea.h)
	mon.position := mon.Getpositions(mon.box, mon.div ,mon.workarea, mon.vertical)

	; prevDiv := mon.div - newDiv
	; for key, win in winStora{
	; 	if (win.mon = monitorName && win.snapped = 1){
	; 		; if((win.snapPos+1)/mon.div - win.snapPos/prevDiv > win.snapPos/prevDiv - win.snapPos/mon.div)
	; 		win.snapPos := (win.snapPos+1)/mon.div - win.snapPos/prevDiv <= win.snapPos/prevDiv - win.snapPos/mon.div ? win.snapPos+1 : win.snapPos
	; 		win.snapWidth := (win.snapWidth+1)/mon.div - win.snapPWidthprevDiv <= win.snapWidth/prevDiv - win.snapWidth/mon.div ? win.snapWidth+1 : win.snapWidth
	; 		win.snapWidth := (win.snapPos + win.snapWidth) > mon.div+1 ? win.snapWidth-1 : win.snapWidth
	; 		WinMove(win.id, mon.position[win.snapPos].x +xOffset, mon.position[win.snapPos].y, win.snapWidth*mon.box.w-2*xoffset, mon.box.h -xOffset)
 ; 		}
	; }

	if(winStora[winID] && winStora[winID].snapped = 1 && winStora[winID].snapWidth=1 && monitorName = winStora[winID].mon){
		width := mon.box.w - 2*xoffset
		if(winStora[winID].snapPos = 1){
			WinMove(winID,,, width)
		}
		else if (winStora[winID].snapPos = mon.div - newDiv){
			WinMove(winID,mon.position[mon.div].x +xOffset,, width)
			winStora[winID].snapPos:=mon.div
		}
	}
	monStora[mon.name]:=mon
	GUIDestroy()		;To make sure that if the mouse moves from one monitor to another while the win key is down, no lines will stay on the previous monitor
	GUISections(mon,,"d9d9d9")
	WinActivate, ahk_id %winID%
	ToolTip, % mon.div
    SetTimer, RemoveToolTip, 1500
    SetTimer, RemoveGUI, 1500
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return

    RemoveGUI:
    If !(GetKeyState("RWin") || GetKeyState("LWin")){
	    SetTimer, RemoveGUI, Off
	    GUIDestroy()
	}
    return
}

WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime){			; wait for the window to change size/pos
	if (hwnd){
		WinGet, winID, ID, A
		leftMouseButtonState := GetKeyState("LButton", "P") 		; Tried to differentiate events 0xA and 0XB with A_EventInfo and the var "event" but there always were bugs, this is more reliable
		; leftMouseButtonState := A_EventInfo 		; finally, it works
		if(EnableHoldKey){
			holdKeyState := GetKeyState(holdKey)
		}

		CoordMode Mouse, Screen
		MouseGetPos, mouseAbsPosX, mouseAbsPosY
		SendMessage 0x84,, ( mouseAbsPosY << 16 )|mouseAbsPosX & 0xFFFF,, A 		; 0x84 is WM_NCHITTEST, it determines what part of the window corresponds to a particular screen coordinate through ErrorLevel
		HitTest:=ErrorLevel 											; ErrorLevel will update through other functions so we need to store the result of the line above

		if (leftMouseButtonState = 0) {
			mon:=monStora[GetMonitorFromPoint(mouseAbsPosX, mouseAbsPosY)]
			if (mon.vertical = 1)
				return
		}
		if (leftMouseButtonState = 1){
			if (HitTest < 10 || HitTest > 17){		;if HitTest (errorlevel) belongs to [10; 17], the user is resizing the window
				if (!winStora[winID]){
						winStora[winID] := new window(winID)
						GetWindowPlacement(winID, wp)
						winStora[winID].restorePos := new SizePosition(wp.rcNormalPosition.left, wp.rcNormalPosition.top,,, wp.rcNormalPosition.right, wp.rcNormalPosition.bottom)
				}
				else if (winStora[winID].snapped = 1){				;this function serve to "restore" the window when the user is moving it from a snapped position
					; BlockInput, MouseMove ; user can move mouse faster than we can move window, so clicking later may miss the title bar
					; SetWinDelay, 0 						; i don't like this method with unclicking and clicking. I tried different methods to the window but the original dev of this function is right : see "click up" line
					; SetMouseDelay, 0
					; winStora[winID].snapped := 0
					; WinActivate, ahk_id %winID%
					; Click, up ; can't move (resize) window ourselves until the system thinks the user is done
					; WinActivate, ahk_id %winID%
					; CoordMode, Mouse, Window
					; MouseGetPos, mouseRelPosX, mouseRelPosY
					; WinGetPos, , , currentWidth, , % "ahk_id " winID
													
					; ; ; "restore" width and height from snapped state, set left and top relative to where title bar was grabbed
					; WinMove, % "ahk_id " winID, , mouseAbsPosX - (mouseRelPosX / currentWidth) * winStora[winID].restorePos.w
					; 												, mouseAbsPosY - mouseRelPosY 
					; 												, winStora[winID].restorePos.w
					; 												, winStora[winID].restorePos.h

					; Click, down ; grab title bar
					; WinActivate, ahk_id %winID%
					; BlockInput, MouseMoveOff
					SetWinDelay, 0 	
					SetMouseDelay, 0
					winStora[winID].snapped := 0
					Click, up ; can't move (resize) window ourselves until the system thinks the user is done
					CoordMode, Mouse, Window
					MouseGetPos, mouseRelPosX, mouseRelPosY
					CoordMode Mouse, Screen
					WinGetPos, , , currentWidth, , % "ahk_id " winID
					listlines off
					while GetKeyState("LButton", "P"){ 			; imitation of a window moving until the user release the Lbutton
						MouseGetPos, mouseAbsPosX, mouseAbsPosY
						WinMove, % "ahk_id " winID, , mouseAbsPosX - (mouseRelPosX / currentWidth) * winStora[winID].restorePos.w
																	, mouseAbsPosY - mouseRelPosY 
																	, winStora[winID].restorePos.w
																	, winStora[winID].restorePos.h
					}
					listlines On
					for key, mon in monStora{		; imitation of common snapping gestures
						if (MouseAbsPosY = mon.workArea.t){
							WinMaximize, ahk_id %winID%
							SetRestoreWindowPlacement(winID)
						}
						else if (MouseAbsPosX = mon.workArea.l){
							SetRestoreWindowPlacement(winID)
							Send, #{Left}
						}
						else if (MouseAbsPosX = mon.workArea.r-1){
							SetRestoreWindowPlacement(winID)
							Send, #{Right}
						}
					}
				}
				if(holdKeyState = 1 && monStora[GetMonitorFromPoint(mouseAbsPosX, mouseAbsPosY)].vertical = 0)	;else
					GUIWindow(winID)		; the the grid to position the window
			}
			else if (winStora[winID].snapped = 1 && holdKeyState = 1 && monStora[GetMonitorFromPoint(mouseAbsPosX, mouseAbsPosY)].vertical = 0){
				if (HitTest = 10 || HitTest = 11) 	; left or right side
					GuiSections(monStora[winStora[winID].mon])	; show the sections to resize the window
				else if (HitTest = 12 || HitTest = 15){ ; 12 = top edge, 15 = bottom edge
					mon:=monstora[winStora[winID].mon]
					Gui, Section1: +ToolWindow -Caption -DPIScale +AlwaysOnTop
					Gui, Section1: Color, B00B13
					Gui, Section1: Show, % "x" mon.position[winStora[winID].snapPos].x "y" mon.position[winStora[winID].snapPos].y + mon.box.h/2 "w" winStora[winID].snapWidth * mon.box.w "h" 5 "NA" ; NoActivate
				}
			}
		}
		else if (leftMouseButtonState = 0 && holdKeyState = 1){
			if (HitTest < 10 || HitTest > 17){				; Positioning/Snapping the window after holding down shift and Lbutton
				winStora[winID].snapped := 1
				GetWindowPlacement(winID, wp)		; gives us the positions of the restored window, which we will store if the window is not snapped
				winStora[winID].restorePos := new SizePosition(wp.rcNormalPosition.left, wp.rcNormalPosition.top,,, wp.rcNormalPosition.right, wp.rcNormalPosition.bottom)
				; mon:=monStora[GetMonitorFromPoint(mouseAbsPosX, mouseAbsPosY)]
				loop % mon.div {
					if(mouseAbsPosX > mon.position[A_index].x && mouseAbsPosX < (A_index = mon.div ? mon.WorkArea.r : mon.position[A_index+1].x)){
						if (A_index != 1 && mouseAbsPosX - mon.position[A_index].x < 30){
							newPos := A_index-1
							NewWidth := 2
						}
						else if (A_index != mon.div && mon.position[A_index+1].x - mouseAbsPosX < 30){
							newPos := A_index
							NewWidth := 2
						}
						else {
							if (mouseAbsPosY - mon.position[A_index].y < 75 && A_index != 1 && A_index != mon.div){
								newPos := A_index-1
								NewWidth := 3
							}
							else{
								newPos := A_index
								NewWidth := 1
							}
						}
						if (NewWidth=mon.div){
							WinMaximize, ahk_id %winID%
							SetRestoreWindowPlacement(winID) 
							winStora[winID].snapped:=0
							return
						}
						WinGetPosEx(winID, , , , , xOffset, yOffset)
						WinMove(winID,mon.position[NewPos].x +xOffset, mon.position[NewPos].y, NewWidth * mon.box.w-2*xoffset, mon.box.h -xOffset)
						winStora[winID].snapped := 1
						winStora[winID].snapPos := NewPos
						winStora[winID].snapWidth := NewWidth
						AeroSnap()
						return
											
					}
				}
			}
			else if(winStora[winID].snapped = 1){	; if the user resizes on the left or right side attempts to snap it with a different width
				if (HitTest = 10 || HitTest = 11 ){
					mon:=monStora[winStora[winID].mon]
					loop % mon.div{
						if(mouseAbsPosX > mon.position[A_index].x && mouseAbsPosX < (A_index = mon.div ? mon.WorkArea.r : mon.position[A_index+1].x)){
							if (mouseAbsPosX - mon.position[A_index].x < mon.box.w/4){
								if(HitTest=11){		;if the user resizes on the left side
									NewPos := winStora[winID].snapPos
									NewWidth := A_index - winStora[winID].snapPos
								}
								else{				;right side
									NewPos := A_index
									NewWidth := winStora[winID].snapWidth + winStora[winID].snapPos - NewPos
								}
							}
							else if (mon.position[A_index+1].x ? mon.position[A_index+1].x - mouseAbsPosX < mon.box.w/4 : mon.workArea.r - mouseAbsPosX < mon.box.w/4){
								if(HitTest=11){		;if the user resizes on the left side
									NewPos := winStora[winID].snapPos
									NewWidth := A_index +1 - winStora[winID].snapPos
								}
								else{
									NewPos := A_index +1
									NewWidth := winStora[winID].snapWidth + winStora[winID].snapPos - NewPos
								}
							}
							else{
								NewPos := winStora[winID].snapPos
								NewWidth := winStora[winID].snapWidth
							}
							if (NewWidth=mon.div){
								WinMaximize, ahk_id %winID%
								SetRestoreWindowPlacement(winID) 
								winStora[winID].snapped:=0
								return
							}
							WinGetPosEx(winID, , , , , xOffset, yOffset)
							WinMove(winID,mon.position[NewPos].x +xOffset, , NewWidth * mon.box.w-2*xoffset)
							winStora[winID].snapPos := NewPos
							winStora[winID].snapWidth := NewWidth
							return
						}
					}
				}
				else if (HitTest = 12 || HitTest = 15){ 		; 12 = top edge, 15 = bottom edge
					mon:=monStora[winStora[winID].mon]
					WinGetPosEx(winID, , , , , xOffset, yOffset)
					if (mouseAbsPosY - mon.workArea.y < 75){
						if (HitTest = 12)
							WinMove(winID,, mon.workArea.y, , mon.box.h - xoffset)
						; else if (HitTest = 15)
					}
					else if (abs(MouseAbsPosY - (mon.workArea.y + mon.box.h/2)) < 75){
						if (HitTest = 12)
							WinMove(winID,, mon.workArea.y + mon.box.h/2, , mon.box.h/2 - xoffset)
						else if (HitTest = 15)
							WinMove(winID,, mon.workArea.y, , mon.box.h/2 - xoffset)
					}
					else if (abs(MouseAbsPosY - (mon.workArea.y + mon.box.h)) < 75){
						; if (HitTest = 12)
						if (HitTest = 15)
							WinMove(winID,, mon.workArea.y, , mon.box.h - xoffset)
					}
				}
			}
		}
		if (winStora[winID].snapped = 1 && leftMouseButtonState = 0 && (HitTest >= 10 || HitTest <= 17)){				; is the window after size modification is still considered as snapped ?
			WinGetPos, x, y, w, h, ahk_id %winID%
			WinGetPosEx(winID, , , , , xOffset, yOffset)
			NotSnapped := 0
			
			if (abs(x-xOffset - mon.position[winStora[winID].snapPos].x) > 4)
				NotSnapped++
			if(winStora[winID].snapPos + winStora[winID].snapWidth <= mon.div){
				if (abs(w+x+xOffset - mon.position[winStora[winID].snapPos+winStora[winID].snapWidth].x) > 4)
					NotSnapped++
			}
			else{
				if (abs(w+x+xOffset - mon.workArea.r) > 4)
					NotSnapped++		
			}

			if (abs(y - mon.position[winStora[winID].snapPos].y) > 4 ){
				if (abs(y - (mon.position[winStora[winID].snapPos].y + mon.box.h/2)) > 4)
					NotSnapped++
			}
			if (abs(h + xoffset - mon.box.h) > 4){
				if (abs(h + xoffset - mon.box.h/2) > 4)
					NotSnapped++
			}
			if (NotSnapped >= 2){ 					; if 2 sides or more of the window are not at their snapped position
				winStora[winID].snapped := 0
				return
			}
		}
	}
	return
}

WinGetsMaxOrClosed(){
	CoordMode Mouse, Screen
	MouseGetPos, mouseAbsPosX, mouseAbsPosY, winID
	if (winStora[winID]){
		if (A_ThisHotkey = "!F4")
			HitTest := 20
		else {
			SendMessage 0x84,, ( mouseAbsPosY << 16 )|mouseAbsPosX & 0xFFFF,, ahk_id %winID%
			HitTest:=ErrorLevel
		}
		if (HitTest = 9 && winStora[winID].snapped= 1){ 		; if the window is maximized via the maximize button, restore the non-snapped position
			winStora[winID].snapped:=0
			WinGet, MinMaxBefore, MinMax, ahk_id %winID%
			timestamp:=0
			loop { 					; wait for the window to be properly maximized
				sleep 10
				WinGet, MinMaxNow, MinMax, ahk_id %winID%
				timestamp+=10
			} until (minmaxbefore != minmaxnow || timestamp >=1000)
			sleep 10
			SetRestoreWindowPlacement(winID)
		}
		else if (HitTest = 20){ 			;  if the user closes the window
			if (winStora[winID].snapped= 1){
				winGet, process, ProcessName, ahk_id %winID%
				WinGet listID, Count,ahk_exe %Process%
				if (listID = 1){
					SetRestoreWindowPlacement(winID)	
					WinClose ahk_id %winID%
				}
			}
			else if (A_thisHotkey = "!F4")
				WinClose ahk_id %winID%
			sleep 100
			IfWinNotExist, ahk_id %winID% 
			{
				winStora.delete(winID)
			}
		}
	}
	if (A_thisHotkey = "!F4")
		WinClose ahk_id %winID%
	Return
}

WinGetsMinimized(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime){
	if (hwnd){
		WinGet, winID, ID, A
		if (winStora[winID].snapped = 1){
			SetRestoreWindowPlacement(hwnd)
			winStora[winID].snapped:=0
		}
	}
	return
}

WinMove(winID, x:="n/a", y:="n/a", w:="n/a", h:="n/a"){ 		; WinMove provided by autohotkey does not provide options like 0x01, 0x02 and 0x08
	WinGetPos, x1, y1, w1, h1, ahk_id %winID% 					; which allow windows to be placed correcly independently of DPI especially when a window is
	x:= x!="n/a" ? x : x1 										; on the far right of a screen with another screen on the right.
	y:= y!="n/a" ? y : y1 										; The offsets will cause the down right corner of the window to be placed according to the adjacent screen and width and height could be malformed
	w:= w!="n/a" ? w : w1
	h:= h!="n/a" ? h : h1

	dllcall("SetWindowPos", Ptr, winID, Int, 0, int, x, int, y, int, w, int,  h, Uint, 0x0009) ; 0x0001 SWP_NOSIZE keeps the current size ; 0x0008 SWP_NOREDRAW does not redraw changes
	dllcall("SetWindowPos", Ptr, winID, Int, 0, int, x, int, y, int, w, int,  h, Uint, 0x0002) ; 0x0002 SWP_NOMOVE retains the current position

	mon:=monStora[GetMonitorFromWindow(winID)]
	if (x < mon.workArea.l){									; in mon case, windows sets the y position based on the other monitor (and thus other DPI) causing malformation
		AdjacentMonitorName := GetMonitorFromPoint(x, y)
		if (AdjacentMonitorName != mon.name){
			AdjDPIFactor := monstora[AdjacentMonitorName].dpiFactor
			dllcall("SetWindowPos", Ptr, winID, Int, 0, int, x, int, y * mon.dpiFactor/AdjDPIFactor, int, w, int,  h, Uint, 0x0001 | 0x0008)
			dllcall("SetWindowPos", Ptr, winID, Int, 0, int, x, int, y * mon.dpiFactor/AdjDPIFactor, int, w, int,  h, Uint, 0x0002)
		}
	}
	return
}