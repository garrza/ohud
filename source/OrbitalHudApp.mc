import Toybox.Application;
import Toybox.WatchUi;

class OrbitalHudApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as Array<Views or InputDelegates>? {
        DataManager.loadSettings();
        return [new OrbitalHudView(), new OrbitalHudDelegate()] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() as Void {
        DataManager.loadSettings();
        WatchUi.requestUpdate();
    }
}
