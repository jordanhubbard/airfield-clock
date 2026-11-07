import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Time;
import Toybox.WatchUi;

class AirfieldClockApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // This runs only for the visible face. onStart also runs in the
        // background process, where registering a new event can prevent the
        // pending service event from reaching onTemporalEvent.
        var home = Storage.getValue("homeAirport");
        if (!isValidAirportCode(home)) {
            home = "KPAO";
            Storage.setValue("homeAirport", home);
        }
        var airport = Storage.getValue("airport");
        var repairedAirport = !isValidAirportCode(airport);
        if (repairedAirport) {
            Storage.setValue("airport", home);
            Storage.setValue("airportMode", "selected");
            Storage.deleteValue("metar");
        }
        if (repairedAirport || Storage.getValue("weatherScheduleVersion") != 3 ||
            Background.getTemporalEventRegisteredTime() == null) {
            // An update can leave a registration from the previous build that
            // is no longer delivered. Replace it once when this version starts.
            if (scheduleWeatherSoon() && Storage.getValue("metar") == null) {
                Storage.setValue("metarStatus", "WAIT FETCH");
            }
        }
        return [new AirfieldClockView()];
    }

    function getSettingsView() {
        return [new AirportSettingsMenu(), new AirportSettingsDelegate()];
    }

    function getServiceDelegate() {
        return [new AirportWeatherService()];
    }

    function onBackgroundData(data) {
        WatchUi.requestUpdate();
    }

    function onStorageChanged() {
        WatchUi.requestUpdate();
    }
}
