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

On the D2 Air X15, start at the Airfield Clock time screen and swipe right to left. Open **Watch Face**, scroll to the **Airfield Clock** preview, tap that preview, swipe right to left again, then select **Customize**. The menu title is **Airports**. This is the watch face's own menu, not the watch's general Settings app.

Choose:

- **Show home airport** to return to your saved home airport.
- **Set home ICAO** to change the default from KPAO to a four-character ICAO identifier.
- **Show another ICAO** for a temporary airport without changing home.
- **Nearby reporting airport** to choose the closest reporting station near the watch's cached Garmin Weather observation location. The cached location can lag travel or be unavailable; use a manual ICAO if it does not update.

The face asks the [Aviation Weather Center API](https://aviationweather.gov/data/api/) for METAR data in a Connect IQ background service. It schedules a repeating six-minute event after installation or an airport change. A failed or timed-out fetch keeps that six-minute retry; a successful fetch switches to a 30-minute interval. If an initial event is missed, the face re-registers it when active and shows `METAR TIMER RETRY`. A phone connection with a working Garmin Connect/Connect IQ network path is needed for weather downloads. `METAR NET -104` means the Bluetooth connection to the phone was unavailable when the request ran. A report older than two hours is hidden. The bottom line shows the UTC observation time or a status such as `METAR WAIT LOCATION`, `METAR FETCHING`, `METAR TIMEOUT`, `METAR NET <code>`, or `METAR NO METAR`.

The wind bearing is the direction **from** which the reported wind blows. The perimeter is a fixed north-up reference; Connect IQ watch faces cannot read the compass sensor, so it is not a live heading indicator. Garmin Pilot flight-plan and avionics data are not exposed through a documented public Connect IQ interface for this face. Weather shown here is supplemental and should not be used for flight decisions.

## Build from source

### Dependencies

- [Garmin Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) and **Connect IQ SDK 9.3.0** (the version used for this build). Install the **Venu 4 45 mm / D2 Air X15** device definition through SDK Manager. A newer compatible SDK may work but has not been verified here.
- A personal **4096-bit RSA Garmin developer signing key**. Generate one with the Garmin Monkey C extension's **Generate a Developer Key** command, as described in [Garmin's setup guide](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/). Keep this private key outside the repository. Preserve it if you intend to sign future updates with the same identity.
- Bash for the included build script. The Garmin SDK supplies `monkeyc`; no third-party Monkey C libraries are used.

On macOS, SDK Manager's active SDK is discovered from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`. On other systems, set `GARMIN_SDK_HOME` to the SDK directory (the directory containing `bin/monkeyc`).

```bash
export GARMIN_DEVELOPER_KEY=/absolute/path/to/your/developer_key.der
./scripts/build.sh
```

On systems without the macOS SDK Manager path, set `GARMIN_SDK_HOME=/absolute/path/to/connectiq-sdk` before running the script.

The signed device build is written to `bin/AIRFLD.PRG`. The script targets `venu445mm`, uses `monkey.jungle` and `manifest.xml`, and builds a release binary. `bin/` and developer keys are ignored by Git. To build an optional Connect IQ Store package, run:

```bash
"$GARMIN_SDK_HOME/bin/monkeyc" -f monkey.jungle -o bin/AirfieldClock.iq \
  -d venu445mm -y "$GARMIN_DEVELOPER_KEY" -e -r -w
```

The `.iq` file is **not** the USB installation file. Store publication requires Garmin's separate submission and review process.

## Development status

The SDK 9.3.0 release build compiles for `venu445mm`. In the simulator, the background service retrieved a KPAO METAR and the face displayed VFR, wind, temperature, pressure, and observation time. The Aviation Weather Center also responds to nearby-airport queries. An earlier physical build exposed two bugs: the initial timer could remain at `METAR WAIT FETCH`, and selecting **Set home ICAO** could save the menu ID `home-enter` as an airport, causing `METAR NET 400`. The current source uses a repeating initial timer, rejects invalid airport codes, repairs any previously saved invalid airport to the home airport (KPAO by default), and compares returned station IDs by value. The larger face content and compass ring also come from this source. The corrected METAR path has not yet been verified on the physical watch. If METAR stays blank after installing it, report the airport label and exact bottom-line status.
