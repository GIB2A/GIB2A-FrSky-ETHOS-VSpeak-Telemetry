-- GIB2A TURBINE VSPEAK V 26.1.2 BETA
-- Telemetry-only widget for VSpeak S.Port ECU converters on FrSky ETHOS.
-- Manual sensor assignment only. No turbine control function is provided.

---@diagnostic disable: undefined-global

local WIDGET_VERSION = "V 26.1.2 BETA"
local WIDGET_KEY = "GIB2AVS"
local DEFAULT_RPM_MAX = 160000
local DEFAULT_EGT_MAX = 1000
local DEFAULT_TANK_CAPACITY = 3000
local DEFAULT_PUMP_PW_MAX = 500
local DEFAULT_PUMP_VOLTAGE_MAX = 15
local DEFAULT_FUEL_ALERT_PERCENT = 35
local FUEL_ALERT_HYSTERESIS = 2
local FUEL_YELLOW_THRESHOLD = 50
local FUEL_RED_THRESHOLD = 25
local GIB2A_LOGO_PATH = "gib2a_logo_ethos_180.png"
local GIB2A_LOGO_WIDTH = 130
local GIB2A_LOGO_HEIGHT = 57
local GIB2A_LOGO_COMPACT_WIDTH = 90
local GIB2A_LOGO_COMPACT_HEIGHT = 40
local GIB2A_LOGO_SMALL_WIDTH = 55
local GIB2A_LOGO_SMALL_HEIGHT = 24
local gib2aLogo = nil

local audioPath = "/audio"
if system and system.getAudioVoice then
    local okAudioPath, detectedAudioPath = pcall(system.getAudioVoice)
    if okAudioPath and detectedAudioPath then audioPath = detectedAudioPath end
end

local function playConfiguredAudio(fileName)
    if type(fileName) ~= "string" or fileName == "" then return end
    local path = fileName
    if audioPath and string.sub(fileName, 1, 1) ~= "/" then
        path = audioPath .. "/" .. fileName
    end
    if system and system.playFile then system.playFile(path) end
end

local function loadGib2aLogo()
    if gib2aLogo ~= nil then return end
    local ok, bitmap = pcall(function()
        return lcd.loadBitmap(GIB2A_LOGO_PATH)
    end)
    if ok and bitmap then gib2aLogo = bitmap end
end

local PERSISTENCE_PARAMS = {
    { key = "vspeakEcuType", default = 0 },
    { key = "rpmSource", default = nil },
    { key = "egtSource", default = nil },
    { key = "statusSource", default = nil },
    { key = "fuelSource", default = nil },
    { key = "ecuBatterySource", default = nil },
    { key = "pumpSource", default = nil },
    { key = "throttleSource", default = nil },
    { key = "airspeedSource", default = nil },
    { key = "chronoSource", default = nil },
    { key = "rpmMax", default = DEFAULT_RPM_MAX },
    { key = "egtMax", default = DEFAULT_EGT_MAX },
    { key = "tankCapacity", default = DEFAULT_TANK_CAPACITY },
    { key = "pumpPwMax", default = DEFAULT_PUMP_PW_MAX },
    { key = "pumpVoltageMax", default = DEFAULT_PUMP_VOLTAGE_MAX },
    { key = "theme", default = 0 },
    -- Appended so the inherited persistence order remains unchanged.
    { key = "rxbattSource", default = nil },
    { key = "rssi1Source", default = nil },
    { key = "rssi2Source", default = nil },
    { key = "fuelAlertPercent", default = DEFAULT_FUEL_ALERT_PERCENT },
    { key = "fuelAlertFile", default = nil },
}

local VSPEAK_ECU_CHOICES = {
    { "Select VSpeak ECU", 1 }, { "Jakadofsky", 2 }, { "evoJet", 3 },
    { "PBS", 4 }, { "HORNET", 5 }, { "JetCat", 6 },
    { "KingTech", 7 }, { "AMT", 8 }, { "Xicoy / Kolibri", 9 },
    { "JetCentral", 10 }, { "Kolibri-NG", 11 }, { "Swiwin", 12 },
    { "Linton", 13 },
}

