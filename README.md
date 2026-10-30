# Airfield Clock for Garmin D2 Air X15

Airfield Clock is a Connect IQ watch face with central digital local time, UTC, airport METAR conditions, and a fixed compass-style perimeter. KPAO is the initial home airport. You can choose another ICAO airport or use the nearby reporting-airport mode when traveling.

**Device support:** Garmin D2 Air X15, using the Connect IQ `venu445mm` target (Venu 4 45 mm / D2 Air X15). Other models have not been tested.

## Download and install on the watch

1. Download **`AIRFLD.PRG`** from the [latest GitHub release](https://github.com/jordanhubbard/airfield-clock/releases/latest). The `.iq` package is for Connect IQ Store submission; use the `.PRG` file for USB installation.
2. Connect the D2 Air X15 to your computer with a data-capable USB cable. On macOS, use an MTP file manager such as OpenMTP to open the watch's internal storage.
3. Open **`GARMIN/Apps`** on the watch and copy `AIRFLD.PRG` directly into that folder. If an older `AIRFLD.PRG` is present, replace it. Do not put the file in `GARMIN` itself or in the `Apps/DATA`, `Apps/SETTINGS`, or `Apps/TEMP` subfolders.
4. Wait for the copy to finish, then disconnect the watch. The watch should report that Airfield Clock was installed. Select **Airfield Clock** from the watch-face list.

This is a sideloaded build, not a Connect IQ Store listing. The [Garmin sideloading guide](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/) also specifies `GARMIN/APPS` for device `.PRG` files.

## Airport and weather

Open the watch face's **Settings → Airports** menu to choose:

- **Show home airport** to return to your saved home airport.
- **Set home ICAO** to change the default from KPAO to a four-character ICAO identifier.
- **Show another ICAO** for a temporary airport without changing home.
- **Nearby reporting airport** to choose the closest reporting station near the watch's cached Garmin Weather observation location. The cached location can lag travel or be unavailable; use a manual ICAO if it does not update.

The face asks the [Aviation Weather Center API](https://aviationweather.gov/data/api/) for METAR data in a Connect IQ background service. It retries every 30 minutes and may take several minutes after installation or an airport change. A phone connection with a working Garmin Connect/Connect IQ network path is needed for weather downloads. A report older than two hours is hidden. The bottom line shows the UTC observation time or a status such as `METAR WAIT LOCATION`, `METAR FETCHING`, `METAR TIMEOUT`, `METAR NET <code>`, or `METAR NO METAR`.

The wind bearing is the direction **from** which the reported wind blows. The perimeter is a fixed north-up reference; Connect IQ watch faces cannot read the compass sensor, so it is not a live heading indicator. Garmin Pilot flight-plan and avionics data are not exposed through a documented public Connect IQ interface for this face. Weather shown here is supplemental and should not be used for flight decisions.

## Build from source

### Dependencies

- [Garmin Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) and **Connect IQ SDK 9.3.0** (the version used for this build). Install the **Venu 4 45 mm / D2 Air X15** device definition through SDK Manager. A newer compatible SDK may work but has not been verified here.
- A personal **4096-bit RSA Garmin developer signing key**. Generate one with the Garmin Monkey C extension's **Generate a Developer Key** command, as described in [Garmin's setup guide](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/). Keep this private key outside the repository. Preserve it if you intend to sign future updates with the same identity.
- Bash for the included build script. The Garmin SDK supplies `monkeyc`; no third-party Monkey C libraries are used.

On macOS, SDK Manager's active SDK is discovered from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. On other systems, set `GARMIN_SDK_HOME` to the SDK directory (the directory containing `bin/monkeyc`).

```bash
export GARMIN_DEVELOPER_KEY=/absolute/path/to/your/developer_key.der
# On systems without the macOS SDK Manager path:
export GARMIN_SDK_HOME=/absolute/path/to/connectiq-sdk
./scripts/build.sh
```

The signed device build is written to `bin/AIRFLD.PRG`. The script targets `venu445mm`, uses `monkey.jungle` and `manifest.xml`, and builds a release binary. `bin/` and developer keys are ignored by Git. To build an optional Connect IQ Store package, run:

```bash
"$GARMIN_SDK_HOME/bin/monkeyc" -f monkey.jungle -o bin/AirfieldClock.iq \
  -d venu445mm -y "$GARMIN_DEVELOPER_KEY" -e -r -w
```

The `.iq` file is **not** the USB installation file. Store publication requires Garmin's separate submission and review process.

## Development status

The SDK 9.3.0 release build compiles for `venu445mm`, and the Aviation Weather Center currently responds to KPAO and nearby-airport queries. The latest weather-fetch changes have not yet been verified on a physical watch. If METAR stays blank after installing the latest release, report the exact status on the bottom line; it distinguishes a missing location from a request or network failure.
