import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Position;
import Toybox.UserProfile;

module DataManager {

    // ── Settings ──
    var dateFormat as Number = 0;          // 0=stardate, 1=standard
    var themeId as Number = 0;             // 0-5

    // ── Theme Color Arrays ──
    // Index: [primary, secondary, tertiary, warning, critical, dim, textSecondary]
    const THEME_COLORS = [
        // 0: Deep Space
        [0x00FFFF, 0xAA55FF, 0x00FF55, 0xFFAA00, 0xFF0000, 0x555555, 0xAAAAAA],
        // 1: Phosphor Green
        [0x00FF00, 0x00AA55, 0x55FF00, 0xFFAA00, 0xFF0000, 0x555555, 0xAAAAAA],
        // 2: White Minimal
        [0xFFFFFF, 0xAAAAAA, 0xFFFFFF, 0xFFAA00, 0xFF0000, 0x555555, 0x555555],
        // 3: Red Tactical
        [0xFF0000, 0xFF5500, 0xFF5555, 0xFFAA00, 0xFF55FF, 0x555555, 0xAAAAAA],
        // 4: Amber Retro
        [0xFFAA00, 0xAA5500, 0xFFFF00, 0xFF5500, 0xFF0000, 0x555555, 0xAAAAAA],
        // 5: Solar Flare
        [0xFF5500, 0xFFAA00, 0xFFFF00, 0xFFAA55, 0xFF0000, 0x555555, 0xAAAAAA],
    ];

    const CLR_PRIMARY = 0;
    const CLR_SECONDARY = 1;
    const CLR_TERTIARY = 2;
    const CLR_WARNING = 3;
    const CLR_CRITICAL = 4;
    const CLR_DIM = 5;
    const CLR_TEXT_SEC = 6;

    // ── Tier 2 Definitions ──
    const TIER2_KEYS = [
        "ShowReserve", "ShowBurn", "ShowElev", "ShowRange", "ShowActive",
        "ShowAlt", "ShowSteps", "ShowAtmo", "ShowPress", "ShowBattery",
        "ShowResp", "ShowVO2", "ShowReady", "ShowHRV", "ShowSleep", "ShowRecov"
    ];

    // Text labels for each tier2 item (trailing space as separator)
    const TIER2_ICONS = [
        "BODY ", "CAL ", "FLR ", "DIST ", "ACTV ",
        "ALT ", "STEP ", "WX ", "PRES ", "BAT ",
        "RESP ", "VO2 ", "RDNS ", "HRV ", "SLP ", "RECV "
    ];

    // Row 1 labels (always-on biometrics)
    const ICON_HR = "HR ";
    const ICON_STRESS = "ST ";
    const ICON_SPO2 = "O2 ";
    const ICON_STEPS = "STP ";

    var tier2EnabledIndices as Array<Number> = [];

    // ── Cached Data ──
    var cachedBattery as Number = 0;
    var cachedSteps as Number = 0;
    var cachedHR as Number = 0;
    var cachedStress as Number = 0;
    var cachedSpO2 as Number = 0;

    // ── Cached Sun Data ──
    var cachedSunrise as String = "--:--";
    var cachedSunset as String = "--:--";
    var cachedSunLoc as Position.Location or Null = null;
    var lastSunCalcMin as Number = -1;

    // ── HR History Sparkline (rolling buffer of live readings) ──
    const HR_BUFFER_SIZE = 30;
    var hrHistory as Array<Number> = [] as Array<Number>;

    function pushHrSample() as Void {
        if (cachedHR <= 0) { return; }
        hrHistory.add(cachedHR);
        if (hrHistory.size() > HR_BUFFER_SIZE) {
            hrHistory = hrHistory.slice(hrHistory.size() - HR_BUFFER_SIZE, null) as Array<Number>;
        }
    }

    function loadSettings() as Void {
        var app = Application.getApp();
        var df = app.getProperty("DateFormat");
        dateFormat = (df != null) ? (df as Number) : 0;
        var th = app.getProperty("Theme");
        themeId = (th != null) ? (th as Number) : 0;
        rebuildTier2List();
    }

    function rebuildTier2List() as Void {
        var app = Application.getApp();
        tier2EnabledIndices = [];
        for (var i = 0; i < TIER2_KEYS.size(); i++) {
            var val = app.getProperty(TIER2_KEYS[i]);
            if (val == null || val == true) {
                tier2EnabledIndices.add(i);
            }
        }
        if (tier2EnabledIndices.size() == 0) {
            tier2EnabledIndices.add(0);
        }
    }

