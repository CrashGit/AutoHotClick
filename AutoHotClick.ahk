#Requires AutoHotkey v2.0
#SingleInstance


AC := AutoClicker()

$F1::AC.Toggle()
$F3::AC.ToggleGUI()


class AutoClicker extends Gui {
    Timeout_Click := ObjBindMethod(this, 'Toggle')
    on := false

    static __New() {
        CoordMode('Mouse', 'Screen')
    }

    __New() {
        super.__New('-MinimizeBox', 'AutoClicker', this)
        this.SetFont(, 'Segoe UI')

        /**
         * @click_repeat
         */
        this.SetFont('s12 bold')
        this.AddGroupBox('xm w368 h140 vclick_repeat', 'Click Repeat')

        this.SetFont('s12 norm')
        this.AddRadio('xp+30 yp+40 Checked vrepeat_method', 'Repeat').OnEvent('click', 'TimeoutSectionDisable')
        this.AddRadio('xp yp+30', 'Repeat until stopped').OnEvent('click', 'TimeoutSectionDisable')
        this.AddRadio('xp yp+30', 'Repeat for x time').OnEvent('click', 'TimeoutSectionEnable')

        this['repeat_method'].GetPos(, &y)
        this.AddEdit('x120 y' y-4 ' w110 Border Number Limit8 vrepeat_count')
        this.AddUpDown('Range1-10000000', 1)

        this['click_repeat'].GetPos(, &y)

        /**
         * @click_options
         */
        this.SetFont('s12 bold')
        this.AddGroupBox('x416 y' y ' w368 h140', 'Click Options')

        this.SetFont('s12 norm')
        this.AddText('x446 yp+40', 'Mouse Button:')
        this.AddDropDownList('xp+130 yp Choose1 vmouse_button', ['Left', 'Right', 'Middle'])

        this.AddText('x446 yp+50', 'Click Type:')
        this.AddDropDownList('xp+130 yp Choose1 vclick_type', ['Single', 'Double', 'Triple'])

        /**
         * @timeout
         */
        spacing := 120

        this.SetFont('s12 bold c6b6b6b')
        this.timeout_groupboxes := [this.AddGroupBox('xm w768 h100', 'Timeout')]

        this.SetFont('s10 bold')
        this.timeout_groupboxes.Push(
            this.AddGroupBox('xp+20          yp+25  w100 h60 Center', 'Hours'),
            this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center', 'Minutes'),
            this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center', 'Seconds'),
            this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center', 'Milliseconds')
        )

        this.SetFont('s12 norm cDefault')
        this.timeout_times := [
            this.AddEdit('x40            yp+24 w90 Disabled Border Center Number -WantReturn Limit3 vtimeout_hours',     0),
            this.AddEdit('xp+' spacing ' yp    w90 Disabled Border Center Number -WantReturn Limit3 vtimeout_minutes',   0),
            this.AddEdit('xp+' spacing ' yp    w90 Disabled Border Center Number -WantReturn Limit3 vtimeout_seconds',   0),
            this.AddEdit('xp+' spacing ' yp    w90 Disabled Border Center Number -WantReturn Limit3 vtimeout_ms',        100)
        ]

        this.SetFont('s11 italic c6b6b6b')
        this.AddText('x+15 yp+2 vtimeout_helper', '*Requires Repeat for x time enabled')

        /**
         * @click_interval
         */
        ; random offset
        this.SetFont('s12 norm bold cDefault')
        this.AddGroupBox('xm w768 h100', 'Click Interval')

        this.SetFont('s10 bold')
        this.AddGroupBox('xp+20          yp+25  w100 h60 Center',   'Hours')
        this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center',   'Minutes')
        this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center',   'Seconds')
        this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center',   'Milliseconds')
        this.AddGroupBox('xp+' spacing ' yp     wp   hp  Center',   'Offset')

        this.SetFont('s12 norm')
        this.AddEdit('x40            yp+24 w90  Center Number -WantReturn Limit3 vhours',           0)
        this.AddEdit('xp+' spacing ' yp    w90  Center Number -WantReturn Limit3 vminutes',         0)
        this.AddEdit('xp+' spacing ' yp    w90  Center Number -WantReturn Limit3 vseconds',         0)
        this.AddEdit('xp+' spacing ' yp    w90  Center Number -WantReturn Limit3 vms',              100)
        this.AddEdit('xp+' spacing ' yp    w90  Center Number -WantReturn Limit3 vrandom_offset',   0)

        this.SetFont('s10 italic c6b6b6b')
        this.AddText('x+40 yp-20 w100', '*Add a random offset variation`n+/- value')

        /**
         * @cursor_position
         */
        this.SetFont('s12 norm bold cDefault')
        this.AddGroupBox('xm w768 100', 'Cursor Position')

        this.SetFont('s12 norm')
        this.AddRadio('xp+30 yp+40 Checked vcursor_position', 'Current location').OnEvent('click', 'CursorCustomLocationDisable')
        this.AddRadio('x200 yp', 'Always track').OnEvent('click', 'CursorCustomLocationDisable')
        this.AddRadio('x330 yp', 'Custom location').OnEvent('click', 'CursorCustomLocationEnable')

        this.cursor_custom := [
            this.AddButton('x+0 yp-7 vpick_location', 'Pick location'),
            this.AddText('x+15 yp+7', 'X'),
            this.AddEdit('x+2 yp-4 w60 Right Border Center Number Limit5 vx_position', 0),
            this.AddText('x+10 yp+4', 'Y'),
            this.AddEdit('x+2 yp-4 w60 Right Border Center Number Limit5 vy_position', 0)
        ]

        this['pick_location'].OnEvent('Click', 'PickLocation')

        this.CursorCustomLocationDisable()

        /**
         * @buttons
         */
        this.SetFont('s12 bold')
        this.AddButton('xm+16 y+40 w334 h80 vstart', 'Start').OnEvent('click', 'Toggle')
        this.AddButton('x+64  w334 h80 vstop Disabled', 'Stop').OnEvent('click', 'Toggle')

        /**
         * @show
         */
        this.Show('w800 h580')
    }