-- Exact VSpeak tables from Ref/VS_Horus_LUA(1)/VSpeak_ECU/main.lua.
local VSPEAK_STATUS_JAKADOFSKY = {
    [-30] = " ERROR", [-20] = "TH:-off", [-10] = "TH:cool",
    [-1] = "TH:lock", [0] = "TH:stop", [10] = "TH:run-",
    [20] = "TH:rel-", [25] = "TH:glow", [30] = "TH:spin",
    [40] = "TH:fire", [45] = "TH:ignt", [50] = "TH:heat",
    [60] = "TH:acce", [65] = "TH:cal.", [70] = "TH:idle",
}
local VSPEAK_STATUS_EVOJET = {
    [-30] = " ERROR", [-20] = "TH:-off", [-10] = "TH:cool",
    [-1] = "TH:lock", [0] = "TH:stop", [10] = "TH:run-",
    [20] = "TH:rel-", [25] = "TH:glow", [30] = "TH:spin",
    [40] = "TH:fire", [45] = "TH:ignt", [50] = "TH:heat",
    [60] = "TH:acce", [65] = "TH:cal.", [70] = "TH:idle",
}
local VSPEAK_STATUS_PBS = {
    [-30] = "ERROR", [-10] = "COOL", [-1] = "LOCK", [0] = "STOP",
    [10] = "TH:Idle", [20] = "TH:-Rel", [25] = "TEST",
    [40] = "FIRE", [70] = "IDLE",
}
local VSPEAK_STATUS_HORNET = {
    [-30] = "DEV.DELAY", [-20] = "FLAME OUT", [-10] = "EMERGENCY",
    [0] = "OFF", [1] = "ON", [10] = "Cool Down", [20] = "Slow Down",
    [30] = "STANDBY", [31] = "PROP IGNIT", [32] = "PROP HEAT",
    [33] = "Pump Start", [34] = "BURNER ON", [35] = "FUEL IGNIT",
    [36] = "FUEL HEAT", [37] = "Ramp Delay", [38] = "RAMP UP",
    [40] = "STEADY", [41] = "CAL IDLE", [42] = "CALIBRATE",
    [43] = "WAIT ACC", [44] = "GO IDLE", [50] = "AUTO", [51] = "AUTO HC",
}
local VSPEAK_STATUS_JETCAT = {
    [-40] = "Failure", [-32] = "ECU reboot", [-31] = "ClutchFail",
    [-30] = "Low Rpm", [-29] = "Low Rpm", [-28] = "Out Fuel",
    [-27] = "Pump Comm", [-26] = "WrongPump", [-25] = "No Pump!",
    [-24] = "OverCurr", [-23] = "No-OIL", [-22] = "2nd Comm",
    [-21] = "2nd Diff", [-20] = "2nd EngF", [-19] = "Rpm2Fail",
    [-18] = "FuelFail", [-17] = "TempFail", [-16] = "PowerFail",
    [-15] = "IgnTimOut", [-14] = "FailSafe", [-13] = "WatchDog",
    [-12] = "GlowPlug!", [-11] = "HiTempOff", [-10] = "LowTempOff",
    [-9] = "OverTemp", [-8] = "BattryLow", [-7] = "Low-Rpm",
    [-6] = "Over-Rpm", [-5] = "Acc. Slow", [-4] = "AccTimOut",
    [-3] = "Manual Off", [-2] = "Auto-Off", [-1] = "RC-Off",
    [0] = "-OFF-", [1] = "SlowDown", [2] = "SwitchOff",
    [3] = "Stby/START", [4] = "PreHeat1", [5] = "PreHeat2",
    [6] = "Ignite...", [7] = "AccelrDly", [8] = "MainFStrt",
    [9] = "Keros.Full", [10] = "accelerate", [11] = "Stabilise",
    [12] = "LearnLO", [13] = "RUN (reg.)", [14] = "SpeedCtrl",
    [15] = "Rpm2Ctrl",
}
local VSPEAK_STATUS_KINGTECH = {
    [-20] = "- ERROR -", [-19] = "Unknown", [-13] = "CAB-Lost",
    [-12] = "FlameOut", [-11] = "TempHigh", [-10] = "SpeedLow",
    [-9] = "Failsafe", [-8] = "RxPwFail", [-7] = "Overload",
    [-6] = "Low Batt", [-5] = "StartBad", [-4] = "Weak Gas",
    [-3] = "Time Out", [-2] = "Ign.Fail", [-1] = "Glow Bad",
    [0] = "Trim Low", [1] = "User Off", [2] = "Stop",
    [3] = "Cooling", [4] = "Ready", [5] = "GdReady", [6] = "GlowTest",
    [7] = "StickLo!", [8] = "PrimeVap", [9] = "BurnerOn",
    [10] = "Start On", [11] = "Ignition", [12] = "Stage1",
    [13] = "Stage2", [14] = "Stage3", [20] = "Running", [22] = "ReStart",
}
local VSPEAK_STATUS_AMT = {
    [-20] = "- ERROR -", [-8] = "Supply ASS", [-7] = "Supply low",
    [-6] = "RPM high", [-5] = "EGT error", [-4] = "Throttle fail",
    [-3] = "Switch failure", [-2] = "RPM low", [-1] = "No serial input",
    [0] = "No Start Clear", [1] = "Start Clear", [2] = "Starting",
    [3] = "Started up", [4] = "Calibrated", [5] = "Auto stop",
    [6] = "Running", [7] = "Max. RPM",
}
local VSPEAK_STATUS_XICOY_KOLIBRI = {
    [-14] = "FlameOut", [-13] = "TempHigh", [-12] = "SpeedLow",
    [-11] = "Failsafe", [-10] = "RxPwFail", [-9] = "PumpLimit",
    [-8] = "Overload", [-7] = "Low Batt", [-6] = "StartBad",
    [-5] = "Weak Gas", [-4] = "Time Out", [-3] = "IgntrBaD",
    [-2] = "Glow Bad", [-1] = "Unknown", [0] = "Trim Low",
    [1] = "User Off", [2] = "Stop", [3] = "Cooling", [4] = "Ready",
    [5] = "SetIdle!", [6] = "StickLo!", [7] = "GlowTest",
    [8] = "Starting", [9] = "BurnerOn", [10] = "Start On",
    [11] = "Ignition", [12] = "Pre Heat", [13] = "SwitchOver",
    [14] = "FuelRamp", [20] = "Run-Idle", [21] = "Running",
    [22] = "Run-Max", [23] = "ReStart",
}
local VSPEAK_STATUS_JETCENTRAL = {
    [-21] = "ERROR", [-20] = "- no data -", [-19] = "MaxPump",
    [-18] = "RPMSensorErr", [-17] = "LowRPM", [-16] = "MaxAmpers",
    [-15] = "MaxTemp", [-14] = "ComTurbErr", [-13] = "TempSensErr",
    [-12] = "RxSetupError", [-11] = "Failsafe", [-10] = "NoRx",
    [-9] = "LowECUBatt", [-8] = "LowRXBatt", [-7] = "IgniterBad",
    [-6] = "AcelerateBad", [-5] = "ToIdle Error", [-4] = "StarterError",
    [-3] = "SwitchOverErr", [-2] = "PreheatError", [-1] = "IgnitionError",
    [0] = "OFF", [1] = "ManCooling", [2] = "AutoCooling",
    [6] = "GlowTest", [7] = "StarterTest", [8] = "PrimeFuel",
    [9] = "PrimeBurner", [10] = "Standby", [11] = "Start",
    [12] = "IgniterHeat", [13] = "Ignition", [14] = "Preheat",
    [15] = "Switchover", [16] = "To Idle", [17] = "MinPumpOk",
    [18] = "MaxPumpOk", [19] = "Running", [20] = "Full",
}
local VSPEAK_STATUS_KOLIBRI_NG = {
    [-10] = "FLAME OUT", [-2] = "BATT LOW!", [-1] = "GLOW PLUG!",
    [0] = "OFF", [1] = "ON", [2] = "COOL-DOWN", [3] = "SLOW-DOWN",
    [10] = "STANDBY", [11] = "PROPIGNIT", [12] = "PROP-HEAT",
    [13] = "PUMPSTART", [14] = "FUELHEAT", [15] = "RAMP-UP", [20] = "AUTO",
}
local VSPEAK_STATUS_SWIWIN = {
    [-30] = "no data", [-18] = "Engine Offline", [-17] = "Current overload",
    [-16] = "Clutch failure", [-15] = "Pump Temp High",
    [-14] = "StarterTempHigh", [-13] = "Lost Signal",
    [-12] = "Fuel Valve Bad", [-11] = "Gas Valve Bad",
    [-10] = "TempSensorfail", [-9] = "Low Temp", [-8] = "High Temp",
    [-7] = "RPM Instability", [-6] = "RPM Low", [-5] = "Starter failure",
    [-4] = "Pump Anomaly", [-3] = "GlowPlug Bad", [-2] = "Low Battery",
    [-1] = "Time Out", [0] = "Stop", [1] = "Cooling", [5] = "TestGlowPlug",
    [6] = "TestFuelValve", [7] = "TestGasValve", [8] = "TestPump",
    [9] = "TestStarter", [10] = "Ready", [11] = "Ignition",
    [12] = "Preheat", [13] = "Fuelramp", [20] = "Running", [21] = "Restart",
}
local VSPEAK_STATUS_LINTON = {
    [-40] = "-no data-", [-39] = "Error Alarms", [-38] = "Acc7",
    [-37] = "Acc6", [-36] = "Acc5", [-35] = "Power limit",
    [-34] = "Restart Fail", [-33] = "Acc24", [-32] = "Dec23",
    [-31] = "Acc22", [-30] = "Idle21", [-29] = "Idle Time",
    [-28] = "CTH Time", [-27] = "Pump bubble", [-26] = "Temp5 Pro",
    [-25] = "Temp4 Pro", [-24] = "Temp3 Pro", [-23] = "Temp2 Pro",
    [-22] = "Temp1 Pro", [-21] = "HEGT3", [-20] = "HEGT2",
    [-19] = "HEGT1", [-18] = "Fuel Fail", [-17] = "RPM Low",
    [-16] = "RPM Err", [-15] = "Rc Lost Off", [-14] = "Pump Fail",
    [-13] = "PumpCurrent", [-12] = "Pump Open", [-11] = "CTH Fail",
    [-10] = "MotorCurrent", [-9] = "Motor Open", [-8] = "IGT Short",
    [-7] = "IGT Open", [-6] = "EGT Warn", [-5] = "TT Trans",
    [-4] = "TT Open", [-3] = "OverCurrent", [-2] = "Volt High",
    [-1] = "Volt Low", [0] = "Ready", [1] = "Ready start",
    [2] = "Temp high", [3] = "Start..", [4] = "Burner..", [5] = "Success",
    [6] = "Heating1..", [7] = "Heating2..", [8] = "Heating3..",
    [9] = "Heating4..", [10] = "Heating5..", [11] = "Heating6..",
    [12] = "Pump Acc..", [13] = "CTH..", [14] = "Acc5..",
    [15] = "Acc6..", [16] = "Acc7..", [17] = "Acc8..",
    [18] = "Idling..", [19] = "Acc..", [20] = "Dec..", [21] = "Speed..",
    [22] = "Max Speed..", [23] = "RC Learn", [24] = "RC Learning..",
    [25] = "RC Successful", [26] = "Restart", [27] = "Restart..",
    [28] = "Cooling..", [29] = "Error Status",
}

