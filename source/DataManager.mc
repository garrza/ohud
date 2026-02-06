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

module DataManager {

    // ── Settings ──
    var dateFormat as Number = 0;          // 0=stardate, 1=standard
    var cycleInterval as Number = 10;      // seconds
    var themeId as Number = 0;             // 0=deep space, 1=phosphor, 2=white

    // ── Theme Color Arrays ──
    // Index: [primary, secondary, tertiary, warning, critical, dim, textSecondary]
    const THEME_COLORS = [
        // Deep Space
        [0x00FFFF, 0xAA55FF, 0x00FF55, 0xFFAA00, 0xFF0000, 0x555555, 0xAAAAAA],
        // Phosphor Green
        [0x00FF00, 0x00AA55, 0x55FF00, 0xFFAA00, 0xFF0000, 0x555555, 0xAAAAAA],
        // White Minimal
        [0xFFFFFF, 0xAAAAAA, 0xFFFFFF, 0xFFAA00, 0xFF0000, 0x555555, 0x555555],
    ];

    const CLR_PRIMARY = 0;
    const CLR_SECONDARY = 1;
    const CLR_TERTIARY = 2;
    const CLR_WARNING = 3;
    const CLR_CRITICAL = 4;
    const CLR_DIM = 5;
    const CLR_TEXT_SEC = 6;

    // ── Tier 2 Cycling ──
    // All possible tier2 slot keys, in order
    const TIER2_KEYS = [
        "ShowReserve", "ShowBurn", "ShowElev", "ShowRange", "ShowActive",
        "ShowAlt", "ShowSol", "ShowAtmo", "ShowPress", "ShowTemp"
    ];
    const TIER2_LABELS = [
        "RESERVE", "BURN", "ELEV", "RANGE", "ACTIVE",
        "ALT", "SOL", "ATMO", "PRESS", "TEMP"
    ];

    var tier2EnabledIndices as Array<Number> = [];  // indices into TIER2_KEYS that are enabled
    var tier2Current as Number = 0;                 // index into tier2EnabledIndices
    var tier2Counter as Number = 0;                 // seconds counter for cycling

    // ── Cached Data ──
    var cachedBattery as Number = 0;
    var cachedSteps as Number = 0;
    var cachedStepGoal as Number = 10000;
    var cachedHR as Number = 0;
    var cachedStress as Number = 0;
    var cachedSpO2 as Number = 0;

    // ── ECG Sparkline ──
    // Synthetic ECG waveform pattern (20 points, normalized 0-1)
    const ECG_PATTERN = [
        0.1, 0.1, 0.12, 0.1, 0.15, 0.1, 0.08,
        0.1, 0.3, 0.9, 0.2, 0.05, 0.15, 0.25,
        0.2, 0.12, 0.1, 0.1, 0.1, 0.1
    ];
    var ecgOffset as Number = 0;  // animation offset for high power

