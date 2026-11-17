# Changelog

## [26.1.2-BETA] - 2026-11-17

### Added

- First public-preparation build of GIB2A VS for FrSky ETHOS.
- Manual source assignment for VSpeak RPM, EGT, ECU status, remaining fuel, ECU battery, pump, throttle, airspeed and chrono telemetry.
- Twelve VSpeak ECU status tables: Jakadofsky, evoJet, PBS, HORNET, JetCat, KingTech, AMT, Xicoy/Kolibri, JetCentral, Kolibri-NG, Swiwin and Linton.
- Separate Pump PW handling for KingTech and Xicoy/Kolibri while preserving raw ETHOS source values.
- Configurable RPM, EGT, pump and fuel ranges, fuel alert audio and three dashboard themes.
- Optional RX voltage, RSSI 2.4 GHz and RSSI 900 MHz display sources.
- Responsive dashboard layouts for 800×480, 640×360, 480×320 and 480×272 widget areas.

### Safety

- Telemetry-only implementation: no turbine, receiver, servo, throttle or pump control command is provided.

### Validation status

- Local structural and regression tests passed before packaging.
- Lua compilation, ETHOS Suite installation and target-radio/VSpeak hardware validation remain required before flight.