local VSPEAK_STATUS_TABLES = {
    [1] = VSPEAK_STATUS_JAKADOFSKY, [2] = VSPEAK_STATUS_EVOJET,
    [3] = VSPEAK_STATUS_PBS, [4] = VSPEAK_STATUS_HORNET,
    [5] = VSPEAK_STATUS_JETCAT, [6] = VSPEAK_STATUS_KINGTECH,
    [7] = VSPEAK_STATUS_AMT, [8] = VSPEAK_STATUS_XICOY_KOLIBRI,
    [9] = VSPEAK_STATUS_JETCENTRAL, [10] = VSPEAK_STATUS_KOLIBRI_NG,
    [11] = VSPEAK_STATUS_SWIWIN, [12] = VSPEAK_STATUS_LINTON,
}

local function decodeVSpeakStatus(ecuType, status)
    if type(ecuType) ~= "number" or ecuType ~= math.floor(ecuType)
        or VSPEAK_STATUS_TABLES[ecuType] == nil then
        return "SELECT VSPEAK ECU"
    end
    if type(status) ~= "number" or status ~= status then return "NO DATA" end
    return VSPEAK_STATUS_TABLES[ecuType][status]
        or ("UNKNOWN CODE " .. tostring(status))
end

local function isPumpPwEcu(ecuType)
    return ecuType == 6 or ecuType == 8
end

local function create(zone, options)
    local widget = {
        zone = zone, options = options, _resolvedSources = {}, _sourceUnits = {},
        rpmValue = nil, egtValue = nil, statusValue = nil, fuelValue = nil,
        ecuBatteryValue = nil, pumpValue = nil, throttleValue = nil,
        airspeedValue = nil, chronoValue = nil,
        rxbattValue = nil,
        rssi1Value = nil,
        rssi2Value = nil,
        _tankCapacityConfirmed = false,
        _fuelAlertPreviousPercent = nil,
        _fuelAlertArmed = false,
        _fuelAlertNeedsHysteresis = false,
        _fuelAlertSignature = nil,
    }
    for i = 1, #PERSISTENCE_PARAMS do
        local param = PERSISTENCE_PARAMS[i]
        widget[param.key] = param.default
    end
    return widget
end

local function safeSourceName(source)
    if not source or type(source.name) ~= "function" then return nil end
    local ok, name = pcall(source.name, source)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

local function resolveSource(widget, field)
    local savedSource = widget[field]
    if not savedSource then widget._resolvedSources[field] = nil return nil end
    if widget._resolvedSources[field] == savedSource then return savedSource end
    local source = savedSource
    local name = safeSourceName(savedSource)
    if name and system and system.getSource then
        local ok, currentSource = pcall(system.getSource, name)
        if ok and currentSource and type(currentSource.value) == "function" then
            source = currentSource
            widget[field] = currentSource
        end
    end
    widget._resolvedSources[field] = source
    return source
end

local function readSource(widget, field)
    local source = resolveSource(widget, field)
    if not source or type(source.value) ~= "function" then return nil end
    local ok, value = pcall(source.value, source)
    if ok and type(value) == "number" and value == value then return value end
    return nil
end

local function readSourceUnit(widget, field)
    local source = resolveSource(widget, field)
    if not source or type(source.stringUnit) ~= "function" then return "" end
    local ok, unit = pcall(source.stringUnit, source)
    if ok and type(unit) == "string" then return unit end
    return ""
end

-- Identical system-source reader used by GIB2A TURBINE for RxBatt/RSSI.
local function readSystemSourceValue(src)
    if not src then
        return nil
    end

    local realSrc = src
    if type(src.name) == "function" and system.getSource then
        local okName, name = pcall(src.name, src)
        if okName and type(name) == "string" and name ~= "" then
            local okSource, resolvedSource = pcall(system.getSource, name)
            if okSource and resolvedSource and type(resolvedSource.value) == "function" then
                realSrc = resolvedSource
            end
        end
    end

    if type(realSrc.value) == "function" then
        local okValue, value = pcall(realSrc.value, realSrc)
        if okValue then
            return value
        end
    end

    if realSrc ~= src and type(src.value) == "function" then
        local okFallback, fallbackValue = pcall(src.value, src)
        if okFallback then
            return fallbackValue
        end
    end

    return nil
