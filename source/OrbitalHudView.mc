import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Math;

class OrbitalHudView extends WatchUi.WatchFace {

    // ── Cached layout values ──
    private var _w as Number = 260;
    private var _h as Number = 260;
    private var _cx as Number = 130;
    private var _cy as Number = 130;
    private var _isHighPower as Boolean = true;

    // ── Seconds clip region ──
    private var _ssX as Number = 0;
    private var _ssY as Number = 0;
    private var _ssW as Number = 0;
    private var _ssH as Number = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = _w / 2;
        _cy = _h / 2;

        // Pre-calculate seconds clip region (right of center time)
        _ssX = _cx + (_w * 0.18).toNumber();
        _ssY = _cy - (_h * 0.05).toNumber();
        _ssW = (_w * 0.15).toNumber();
        _ssH = (_h * 0.10).toNumber();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Fetch data
        DataManager.fetchBattery();
        DataManager.fetchSteps();
        DataManager.fetchHeartRate();
        DataManager.fetchStress();
        DataManager.fetchSpO2();

        // Tick cycling counter
        DataManager.tickCycle(_isHighPower);

        // Advance ECG animation in high power
        if (_isHighPower) {
            DataManager.ecgOffset = (DataManager.ecgOffset + 1) % 20;
        }

        // ── Draw all elements ──
        drawCornerBrackets(dc);
        drawDate(dc);
        drawBatteryArc(dc);
        drawStepsArc(dc);
        drawTime(dc);
        drawStepCount(dc);
        drawLeftStrip(dc);
        drawRightStrip(dc);
        drawAnnunciators(dc);
    }

    // ── onPartialUpdate: low-power seconds only ──
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        dc.setClip(_ssX, _ssY, _ssW, _ssH);
        // Clear clip region
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_ssX, _ssY, _ssW, _ssH);
        // Draw seconds
        var clockTime = System.getClockTime();
        var ss = clockTime.sec.format("%02d");
        dc.setColor(DataManager.getColor(DataManager.CLR_TEXT_SEC), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX + 2, _cy - (_h * 0.03).toNumber(), Graphics.FONT_TINY, ":" + ss, Graphics.TEXT_JUSTIFY_LEFT);
        dc.clearClip();
    }

    function onEnterSleep() as Void {
        _isHighPower = false;
    }

    function onExitSleep() as Void {
        _isHighPower = true;
        DataManager.tier2Counter = 0;
    }

    // ══════════════════════════════════════════
    //  DRAWING FUNCTIONS
    // ══════════════════════════════════════════

    // ── Corner Brackets ──
    private function drawCornerBrackets(dc as Graphics.Dc) as Void {
        var m = (_w * 0.06).toNumber();   // margin from edge
        var len = (_w * 0.10).toNumber(); // bracket arm length
        var color = DataManager.getColor(DataManager.CLR_DIM);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // Top-left
        dc.drawLine(m, m, m + len, m);
        dc.drawLine(m, m, m, m + len);
        // Top-right
        dc.drawLine(_w - m, m, _w - m - len, m);
        dc.drawLine(_w - m, m, _w - m, m + len);
        // Bottom-left
        dc.drawLine(m, _h - m, m + len, _h - m);
        dc.drawLine(m, _h - m, m, _h - m - len);
        // Bottom-right
        dc.drawLine(_w - m, _h - m, _w - m - len, _h - m);
        dc.drawLine(_w - m, _h - m, _w - m, _h - m - len);
    }

    // ── Time (center) ──
    private function drawTime(dc as Graphics.Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;

        // Respect 12/24h setting
        if (!System.getDeviceSettings().is24Hour) {
            if (hour == 0) { hour = 12; }
            else if (hour > 12) { hour = hour - 12; }
        }

        var hhmm = hour.format("%02d") + ":" + clockTime.min.format("%02d");
        var ss = ":" + clockTime.sec.format("%02d");

        // HH:MM large, centered
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, _cy - (_h * 0.06).toNumber(), Graphics.FONT_NUMBER_HOT, hhmm, Graphics.TEXT_JUSTIFY_CENTER);

        // :SS small, right of HH:MM
        dc.setColor(DataManager.getColor(DataManager.CLR_TEXT_SEC), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX + 2, _cy - (_h * 0.03).toNumber(), Graphics.FONT_TINY, ss, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ── Date (top area) ──
    private function drawDate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);

        // "MISSION DATE" label
        var labelY = (_h * 0.12).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, labelY, Graphics.FONT_XTINY, "MISSION DATE", Graphics.TEXT_JUSTIFY_CENTER);

        var dateStr;
        if (DataManager.dateFormat == 0) {
            // Stardate: YYYY.DDD
            var doy = computeDayOfYear(info.year, info.month, info.day);
            dateStr = info.year.toString() + "." + doy.format("%03d");
        } else {
            // Standard: FEB 06 THU
            var months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
            var days = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
            var mIdx = info.month as Number;
            var dIdx = info.day_of_week as Number;
            // CIQ months are 1-12, day_of_week 1-7 (Sun=1)
            dateStr = months[mIdx - 1] + " " + info.day.format("%02d") + " " + days[dIdx - 1];
        }

        var valueY = labelY + (_h * 0.06).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_TEXT_SEC), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, valueY, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function computeDayOfYear(year as Number, month as Number, day as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        // Leap year check
        if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
            daysInMonth[1] = 29;
        }
        var doy = 0;
        for (var i = 0; i < month - 1; i++) {
            doy += daysInMonth[i];
        }
        doy += day;
        return doy;
    }

    // ── Battery Arc (outer ring) ──
    private function drawBatteryArc(dc as Graphics.Dc) as Void {
        var battery = DataManager.cachedBattery;
        var radius = (_w / 2) - 3;
        var penW = 4;

        // Determine color based on battery level
        var arcColor;
        if (battery > 30) {
            arcColor = DataManager.getColor(DataManager.CLR_PRIMARY);
        } else if (battery > 15) {
            arcColor = DataManager.getColor(DataManager.CLR_WARNING);
        } else {
            arcColor = DataManager.getColor(DataManager.CLR_CRITICAL);
        }

        // CIQ drawArc: 0° = 3 o'clock, goes counter-clockwise
        // We want clockwise from 12 o'clock (90° in CIQ)
        // Fill amount
        var fillDeg = (battery.toFloat() / 100.0 * 360.0).toNumber();

        // Draw unfilled portion (full dark hairline ring)
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91);

        // Draw filled portion
        if (fillDeg > 0) {
            dc.setPenWidth(penW);
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            var startAngle = 90;
            var endAngle = 90 - fillDeg;
            if (endAngle < 0) { endAngle += 360; }
            dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, startAngle, endAngle);

            // Arrowhead at fill endpoint
            var arrowAngleDeg = 90.0 - fillDeg.toFloat();
            DrawUtils.drawArrowhead(dc, _cx, _cy, radius, arrowAngleDeg, arcColor, 6);
        }

        // Tick marks at 25%, 50%, 75% (clockwise from 12 o'clock)
        // In CIQ angles: 12 o'clock = 90°, clockwise decreases
        // 25% = 90 - 90 = 0°, 50% = 90 - 180 = -90° = 270°, 75% = 90 - 270 = -180° = 180°
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        var tickAngles = [0.0, 270.0, 180.0];
        for (var i = 0; i < tickAngles.size(); i++) {
            var rad = Math.toRadians(tickAngles[i]);
            var innerR = radius - 4;
            var outerR = radius + 4;
            var x1 = _cx + (innerR * Math.cos(rad)).toNumber();
            var y1 = _cy - (innerR * Math.sin(rad)).toNumber();
            var x2 = _cx + (outerR * Math.cos(rad)).toNumber();
            var y2 = _cy - (outerR * Math.sin(rad)).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }

        // "PWR" label at 12 o'clock outside ring
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.01).toNumber(), Graphics.FONT_XTINY, "PWR", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Steps Arc (inner ring) ──
    private function drawStepsArc(dc as Graphics.Dc) as Void {
        var steps = DataManager.cachedSteps;
        var goal = DataManager.cachedStepGoal;
        var radius = (_w / 2) - 10;
        var penW = 4;

        var pct = steps.toFloat() / goal.toFloat();
        if (pct > 2.0) { pct = 2.0; } // cap at 200%

        // Draw unfilled ring (full dark hairline circle)
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91);

        var arcColor = DataManager.getColor(DataManager.CLR_SECONDARY);

        if (pct <= 1.0) {
            // Normal fill
            var fillDeg = (pct * 360.0).toNumber();
            if (fillDeg > 0) {
                dc.setPenWidth(penW);
                dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
                var endAngle = 90 - fillDeg;
                if (endAngle < 0) { endAngle += 360; }
                dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);

                var arrowAngleDeg = 90.0 - fillDeg.toFloat();
                DrawUtils.drawArrowhead(dc, _cx, _cy, radius, arrowAngleDeg, arcColor, 5);
            }
        } else {
            // Goal exceeded: full ring + overflow in dim secondary
            dc.setPenWidth(penW);
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91); // full circle

            // Overflow ring
            var overflowPct = pct - 1.0;
            var overflowDeg = (overflowPct * 360.0).toNumber();
            if (overflowDeg > 0) {
                dc.setPenWidth(2);
                dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
                var endAngle = 90 - overflowDeg;
                if (endAngle < 0) { endAngle += 360; }
                dc.drawArc(_cx, _cy, radius - 5, Graphics.ARC_CLOCKWISE, 90, endAngle);
            }
        }

        // "STP" label at 12 o'clock, offset from PWR
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.05).toNumber(), Graphics.FONT_XTINY, "STP", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Step Count (near inner ring) ──
    private function drawStepCount(dc as Graphics.Dc) as Void {
        var steps = DataManager.cachedSteps;
        var stepStr = DataManager.formatNumber(steps);
        // Position below the center time area
        var y = _cy + (_h * 0.12).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_SECONDARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, y, Graphics.FONT_XTINY, stepStr + " stp", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Left Strip (Biometrics) ──
    private function drawLeftStrip(dc as Graphics.Dc) as Void {
        var lx = (_w * 0.10).toNumber();  // left strip X origin
        var topY = (_h * 0.30).toNumber();
        var lineH = (_h * 0.065).toNumber();

        // PULSE label
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, topY, Graphics.FONT_XTINY, "PULSE", Graphics.TEXT_JUSTIFY_LEFT);

        // HR value with zone color
        var hr = DataManager.cachedHR;
        var hrStr = hr > 0 ? hr.toString() : "--";
        var hrColor = DataManager.getHrZoneColor(hr);
        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, topY + lineH, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_LEFT);

        // ECG sparkline
        var ecgY = topY + lineH * 2 + (_h * 0.02).toNumber();
        drawEcgWave(dc, lx, ecgY, (_w * 0.22).toNumber(), (_h * 0.06).toNumber());

        // STR (Stress) label + bar
        var strY = ecgY + (_h * 0.08).toNumber();
        var stress = DataManager.cachedStress;
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, strY, Graphics.FONT_XTINY, "STR " + (stress > 0 ? stress.toString() : "--"), Graphics.TEXT_JUSTIFY_LEFT);

        var barY = strY + (_h * 0.055).toNumber();
        var barW = (_w * 0.18).toNumber();
        var barH = 3;
        var stressPct = stress > 0 ? stress.toFloat() / 100.0 : 0.0;
        var stressColor = stress > 50 ? DataManager.getColor(DataManager.CLR_WARNING) : DataManager.getColor(DataManager.CLR_PRIMARY);
        DrawUtils.drawProgressBar(dc, lx, barY, barW, barH, stressPct, stressColor, DataManager.getColor(DataManager.CLR_DIM));

        // O2 (SpO2)
        var o2Y = barY + (_h * 0.03).toNumber();
        var spo2 = DataManager.cachedSpO2;
        var o2Str = spo2 > 0 ? spo2.toString() + "%" : "--%";
        var o2Color = (spo2 > 0 && spo2 < 90) ? DataManager.getColor(DataManager.CLR_CRITICAL) : DataManager.getColor(DataManager.CLR_PRIMARY);
        dc.setColor(o2Color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, o2Y, Graphics.FONT_XTINY, "O2 " + o2Str, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ── ECG Waveform ──
    private function drawEcgWave(dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var points = DataManager.ECG_PATTERN.size();
        var stepX = w.toFloat() / (points - 1).toFloat();
        var offset = _isHighPower ? DataManager.ecgOffset : 0;

        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        for (var i = 0; i < points - 1; i++) {
            var idx1 = (i + offset) % points;
            var idx2 = (i + 1 + offset) % points;
            var v1 = (DataManager.ECG_PATTERN as Array<Float>)[idx1];
            var v2 = (DataManager.ECG_PATTERN as Array<Float>)[idx2];

            var x1 = x + (i * stepX).toNumber();
            var y1 = y + h - (v1 * h).toNumber();
            var x2 = x + ((i + 1) * stepX).toNumber();
            var y2 = y + h - (v2 * h).toNumber();

            dc.drawLine(x1, y1, x2, y2);
        }
    }

    // ── Right Strip (Cycling Tier 2) ──
    private function drawRightStrip(dc as Graphics.Dc) as Void {
        var rx = (_w * 0.75).toNumber();  // right strip X
        var topY = (_h * 0.30).toNumber();
        var lineH = (_h * 0.065).toNumber();
        var stripW = (_w * 0.20).toNumber();

        // HUD Label
        var label = DataManager.getCurrentTier2Label();
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(rx, topY, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);

        // Value
        var value = DataManager.getCurrentTier2Value();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rx, topY + lineH, Graphics.FONT_SMALL, value, Graphics.TEXT_JUSTIFY_LEFT);

        // Mini bar for RESERVE (body battery)
        var barVal = DataManager.getCurrentTier2BarValue();
        if (barVal != null) {
            var barY = topY + lineH * 2 + (_h * 0.02).toNumber();
            DrawUtils.drawProgressBar(dc, rx, barY, stripW, 3, barVal,
                DataManager.getColor(DataManager.CLR_TERTIARY),
                DataManager.getColor(DataManager.CLR_DIM));
        }

        // Cycle indicator dots
        drawCycleIndicator(dc, rx, topY + lineH * 3 + (_h * 0.04).toNumber());
    }

    // ── Cycle Indicator Dots ──
    private function drawCycleIndicator(dc as Graphics.Dc, x as Number, y as Number) as Void {
        var count = DataManager.tier2EnabledIndices.size();
        if (count <= 1) { return; }

        var dotSpacing = 8;
        var totalW = (count - 1) * dotSpacing;
        var startX = x;

        for (var i = 0; i < count; i++) {
            var dx = startX + i * dotSpacing;
            if (i == DataManager.tier2Current) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 2);
            } else {
                dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 1);
            }
        }
    }

    // ── Annunciator Nodes (bottom bar) ──
    private function drawAnnunciators(dc as Graphics.Dc) as Void {
        var settings = System.getDeviceSettings();
        var y = (_h * 0.86).toNumber();
        var spacing = (_w * 0.16).toNumber();
        var startX = _cx - spacing * 2;

        // BT
        var btActive = settings.phoneConnected;
        DrawUtils.drawStatusNode(dc, startX, y, "BT", btActive,
            0x00FFFF, DataManager.getColor(DataManager.CLR_DIM), null);

        // NTF
        var ntfCount = settings.notificationCount;
        var ntfActive = ntfCount > 0;
        var ntfBadge = ntfActive ? ntfCount.toString() : null;
        DrawUtils.drawStatusNode(dc, startX + spacing, y, "NTF", ntfActive,
            Graphics.COLOR_WHITE, DataManager.getColor(DataManager.CLR_DIM), ntfBadge);

        // DND
        var dndActive = settings.doNotDisturb;
        DrawUtils.drawStatusNode(dc, startX + spacing * 2, y, "DND", dndActive,
            0xAA55FF, DataManager.getColor(DataManager.CLR_DIM), null);

        // ALM
        var almCount = settings.alarmCount;
        var almActive = almCount > 0;
        DrawUtils.drawStatusNode(dc, startX + spacing * 3, y, "ALM", almActive,
            0xFFAA00, DataManager.getColor(DataManager.CLR_DIM), null);

        // MOV
        var movLevel = 0;
        try {
            var amInfo = ActivityMonitor.getInfo();
            if (amInfo.moveBarLevel != null) {
                movLevel = amInfo.moveBarLevel as Number;
            }
        } catch (e) {}
        var movActive = movLevel > 0;
        DrawUtils.drawStatusNode(dc, startX + spacing * 4, y, "MOV", movActive,
            0xFF0000, DataManager.getColor(DataManager.CLR_DIM), null);
    }
}