    function loadSettings() as Void {
        var app = Application.getApp();
        var df = app.getProperty("DateFormat");
        dateFormat = (df != null) ? (df as Number) : 0;
        var ci = app.getProperty("CycleInterval");
        cycleInterval = (ci != null) ? (ci as Number) : 10;
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
            // Always show at least RESERVE
            tier2EnabledIndices.add(0);
        }
        if (tier2Current >= tier2EnabledIndices.size()) {
            tier2Current = 0;
        }
    }

    function getColor(role as Number) as Number {
        var t = themeId;
        if (t < 0 || t > 2) { t = 0; }
        return (THEME_COLORS[t] as Array<Number>)[role];
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
        cachedStepGoal = info.stepGoal != null ? info.stepGoal as Number : 10000;
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
        } catch (e) {
            // SensorHistory may not be available
        }
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
        } catch (e) {
            // SensorHistory may not be available
        }
        return cachedSpO2;
    }

    // ── Tier 2 Data ──

    function advanceTier2() as Void {
        if (tier2EnabledIndices.size() > 0) {
            tier2Current = (tier2Current + 1) % tier2EnabledIndices.size();
            tier2Counter = 0;
        }
    }

    function tickCycle(isHighPower as Boolean) as Void {
        if (tier2EnabledIndices.size() <= 1) { return; }
        if (isHighPower) {
            tier2Counter++;
            if (tier2Counter >= cycleInterval) {
                advanceTier2();
            }
        } else {
            // Low power: advance every onUpdate call (once per minute)
            advanceTier2();
        }
    }

    function getCurrentTier2Index() as Number {
        if (tier2EnabledIndices.size() == 0) { return 0; }
        return tier2EnabledIndices[tier2Current];
    }

    function getCurrentTier2Label() as String {
        var idx = getCurrentTier2Index();
        return TIER2_LABELS[idx];
    }

    function getCurrentTier2Value() as String {
        var idx = getCurrentTier2Index();
        switch (idx) {
            case 0: return fetchBodyBattery();
            case 1: return fetchCalories();
            case 2: return fetchFloors();
            case 3: return fetchDistance();
            case 4: return fetchActiveMinutes();
            case 5: return fetchAltitude();
            case 6: return fetchSunTimes();
            case 7: return fetchWeather();
            case 8: return fetchPressure();
            case 9: return fetchTemperature();
        }
        return "--";
    }

    function getCurrentTier2BarValue() as Float? {
        // Only RESERVE (body battery) shows a bar, 0-100
        var idx = getCurrentTier2Index();
        if (idx == 0) {
            try {
                var iter = SensorHistory.getBodyBatteryHistory({:period => 1});
                if (iter != null) {
                    var sample = iter.next();
                    if (sample != null && sample.data != null) {
                        return sample.data.toFloat() / 100.0;
                    }
                }
            } catch (e) {}
        }
        return null;
    }

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
            return formatNumber(info.calories as Number) + " kcal";
        }
        return "-- kcal";
    }

    function fetchFloors() as String {
        var info = ActivityMonitor.getInfo();
        if (info.floorsClimbed != null) {
            return "^ " + (info.floorsClimbed as Number).toString();
        }
        return "^ --";
    }

    function fetchDistance() as String {
        var info = ActivityMonitor.getInfo();
        if (info.distance != null) {
            // distance is in cm, convert to km
            var km = (info.distance as Number).toFloat() / 100000.0;
            return km.format("%.1f") + " km";
        }
        return "-- km";
    }

    function fetchActiveMinutes() as String {
        try {
            var info = ActivityMonitor.getInfo();
            if (info.activeMinutesDay != null) {
                var mins = info.activeMinutesDay;
                if (mins.total != null) {
                    return (mins.total as Number).toString() + " min";
                }
            }
        } catch (e) {}
        return "-- min";
    }

    function fetchAltitude() as String {
        try {
            var iter = SensorHistory.getElevationHistory({:period => 1});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber().toString() + "m";
                }
            }
        } catch (e) {}
        return "--m";
    }

    function fetchSunTimes() as String {
        try {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.observationLocationPosition != null) {
                var loc = cond.observationLocationPosition;
                var now = Time.now();
                var rise = Weather.getSunrise(loc, now);
                var set_ = Weather.getSunset(loc, now);
                if (rise != null && set_ != null) {
                    var rInfo = Gregorian.info(rise, Time.FORMAT_SHORT);
                    var sInfo = Gregorian.info(set_, Time.FORMAT_SHORT);
                    return Lang.format("^$1$:$2$ v$3$:$4$", [
                        rInfo.hour.format("%02d"), rInfo.min.format("%02d"),
                        sInfo.hour.format("%02d"), sInfo.min.format("%02d")
                    ]);
                }
            }
        } catch (e) {}
        return "^--:-- v--:--";
    }

    function fetchWeather() as String {
        try {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) {
                return (cond.temperature as Number).toString() + "C";
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
                    // Pressure in Pa, convert to hPa
                    var hpa = (sample.data.toFloat() / 100.0).toNumber();
                    return hpa.toString() + " hPa";
                }
            }
        } catch (e) {}
        return "-- hPa";
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

    // ── Helpers ──

    function formatNumber(n as Number) as String {
        if (n >= 1000) {
            var thousands = n / 1000;
            var remainder = (n % 1000);
            return thousands.toString() + "," + remainder.format("%03d");
        }
        return n.toString();
    }

    function getHrZoneColor(hr as Number) as Number {
        // Simple zone estimation based on typical max HR
        if (hr <= 0) { return getColor(CLR_DIM); }
        if (hr < 100) { return getColor(CLR_DIM); }       // resting
        if (hr < 140) { return getColor(CLR_PRIMARY); }    // Z1-2
        if (hr < 160) { return getColor(CLR_WARNING); }    // Z3
        return getColor(CLR_CRITICAL);                      // Z4-5
    }
}