end

local function updateSystemField(widget, srcField, valField)
    local newValue = readSystemSourceValue(widget[srcField])
    if widget[valField] ~= newValue then
        widget[valField] = newValue
        return true
    end
    return false
end

local WAKEUP_SYSTEM_FIELDS = {
    "rxbattSource", "rxbattValue",
    "rssi1Source", "rssi1Value",
    "rssi2Source", "rssi2Value",
}

local function updateFuelAlert(widget)
    local threshold = widget.fuelAlertPercent or DEFAULT_FUEL_ALERT_PERCENT
    local capacity = widget.tankCapacity
    local remaining = widget.fuelValue
    local signature = table.concat({
        tostring(widget.fuelSource), tostring(capacity), tostring(threshold),
        tostring(widget.fuelAlertFile), tostring(widget._tankCapacityConfirmed),
    }, "|")

    if widget._fuelAlertSignature ~= signature then
        widget._fuelAlertSignature = signature
        widget._fuelAlertPreviousPercent = nil
        widget._fuelAlertArmed = false
        widget._fuelAlertNeedsHysteresis = false
    end

    if threshold <= 0 or not widget._tankCapacityConfirmed
        or type(capacity) ~= "number" or capacity <= 0
        or type(remaining) ~= "number" or remaining ~= remaining or remaining < 0 then
        widget._fuelAlertPreviousPercent = nil
        widget._fuelAlertArmed = false
        return
    end

    local percent = remaining / capacity * 100
    local previous = widget._fuelAlertPreviousPercent
    if previous == nil then
        widget._fuelAlertPreviousPercent = percent
        if widget._fuelAlertNeedsHysteresis then
            widget._fuelAlertArmed = percent >= threshold + FUEL_ALERT_HYSTERESIS
        else
            widget._fuelAlertArmed = percent > threshold
        end
        return
    end

    if not widget._fuelAlertArmed
        and percent >= threshold + FUEL_ALERT_HYSTERESIS then
        widget._fuelAlertArmed = true
        widget._fuelAlertNeedsHysteresis = false
    end

    if widget._fuelAlertArmed and previous > threshold and percent <= threshold then
        widget._fuelAlertArmed = false
        widget._fuelAlertNeedsHysteresis = true
        if system and system.playHaptic then system.playHaptic(300) end
        playConfiguredAudio(widget.fuelAlertFile)
        if system and system.playNumber and UNIT_PERCENT then
            system.playNumber(math.floor(percent + 0.5), UNIT_PERCENT, 0)
        end
    end

    widget._fuelAlertPreviousPercent = percent
end

local function wakeup(widget)
    local bindings = {
        { "rpmSource", "rpmValue" }, { "egtSource", "egtValue" },
        { "statusSource", "statusValue" }, { "fuelSource", "fuelValue" },
        { "ecuBatterySource", "ecuBatteryValue" }, { "pumpSource", "pumpValue" },
        { "throttleSource", "throttleValue" }, { "airspeedSource", "airspeedValue" },
        { "chronoSource", "chronoValue" },
    }
    local dirty = false
    for i = 1, #bindings do
        local field, valueField = bindings[i][1], bindings[i][2]
        local value = readSource(widget, field)
        if widget[valueField] ~= value then widget[valueField] = value dirty = true end
    end
    local airspeedUnit = readSourceUnit(widget, "airspeedSource")
    if widget._sourceUnits.airspeedSource ~= airspeedUnit then
        widget._sourceUnits.airspeedSource = airspeedUnit
        dirty = true
    end
    for i = 1, #WAKEUP_SYSTEM_FIELDS, 2 do
        dirty = updateSystemField(
            widget,
            WAKEUP_SYSTEM_FIELDS[i],
            WAKEUP_SYSTEM_FIELDS[i + 1]
        ) or dirty
    end
    updateFuelAlert(widget)
    if dirty and ((not lcd.isVisible) or lcd.isVisible()) then lcd.invalidate() end
