# GIB2A VS — Configuration

## Before configuration

1. Install the widget and restart the radio.
2. Connect the receiver, VSpeak converter and ECU according to their manufacturer documentation.
3. Discover telemetry in ETHOS.
4. Confirm that the expected sources are present before opening the widget configuration.

## ECU selection

Select the VSpeak ECU family matching the connected system. The selection determines the `Tmp2` ECU-status table and whether the Pump gauge is interpreted as Pump PW or Pump Voltage.

Pump PW mode is used only for KingTech and Xicoy/Kolibri selections. Other selections use Pump Voltage. The widget does not convert the raw ETHOS A4 value with an OpenTX `×100` factor.

## Telemetry sources

| Widget field | Expected VSpeak role |
| --- | --- |
| RPM Sensor | RPM |
| Tmp1 EGT Sensor | Exhaust gas temperature |
| Tmp2 Status Sensor | Signed ECU status code |
| Fuel Sensor (ml) | Remaining fuel volume |
| A3 ECU Battery | ECU battery voltage |
| A4 Pump Sensor | Pump PW or Pump Voltage according to ECU selection |
| Thro Sensor | Optional ECU throttle |
| ASpd Sensor | Optional airspeed |
| Chrono Source | Optional flight timer |
| RxBatt Source | Optional receiver voltage |
| RSSI Source 1 / 2 | Optional 2.4 GHz and 900 MHz RSSI |

If a saved source is deleted, renamed or temporarily unavailable, the widget protects source access and displays missing data instead of issuing control commands.

## Numeric settings

- RPM Max: 1,000 rpm steps
- EGT Max: 10 °C steps
- Pump PW Max: 10 PW steps
- Pump Voltage Max: 0.1 V steps, stored in volts
- Fuel Tank Capacity: 50 ml steps
- Fuel Alert: 1% steps

Configure the tank capacity before relying on the fuel percentage. Select an audio file if a fuel alert sound is required.

## Final verification

Verify RPM, EGT, status, remaining fuel, battery and pump readings against the ECU/VSpeak system. The A4 scale for each real KingTech or Xicoy/Kolibri installation remains a hardware-validation item. Complete all checks before flight.
