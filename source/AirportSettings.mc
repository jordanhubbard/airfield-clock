import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class AirportSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => "Airports"});
        var home = Storage.getValue("homeAirport");
        if (home == null) { home = "KPAO"; }
        var current = Storage.getValue("airport");
        if (current == null) { current = home; }
        addItem(new WatchUi.MenuItem("Show home airport", home, :home_show, null));
        addItem(new WatchUi.MenuItem("Set home ICAO", home, :home_enter, null));
        addItem(new WatchUi.MenuItem("Show another ICAO", current, :display_enter, null));
        addItem(new WatchUi.MenuItem("Nearby reporting airport", null, :nearby, null));
        addItem(new WatchUi.MenuItem("KPAO  Palo Alto", null, "KPAO", null));
        addItem(new WatchUi.MenuItem("KSQL  San Carlos", null, "KSQL", null));
        addItem(new WatchUi.MenuItem("KSJC  San Jose", null, "KSJC", null));
        addItem(new WatchUi.MenuItem("KOAK  Oakland", null, "KOAK", null));
    }
}

class AirportSettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        if (id == :home_enter) {
            var home = Storage.getValue("homeAirport");
            WatchUi.pushView(new WatchUi.TextPicker(home == null ? "KPAO" : home),
                             new AirportTextDelegate(true), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :display_enter) {
            var current = Storage.getValue("airport");
            WatchUi.pushView(new WatchUi.TextPicker(current == null ? "KPAO" : current),
                             new AirportTextDelegate(false), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :home_show) {
            var home = Storage.getValue("homeAirport");
            setAirport(home == null ? "KPAO" : home);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :nearby) {
            Storage.setValue("airportMode", "nearby");
            Storage.deleteValue("metar");
            Storage.setValue("metarStatus", "WAIT LOCATION");
            scheduleWeatherSoon();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id instanceof String) {
            setAirport(id);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

class AirportTextDelegate extends WatchUi.TextPickerDelegate {
    var _editingHome;

    function initialize(editingHome) {
        TextPickerDelegate.initialize();
        _editingHome = editingHome;
    }

    function onTextEntered(text, changed) {
        var code = text.toUpper();
        // ICAO aerodrome identifiers are four alphanumeric characters.
        if (isValidAirportCode(code)) {
            if (_editingHome) { setHomeAirport(code); }
            else { setAirport(code); }
            // TextPicker closes itself after the delegate accepts the text;
            // close the underlying settings menu to show the updated face.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function onCancel() { return true; }
}

function setHomeAirport(code) {
    var oldHome = Storage.getValue("homeAirport");
    if (oldHome == null) { oldHome = "KPAO"; }
    if (!code.equals(oldHome)) {
        Storage.setValue("homeAirport", code);
        // Keep the home airport on screen when it was already selected.
        var current = Storage.getValue("airport");
        if (current instanceof String && current.equals(oldHome)) { setAirport(code); }
    }
}

function isValidAirportCode(code) {
    if (!(code instanceof String) || code.length() != 4) { return false; }
    for (var i = 0; i < code.length(); i += 1) {
        var c = code.substring(i, i + 1);
        if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".find(c) == null) {
            return false;
        }
    }
    return true;
}

function setAirport(code) {
    if (!isValidAirportCode(code)) { return; }
    code = code.toUpper();
    Storage.setValue("airportMode", "selected");
    var current = Storage.getValue("airport");
    if (!(current instanceof String) || !code.equals(current)) {
        Storage.setValue("airport", code);
        Storage.deleteValue("metar");
    }
    Storage.setValue("metarStatus", "WAIT FETCH");
    scheduleWeatherSoon();
}

function scheduleWeatherSoon() {
    try {
        var next = Time.now().add(new Time.Duration(6 * 60));
        // A Duration keeps the initial retry alive if one wake is missed.
        // The service replaces it with its normal 30-minute interval.
        Background.registerForTemporalEvent(new Time.Duration(6 * 60));
        Storage.setValue("weatherScheduledEpoch", next.value());
        Storage.setValue("weatherScheduleVersion", 3);
        return true;
    } catch (e) {
        Storage.setValue("metarStatus", "SCHEDULE ERROR");
        return false;
    }
}

function ensureWeatherRetry() {
    var status = Storage.getValue("metarStatus");
    if (!(status instanceof String) ||
        (!status.equals("WAIT FETCH") && !status.equals("TIMER RETRY") &&
         !status.equals("SCHEDULE ERROR"))) { return; }
    var scheduled = Storage.getValue("weatherScheduledEpoch");
    if (!(scheduled instanceof Number) ||
        Time.now().value() > scheduled + 2 * 60) {
        if (scheduleWeatherSoon()) {
            Storage.setValue("metarStatus", "TIMER RETRY");
        }
    }
}
