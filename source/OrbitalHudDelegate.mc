import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class OrbitalHudDelegate extends WatchUi.WatchFaceDelegate {

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var screenW = System.getDeviceSettings().screenWidth;
        // Tap on right 40% of screen advances cycling strip
        if (x > screenW * 0.6) {
            DataManager.advanceTier2();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onPowerBudgetExceeded(powerInfo as WatchUi.WatchFacePowerInfo) as Void {
        // Disable partial updates if power budget exceeded
    }
}
