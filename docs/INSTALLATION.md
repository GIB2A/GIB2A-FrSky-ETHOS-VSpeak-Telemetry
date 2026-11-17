# GIB2A VS — Installation

## ETHOS Suite

1. Download `GIB2A-VS-v26.1.2-BETA-ETHOS-Suite.zip`.
2. Verify the ZIP against `SHA256SUMS.txt`.
3. In ETHOS Suite, open `Lua Library` > `Install from local .zip`.
4. Select the ZIP without extracting it.
5. Confirm that ETHOS Suite installs the `GIB2AVS` widget folder.
6. Restart the radio and add `GIB2A TURBINE VSPEAK V 26.1.2 BETA` to a view.

The ZIP contains `ethos_lua_manifest.json` and every declared file directly at its root. The manifest installs the files into `RADIO:/scripts/GIB2AVS/`.

## Manual SD installation

1. Download `GIB2A-VS-v26.1.2-BETA-SD.zip`.
2. Verify its SHA-256.
3. Extract it at the SD-card root without adding an enclosing folder.
4. Confirm `SCRIPTS/GIB2AVS/main.lua` and `SCRIPTS/GIB2AVS/gib2a_logo_ethos_180.png`.
5. Restart the radio and add the widget.

## Required configuration and verification

1. Discover telemetry in ETHOS.
2. Select the correct VSpeak ECU family.
3. Assign RPM, Tmp1 EGT, Tmp2 Status, Fuel, A3 ECU Battery and A4 Pump sources.
4. Assign Thro, ASpd, chrono, RX voltage and RSSI sources only when available.
5. Review RPM, EGT, Pump and fuel settings.
6. Configure the fuel-alert sound if required.
7. Verify every displayed value against the ECU and VSpeak system before flight.

The widget is telemetry-only. The actual ETHOS A4 scale for KingTech and Xicoy/Kolibri remains a hardware-validation item; do not infer an OpenTX scaling factor.

See [Configuration](CONFIGURATION.md) and [Compatibility](COMPATIBILITY.md) before flight use.
