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
        if (Storage.getValue("homeAirport") == null) {
            // Preserve existing installations that already selected a different
            // display airport; KPAO is the initial home airport.
            Storage.setValue("homeAirport", "KPAO");
        }
        if (Storage.getValue("airport") == null) {
            Storage.setValue("airport", Storage.getValue("homeAirport"));
        }
        if (Background.getTemporalEventRegisteredTime() == null) {
            // Watch faces retain the five-minute temporal-event limit across
            // launches. A six-minute delay is safe even when the last event
            // time is unavailable after an app update or device restart.
            try {
                Background.registerForTemporalEvent(Time.now().add(new Time.Duration(6 * 60)));
                if (Storage.getValue("metar") == null &&
                    Storage.getValue("metarStatus") == null) {
                    Storage.setValue("metarStatus", "WAIT FETCH");
                }
            } catch (e) {
                Storage.setValue("metarStatus", "SCHEDULE ERROR");
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
