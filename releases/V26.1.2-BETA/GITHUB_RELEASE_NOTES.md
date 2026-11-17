# GIB2A VS V26.1.2-BETA

This pre-release introduces **GIB2A VS — Advanced VSpeak Turbine Telemetry Dashboard for FrSky ETHOS**.

## Main features

- Pilot-readable RPM, EGT, remaining fuel, pump and ECU-status dashboard
- Manual and protected assignment of VSpeak telemetry sources
- Twelve VSpeak ECU status decoders
- Pump PW handling for KingTech and Xicoy/Kolibri without an OpenTX scaling conversion
- Pump Voltage display for the other ECU selections
- Configurable RPM, EGT, pump and fuel scales
- Configurable remaining-fuel alert and audio file
- Optional throttle, airspeed, chrono, RX voltage and dual-band RSSI display
- Standard, high-contrast and amber GIB2A themes
- Responsive local layouts for 800×480, 640×360, 480×320 and 480×272 widget areas

## VSpeak telemetry roles

The widget supports manual selection of RPM, Tmp1 EGT, Tmp2 ECU status, Fuel remaining volume, A3 ECU battery, A4 Pump, Thro, ASpd and chrono sources. RX voltage and RSSI sources are optional.

## Installation

- Use `GIB2A-VS-v26.1.2-BETA-ETHOS-Suite.zip` with ETHOS Suite > Lua Library > Install from local .zip.
- Use `GIB2A-VS-v26.1.2-BETA-SD.zip` for manual extraction at the SD-card root.
- Verify both packages against `SHA256SUMS.txt`.

## Compatibility and limitations

The widget targets the public FrSky ETHOS Lua APIs used by ETHOS 1.6.x and ETHOS 26.1.x. Local regression and package-structure checks passed. ETHOS Suite installation, Lua compilation, target-radio rendering, persistence and real VSpeak/ECU telemetry remain external validation gates.

The actual ETHOS A4 scale for KingTech and Xicoy/Kolibri must be confirmed on the intended radio and hardware. No manufacturer certification or universal hardware compatibility is claimed.

## Safety

GIB2A VS is telemetry-only. It provides no turbine start, stop, restart, prime, throttle, receiver, servo, failsafe or direct pump control. Verify all telemetry sources and values before flight.
