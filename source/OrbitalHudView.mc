import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Math;

class OrbitalHudView extends WatchUi.WatchFace {

    // ── Screen dimensions ──
    private var _w as Number = 260;
    private var _h as Number = 260;
    private var _cx as Number = 130;
    private var _cy as Number = 130;
    private var _isHighPower as Boolean = true;

    // ── Custom fonts ──
    private var _timeFontLg as Graphics.FontType = Graphics.FONT_NUMBER_HOT;
    private var _timeFontSm as Graphics.FontType = Graphics.FONT_SMALL;
    private var _dataFont as Graphics.FontType = Graphics.FONT_XTINY;
    private var _fTimeLg as Number = 42;
    private var _fTimeSm as Number = 20;
    private var _fData as Number = 14;

    // ── Seconds clip region ──
    private var _ssX as Number = 0;
    private var _ssY as Number = 0;
    private var _ssW as Number = 50;
    private var _ssH as Number = 24;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = _w / 2;
        _cy = _h / 2;

        // Load custom fonts
        _timeFontLg = WatchUi.loadResource(Rez.Fonts.TimeFontLg) as Graphics.FontType;
        _timeFontSm = WatchUi.loadResource(Rez.Fonts.TimeFontSm) as Graphics.FontType;
        _dataFont = WatchUi.loadResource(Rez.Fonts.DataFont) as Graphics.FontType;
        _fTimeLg = dc.getFontHeight(_timeFontLg);
        _fTimeSm = dc.getFontHeight(_timeFontSm);
        _fData = dc.getFontHeight(_dataFont);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Fetch all sensor data
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
        drawSeparator(dc, 40);
        drawRow1(dc);
        drawEcgWave(dc, 35, 61, _w - 70, 5);
        drawTier2Grid(dc);
        drawScanLines(dc);
        drawTime(dc);
        drawSeparator(dc, 199);
        drawBottomBar(dc);
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        dc.setClip(_ssX, _ssY, _ssW, _ssH);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_ssX, _ssY, _ssW, _ssH);
        var clockTime = System.getClockTime();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY + 1, _timeFontSm, ":" + clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.clearClip();
    }

    function onEnterSleep() as Void { _isHighPower = false; }
    function onExitSleep() as Void {
        _isHighPower = true;
        DataManager.tier2Counter = 0;
    }

    // ══════════════════════════════════════════
    //  DRAWING FUNCTIONS
    // ══════════════════════════════════════════

    // ── Date (top center, Orbitron 14) ──
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
        dc.drawText(_cx, 28, _dataFont, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function computeDayOfYear(year as Number, month as Number, day as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
            daysInMonth[1] = 29;
        }
        var doy = 0;
        for (var i = 0; i < month - 1; i++) { doy += daysInMonth[i]; }
        doy += day;
        return doy;
    }

    // ── Dashed separator line ──
    private function drawSeparator(dc as Graphics.Dc, y as Number) as Void {
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        // Calculate visible width at this Y for round display
        var margin = getHorizontalMargin(y);
        var x1 = margin + 8;
        var x2 = _w - margin - 8;
        var dashLen = 4;
        var gapLen = 4;
        var x = x1;
        while (x < x2) {
            var endX = x + dashLen;
            if (endX > x2) { endX = x2; }
            dc.drawLine(x, y, endX, y);
            x += dashLen + gapLen;
        }
    }

    // ── Row 1: Always-on biometrics (HR, Stress, SpO2) ──
    private function drawRow1(dc as Graphics.Dc) as Void {
        var y = 43;
        var margin = getHorizontalMargin(y + _fData / 2);
        var usableW = _w - 2 * margin - 16;
        var cellW = usableW / 3;
        var baseX = margin + 8;

        var clrPri = DataManager.getColor(DataManager.CLR_PRIMARY);

        // HR: ♥ + value
        var hr = DataManager.cachedHR;
        var hrStr = hr > 0 ? hr.toString() : "--";
        dc.setColor(DataManager.getHrZoneColor(hr), Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX, y, _dataFont, DataManager.ICON_HR + hrStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Stress: ⚡ + value
        var stress = DataManager.cachedStress;
        var strStr = stress > 0 ? stress.toString() : "--";
        var strColor = stress > 50 ? DataManager.getColor(DataManager.CLR_WARNING) : clrPri;
        dc.setColor(strColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX + cellW, y, _dataFont, DataManager.ICON_STRESS + strStr, Graphics.TEXT_JUSTIFY_LEFT);

        // SpO2: ◎ + value
        var spo2 = DataManager.cachedSpO2;
        var o2Str = spo2 > 0 ? spo2.toString() + "%" : "--%";
        var o2Color = (spo2 > 0 && spo2 < 90) ? DataManager.getColor(DataManager.CLR_CRITICAL) : clrPri;
        dc.setColor(o2Color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX + cellW * 2, y, _dataFont, DataManager.ICON_SPO2 + o2Str, Graphics.TEXT_JUSTIFY_LEFT);
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

    // ── Tier2 Grid (rows 2-4 above and below time) ──
    private function drawTier2Grid(dc as Graphics.Dc) as Void {
        var pageItems = DataManager.getTier2PageItems();
        var count = pageItems.size();
        if (count == 0) { return; }

        // Row Y positions: above time and below time
        var rowYs = [68, 160, 183];
        var rowIdx = 0;

        for (var i = 0; i < count && rowIdx < 3; i += 3) {
            var y = rowYs[rowIdx] as Number;
            // How many items in this row
            var rowCount = count - i;
            if (rowCount > 3) { rowCount = 3; }
            drawTier2Row(dc, y, pageItems, i, rowCount);
            rowIdx++;
        }

        // Draw page indicator dots if multiple pages
        if (DataManager.getTier2PageCount() > 1) {
            drawPageDots(dc, 210);
        }
    }

    private function drawTier2Row(dc as Graphics.Dc, y as Number, items as Array<Number>,
            startIdx as Number, count as Number) as Void {
        var margin = getHorizontalMargin(y + _fData / 2);
        var usableW = _w - 2 * margin - 16;
        var cellW = usableW / 3;
        var baseX = margin + 8;

        var clrPri = DataManager.getColor(DataManager.CLR_PRIMARY);
        dc.setColor(clrPri, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < count; i++) {
            var itemIdx = items[startIdx + i];
            var icon = DataManager.getTier2Icon(itemIdx);
            var value = DataManager.getTier2Value(itemIdx);
            dc.drawText(baseX + cellW * i, y, _dataFont, icon + value, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // ── Scan Lines (wings around time) ──
    private function drawScanLines(dc as Graphics.Dc) as Void {
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // Top scan line wings at y=88
        var y1 = 88;
        var m1 = getHorizontalMargin(y1);
        // Left wing
        dc.drawLine(m1 + 8, y1, m1 + 28, y1);
        dc.drawLine(m1 + 32, y1, m1 + 36, y1);
        // Right wing
        dc.drawLine(_w - m1 - 36, y1, _w - m1 - 32, y1);
        dc.drawLine(_w - m1 - 28, y1, _w - m1 - 8, y1);

        // Bottom scan line wings at y=155
        var y2 = 155;
        var m2 = getHorizontalMargin(y2);
        // Left wing
        dc.drawLine(m2 + 8, y2, m2 + 28, y2);
        dc.drawLine(m2 + 32, y2, m2 + 36, y2);
        // Right wing
        dc.drawLine(_w - m2 - 36, y2, _w - m2 - 32, y2);
        dc.drawLine(_w - m2 - 28, y2, _w - m2 - 8, y2);
    }

    // ── Inline Time (HH:MM centered + :SS to the right) ──
    private function drawTime(dc as Graphics.Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hour == 0) { hour = 12; }
            else if (hour > 12) { hour = hour - 12; }
        }

        var timeStr = hour.format("%02d") + ":" + clockTime.min.format("%02d");
        var timeY = 97;

        // Draw HH:MM centered
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, timeY, _timeFontLg, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Seconds positioned at right edge of time text
        var timeDims = dc.getTextDimensions(timeStr, _timeFontLg);
        var timeW = timeDims[0];
        _ssX = _cx + timeW / 2 + 2;
        _ssY = timeY + _fTimeLg - _fTimeSm - 2;
        _ssW = 40;
        _ssH = _fTimeSm + 4;

        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY, _timeFontSm, ":" + clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ── Bottom Bar: Steps + Annunciator Dots ──
    private function drawBottomBar(dc as Graphics.Dc) as Void {
        var y = 204;
        var margin = getHorizontalMargin(y + _fData / 2);
        var lx = margin + 8;

        // ● icon + step count (single drawText)
        dc.setColor(DataManager.getColor(DataManager.CLR_SECONDARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(lx, y, _dataFont, DataManager.ICON_STEPS + DataManager.formatNumber(DataManager.cachedSteps), Graphics.TEXT_JUSTIFY_LEFT);

        // Annunciator dots (right side)
        var rx = _w - margin - 8;
        drawAnnunciatorDots(dc, rx, y + _fData / 2);
    }

    // ── Annunciator Dots (5 colored dots) ──
    private function drawAnnunciatorDots(dc as Graphics.Dc, rx as Number, cy as Number) as Void {
        var settings = System.getDeviceSettings();
        var spacing = 10;
        var startX = rx - 4 * spacing;

        // BT
        var btActive = settings.phoneConnected;
        dc.setColor(btActive ? DataManager.getColor(DataManager.CLR_PRIMARY) : DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        if (btActive) { dc.fillCircle(startX, cy, 3); } else { dc.drawCircle(startX, cy, 2); }

        // NTF
        var ntfActive = settings.notificationCount > 0;
        dc.setColor(ntfActive ? Graphics.COLOR_WHITE : DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        if (ntfActive) { dc.fillCircle(startX + spacing, cy, 3); } else { dc.drawCircle(startX + spacing, cy, 2); }

        // DND
        var dndActive = settings.doNotDisturb;
        dc.setColor(dndActive ? DataManager.getColor(DataManager.CLR_SECONDARY) : DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        if (dndActive) { dc.fillCircle(startX + spacing * 2, cy, 3); } else { dc.drawCircle(startX + spacing * 2, cy, 2); }

        // ALM
        var almActive = settings.alarmCount > 0;
        dc.setColor(almActive ? DataManager.getColor(DataManager.CLR_WARNING) : DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        if (almActive) { dc.fillCircle(startX + spacing * 3, cy, 3); } else { dc.drawCircle(startX + spacing * 3, cy, 2); }

        // MOV
        var movActive = false;
        try {
            var amInfo = ActivityMonitor.getInfo();
            if (amInfo.moveBarLevel != null) { movActive = (amInfo.moveBarLevel as Number) > 0; }
        } catch (e) {}
        dc.setColor(movActive ? DataManager.getColor(DataManager.CLR_CRITICAL) : DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        if (movActive) { dc.fillCircle(startX + spacing * 4, cy, 3); } else { dc.drawCircle(startX + spacing * 4, cy, 2); }
    }

    // ── Page Indicator Dots ──
    private function drawPageDots(dc as Graphics.Dc, y as Number) as Void {
        var pages = DataManager.getTier2PageCount();
        if (pages <= 1) { return; }
        var spacing = 8;
        var totalW = (pages - 1) * spacing;
        var startX = _cx - totalW / 2;
        for (var i = 0; i < pages; i++) {
            var dx = startX + i * spacing;
            if (i == DataManager.tier2Current) {
                dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 2);
            } else {
                dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, y, 1);
            }
        }
    }

    // ── Corner Brackets (HUD frame) ──
    private function drawCornerBrackets(dc as Graphics.Dc) as Void {
        var inset = 24;
        var len = 14;
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

    // ── Battery Arc (outer ring) ──
    private function drawBatteryArc(dc as Graphics.Dc) as Void {
        var battery = DataManager.cachedBattery;
        var radius = (_w / 2) - 3;

        var arcColor;
        if (battery > 30) { arcColor = DataManager.getColor(DataManager.CLR_PRIMARY); }
        else if (battery > 15) { arcColor = DataManager.getColor(DataManager.CLR_WARNING); }
        else { arcColor = DataManager.getColor(DataManager.CLR_CRITICAL); }

        var fillDeg = (battery.toFloat() / 100.0 * 360.0).toNumber();

        // Unfilled ring
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
    }

    // ── Helper: horizontal margin for round display at given Y ──
    // Returns the X distance from edge to the chord at height Y
    private function getHorizontalMargin(y as Number) as Number {
        var r = _w / 2;
        var dy = (y - _cy).abs();
        if (dy >= r) { return r; }
        var chord = Math.sqrt((r * r - dy * dy).toFloat()).toNumber();
        return r - chord;
    }
}
