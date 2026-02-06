import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class OrbitalHudDelegate extends WatchUi.WatchFaceDelegate {

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var y = coords[1];
        var screenH = System.getDeviceSettings().screenHeight;
        // Tap on bottom half advances tier2 page
        if (y > screenH / 2) {
            DataManager.advanceTier2();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onPowerBudgetExceeded(powerInfo as WatchUi.WatchFacePowerInfo) as Void {
    }
}