    function getColor(role as Number) as Number {
        var t = themeId;
        if (t < 0 || t > 5) { t = 0; }
        return (THEME_COLORS[t] as Array<Number>)[role];
    }

    // Returns up to 12 enabled tier2 indices (no pagination)
    function getTier2SlotItems() as Array<Number> {
        var items = [] as Array<Number>;
        var total = tier2EnabledIndices.size();
        var limit = total > 12 ? 12 : total;
        for (var i = 0; i < limit; i++) {
            items.add(tier2EnabledIndices[i]);
        }
        return items;
    }

    // Get the value string for a tier2 item by its global index
    function getTier2Value(idx as Number) as String {
        switch (idx) {
            case 0: return fetchBodyBattery();
            case 1: return fetchCalories();
            case 2: return fetchFloors();
            case 3: return fetchDistance();
            case 4: return fetchActiveMinutes();
            case 5: return fetchAltitude();
            case 6: return formatNumber(cachedSteps);
            case 7: return fetchWeather();
            case 8: return fetchPressure();
            case 9: return cachedBattery.toString() + "%";
            case 10: return fetchRespRate();
            case 11: return fetchVO2Max();
            case 12: return fetchReadiness();
            case 13: return fetchHRV();
            case 14: return fetchSleep();
            case 15: return fetchRecoveryTime();
        }
        return "--";
    }

    // Get the icon glyph for a tier2 item
    function getTier2Icon(idx as Number) as String {
        if (idx >= 0 && idx < TIER2_ICONS.size()) {
            return (TIER2_ICONS as Array<String>)[idx];
        }
        return "\u25CF";
    }

    // ── Data Fetch ──

    function fetchBattery() as Number {
        var stats = System.getSystemStats();
        cachedBattery = stats.battery.toNumber();
        return cachedBattery;
    }

    function fetchSteps() as Void {
        var info = ActivityMonitor.getInfo();
        cachedSteps = info.steps != null ? info.steps as Number : 0;
    }