end

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end
local function ratio(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then return nil end
    return clamp(value / maximum, 0, 1)
end
local function resolveSafeColor(fallback)
    if SAFE_COLOR ~= nil then
        return SAFE_COLOR
    end
    if THEME_SAFE_COLOR ~= nil then
        return lcd.themeColor(THEME_SAFE_COLOR)
    end
    return fallback
end

local function resolveErrorColor(fallback)
    if ERROR_COLOR ~= nil then
        return ERROR_COLOR
    end
    if THEME_ERROR_COLOR ~= nil then
        return lcd.themeColor(THEME_ERROR_COLOR)
    end
    return fallback
end

local function getPalette(theme)
    if theme == nil then theme = 0 end
    if theme == 0 then
        return {
            bgColor = lcd.RGB(0, 0, 0), gaugeColor = lcd.RGB(0, 160, 0),
            alertColor = lcd.RGB(255, 0, 0),
            safeColor = resolveSafeColor(lcd.RGB(0, 160, 0)),
            criticalColor = resolveErrorColor(lcd.RGB(255, 0, 0)),
            bgGaugeColor = lcd.RGB(60, 60, 60), textColor = lcd.RGB(255, 255, 255),
        }
    end
    if theme == 1 then
        return {
            bgColor = lcd.RGB(0, 0, 0), gaugeColor = lcd.RGB(0, 220, 255),
            alertColor = lcd.RGB(255, 80, 120),
            safeColor = resolveSafeColor(lcd.RGB(0, 220, 255)),
            criticalColor = resolveErrorColor(lcd.RGB(255, 80, 120)),
            bgGaugeColor = lcd.RGB(40, 40, 60), textColor = lcd.RGB(255, 255, 255),
        }
    end
    if theme == 2 then
        return {
            bgColor = lcd.RGB(0, 0, 0), gaugeColor = lcd.RGB(255, 180, 0),
            alertColor = lcd.RGB(255, 80, 0),
            safeColor = resolveSafeColor(lcd.RGB(255, 180, 0)),
            criticalColor = resolveErrorColor(lcd.RGB(255, 80, 0)),
            bgGaugeColor = lcd.RGB(60, 30, 0), textColor = lcd.RGB(255, 230, 200),
        }
    end
    return {
        bgColor = lcd.RGB(0, 0, 0), gaugeColor = lcd.RGB(0, 160, 0),
        alertColor = lcd.RGB(255, 0, 0),
        safeColor = resolveSafeColor(lcd.RGB(0, 160, 0)),
        criticalColor = resolveErrorColor(lcd.RGB(255, 0, 0)),
        bgGaugeColor = lcd.RGB(60, 60, 60), textColor = lcd.RGB(255, 255, 255),
    }
end

local function dashboardValue(value, decimals)
    if type(value) == "string" and value ~= "" then return value end
    if type(value) ~= "number" or value ~= value then return "--" end
    if decimals == 1 then return string.format("%.1f", value) end
    return string.format("%d", math.floor(value + 0.5))
end

local function drawCentered(centerX, y, text, font, color)
    lcd.font(font)
    lcd.color(color)
    local width = lcd.getTextSize(text)
    lcd.drawText(centerX - math.floor(width / 2), y, text, 0)
end

local function getTelemetryPanelLayout(rowCount, availableHeight, compact)
    if rowCount <= 0 then return compact and FONT_XXS or FONT_XS, 1 end
    local maxRowH = math.max(1, math.floor(availableHeight / rowCount))
    local font, preferredRowH
    if compact then
        if rowCount <= 3 and maxRowH >= 16 then font, preferredRowH = FONT_XS, 18
        else font, preferredRowH = FONT_XXS, rowCount <= 6 and 14 or 13 end
    else
        if rowCount <= 4 and maxRowH >= 22 then font, preferredRowH = FONT_STD, 22
        elseif rowCount <= 6 and maxRowH >= 18 then font, preferredRowH = FONT_XS, 19
        else font, preferredRowH = FONT_XXS, rowCount <= 9 and 16 or 14 end
    end
    return font, math.max(1, math.min(preferredRowH, maxRowH))
end

local function drawTelemetryPanel(x, y, width, rows, availableHeight, palette, compact)
    local font, rowH = getTelemetryPanelLayout(#rows, availableHeight, compact)
    lcd.font(font)
    for i, row in ipairs(rows) do
        local rowY = y + (i - 1) * rowH
        lcd.color(palette.textColor)
        lcd.drawText(x, rowY, row[1], 0)
        local value, unit = row[2] or "--", row[3] or ""
        local valueW, unitW = lcd.getTextSize(value), lcd.getTextSize(unit)
        local valueX = x + width - valueW - unitW - (unit ~= "" and 3 or 0)
        lcd.color(palette.textColor)
        lcd.drawText(valueX, rowY, value, 0)
        if unit ~= "" and value ~= "--" then
            lcd.color(palette.gaugeColor)
            lcd.drawText(valueX + valueW + 3, rowY, unit, 0)
        end
        lcd.color(palette.bgGaugeColor)
        lcd.drawLine(x, rowY + rowH - 2, x + width, rowY + rowH - 2)
    end
end

local function fitStatusFont(text, maxWidth, compact, small)
    local fonts
    if small then fonts = { FONT_L, FONT_STD, FONT_XS, FONT_XXS }
    elseif compact then fonts = { FONT_XL, FONT_L, FONT_STD, FONT_XS, FONT_XXS }
    else fonts = { FONT_XXL, FONT_XL, FONT_L, FONT_STD, FONT_XS, FONT_XXS } end
    for i = 1, #fonts do
        lcd.font(fonts[i])
        local textW = lcd.getTextSize(text)
        if textW <= maxWidth then return fonts[i] end
    end
    return FONT_XXS
end

local function drawStatusHeader(cx, y, status, chrono, width, palette, compact, small)
    local statusText = string.upper(status or "NO DATA")
    local statusBgColor = lcd.RGB(52, 56, 60)
    local horizontalPadding = small and 16 or (compact and 26 or 40)
    local frameW = width
    local statusFont = fitStatusFont(statusText, math.max(1, frameW - horizontalPadding), compact, small)
    lcd.font(statusFont)
    local _, statusH = lcd.getTextSize(statusText)
    local frameH = small and 40 or (compact and 54 or 72)
    local frameX = math.floor(cx - frameW / 2)
    local statusY = y + math.floor((frameH - statusH) / 2) + (compact and 1 or 2)
    lcd.color(statusBgColor)
    lcd.drawFilledRectangle(frameX + 1, y + 1, frameW - 2, frameH - 2)
    lcd.color(palette.gaugeColor)
    lcd.drawLine(frameX, y, frameX + frameW, y)
    lcd.drawLine(frameX + frameW, y, frameX + frameW, y + frameH)
    lcd.drawLine(frameX + frameW, y + frameH, frameX, y + frameH)
    lcd.drawLine(frameX, y + frameH, frameX, y)
    drawCentered(frameX + frameW / 2, statusY, statusText, statusFont, palette.textColor)
    local chronoY = y + frameH + (small and 3 or (compact and 7 or 9))
    local chronoFont = small and FONT_L or (compact and FONT_XL or FONT_XXL)
    drawCentered(cx, chronoY, chrono, chronoFont, palette.textColor)
    lcd.font(chronoFont)
    local _, chronoValueH = lcd.getTextSize(chrono)
    return chronoY + chronoValueH
end

local function drawGib2aLogo(centerX, y, compact, small)
    if gib2aLogo == nil or not lcd.drawBitmap then return end
    local logoW = small and GIB2A_LOGO_SMALL_WIDTH
        or (compact and GIB2A_LOGO_COMPACT_WIDTH or GIB2A_LOGO_WIDTH)
    local logoH = small and GIB2A_LOGO_SMALL_HEIGHT
        or (compact and GIB2A_LOGO_COMPACT_HEIGHT or GIB2A_LOGO_HEIGHT)
    lcd.drawBitmap(math.floor(centerX - logoW / 2), math.floor(y), gib2aLogo, logoW, logoH)
end

local function drawSegmentedGauge(cx, cy, radius, percent, maxPercent, palette)
    local inner = math.max(1, radius - math.max(5, math.floor(radius * 0.13)))
    local active = math.max(0, math.min(maxPercent, percent or 0))
    local yellow = lcd.RGB(255, 210, 0)
    local orange = lcd.RGB(255, 110, 0)
    for i = 0, 23 do
        local fromP, midP = maxPercent * i / 24, maxPercent * (i + 0.5) / 24
        local color = palette.bgGaugeColor
        if active > fromP then
            if midP < maxPercent * 0.62 then color = palette.safeColor
            elseif midP < maxPercent * 0.78 then color = yellow
            elseif midP < maxPercent * 0.91 then color = orange
            else color = palette.criticalColor end
        end
        if lcd.drawAnnulusSector then
            lcd.color(color)
            lcd.drawAnnulusSector(cx, cy, inner, radius,
                210 + 300 * i / 24, 210 + 300 * (i + 0.82) / 24)
        end
    end
end

local GAUGE_VALUE_FONTS = { FONT_XXL, FONT_XL, FONT_L, FONT_STD, FONT_XS, FONT_XXS }

local function fitGaugeValueFont(text, maxWidth, maxHeight, firstFont)
    local fallback = GAUGE_VALUE_FONTS[#GAUGE_VALUE_FONTS]
    for i = firstFont, #GAUGE_VALUE_FONTS do
        local font = GAUGE_VALUE_FONTS[i]
        lcd.font(font)
        local textW, textH = lcd.getTextSize(text)
        if textW <= maxWidth and textH <= maxHeight then return font, textW, textH end
    end
    lcd.font(fallback)
    local textW, textH = lcd.getTextSize(text)
    return fallback, textW, textH
end

local function drawMainGauge(cx, cy, radius, value, label, unit, percent, palette, compact, mediumNarrow)
    drawSegmentedGauge(cx, cy, radius, percent, 110, palette)
    local labelY = unit ~= "" and (cy + (compact and 3 or 6)) or (cy + (compact and 8 or 14))
    local innerRadius = radius - math.max(5, math.floor(radius * 0.13))
    local valueGap = 3
    local maxValueWidth = math.max(1, innerRadius * 2 - 8)
    local maxValueHeight = math.max(1, labelY - valueGap - (cy - innerRadius))
    local valueFont, valueW, valueH = fitGaugeValueFont(
        value, maxValueWidth, maxValueHeight, compact and 2 or 1)
    local valueY = labelY - valueH - valueGap
    if mediumNarrow then valueY = valueY + 2 end
    lcd.font(valueFont)
    lcd.color(palette.textColor)
    lcd.drawText(math.floor(cx - valueW / 2), math.floor(valueY), value, 0)
    drawCentered(cx, labelY, label, compact and FONT_XS or FONT_STD, palette.textColor)
    if unit ~= "" then
        drawCentered(cx, cy + (compact and 16 or 24), unit,
            compact and FONT_XXS or FONT_XS, palette.gaugeColor)
    end
end

local function pumpDisplay(widget)
    if isPumpPwEcu(widget.vspeakEcuType) then
        -- source:value() already exposes the ETHOS-normalized source value.
        -- Do not reuse the OpenTX display scaling here.
        return widget.pumpValue,
            widget.pumpPwMax or DEFAULT_PUMP_PW_MAX, "PUMP PW", 0
    end
    return widget.pumpValue, widget.pumpVoltageMax or DEFAULT_PUMP_VOLTAGE_MAX,
        "PUMP", 1
end

local function drawPumpGauge(cx, cy, radius, value, percent, palette, compact, label, maxPercent)
    label = label or "PUMP"
    drawSegmentedGauge(cx, cy, radius, percent, maxPercent or 100, palette)
    local labelY = cy + (compact and 4 or 6)
    local innerRadius = radius - math.max(5, math.floor(radius * 0.13))
    local valueGap = 3
    local maxValueWidth = math.max(1, innerRadius * 2 - 8)
    local maxValueHeight = math.max(1, labelY - valueGap - (cy - innerRadius))
    local valueFont, valueW, valueH = fitGaugeValueFont(
        value, maxValueWidth, maxValueHeight, compact and 3 or 2)
    local valueY = labelY - valueH - valueGap
    lcd.font(valueFont)
    lcd.color(palette.textColor)
    lcd.drawText(math.floor(cx - valueW / 2), math.floor(valueY), value, 0)
    drawCentered(cx, labelY, label, compact and FONT_XXS or FONT_XS, palette.textColor)
end

local function drawFuelGauge(x, y, width, percent, value, palette, compact)
    local red = palette.criticalColor
    local yellow = lcd.RGB(255, 210, 0)
    local barH = compact and 16 or 24
    local p = math.max(0, math.min(100, percent or 0))
    local fuelTextFont = compact and FONT_XS or FONT_STD
    local fuelLabelText, valueText, percentText = "FUEL", value, " %"
    local labelValueSpacing = compact and 4 or 7
    lcd.font(fuelTextFont)
    local fuelLabelW, fuelTextH = lcd.getTextSize(fuelLabelText)
    local valueW, valueH = lcd.getTextSize(valueText)
    local percentW, percentH = lcd.getTextSize(percentText)
    local textGroupW = fuelLabelW + labelValueSpacing + valueW + percentW
    local textGroupH = math.max(fuelTextH, math.max(valueH, percentH))
    local textGroupX = x + math.floor((width - textGroupW) / 2)
    local textGroupY = y + math.floor((barH - textGroupH) / 2)
    local valueX = textGroupX + fuelLabelW + labelValueSpacing
    local percentX = valueX + valueW
    lcd.color(palette.bgGaugeColor)
    lcd.drawFilledRectangle(x, y, width, barH)
    local activeWidth = math.floor(width * p / 100)
    local function drawActiveZone(fromPercent, toPercent, color)
        local zoneX = math.floor(width * fromPercent / 100)
        local zoneEnd = math.min(activeWidth, math.floor(width * toPercent / 100))
        if zoneEnd > zoneX then
            lcd.color(color)
            lcd.drawFilledRectangle(x + zoneX, y, zoneEnd - zoneX, barH)
        end
    end
    drawActiveZone(0, FUEL_RED_THRESHOLD, red)
    drawActiveZone(FUEL_RED_THRESHOLD, FUEL_YELLOW_THRESHOLD, yellow)
    drawActiveZone(FUEL_YELLOW_THRESHOLD, 100, palette.safeColor)
    lcd.font(fuelTextFont)
    lcd.color(palette.bgColor)
    lcd.drawText(textGroupX + 1, textGroupY + 1, fuelLabelText, 0)
    lcd.drawText(valueX + 1, textGroupY + 1, valueText, 0)
    lcd.drawText(percentX + 1, textGroupY + 1, percentText, 0)
    lcd.color(palette.textColor)
    lcd.drawText(textGroupX, textGroupY, fuelLabelText, 0)
    lcd.drawText(valueX, textGroupY, valueText, 0)
    lcd.color(palette.gaugeColor)
    lcd.drawText(percentX, textGroupY, percentText, 0)
    lcd.font(compact and FONT_XXS or FONT_XS)
    lcd.color(palette.textColor)
    local labels = { "0%", "25%", "50%", "75%", "100%" }
    for i = 0, 4 do
        local px = x + math.floor(width * i / 4)
        local tw = lcd.getTextSize(labels[i + 1])
        local labelX = math.max(x, math.min(x + width - tw, px - tw / 2))
        lcd.drawText(labelX, y + barH + 2, labels[i + 1], 0)
    end
end

local function getDashboardLayout(w, h)
    local margin = math.max(5, math.floor(w * 0.012))
    if w >= 700 and h >= 430 then
        local bigR = math.floor(math.min(w * 0.17, h * 0.25))
        return false, false, margin,
            math.floor(h * 0.58), bigR,
            math.floor(h * 0.65), math.floor(bigR * 0.59),
            math.floor(h * 0.89), true
    end
    local fuelY = h - 32
    local small = h < 300
    local pumpR, pumpY, gaugeTop, gaugeBottom
    if small then
        pumpR = math.max(18, math.floor(math.min(w * 0.055, h * 0.09)))
        pumpY = fuelY - pumpR - 20
        gaugeTop = 100
        gaugeBottom = pumpY - pumpR - 4
    else
        pumpR = math.max(24, math.floor(math.min(w * 0.075, h * 0.10)))
        pumpY = fuelY - pumpR - 22
        gaugeTop = 115
        gaugeBottom = pumpY - pumpR - 5
    end
    local availableGaugeHeight = math.max(2, gaugeBottom - gaugeTop)
    local bigR = math.floor(math.min(w * (small and 0.105 or 0.13), availableGaugeHeight / 2))
    if not small and w >= 600 then
        bigR = math.floor(math.min(w * 0.115625, h * 0.20556))
        pumpR = math.floor(math.min(w * 0.078125, h * 0.13889))
    end
    local gaugeY = math.floor((gaugeTop + gaugeBottom) / 2)
    if not small then gaugeY = math.floor(h * 0.63) pumpY = gaugeY end
    local mediumNarrow = (not small) and w >= 460 and w < 600
    if mediumNarrow then
        bigR = math.floor(math.min(w * 0.1292, h * 0.194))
        pumpR = math.floor(math.min(w * 0.0875, h * 0.132))
    end
    local panelAvailableHeight = math.max(1, gaugeY - bigR - margin - 2)
    local narrowPanelsFit = mediumNarrow and panelAvailableHeight >= 121
    local widePanels = (not small) and w >= 600 and h >= 320
    local showPanels = widePanels or narrowPanelsFit
    return true, small, margin, gaugeY, bigR, pumpY, pumpR, fuelY, showPanels
end

local function fmtTimeMMSS(value)
    if type(value) ~= "number" then return "--" end
    local total = math.floor(math.abs(value))
    local text = string.format("%d:%02d", math.floor(total / 60), total % 60)
    if value < 0 then text = "-" .. text end
    return text
end

local function gaugePercent(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then return 0 end
    return value * 100 / maximum
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    local palette = getPalette(widget.theme or 0)
    lcd.color(palette.bgColor)
    lcd.drawFilledRectangle(0, 0, w, h)
    local compact, small, margin, gaugeY, bigR,
        pumpY, pumpR, fuelY, showPanels = getDashboardLayout(w, h)
    local centerX = math.floor(w / 2)
    local panelW = math.floor(w * 0.255)
    local panelAvailableHeight = math.max(1, gaugeY - bigR - margin - 2)

    local headerBottomY = drawStatusHeader(centerX, margin,
        decodeVSpeakStatus(widget.vspeakEcuType, widget.statusValue),
        fmtTimeMMSS(widget.chronoValue),
        math.floor(w * (small and 0.46 or (compact and 0.38 or 0.40))),
        palette, compact, small)
    drawGib2aLogo(centerX,
        headerBottomY + (small and 1 or (compact and 3 or 5)), compact, small)

    if showPanels then
        local leftRows = {}
        if widget.ecuBatterySource ~= nil then
            leftRows[#leftRows + 1] = { "ECU V", dashboardValue(widget.ecuBatteryValue, 1), "V" }
        end
        if widget.fuelSource ~= nil then
            leftRows[#leftRows + 1] = { "FUEL", dashboardValue(widget.fuelValue), "ml" }
        end
        local rightRows = {}
        if widget.rxbattSource ~= nil then
            rightRows[#rightRows + 1] = { "RX V", dashboardValue(widget.rxbattValue, 1), "V" }
        end
        if widget.rssi1Source ~= nil then
            rightRows[#rightRows + 1] = { "RSSI 2.4", dashboardValue(widget.rssi1Value), "%" }
        end
        if widget.rssi2Source ~= nil then
            rightRows[#rightRows + 1] = { "RSSI 900", dashboardValue(widget.rssi2Value), "%" }
        end
        if widget.throttleSource ~= nil then
            rightRows[#rightRows + 1] = { "ECU THR", dashboardValue(widget.throttleValue), "%" }
        end
        if widget.airspeedSource ~= nil then
            rightRows[#rightRows + 1] = {
                "ASPD", dashboardValue(widget.airspeedValue),
                widget._sourceUnits.airspeedSource or ""
            }
        end
        drawTelemetryPanel(margin, margin, panelW, leftRows,
            panelAvailableHeight, palette, compact)
        drawTelemetryPanel(w - margin - panelW, margin, panelW, rightRows,
            panelAvailableHeight, palette, compact)
    end

    local rpmMax = widget.rpmMax and widget.rpmMax > 0 and widget.rpmMax or DEFAULT_RPM_MAX
    local egtMax = widget.egtMax and widget.egtMax > 0 and widget.egtMax or DEFAULT_EGT_MAX
    local mediumNarrow = compact and not small and w >= 460 and w < 600
    drawMainGauge(math.floor(w * 0.20), gaugeY, bigR,
        dashboardValue(widget.rpmValue), "RPM", "",
        gaugePercent(widget.rpmValue, rpmMax), palette, compact, mediumNarrow)
    drawMainGauge(math.floor(w * 0.80), gaugeY, bigR,
        dashboardValue(widget.egtValue), "EGT", "",
        gaugePercent(widget.egtValue, egtMax), palette, compact, mediumNarrow)

    local pumpValue, pumpMaximum, pumpLabel, pumpDecimals = pumpDisplay(widget)
    if not isPumpPwEcu(widget.vspeakEcuType) then pumpLabel = "PUMP V" end
    drawPumpGauge(centerX, pumpY, pumpR,
        dashboardValue(pumpValue, pumpDecimals == 0 and 0 or 1),
        gaugePercent(pumpValue, pumpMaximum), palette, compact, pumpLabel, 100)

    local fuelPercent = ratio(widget.fuelValue,
        widget.tankCapacity or DEFAULT_TANK_CAPACITY)
    fuelPercent = fuelPercent and fuelPercent * 100 or nil
    drawFuelGauge(margin, fuelY, w - 2 * margin,
        fuelPercent, dashboardValue(fuelPercent), palette, compact)
end

local function addSourceLine(widget, label, field)
    local line = form.addLine(label)
    form.addSourceField(line, nil, function() return widget[field] end,
        function(value) widget[field] = value widget._resolvedSources[field] = nil end)
end
local function addNumberLine(label, minimum, maximum, getter, setter, suffix, step, decimals)
    local line = form.addLine(label)
    local field = form.addNumberField(line, nil, minimum, maximum, getter, setter)
    if field and field.suffix and suffix then field:suffix(suffix) end
    if field and field.step and step then field:step(step) end
    if field and field.decimals and decimals then field:decimals(decimals) end
end

local function configure(widget)
    local line = form.addLine("VSPEAK ECU")
    if form.addChoiceField then
        form.addChoiceField(line, nil, VSPEAK_ECU_CHOICES,
            function() return clamp((widget.vspeakEcuType or 0) + 1, 1, 13) end,
            function(value)
                widget.vspeakEcuType = clamp((value or 1) - 1, 0, 12)
                lcd.invalidate()
            end)
    else
        addNumberLine("VSPEAK ECU (1-12)", 0, 12,
            function() return widget.vspeakEcuType or 0 end,
            function(value) widget.vspeakEcuType = value or 0 end, nil, 1)
    end
    addSourceLine(widget, "RPM Sensor", "rpmSource")
    addSourceLine(widget, "Tmp1 EGT Sensor", "egtSource")
    addSourceLine(widget, "Tmp2 Status Sensor", "statusSource")
    addSourceLine(widget, "Fuel Sensor (ml)", "fuelSource")
    addSourceLine(widget, "A3 ECU Battery", "ecuBatterySource")
    addSourceLine(widget, "A4 Pump Sensor", "pumpSource")
    addSourceLine(widget, "Thro Sensor", "throttleSource")
    addSourceLine(widget, "ASpd Sensor", "airspeedSource")
    addSourceLine(widget, "Chrono Source", "chronoSource")
    line = form.addLine("RxBatt Source")
    form.addSourceField(line, nil,
        function() return widget.rxbattSource end,
        function(v) widget.rxbattSource = v end)
    line = form.addLine("RSSI Source 1 (2.4G)")
    form.addSourceField(line, nil,
        function() return widget.rssi1Source end,
        function(v) widget.rssi1Source = v end)
    line = form.addLine("RSSI Source 2 (900M)")
    form.addSourceField(line, nil,
        function() return widget.rssi2Source end,
        function(v) widget.rssi2Source = v end)
    addNumberLine("RPM Max", 1000, 500000, function() return widget.rpmMax end,
        function(value) widget.rpmMax = value end, "rpm", 1000)
    addNumberLine("EGT Max", 100, 1500, function() return widget.egtMax end,
        function(value) widget.egtMax = value end, "C", 10)
    if isPumpPwEcu(widget.vspeakEcuType) then
        addNumberLine("Pump PW Max", 1, 2500, function() return widget.pumpPwMax end,
            function(value) widget.pumpPwMax = value end, "PW", 10)
    else
        addNumberLine("Pump Voltage Max", 1, 300,
            function() return math.floor((widget.pumpVoltageMax or DEFAULT_PUMP_VOLTAGE_MAX) * 10 + 0.5) end,
            function(value) widget.pumpVoltageMax = value / 10 end, "V", 1, 1)
    end
    addNumberLine("Fuel Tank Capacity", 1, 50000, function() return widget.tankCapacity end,
        function(value)
            widget.tankCapacity = value
            widget._tankCapacityConfirmed = true
        end, "ml", 50)
    addNumberLine("Fuel Alert (%)", 0, 100,
        function() return widget.fuelAlertPercent or DEFAULT_FUEL_ALERT_PERCENT end,
        function(value) widget.fuelAlertPercent = value end, "%", 1)
    line = form.addLine("Fuel Alert Sound")
    form.addFileField(line, nil, audioPath, "audio +ext",
        function() return widget.fuelAlertFile end,
        function(value) widget.fuelAlertFile = value end)
    local themeChoices = {
        { "Standard",      1 },
        { "High contrast", 2 },
        { "Amber",         3 },
    }
    if form.addChoiceField then
        line = form.addLine("Theme")
        form.addChoiceField(line, nil, themeChoices,
            function()
                local theme = widget.theme or 0
                return clamp(theme, 0, #themeChoices - 1) + 1
            end,
            function(value)
                local newTheme = clamp((value or 1) - 1, 0, #themeChoices - 1)
                if (widget.theme or 0) ~= newTheme then
                    widget.theme = newTheme
                    if (not lcd.isVisible) or lcd.isVisible() then
                        lcd.invalidate()
                    end
                end
            end)
    else
        addNumberLine("Theme (0=Std 1=High 2=Amber)", 0, 2,
            function() return widget.theme or 0 end,
            function(value)
                local newTheme = clamp(value or 0, 0, 2)
                if (widget.theme or 0) ~= newTheme then
                    widget.theme = newTheme
                    if (not lcd.isVisible) or lcd.isVisible() then
                        lcd.invalidate()
                    end
                end
            end, nil, 1)
    end
end

local function read(widget)
    for i = 1, #PERSISTENCE_PARAMS do
        local param = PERSISTENCE_PARAMS[i]
        local value = storage.read(param.key)
        if value == nil then value = param.default end
        widget[param.key] = value
    end
    -- One-time compatibility with the names used by the preceding beta patch.
    if widget.rxbattSource == nil then widget.rxbattSource = storage.read("rxVoltageSource") end
    if widget.rssi1Source == nil then widget.rssi1Source = storage.read("rssi24Source") end
    if widget.rssi2Source == nil then widget.rssi2Source = storage.read("rssi900Source") end
    if type(widget.vspeakEcuType) ~= "number"
        or widget.vspeakEcuType ~= math.floor(widget.vspeakEcuType)
        or widget.vspeakEcuType < 0 or widget.vspeakEcuType > 12 then
        widget.vspeakEcuType = 0
    end
    widget._resolvedSources = {}
    widget._tankCapacityConfirmed = storage.read("tankCapacityConfirmed") == true
    widget._fuelAlertPreviousPercent = nil
    widget._fuelAlertArmed = false
    widget._fuelAlertNeedsHysteresis = false
    widget._fuelAlertSignature = nil
end
local function write(widget)
    for i = 1, #PERSISTENCE_PARAMS do
        local param = PERSISTENCE_PARAMS[i]
        storage.write(param.key, widget[param.key])
    end
    storage.write("tankCapacityConfirmed", widget._tankCapacityConfirmed == true)
end
local function init()
    loadGib2aLogo()
    system.registerWidget({ key = WIDGET_KEY,
        name = "GIB2A TURBINE VSPEAK " .. WIDGET_VERSION,
        create = create, wakeup = wakeup, configure = configure,
        paint = paint, read = read, write = write })
end
return { init = init }
