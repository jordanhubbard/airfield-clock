import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Time;
import Toybox.WatchUi;

class AirfieldClockApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        if (Storage.getValue("homeAirport") == null) {
            // Preserve existing installations that already selected a different
            // display airport; KPAO is the initial home airport.
            Storage.setValue("homeAirport", "KPAO");
        }
        if (Storage.getValue("airport") == null) {
            Storage.setValue("airport", Storage.getValue("homeAirport"));
        }
        if (Background.getTemporalEventRegisteredTime() == null ||
            Storage.getValue("metar") == null) {
            // Retry promptly after installation, app updates, and failed fetches.
            var next = Time.now();
            var last = Background.getLastTemporalEventTime();
            if (last != null && last.add(new Time.Duration(5 * 60)).value() > next.value()) {
                next = last.add(new Time.Duration(5 * 60));
            }
            Background.registerForTemporalEvent(next);
        }
    }

    function getInitialView() {
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