    Toggle(ctrlObj?, *) {
        this.on ^= 1
        this['start'].Enabled := !this.on
        this['stop'].Enabled := this.on

        if not this.on {
            this.TurnOffTimer()
            return
        }

        ms      := this['ms'].Value
        seconds := this['seconds'].Value * 1000
        minutes := this['minutes'].Value * 60000
        hours   := this['hours'].Value   * 3600000
        this.interval := ms + seconds + minutes + hours

        info := this.Submit(false)

        this.mouse_button := this['mouse_button'].Text
        this.click_type   := this['click_type'].Value

        switch info.cursor_position {
            case 1: ; current location
                MouseGetPos(&x, &y)
                this.click := ObjBindMethod(this, 'ClickAtLocation', x, y)
            case 2: ; always track
                this.click := ObjBindMethod(this, 'AlwaysTrack')
            case 3: ; custom location
                this.click := ObjBindMethod(this, 'ClickAtLocation', this['x_position'].Value, this['y_position'].Value)
        }

        switch info.repeat_method {
            case 1:
                this.repeat_count := this['repeat_count'].Value
                this.AutoClick := ObjBindMethod(this, 'ClickRepeat')
            case 2:
                this.AutoClick := ObjBindMethod(this, 'ClickRepeatUntilStopped')
            case 3:
                ms      := this['timeout_ms'].Value
                seconds := this['timeout_seconds'].Value * 1000
                minutes := this['timeout_minutes'].Value * 60000
                hours   := this['timeout_hours'].Value   * 3600000
                timeout := ms + seconds + minutes + hours
                this.AutoClick := ObjBindMethod(this, 'ClickRepeatUntilTimeout')
                SetTimer(this.Timeout_Click, -timeout)
        }

        if IsSet(ctrlObj) {
            SetTimer(this.AutoClick, -this.interval)
        } else {
            this.AutoClick()
        }
    }

    TurnOffTimer() {
        SetTimer(this.AutoClick, 0)
        SetTimer(this.Timeout_Click, 0)
        this['start'].Enabled := true
        this['stop'].Enabled := false
    }

    ClickRepeat(*) {
        this.click()
        this.repeat_count--
        if this.repeat_count = 0 {
            this.on := false
            this.TurnOffTimer()
        }
    }

    ClickRepeatUntilStopped(*) {
        this.click()
    }

    ClickRepeatUntilTimeout(*) {
        this.click()
    }

    ClickAtLocation(x, y, *) {
        SetTimer(this.AutoClick, -this.interval)
        BlockInput('MouseMove')
        MouseGetPos(&x_start, &y_start)
        Click(x, y, this.mouse_button, this.click_type)
        MouseMove(x_start, y_start, 0)
        BlockInput('MouseMoveOff')
    }

    AlwaysTrack(*) {
        SetTimer(this.AutoClick, -this.interval)
        MouseGetPos(&x, &y)
        Click(x, y, this.mouse_button, this.click_type)
    }

    PickLocation(*) {
        keys := InputHook('V')
        keys.KeyOpt('{Esc}', 'E')
        WinSetEnabled(false, 'ahk_id ' this.Hwnd)
        SetTimer(DisplayPosition, 50)

        HotIf (*) => keys.InProgress
        Hotkey('$LButton', (*) => (keys.Stop()))
        HotIf

        keys.Start(), keys.Wait()

        if not keys.EndKey {
            MouseGetPos(&x, &y)
            this['x_position'].Value := x
            this['y_position'].Value := y
        }

        WinSetEnabled(true, 'ahk_id ' this.Hwnd)
        SetTimer(DisplayPosition, 0)
        ToolTip()

        DisplayPosition() {
            MouseGetPos(&x, &y),
            ToolTip('x: ' x '`ny: ' y)
        }
    }

    TimeoutSectionEnable(*) {
        for box in this.timeout_groupboxes {
            box.SetFont('c000000')
        }
        for time in this.timeout_times {
            time.Enabled := true
        }
        this['timeout_helper'].Visible := false
    }
    TimeoutSectionDisable(*) {
        for box in this.timeout_groupboxes {
            box.SetFont('c6b6b6b')
        }
        for time in this.timeout_times {
            time.Enabled := false
        }
        this['timeout_helper'].Visible := true
    }

    CursorCustomLocationEnable(*) {
        for ctrl in this.cursor_custom {
            ctrl.Enabled := true
        }
    }
    CursorCustomLocationDisable(*) {
        for ctrl in this.cursor_custom {
            ctrl.Enabled := false
        }
    }

    ToggleGUI() => (WinExist('ahk_id ' this.Hwnd) ? this.Hide() : this.Show())
}