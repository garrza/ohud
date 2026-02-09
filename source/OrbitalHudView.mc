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
    private var _loadedThemeId as Number = -1;

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

    // ── Planet animation (60 frames, one per second) ──
    private var _planet as Array<Graphics.BitmapType> = [] as Array<Graphics.BitmapType>;

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

        // Load planet frames for current theme
        loadPlanetFrames();

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

    // ── Load planet frames for current theme (6 theme variants × 60 frames) ──
    private function loadPlanetFrames() as Void {
        var t = DataManager.themeId;
        if (t == _loadedThemeId) { return; }
        switch (t) {
            case 0:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT0_60) as Graphics.BitmapType
                ];
                break;
            case 1:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT1_60) as Graphics.BitmapType
                ];
                break;
            case 2:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT2_60) as Graphics.BitmapType
                ];
                break;
            case 3:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT3_60) as Graphics.BitmapType
                ];
                break;
            case 4:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT4_60) as Graphics.BitmapType
                ];
                break;
            default:
                _planet = [
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_01) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_02) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_03) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_04) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_05) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_06) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_07) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_08) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_09) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_10) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_11) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_12) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_13) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_14) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_15) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_16) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_17) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_18) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_19) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_20) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_21) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_22) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_23) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_24) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_25) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_26) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_27) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_28) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_29) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_30) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_31) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_32) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_33) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_34) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_35) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_36) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_37) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_38) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_39) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_40) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_41) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_42) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_43) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_44) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_45) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_46) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_47) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_48) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_49) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_50) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_51) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_52) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_53) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_54) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_55) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_56) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_57) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_58) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_59) as Graphics.BitmapType,
                    WatchUi.loadResource(Rez.Drawables.PlanetT5_60) as Graphics.BitmapType
                ];
                break;
        }
        _loadedThemeId = t;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Reload planet frames if theme changed
        if (_loadedThemeId != DataManager.themeId) {
            loadPlanetFrames();
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Fetch all sensor data
        DataManager.fetchBattery();
        DataManager.fetchSteps();
        DataManager.fetchHeartRate();
        DataManager.fetchStress();
        DataManager.fetchSpO2();

        if (_isHighPower) {
            DataManager.pushHrSample();
        }

        // Draw back to front
        drawCornerBrackets(dc);
        drawInfoBar(dc);
        drawSeparator(dc, 34);
        drawRow1(dc);
        drawHrSparkline(dc, 35, 61, _w - 70, 5);
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
        var ssCenterX = _ssX + _ssW / 2;
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(ssCenterX, _ssY, _dataFont, "SEC", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(ssCenterX, _ssY + _fData - 4, _timeFontSm, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
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

    // ── HR History Sparkline (real data) ──
    private function drawHrSparkline(dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number) as Void {
        var data = DataManager.hrHistory;
        var count = data.size();
        if (count < 2) {
            // No data — draw flat dim line
            dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(x, y + h, x + w, y + h);
            return;
        }

        // Find min/max for normalization
        var minHr = data[0] as Number;
        var maxHr = data[0] as Number;
        for (var i = 1; i < count; i++) {
            var v = data[i] as Number;
            if (v < minHr) { minHr = v; }
            if (v > maxHr) { maxHr = v; }
        }
        var range = maxHr - minHr;
        if (range < 5) { range = 5; } // Avoid flat line for stable HR

        var stepX = w.toFloat() / (count - 1).toFloat();
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < count - 1; i++) {
            var v1 = ((data[i] as Number) - minHr).toFloat() / range.toFloat();
            var v2 = ((data[i + 1] as Number) - minHr).toFloat() / range.toFloat();
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

        var timeDims = dc.getTextDimensions(timeStr, _timeFontLg);
        var timeW = timeDims[0];
        var midY = timeY + _fTimeLg / 2;

        // Seconds: "SEC" label (data font, dim) + number (Silkscreen), balanced with planet
        var gap = 14;
        var secNumH = _fTimeSm;
        var secLblH = _fData;
        var secTotalH = secLblH + secNumH - 4;
        _ssX = _cx + timeW / 2 + gap;
        _ssY = midY - secTotalH / 2;
        _ssW = 40;
        _ssH = secTotalH + 4;

        var ssCenterX = _ssX + _ssW / 2;
        dc.setColor(DataManager.getColor(DataManager.CLR_DIM), Graphics.COLOR_TRANSPARENT);
        dc.drawText(ssCenterX, _ssY, _dataFont, "SEC", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(DataManager.getColor(DataManager.CLR_PRIMARY), Graphics.COLOR_TRANSPARENT);
        dc.drawText(ssCenterX, _ssY + secLblH - 4, _timeFontSm, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);

        // Planet: vertically centered with time, spaced left
        var planetX = _cx - timeW / 2 - gap - 30;
        var planetY = midY - 15;
        var frame = clockTime.sec % 60;
        dc.drawBitmap(planetX, planetY, _planet[frame]);
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
