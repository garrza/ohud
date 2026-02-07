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
    private var _fTimeSm as Number = 14;
    private var _fData as Number = 14;

    // ── Seconds clip region ──
    private var _ssX as Number = 0;
    private var _ssY as Number = 0;
    private var _ssW as Number = 50;
    private var _ssH as Number = 24;

    // ── Rocket sprites (8 rotations, every 45°) ──
    private var _rockets as Array<Graphics.BitmapType> = [] as Array<Graphics.BitmapType>;

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

        // Load rocket sprites (8 headings: 0°, 45°, 90°, ... 315°)
        _rockets = [
            WatchUi.loadResource(Rez.Drawables.Rocket0) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket1) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket2) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket3) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket4) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket5) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket6) as Graphics.BitmapType,
            WatchUi.loadResource(Rez.Drawables.Rocket7) as Graphics.BitmapType
        ];
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

        if (_isHighPower) {
            DataManager.ecgOffset = (DataManager.ecgOffset + 1) % 20;
        }

        // Draw back to front
        drawCornerBrackets(dc);
        drawInfoBar(dc);
        drawSeparator(dc, 34);
        drawRow1(dc);
        drawEcgWave(dc, 35, 61, _w - 70, 5);
        drawDataRows(dc);
        drawScanLines(dc);
        drawTime(dc);
        drawSeparator(dc, 216);
        drawBottomBar(dc);
        drawSecondsRing(dc);
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        dc.setClip(_ssX, _ssY, _ssW, _ssH);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_ssX, _ssY, _ssW, _ssH);
        var clockTime = System.getClockTime();
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY, _timeFontSm, ":" + clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
        dc.clearClip();
    }

    function onEnterSleep() as Void { _isHighPower = false; }
    function onExitSleep() as Void { _isHighPower = true; }

    // ══════════════════════════════════════════
    //  DRAWING FUNCTIONS
    // ══════════════════════════════════════════

    // ── Info Bar (centered date) ──
    private function drawInfoBar(dc as Graphics.Dc) as Void {
        var y = 20;
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
        var days = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
        var dateStr = days[(info.day_of_week as Number) - 1] + " / " +
            months[(info.month as Number) - 1] + " " + (info.day as Number).format("%02d");

        dc.setColor(DataManager.getColor(DataManager.CLR_TEXT_SEC), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, y, _dataFont, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
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
        var y = 38;
        drawDataRow(dc, y, [
            [DataManager.ICON_HR, DataManager.cachedHR > 0 ? DataManager.cachedHR.toString() : "--", DataManager.getHrZoneColor(DataManager.cachedHR)],
            [DataManager.ICON_STRESS, DataManager.cachedStress > 0 ? DataManager.cachedStress.toString() : "--",
                DataManager.cachedStress > 50 ? DataManager.getColor(DataManager.CLR_WARNING) : DataManager.getColor(DataManager.CLR_PRIMARY)],
            [DataManager.ICON_SPO2, DataManager.cachedSpO2 > 0 ? DataManager.cachedSpO2.toString() + "%" : "--%",
                (DataManager.cachedSpO2 > 0 && DataManager.cachedSpO2 < 90) ? DataManager.getColor(DataManager.CLR_CRITICAL) : DataManager.getColor(DataManager.CLR_PRIMARY)]
        ]);
    }

    // ── Generic data row: draws up to 3 cells with label (dim) + value (color), both DataFont ──
    private function drawDataRow(dc as Graphics.Dc, y as Number, cells as Array) as Void {
        var margin = getHorizontalMargin(y + _fData / 2);
        var usableW = _w - 2 * margin - 16;
        var n = cells.size();
        var cellW = usableW / n;
        var baseX = margin + 8;

        for (var i = 0; i < n; i++) {
            var cell = cells[i] as Array;
            var label = cell[0] as String;
            var value = cell[1] as String;
            var color = cell[2] as Number;

            var labelW = dc.getTextWidthInPixels(label, _dataFont);
            var valueW = dc.getTextWidthInPixels(value, _dataFont);
            var totalW = labelW + valueW;
            var cellCenterX = baseX + cellW * i + cellW / 2;
            var x = cellCenterX - totalW / 2;

            // Draw label in dim color
            dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, _dataFont, label, Graphics.TEXT_JUSTIFY_LEFT);

            // Draw value in cell color
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + labelW, y, _dataFont, value, Graphics.TEXT_JUSTIFY_LEFT);
        }
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

    // ── Tier2 Data Rows (5 rows: row2 above time, rows 3-5 below time) ──
    private function drawDataRows(dc as Graphics.Dc) as Void {
        var slotItems = DataManager.getTier2SlotItems();
        var count = slotItems.size();
        if (count == 0) { return; }

        // Y positions for rows 2-5 (row 1 is biometrics, handled separately)
        var rowYs = [68, 152, 170, 190];
        var clrPri = DataManager.getColor(DataManager.CLR_PRIMARY);

        for (var row = 0; row < 4; row++) {
            var startIdx = row * 3;
            if (startIdx >= count) { break; }
            var rowCount = count - startIdx;
            if (rowCount > 3) { rowCount = 3; }

            var cells = [] as Array;
            for (var i = 0; i < rowCount; i++) {
                var itemIdx = slotItems[startIdx + i];
                cells.add([DataManager.getTier2Icon(itemIdx), DataManager.getTier2Value(itemIdx), clrPri]);
            }
            drawDataRow(dc, rowYs[row] as Number, cells);
        }
    }

    // ── Scan Lines (wings around time) ──
    private function drawScanLines(dc as Graphics.Dc) as Void {
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // Top scan line wings at y=84
        var y1 = 84;
        var m1 = getHorizontalMargin(y1);
        dc.drawLine(m1 + 8, y1, m1 + 28, y1);
        dc.drawLine(m1 + 32, y1, m1 + 36, y1);
        dc.drawLine(_w - m1 - 36, y1, _w - m1 - 32, y1);
        dc.drawLine(_w - m1 - 28, y1, _w - m1 - 8, y1);

        // Bottom scan line wings at y=148
        var y2 = 148;
        var m2 = getHorizontalMargin(y2);
        dc.drawLine(m2 + 8, y2, m2 + 28, y2);
        dc.drawLine(m2 + 32, y2, m2 + 36, y2);
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
        var timeY = 88;

        // Draw HH:MM centered
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, timeY, _timeFontLg, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Seconds baseline-aligned with time, at right edge
        var timeDims = dc.getTextDimensions(timeStr, _timeFontLg);
        var timeW = timeDims[0];
        _ssX = _cx + timeW / 2 + 2;
        // Baseline-align: ascent ratio for Departure Mono is 11/14 of lineHeight
        _ssY = timeY + (_fTimeLg - _fTimeSm) * 11 / 14;
        _ssW = 50;
        _ssH = _fTimeSm + 4;

        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_ssX, _ssY, _timeFontSm, ":" + clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ── Bottom Bar: Sunrise + Sunset ──
    private function drawBottomBar(dc as Graphics.Dc) as Void {
        var y = 220;
        var clrSec = DataManager.getColor(DataManager.CLR_SECONDARY);
        drawDataRow(dc, y, [
            ["SR ", DataManager.fetchSunrise(), clrSec],
            ["SS ", DataManager.fetchSunset(), clrSec]
        ]);
    }

    // ── Corner Brackets (HUD frame) ──
    private function drawCornerBrackets(dc as Graphics.Dc) as Void {
        var inset = 24;
        var len = 14;
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(inset, inset, inset + len, inset);
        dc.drawLine(inset, inset, inset, inset + len);
        dc.drawLine(_w - inset, inset, _w - inset - len, inset);
        dc.drawLine(_w - inset, inset, _w - inset, inset + len);
        dc.drawLine(inset, _h - inset, inset + len, _h - inset);
        dc.drawLine(inset, _h - inset, inset, _h - inset - len);
        dc.drawLine(_w - inset, _h - inset, _w - inset - len, _h - inset);
        dc.drawLine(_w - inset, _h - inset, _w - inset, _h - inset - len);
    }

    // ── Seconds Ring (outer edge, fills CW from 12 o'clock) ──
    private function drawSecondsRing(dc as Graphics.Dc) as Void {
        var clockTime = System.getClockTime();
        var sec = clockTime.sec;
        var radius = (_w / 2) - 3;

        // Unfilled ring (dim, full circle)
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, radius, Graphics.ARC_CLOCKWISE, 0, 1);

        // Tick marks at 15s intervals (12/3/6/9 positions = 90/0/270/180 degrees)
        dc.setPenWidth(1);
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        var tickAngles = [90.0, 0.0, 270.0, 180.0];
        for (var i = 0; i < tickAngles.size(); i++) {
            var rad = Math.toRadians(tickAngles[i]);
            var x1 = _cx + ((radius - 4) * Math.cos(rad)).toNumber();
            var y1 = _cy - ((radius - 4) * Math.sin(rad)).toNumber();
            var x2 = _cx + ((radius + 4) * Math.cos(rad)).toNumber();
            var y2 = _cy - ((radius + 4) * Math.sin(rad)).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }

        // Rocket sprite at current second position (drawn last = on top)
        var fillDeg = (sec.toFloat() / 60.0 * 360.0).toNumber();
        var posAngle = 90.0 - fillDeg.toFloat();
        var posRad = Math.toRadians(posAngle);

        var rX = _cx + (radius * Math.cos(posRad)).toNumber();
        var rY = _cy - (radius * Math.sin(posRad)).toNumber();

        var heading = posAngle - 90.0;
        if (heading < 0.0) { heading += 360.0; }

        var idx = ((heading + 22.5) / 45.0).toNumber() % 8;
        dc.drawBitmap(rX - 6, rY - 6, _rockets[idx]);
    }

    // ── Helper: horizontal margin for round display at given Y ──
    private function getHorizontalMargin(y as Number) as Number {
        var r = _w / 2;
        var dy = (y - _cy).abs();
        if (dy >= r) { return r; }
        var chord = Math.sqrt((r * r - dy * dy).toFloat()).toNumber();
        return r - chord;
    }
}
