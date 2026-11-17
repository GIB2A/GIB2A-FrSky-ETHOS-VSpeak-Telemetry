# GIB2A VS — Compatibility

## Software scope

GIB2A VS uses the public FrSky ETHOS Lua widget APIs and is designed around the ETHOS `create`, `wakeup`, `paint`, `configure`, `read` and `write` callbacks.

- Intended baseline: ETHOS 1.6.x
- ETHOS 26.1.0-RC3 and 26.1.x compatibility is targeted when the required public APIs are available
- Local layout checks: 800×480, 640×360, 480×320 and 480×272 widget areas

Local structural and regression tests do not constitute validation on every ETHOS radio or firmware release.

## VSpeak ECU status coverage

The widget contains status tables for Jakadofsky, evoJet, PBS, HORNET, JetCat, KingTech, AMT, Xicoy/Kolibri, JetCentral, Kolibri-NG, Swiwin and Linton.

These tables provide decoding coverage only. Source availability, units and scaling depend on the connected ECU, VSpeak converter, receiver, ETHOS firmware and telemetry discovery.

## Known validation limits

- ETHOS Suite installation must be confirmed with the application.
- Lua compilation must be confirmed in an appropriate Lua/ETHOS environment.
- Target-radio rendering, persistence and alarms require radio validation.
- Real A4 Pump PW/Voltage scaling for KingTech and Xicoy/Kolibri requires measurement on the intended hardware.
- No manufacturer certification is claimed.

## Safety

The widget is telemetry-only. It does not send turbine start/stop, pump, receiver, servo, throttle, restart or failsafe commands.
