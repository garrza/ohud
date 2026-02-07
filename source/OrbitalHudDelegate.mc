import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class OrbitalHudDelegate extends WatchUi.WatchFaceDelegate {

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        return false;
    }

    function onPowerBudgetExceeded(powerInfo as WatchUi.WatchFacePowerInfo) as Void {
    }
}