    function fetchHeartRate() as Number {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            cachedHR = info.currentHeartRate as Number;
        }
        return cachedHR;
    }

    function fetchStress() as Number {
        try {
            var iter = SensorHistory.getStressHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    cachedStress = sample.data.toNumber();
                }
            }
        } catch (e) {}
        return cachedStress;
    }

    function fetchSpO2() as Number {
        try {
            var iter = SensorHistory.getOxygenSaturationHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    cachedSpO2 = sample.data.toNumber();
                }
            }
        } catch (e) {}
        return cachedSpO2;
    }

    // ── Tier 2 Fetch Functions (short format for grid) ──

    function fetchBodyBattery() as String {
        try {
            var iter = SensorHistory.getBodyBatteryHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber().toString() + "%";
                }
            }
        } catch (e) {}
        return "--%";
    }

    function fetchCalories() as String {
        var info = ActivityMonitor.getInfo();
        if (info.calories != null) {
            return formatCompact(info.calories as Number);
        }
        return "--";
    }

    function fetchFloors() as String {
        var info = ActivityMonitor.getInfo();
        if (info.floorsClimbed != null) {
            return (info.floorsClimbed as Number).toString();
        }
        return "--";
    }

    function fetchDistance() as String {
        var info = ActivityMonitor.getInfo();
        if (info.distance != null) {
            var km = (info.distance as Number).toFloat() / 100000.0;
            return km.format("%.1f");
        }
        return "--";
    }

    function fetchActiveMinutes() as String {
        try {
            var info = ActivityMonitor.getInfo();
            if (info.activeMinutesDay != null) {
                var mins = info.activeMinutesDay;
                if (mins.total != null) {
                    return (mins.total as Number).toString();
                }
            }
        } catch (e) {}
        return "--";
    }

    function fetchAltitude() as String {
        try {
            var iter = SensorHistory.getElevationHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber().toString() + "M";
                }
            }
        } catch (e) {}
        return "--M";
    }

    // Recalculate sunrise/sunset every 15 minutes, cache location + results
    function updateSunTimes() as Void {
        var clockTime = System.getClockTime();
        var currentMin = clockTime.hour * 60 + clockTime.min;

        // Skip recalc if we already have values and it's been < 15 min
        if (lastSunCalcMin >= 0 && !cachedSunrise.equals("--:--")) {
            var diff = currentMin - lastSunCalcMin;
            if (diff < 0) { diff += 1440; } // handle midnight wrap
            if (diff < 15) { return; }
        }

        try {
            var loc = null as Position.Location or Null;

            // Try weather conditions for location
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.observationLocationPosition != null) {
                loc = cond.observationLocationPosition;
                cachedSunLoc = loc;
            } else if (cachedSunLoc != null) {
                // Reuse last known location if weather is temporarily unavailable
                loc = cachedSunLoc;
            }

            // Fallback: try last known GPS position from activity
            if (loc == null) {
                var actInfo = Activity.getActivityInfo();
                if (actInfo != null && actInfo.currentLocation != null) {
                    loc = actInfo.currentLocation;
                    cachedSunLoc = loc;
                }
            }

            if (loc != null) {
                var now = Time.now();
                var rise = Weather.getSunrise(loc, now);
                if (rise != null) {
                    var rInfo = Gregorian.info(rise, Time.FORMAT_SHORT);
                    cachedSunrise = (rInfo.hour as Number).format("%02d") + ":" + (rInfo.min as Number).format("%02d");
                }
                var setMoment = Weather.getSunset(loc, now);
                if (setMoment != null) {
                    var sInfo = Gregorian.info(setMoment, Time.FORMAT_SHORT);
                    cachedSunset = (sInfo.hour as Number).format("%02d") + ":" + (sInfo.min as Number).format("%02d");
                }
                lastSunCalcMin = currentMin;
            }
        } catch (e) {}
    }

    function fetchSunrise() as String {
        updateSunTimes();
        return cachedSunrise;
    }

    function fetchSunset() as String {
        updateSunTimes();
        return cachedSunset;
    }

    function fetchWeather() as String {
        try {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                return cond.temperature.toNumber().toString() + "C";
            }
        } catch (e) {}
        return "--C";
    }

    function fetchPressure() as String {
        try {
            var iter = SensorHistory.getPressureHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    var hpa = (sample.data.toFloat() / 100.0).toNumber();
                    return hpa.toString();
                }
            }
        } catch (e) {}
        return "--";
    }

    function fetchTemperature() as String {
        try {
            var iter = SensorHistory.getTemperatureHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber().toString() + "C";
                }
            }
        } catch (e) {}
        return "--C";
    }

    function fetchRespRate() as String {
        try {
            var info = ActivityMonitor.getInfo();
            if (info has :respirationRate && info.respirationRate != null) {
                return (info.respirationRate as Number).toString();
            }
        } catch (e) {}
        return "--";
    }

    function fetchVO2Max() as String {
        try {
            // Try UserProfile first (where VO2 max is stored on some devices)
            var profile = UserProfile.getProfile();
            if (profile != null && profile has :vo2maxRunning && profile.vo2maxRunning != null) {
                return (profile.vo2maxRunning as Number).toString();
            }

            // Fall back to ActivityMonitor
            var info = ActivityMonitor.getInfo();
            if (info has :vo2maxRunning && info.vo2maxRunning != null) {
                return (info.vo2maxRunning as Number).toString();
            }
        } catch (e) {}
        return "--";
    }

    function fetchReadiness() as String {
        return "--";
    }

    function fetchHRV() as String {
        return "--";
    }

    function fetchSleep() as String {
        return "--";
    }

    function fetchRecoveryTime() as String {
        try {
            var info = ActivityMonitor.getInfo();
            if (info has :timeToRecovery && info.timeToRecovery != null) {
                return (info.timeToRecovery as Number).toString() + "H";
            }
        } catch (e) {}
        return "--H";
    }

    // ── Helpers ──

    function formatNumber(n as Number) as String {
        if (n >= 1000) {
            var thousands = n / 1000;
            var remainder = (n % 1000);
            return thousands.toString() + "," + remainder.format("%03d");
        }
        return n.toString();
    }

    // Compact format: 1234 -> "1.2K", 12345 -> "12.3K"
    function formatCompact(n as Number) as String {
        if (n >= 1000) {
            var k = n.toFloat() / 1000.0;
            return k.format("%.1f") + "K";
        }
        return n.toString();
    }

    function getHrZoneColor(hr as Number) as Number {
        if (hr <= 0) { return getColor(CLR_DIM); }
        if (hr < 100) { return getColor(CLR_DIM); }
        if (hr < 140) { return getColor(CLR_PRIMARY); }
        if (hr < 160) { return getColor(CLR_WARNING); }
        return getColor(CLR_CRITICAL);
    }
}
