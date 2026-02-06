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

    // ── Font metrics (cached in onLayout) ──
    private var _fontHotH as Number = 60;
    private var _fontSmallH as Number = 20;
    private var _fontTinyH as Number = 16;
    private var _fontXtinyH as Number = 13;

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

        _fontHotH = dc.getFontHeight(Graphics.FONT_NUMBER_HOT);
        _fontSmallH = dc.getFontHeight(Graphics.FONT_SMALL);
        _fontTinyH = dc.getFontHeight(Graphics.FONT_TINY);
        _fontXtinyH = dc.getFontHeight(Graphics.FONT_XTINY);

        // Seconds: right of center time, below minutes
        _ssX = _cx + (_w * 0.12).toNumber();
        _ssY = _cy + (_fontHotH / 2) - _fontTinyH + 2;
        _ssW = (_w * 0.14).toNumber();
        _ssH = _fontTinyH + 4;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Fetch data
        DataManager.fetchBattery();
        DataManager.fetchSteps();
        DataManager.fetchHeartRate();
        DataManager.fetchStress();
        DataManager.fetchSpO2();
        DataManager.tickCycle(_isHighPower);

        if (_isHighPower) {
            DataManager.ecgOffset = (DataManager.ecgOffset + 1) % 20;
        }

        // Draw back to front
        drawBatteryArc(dc);
        drawStepsArc(dc);
        drawCornerBrackets(dc);
        drawDate(dc);
        drawTime(dc);
        drawLeftStrip(dc);
        drawRightStrip(dc);
        drawStepCount(dc);
        drawAnnunciators(dc);
    }

    // ── Low power: seconds only ──
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        dc.setClip(_ssX, _ssY, _ssW, _ssH);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_ssX, _ssY, _ssW, _ssH);
        var clockTime = System.getClockTime();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY + 1, Graphics.FONT_TINY, ":" + clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
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
        var len = (_w * 0.08).toNumber();
        var inset = (_w * 0.10).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // Top-left
        dc.drawLine(inset, inset, inset + len, inset);
        dc.drawLine(inset, inset, inset, inset + len);
        // Top-right
        dc.drawLine(_w - inset, inset, _w - inset - len, inset);
        dc.drawLine(_w - inset, inset, _w - inset, inset + len);
        // Bottom-left
        dc.drawLine(inset, _h - inset, inset + len, _h - inset);
        dc.drawLine(inset, _h - inset, inset, _h - inset - len);
        // Bottom-right
        dc.drawLine(_w - inset, _h - inset, _w - inset - len, _h - inset);
        dc.drawLine(_w - inset, _h - inset, _w - inset, _h - inset - len);
    }

    // ── Date (top center) ──
    private function drawDate(dc as Graphics.Dc) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        var dateStr;
        if (DataManager.dateFormat == 0) {
            var doy = computeDayOfYear(info.year as Number, info.month as Number, info.day as Number);
            dateStr = (info.year as Number).toString() + "." + doy.format("%03d");
        } else {
            var months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
            var days = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
            dateStr = months[(info.month as Number) - 1] + " " + (info.day as Number).format("%02d") + " " + days[(info.day_of_week as Number) - 1];
        }

        dc.setColor(DataManager.getColor(DataManager.CLR_TEXT_SEC), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.13).toNumber(), Graphics.FONT_XTINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function computeDayOfYear(year as Number, month as Number, day as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
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

    // ── Stacked Time (HH over MM, horizontal rule between, :SS to the right) ──
    private function drawTime(dc as Graphics.Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
            if (hour == 0) { hour = 12; }
            else if (hour > 12) { hour = hour - 12; }
        }

        var hourStr = hour.format("%02d");
        var minStr = clockTime.min.format("%02d");

        // Stacked layout: hours and minutes centered vertically around _cy
        // Each FONT_NUMBER_HOT line, with a thin rule between
        var ruleGap = 2;
        var totalH = _fontHotH * 2 + ruleGap;
        var topY = _cy - (totalH / 2);

        // Hours
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, topY, Graphics.FONT_NUMBER_HOT, hourStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Horizontal rule
        var ruleY = topY + _fontHotH + (ruleGap / 2);
        var ruleHalfW = (_w * 0.12).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(_cx - ruleHalfW, ruleY, _cx + ruleHalfW, ruleY);

        // Minutes
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, ruleY + (ruleGap / 2), Graphics.FONT_NUMBER_HOT, minStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Seconds: small, to the right of minutes
        var ssStr = ":" + clockTime.sec.format("%02d");
        _ssX = _cx + (_w * 0.12).toNumber();
        _ssY = ruleY + (ruleGap / 2) + _fontHotH - _fontTinyH - 2;
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY, Graphics.FONT_TINY, ssStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ── Battery Arc (outer ring) ──
    private function drawBatteryArc(dc as Graphics.Dc) as Void {
        var battery = DataManager.cachedBattery;
        var radius = (_w / 2) - 3;

        var arcColor;
        if (battery > 30) {
            arcColor = DataManager.getColor(DataManager.CLR_PRIMARY);
        } else if (battery > 15) {
            arcColor = DataManager.getColor(DataManager.CLR_WARNING);
        } else {
            arcColor = DataManager.getColor(DataManager.CLR_CRITICAL);
        }

        var fillDeg = (battery.toFloat() / 100.0 * 360.0).toNumber();

        // Unfilled ring background
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91);

        // Filled arc
        if (fillDeg > 0) {
            dc.setPenWidth(4);
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            var endAngle = 90 - fillDeg;
            if (endAngle < 0) { endAngle += 360; }
            dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);
            DrawUtils.drawArrowhead(dc, _cx, _cy, radius, 90.0 - fillDeg.toFloat(), arcColor, 6);
        }

        // Tick marks at 25%, 50%, 75%
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        var tickAngles = [0.0, 270.0, 180.0];
        for (var i = 0; i < tickAngles.size(); i++) {
            var rad = Math.toRadians(tickAngles[i]);
            var x1 = _cx + ((radius - 4) * Math.cos(rad)).toNumber();
            var y1 = _cy - ((radius - 4) * Math.sin(rad)).toNumber();
            var x2 = _cx + ((radius + 4) * Math.cos(rad)).toNumber();
            var y2 = _cy - ((radius + 4) * Math.sin(rad)).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }

        // PWR label at 12 o'clock
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.01).toNumber(), Graphics.FONT_XTINY, "PWR", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Steps Arc (inner ring) ──
    private function drawStepsArc(dc as Graphics.Dc) as Void {
        var steps = DataManager.cachedSteps;
        var goal = DataManager.cachedStepGoal;
        var radius = (_w / 2) - 10;

        var pct = steps.toFloat() / goal.toFloat();
        if (pct > 2.0) { pct = 2.0; }

        // Unfilled ring
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91);

        var arcColor = DataManager.getColor(DataManager.CLR_SECONDARY);

        if (pct <= 1.0) {
            var fillDeg = (pct * 360.0).toNumber();
            if (fillDeg > 0) {
                dc.setPenWidth(4);
                dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
                var endAngle = 90 - fillDeg;
                if (endAngle < 0) { endAngle += 360; }
                dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);
                DrawUtils.drawArrowhead(dc, _cx, _cy, radius, 90.0 - fillDeg.toFloat(), arcColor, 5);
            }
        } else {
            // Goal exceeded: full ring + overflow
            dc.setPenWidth(4);
            dc.setColor(arcColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 90, 91);
            var overflowDeg = ((pct - 1.0) * 360.0).toNumber();
            if (overflowDeg > 0) {
                dc.setPenWidth(2);
                dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
                var endAngle = 90 - overflowDeg;
                if (endAngle < 0) { endAngle += 360; }
                dc.drawArc(_cx, _cy, radius - 5, Graphics.ARC_CLOCKWISE, 90, endAngle);
            }
        }

        // STP label at 12 o'clock, below PWR
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, (_h * 0.01).toNumber() + _fontXtinyH, Graphics.FONT_XTINY, "STP", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Left Strip (Biometrics) — column alongside time ──
    private function drawLeftStrip(dc as Graphics.Dc) as Void {
        var lx = (_w * 0.10).toNumber();
        var y = (_cy - (_fontHotH)).toNumber();

        // PULSE label
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, y, Graphics.FONT_XTINY, "PULSE", Graphics.TEXT_JUSTIFY_LEFT);
        y += _fontXtinyH + 1;

        // HR value (zone-colored)
        var hr = DataManager.cachedHR;
        var hrStr = hr > 0 ? hr.toString() : "--";
        dc.setColor(DataManager.getHrZoneColor(hr), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, y, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_LEFT);
        y += _fontSmallH + 1;

        // ECG sparkline
        var ecgH = (_h * 0.04).toNumber();
        if (ecgH < 7) { ecgH = 7; }
        var ecgW = (_w * 0.22).toNumber();
        drawEcgWave(dc, lx, y, ecgW, ecgH);
        y += ecgH + 3;

        // STR (stress) label + thin bar
        var stress = DataManager.cachedStress;
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, y, Graphics.FONT_XTINY, "STR " + (stress > 0 ? stress.toString() : "--"), Graphics.TEXT_JUSTIFY_LEFT);
        y += _fontXtinyH;

        var barW = (_w * 0.18).toNumber();
        var stressPct = stress > 0 ? stress.toFloat() / 100.0 : 0.0;
        var stressColor = stress > 50 ? DataManager.getColor(DataManager.CLR_WARNING) : DataManager.getColor(DataManager.CLR_PRIMARY);
        DrawUtils.drawProgressBar(dc, lx, y, barW, 2, stressPct, stressColor, DataManager.getColor(DataManager.CLR_DIM));
        y += 5;

        // O2 (SpO2)
        var spo2 = DataManager.cachedSpO2;
        var o2Str = spo2 > 0 ? spo2.toString() + "%" : "--%";
        var o2Color = (spo2 > 0 && spo2 < 90) ? DataManager.getColor(DataManager.CLR_CRITICAL) : DataManager.getColor(DataManager.CLR_DIM);
        dc.setColor(o2Color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, y, Graphics.FONT_XTINY, "O2 " + o2Str, Graphics.TEXT_JUSTIFY_LEFT);
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

    // ── Right Strip (Cycling Tier 2) — column alongside time ──
    private function drawRightStrip(dc as Graphics.Dc) as Void {
        var rx = (_w * 0.90).toNumber();
        var y = (_cy - (_fontHotH)).toNumber();

        // Label
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(rx, y, Graphics.FONT_XTINY, DataManager.getCurrentTier2Label(), Graphics.TEXT_JUSTIFY_RIGHT);
        y += _fontXtinyH + 1;

        // Value
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rx, y, Graphics.FONT_SMALL, DataManager.getCurrentTier2Value(), Graphics.TEXT_JUSTIFY_RIGHT);
        y += _fontSmallH + 2;

        // Bar (if RESERVE / body battery)
        var barVal = DataManager.getCurrentTier2BarValue();
        var barW = (_w * 0.20).toNumber();
        if (barVal != null) {
            DrawUtils.drawProgressBar(dc, rx - barW, y, barW, 2, barVal,
                DataManager.getColor(DataManager.CLR_TERTIARY),
                DataManager.getColor(DataManager.CLR_DIM));
        }
        y += 6;

        // Cycle indicator dots (right-aligned)
        drawCycleIndicator(dc, rx, y);
    }

    // ── Cycle Indicator Dots ──
    private function drawCycleIndicator(dc as Graphics.Dc, rx as Number, y as Number) as Void {
        var count = DataManager.tier2EnabledIndices.size();
        if (count <= 1) { return; }

        var spacing = 7;
        var totalW = (count - 1) * spacing;
        var startX = rx - totalW;

        for (var i = 0; i < count; i++) {
            var dx = startX + i * spacing;
            if (i == DataManager.tier2Current) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 2);
            } else {
                dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 1);
            }
        }
    }

    // ── Step Count (below time) ──
    private function drawStepCount(dc as Graphics.Dc) as Void {
        var stepStr = DataManager.formatNumber(DataManager.cachedSteps);
        var y = _cy + _fontHotH + (_h * 0.02).toNumber();
        dc.setColor(DataManager.getColor(DataManager.CLR_SECONDARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, y, Graphics.FONT_XTINY, stepStr + " stp", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // ── Annunciator Nodes (bottom) ──
    private function drawAnnunciators(dc as Graphics.Dc) as Void {
        var settings = System.getDeviceSettings();
        var y = (_h * 0.82).toNumber();
        var spacing = (_w * 0.14).toNumber();
        var startX = _cx - spacing * 2;

        // BT
        DrawUtils.drawStatusNode(dc, startX, y, "BT", settings.phoneConnected,
            DataManager.getColor(DataManager.CLR_PRIMARY), DataManager.getColor(DataManager.CLR_DIM), null);

        // NTF
        var ntfCount = settings.notificationCount;
        DrawUtils.drawStatusNode(dc, startX + spacing, y, "NTF", ntfCount > 0,
            Graphics.COLOR_WHITE, DataManager.getColor(DataManager.CLR_DIM),
            ntfCount > 0 ? ntfCount.toString() : null);

        // DND
        DrawUtils.drawStatusNode(dc, startX + spacing * 2, y, "DND", settings.doNotDisturb,
            DataManager.getColor(DataManager.CLR_SECONDARY), DataManager.getColor(DataManager.CLR_DIM), null);

        // ALM
        DrawUtils.drawStatusNode(dc, startX + spacing * 3, y, "ALM", settings.alarmCount > 0,
            DataManager.getColor(DataManager.CLR_WARNING), DataManager.getColor(DataManager.CLR_DIM), null);

        // MOV
        var movLevel = 0;
        try {
            var amInfo = ActivityMonitor.getInfo();
            if (amInfo.moveBarLevel != null) {
                movLevel = amInfo.moveBarLevel as Number;
            }
        } catch (e) {}
        DrawUtils.drawStatusNode(dc, startX + spacing * 4, y, "MOV", movLevel > 0,
            DataManager.getColor(DataManager.CLR_CRITICAL), DataManager.getColor(DataManager.CLR_DIM), null);
    }
}
