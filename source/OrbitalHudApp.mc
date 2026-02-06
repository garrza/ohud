import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class OrbitalHudApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        DataManager.loadSettings();
        return [new OrbitalHudView(), new OrbitalHudDelegate()];
    }

    function onSettingsChanged() as Void {
        DataManager.loadSettings();
        WatchUi.requestUpdate();
    }
}
