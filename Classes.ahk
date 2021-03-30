
Class monitorInfo
{
	__New(monitorId)
	{
		; ListLines, off
		this.id := monitorId
		
		SysGet, name, MonitorName, % monitorId
		this.name := name

		SysGet, monArea, Monitor, % monitorId
		this.vertical := (monAreaRight - monAreaLeft)/(monAreaBottom-monAreaTop)<1 ? 1 : 0
		; this.area := new SizePosition(monAreaLeft, monAreaTop, , , monAreaRight, monAreaBottom)
		
		SysGet, monWorkArea, MonitorWorkArea, % monitorId
		this.workarea := new SizePosition(monWorkAreaLeft, monWorkAreaTop, , , monWorkAreaRight, monWorkAreaBottom, monWorkAreaLeft - monAreaLeft, monWorkAreaTop - monAreaTop)

		this.dpiFactor := GetDPIfromMonitorName(this.name)
		
		if !this.div
			this.div := this.GetDiv(monitorId, this.dpiFactor)
		
		this.box := this.vertical = 1 ? new SizePosition(,,this.workarea.w, floor(this.workarea.h/this.div)) : new SizePosition(,,floor(this.workarea.w/this.div), this.WorkArea.h)
		this.position := this.Getpositions(this.box, this.div ,this.workarea, this.vertical)

		this.dpiFactor := GetDPIfromMonitorName(this.name)
		; ListLines, on
		; msgbox, % "vertical" this.vertical "\n" this.box.w " " this.box.h "\n" this.position[1].x " " this.position[1].y
	}

	GetDiv(monitorId, dpiFactor){
		IniRead, DefaultDiv, %ApplicationName%.ini, Settings, DefaultDivider,3
		
		SysGet, monArea, Monitor, % monitorId

		IniRead, DefaultDiv, %ApplicationName%.ini, ResolutionSpecificDivider, % round((monAreaRight - monAreaLeft)*dpiFactor) . "x" . round((monAreaBottom-monAreaTop)*dpiFactor) , % DefaultDiv
		return DefaultDiv
	}

	Getpositions(box, div, workarea, vertical){
		position:=array()
		if vertical {
			Loop, %div%{
				position.push(new SizePosition(workarea.x, workarea.y+ (A_Index-1)*box.h))
			}
		}
		else {
			Loop, %div%{
				position.push(new SizePosition(workarea.x + (A_Index-1)*box.w, workarea.y))
			}
		}
		return position
	}
}

class window
{
	__New(winID)
	{
		this.id:= winID

		this.snapped := 0
		this.snapPos := 0
		this.snapWidth := 0

		this.restorePos := new SizePosition(0, 0, 0, 0)

		this.mon:= GetMonitorFromWindow(winID)

		this.half := 0

	}
}

class SizePosition
{
	__New(x="?", y="?", w="?", h="?", r="?", b="?", xo="?", yo="?")
	{
		this.x := x != "?" ? x : 0
		this.l := x != "?" ? x : 0
		this.y := y != "?" ? y : 0
		this.t := y != "?" ? y : 0
		this.w := w != "?" ? w : r != "?" ? r - x : 0
		this.h := h != "?" ? h : b != "?" ? b - y : 0
		this.r := r != "?" ? r : w != "?" ? x + w : 0
		this.b := b != "?" ? b : h != "?" ? y + h : 0
	}
}

class WINDOWPLACEMENT
{
	; UINT, UINT, UINT, POINT, POINT, RECT
	__New(length, flags, showCmd, ptMinPosition, ptMaxPosition, rcNormalPosition)
	{
		this.length := length
		this.flags := flags
		this.showCmd := showCmd
		this.ptMinPosition := ptMinPosition
		this.ptMaxPosition := ptMaxPosition
		this.rcNormalPosition := rcNormalPosition
	}
}

class tagPOINT
{
	; LONG, LONG
	__New(x, y)
	{
		this.x := x
		this.y := y
	}
}

class _RECT
{
	; LONG, LONG, LONG, LONG
	__New(left, top, right, bottom)
	{
		this.left := left
		this.top := top
		this.right := right
		this.bottom := bottom
	}
}

class SizeOf
{
	static UInt         := 32 // 8
	static Int          := 32 // 8
	static Long         := SizeOf.Int
	static Point        := SizeOf.Long * 2
	static Rect         := SizeOf.Long * 4
	static Short        := 16 // 8
	static Variant_Bool := SizeOf.Short
}
