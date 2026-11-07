import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:background)
class AirportWeatherService extends System.ServiceDelegate {
    var _nearby = false;
    var _latitude = null;
    var _longitude = null;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        // Keep the next attempt registered even if a request times out.
        Storage.setValue("metarStatus", "STARTED");
        try {
            Background.registerForTemporalEvent(new Time.Duration(30 * 60));
        } catch (e) {
            // Continue this fetch even if the following retry cannot be set.
        }
        _nearby = Storage.getValue("airportMode") == "nearby";
        var url;
        if (_nearby) {
            _latitude = Storage.getValue("nearbyLat");
            _longitude = Storage.getValue("nearbyLon");
            if (!(_latitude instanceof Number || _latitude instanceof Float ||
                  _latitude instanceof Double) ||
                !(_longitude instanceof Number || _longitude instanceof Float ||
                  _longitude instanceof Double)) {
                Storage.setValue("metarStatus", "WAIT LOCATION");
                finish();
                return;
            }
            url = "https://aviationweather.gov/api/data/metar?bbox=" +
                  (_latitude - 0.8).toString() + "," +
                  (_longitude - 1.1).toString() + "," +
                  (_latitude + 0.8).toString() + "," +
                  (_longitude + 1.1).toString() + "&format=geojson";
        } else {
            var airport = Storage.getValue("airport");
            if (airport == null) { airport = "KPAO"; }
            url = "https://aviationweather.gov/api/data/metar?ids=" + airport +
                  "&format=geojson";
        }
        Storage.setValue("metarStatus", "FETCHING");
        Storage.setValue("fetchEpoch", Time.now().value());
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {"User-Agent" => "AirfieldClock/0.2", "Accept" => "application/json"}
        };
        try {
            Communications.makeWebRequest(url, null, options, method(:onWeather));
        } catch (e) {
            Storage.setValue("metarStatus", "REQUEST ERROR");
            finish();
        }
    }

    function onWeather(code as Number, data as Dictionary or String or Null) as Void {
        if (code != 200) {
            Storage.setValue("metarStatus", "NET " + code.toString());
            finish();
            return;
        }
        if (!(data instanceof Dictionary)) {
            Storage.setValue("metarStatus", "BAD RESPONSE");
            finish();
            return;
        }
        var features = data["features"];
        if (!(features instanceof Array) || features.size() == 0) {
            Storage.setValue("metarStatus", "NO METAR");
            finish();
            return;
        }
        var report = null;
        if (_nearby) {
            var best = null;
            var lonScale = Math.cos(_latitude * Math.PI / 180.0);
            for (var i = 0; i < features.size(); i += 1) {
                var feature = features[i];
                if (!(feature instanceof Dictionary)) { continue; }
                var geometry = feature["geometry"];
                var candidate = feature["properties"];
                if (!(geometry instanceof Dictionary) || !(candidate instanceof Dictionary)) { continue; }
                var coordinates = geometry["coordinates"];
                if (!(coordinates instanceof Array) || coordinates.size() < 2 ||
                    !(candidate["id"] instanceof String)) { continue; }
                var dy = coordinates[1] - _latitude;
                var dx = (coordinates[0] - _longitude) * lonScale;
                var distance = dx * dx + dy * dy;
                if (best == null || distance < best) {
                    best = distance;
                    report = candidate;
                }
            }
        } else {
            var target = Storage.getValue("airport");
            if (target == null) { target = "KPAO"; }
            for (var j = 0; j < features.size(); j += 1) {
                var entry = features[j];
                if (!(entry instanceof Dictionary)) { continue; }
                var entryReport = entry["properties"];
                if (entryReport instanceof Dictionary && entryReport["id"] == target) {
                    report = entryReport;
                    break;
                }
            }
        }
        if (report == null) {
            Storage.setValue("metarStatus", "NO METAR");
            finish();
            return;
        }
        var selected = report as Dictionary;
        var airport = selected["id"];
        var observed = selected["obsTime"];
        var observedEpoch = null;
        if (observed instanceof String && observed.length() >= 19) {
            try {
                observedEpoch = Gregorian.moment({
                    :year => observed.substring(0, 4).toNumber(),
                    :month => observed.substring(5, 7).toNumber(),
                    :day => observed.substring(8, 10).toNumber(),
                    :hour => observed.substring(11, 13).toNumber(),
                    :minute => observed.substring(14, 16).toNumber(),
                    :second => observed.substring(17, 19).toNumber()
                }).value();
            } catch (e) {
                observedEpoch = null;
            }
        }
        if (_nearby) { Storage.setValue("airport", airport); }
        Storage.setValue("metar", {
            "airport" => airport,
            "category" => selected["fltcat"],
            "windDir" => selected["wdir"],
            "windSpeed" => selected["wspd"],
            "windGust" => selected["wgst"],
            "temp" => selected["temp"],
            "altim" => selected["altim"],
            "observed" => observed,
            "observedEpoch" => observedEpoch
        });
        Storage.setValue("metarStatus", "OK");
        finish();
    }

    function finish() {
        Background.exit(true);
    }
}
