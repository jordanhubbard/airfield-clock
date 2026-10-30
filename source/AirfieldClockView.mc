import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class AirfieldClockView extends WatchUi.WatchFace {
    var _sleep = false;
    var _timeFont;
    var _utcFont;
    var _badgeFont;
    var _labelFont;

    function initialize() {
        WatchFace.initialize();
        _timeFont = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 94});
        _utcFont = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 38});
        _badgeFont = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 25});
        _labelFont = Graphics.getVectorFont({:face => "RobotoRegular", :size => 20});
        if (_timeFont == null) { _timeFont = Graphics.FONT_NUMBER_HOT; }
        if (_utcFont == null) { _utcFont = Graphics.FONT_MEDIUM; }
        if (_badgeFont == null) { _badgeFont = Graphics.FONT_SMALL; }
        if (_labelFont == null) { _labelFont = Graphics.FONT_XTINY; }
    }

    function onEnterSleep() {
        _sleep = true;
    }

    function onExitSleep() {
        _sleep = false;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var scale = w / 454.0;
        dc.setAntiAlias(true);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        drawCompassRing(dc, cx, h / 2, scale, _labelFont);

        var local = System.getClockTime();
        var utc = Gregorian.utcInfo(Time.now(), Time.FORMAT_SHORT);
        var localText = pad(local.hour) + ":" + pad(local.min);
        var utcText = pad(utc.hour) + ":" + pad(utc.min) + "Z";

        if (_sleep) {
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 2 - 58 * scale, _timeFont,
                        localText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(0x4EA9B7, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 2 + 35 * scale, _labelFont,
                        "UTC " + utcText, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        updateNearbyPosition();

        var airport = Storage.getValue("airport");
        if (airport == null) { airport = "KPAO"; }
        var nearby = Storage.getValue("airportMode") == "nearby";
        var home = Storage.getValue("homeAirport");
        if (home == null) { home = "KPAO"; }
        var weather = Storage.getValue("metar");
        if (!(weather instanceof Dictionary)) { weather = null; }
        if (weather != null && weather["airport"] != airport) { weather = null; }
        var stale = false;
        if (weather != null) {
            var observedEpoch = weather["observedEpoch"];
            if (!(observedEpoch instanceof Number) ||
                Time.now().value() - observedEpoch > 2 * 60 * 60 ||
                observedEpoch - Time.now().value() > 10 * 60) {
                stale = true;
            }
        }

        dc.setColor(0x56CAD7, Graphics.COLOR_TRANSPARENT);
        var airportLabel;
        if (nearby) {
            airportLabel = weather == null ? "NEARBY  /  SEARCHING" : "NEARBY  /  " + airport;
        } else {
            airportLabel = airport == home ? "HOME  /  " + airport : "AIRFIELD  /  " + airport;
        }
        dc.drawText(cx, 77 * scale, _labelFont, airportLabel,
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x93AEB5, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 115 * scale, _labelFont, "LOCAL TIME",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 140 * scale, _timeFont, localText,
                    Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0x17333D, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(101 * scale, 239 * scale, 252 * scale, 52 * scale, 16 * scale);
        dc.setColor(0x58D5E0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 242 * scale, _utcFont, "UTC  " + utcText,
                    Graphics.TEXT_JUSTIFY_CENTER);

        var category = "--";
        var direction = "---";
        var speed = "-- KT";
        var temp = "-- C";
        var altim = "---- HPA";
        var observed = "METAR PENDING";
        if (weather != null && !stale) {
            if (weather["category"] != null) { category = weather["category"]; }
            var windDirection = weather["windDir"];
            var windSpeed = weather["windSpeed"];
            if (windSpeed instanceof Number) {
                if (windSpeed == 0) {
                    direction = "CALM";
                    speed = "0 KT";
                } else {
                    if (windDirection instanceof Number) { direction = pad3(windDirection) + "°"; }
                    else { direction = "VRB"; }
                    speed = windSpeed.toString() + " KT";
                    var gust = weather["windGust"];
                    if (gust instanceof Number && gust > windSpeed) {
                        speed = windSpeed.toString() + "G" + gust.toString();
                    }
                }
            }
            if (weather["temp"] != null) { temp = weather["temp"].toString() + " C"; }
            if (weather["altim"] != null) {
                altim = weather["altim"].toNumber().toString() + " HPA";
            }
            var observation = weather["observed"];
            if (observation instanceof String && observation.length() >= 16) {
                observed = "METAR " + observation.substring(11, 16) + "Z";
            }
        } else if (stale) {
            observed = "METAR STALE";
        } else {
            var status = Storage.getValue("metarStatus");
            if (status instanceof String && status != "OK") {
                var started = Storage.getValue("fetchEpoch");
                if (status == "FETCHING" && started instanceof Number &&
                    Time.now().value() - started > 3 * 60) {
                    observed = "METAR TIMEOUT";
                } else {
                    observed = "METAR " + status;
                }
            }
        }

        dc.setColor(0x8EAAB0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 298 * scale, _labelFont, "FIELD CONDITIONS  /  WIND FROM",
                    Graphics.TEXT_JUSTIFY_CENTER);
        drawBadge(dc, 72 * scale, 322 * scale, 100 * scale, category,
                  categoryColor(category), _badgeFont, scale);
        drawBadge(dc, 179 * scale, 322 * scale, 100 * scale, direction,
                  0x183746, _badgeFont, scale);
        drawBadge(dc, 286 * scale, 322 * scale, 100 * scale, speed,
                  0x183746, _badgeFont, scale);

        dc.setColor(0xACBFC3, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 364 * scale, _labelFont, temp + "   /   " + altim,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x637F87, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 389 * scale, Graphics.FONT_XTINY, observed,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    function updateNearbyPosition() {
        if (Storage.getValue("airportMode") != "nearby") { return; }
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions == null || conditions.observationLocationPosition == null) { return; }
            var coordinates = conditions.observationLocationPosition.toDegrees();
            var oldLat = Storage.getValue("nearbyLat");
            var oldLon = Storage.getValue("nearbyLon");
            if (oldLat == null || oldLon == null ||
                Math.abs(coordinates[0] - oldLat) > 0.15 ||
                Math.abs(coordinates[1] - oldLon) > 0.15) {
                Storage.setValue("nearbyLat", coordinates[0]);
                Storage.setValue("nearbyLon", coordinates[1]);
                Storage.deleteValue("metar");
                Storage.setValue("metarStatus", "WAIT FETCH");
                scheduleWeatherSoon();
            }
        } catch (e) {
            Storage.setValue("metarStatus", "WAIT LOCATION");
        }
    }
}

function drawCompassRing(dc, cx, cy, scale, font) {
    // Fixed north-up scale. Connect IQ watch faces cannot read the compass
    // sensor, so this is a reference ring rather than a heading indicator.
    dc.setPenWidth(2);
    dc.setColor(0x294A52, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(cx, cy, 215 * scale);
    for (var i = 0; i < 24; i += 1) {
        var angle = i * Math.PI / 12.0;
        var dx = Math.sin(angle);
        var dy = -Math.cos(angle);
        var cardinal = i % 6 == 0;
        var major = i % 2 == 0;
        var inner = cardinal ? 190 : (major ? 198 : 205);
        dc.setColor(cardinal ? 0x67D7E1 : (major ? 0x9CB4BB : 0x516C75),
                    Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx + dx * inner * scale, cy + dy * inner * scale,
                    cx + dx * 214 * scale, cy + dy * 214 * scale);
    }
    dc.setColor(0x67D7E1, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx, cy - 202 * scale, font, "N", Graphics.TEXT_JUSTIFY_CENTER);
    dc.setColor(0xB4C8CD, Graphics.COLOR_TRANSPARENT);
    dc.drawText(cx + 186 * scale, cy - 12 * scale, font, "E", Graphics.TEXT_JUSTIFY_CENTER);
    dc.drawText(cx, cy + 188 * scale, font, "S", Graphics.TEXT_JUSTIFY_CENTER);
    dc.drawText(cx - 186 * scale, cy - 12 * scale, font, "W", Graphics.TEXT_JUSTIFY_CENTER);
}

function drawBadge(dc, x, y, width, label, background, font, scale) {
    dc.setColor(background, Graphics.COLOR_TRANSPARENT);
    dc.fillRoundedRectangle(x, y, width, 38 * scale, 11 * scale);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x + width / 2, y + 5 * scale, font, label, Graphics.TEXT_JUSTIFY_CENTER);
}

function pad(value) {
    return value < 10 ? "0" + value.toString() : value.toString();
}

function pad3(value) {
    if (value < 10) { return "00" + value.toString(); }
    if (value < 100) { return "0" + value.toString(); }
    return value.toString();
}

function categoryColor(category) {
    if (category == "VFR") { return 0x168C56; }
    if (category == "MVFR") { return 0x246FBA; }
    if (category == "IFR") { return 0xB33A3A; }
    if (category == "LIFR") { return 0x804B9E; }
    return 0x3B5056;
}
