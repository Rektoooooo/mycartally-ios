//
//  OBDDiagnosticCodes.swift
//  CarTracker
//

import Foundation

enum OBDDiagnosticCodes {

    static func description(for code: String) -> String {
        return knownCodes[code] ?? "Unknown diagnostic code"
    }

    static func severity(for code: String) -> DTCSeverity {
        guard code.count >= 2 else { return .warning }
        let prefix = String(code.prefix(2))

        // Critical codes: misfires, catalytic converter, fuel system
        let criticalPrefixes = ["P03", "P04"]
        if criticalPrefixes.contains(prefix) { return .critical }

        // Specific critical codes
        let criticalCodes: Set<String> = [
            "P0101", "P0102", "P0103", // MAF
            "P0171", "P0172", // Fuel system lean/rich
            "P0217", // Engine overtemp
            "P0219", // Engine overspeed
            "P0300", "P0301", "P0302", "P0303", "P0304", "P0305", "P0306", // Misfires
            "P0420", "P0430", // Catalytic converter
        ]
        if criticalCodes.contains(code) { return .critical }

        // Info codes: pending, evap, O2 sensors
        let infoPrefixes = ["P01", "P02"]
        if infoPrefixes.contains(prefix) && !criticalCodes.contains(code) { return .info }

        // Body and network codes are generally info
        if code.hasPrefix("B") || code.hasPrefix("U") { return .info }

        return .warning
    }

    // MARK: - Known DTC Codes Database

    static let knownCodes: [String: String] = [
        // Fuel and Air Metering
        "P0100": "Mass Air Flow Circuit Malfunction",
        "P0101": "Mass Air Flow Circuit Range/Performance",
        "P0102": "Mass Air Flow Circuit Low Input",
        "P0103": "Mass Air Flow Circuit High Input",
        "P0104": "Mass Air Flow Circuit Intermittent",
        "P0105": "Manifold Absolute Pressure Circuit Malfunction",
        "P0106": "MAP/Barometric Pressure Circuit Range/Performance",
        "P0107": "MAP/Barometric Pressure Circuit Low Input",
        "P0108": "MAP/Barometric Pressure Circuit High Input",
        "P0110": "Intake Air Temperature Circuit Malfunction",
        "P0111": "Intake Air Temperature Circuit Range/Performance",
        "P0112": "Intake Air Temperature Circuit Low Input",
        "P0113": "Intake Air Temperature Circuit High Input",
        "P0115": "Engine Coolant Temperature Circuit Malfunction",
        "P0116": "Engine Coolant Temperature Circuit Range/Performance",
        "P0117": "Engine Coolant Temperature Circuit Low Input",
        "P0118": "Engine Coolant Temperature Circuit High Input",
        "P0120": "Throttle Position Sensor Circuit Malfunction",
        "P0121": "Throttle Position Sensor Circuit Range/Performance",
        "P0122": "Throttle Position Sensor Circuit Low Input",
        "P0123": "Throttle Position Sensor Circuit High Input",
        "P0125": "Insufficient Coolant Temperature for Closed Loop",
        "P0128": "Coolant Thermostat Below Regulating Temperature",
        "P0130": "O2 Sensor Circuit Malfunction (Bank 1, Sensor 1)",
        "P0131": "O2 Sensor Circuit Low Voltage (Bank 1, Sensor 1)",
        "P0132": "O2 Sensor Circuit High Voltage (Bank 1, Sensor 1)",
        "P0133": "O2 Sensor Circuit Slow Response (Bank 1, Sensor 1)",
        "P0134": "O2 Sensor Circuit No Activity (Bank 1, Sensor 1)",
        "P0135": "O2 Sensor Heater Circuit Malfunction (Bank 1, Sensor 1)",
        "P0136": "O2 Sensor Circuit Malfunction (Bank 1, Sensor 2)",
        "P0137": "O2 Sensor Circuit Low Voltage (Bank 1, Sensor 2)",
        "P0138": "O2 Sensor Circuit High Voltage (Bank 1, Sensor 2)",
        "P0139": "O2 Sensor Circuit Slow Response (Bank 1, Sensor 2)",
        "P0140": "O2 Sensor Circuit No Activity (Bank 1, Sensor 2)",
        "P0141": "O2 Sensor Heater Circuit Malfunction (Bank 1, Sensor 2)",
        "P0150": "O2 Sensor Circuit Malfunction (Bank 2, Sensor 1)",
        "P0151": "O2 Sensor Circuit Low Voltage (Bank 2, Sensor 1)",
        "P0152": "O2 Sensor Circuit High Voltage (Bank 2, Sensor 1)",
        "P0153": "O2 Sensor Circuit Slow Response (Bank 2, Sensor 1)",
        "P0154": "O2 Sensor Circuit No Activity (Bank 2, Sensor 1)",
        "P0155": "O2 Sensor Heater Circuit Malfunction (Bank 2, Sensor 1)",

        // Fuel System
        "P0170": "Fuel Trim Malfunction (Bank 1)",
        "P0171": "System Too Lean (Bank 1)",
        "P0172": "System Too Rich (Bank 1)",
        "P0173": "Fuel Trim Malfunction (Bank 2)",
        "P0174": "System Too Lean (Bank 2)",
        "P0175": "System Too Rich (Bank 2)",
        "P0190": "Fuel Rail Pressure Sensor Circuit Malfunction",
        "P0191": "Fuel Rail Pressure Sensor Range/Performance",
        "P0192": "Fuel Rail Pressure Sensor Circuit Low Input",
        "P0193": "Fuel Rail Pressure Sensor Circuit High Input",

        // Ignition System
        "P0200": "Injector Circuit Malfunction",
        "P0201": "Injector Circuit Malfunction - Cylinder 1",
        "P0202": "Injector Circuit Malfunction - Cylinder 2",
        "P0203": "Injector Circuit Malfunction - Cylinder 3",
        "P0204": "Injector Circuit Malfunction - Cylinder 4",
        "P0205": "Injector Circuit Malfunction - Cylinder 5",
        "P0206": "Injector Circuit Malfunction - Cylinder 6",
        "P0217": "Engine Overtemperature Condition",
        "P0219": "Engine Overspeed Condition",
        "P0220": "Throttle/Pedal Position Sensor B Circuit",
        "P0221": "Throttle/Pedal Position Sensor B Range/Performance",
        "P0222": "Throttle/Pedal Position Sensor B Low Input",
        "P0223": "Throttle/Pedal Position Sensor B High Input",

        // Misfire Detection
        "P0300": "Random/Multiple Cylinder Misfire Detected",
        "P0301": "Cylinder 1 Misfire Detected",
        "P0302": "Cylinder 2 Misfire Detected",
        "P0303": "Cylinder 3 Misfire Detected",
        "P0304": "Cylinder 4 Misfire Detected",
        "P0305": "Cylinder 5 Misfire Detected",
        "P0306": "Cylinder 6 Misfire Detected",
        "P0307": "Cylinder 7 Misfire Detected",
        "P0308": "Cylinder 8 Misfire Detected",

        // Emission Controls
        "P0325": "Knock Sensor 1 Circuit Malfunction",
        "P0330": "Knock Sensor 2 Circuit Malfunction",
        "P0335": "Crankshaft Position Sensor A Circuit Malfunction",
        "P0336": "Crankshaft Position Sensor A Range/Performance",
        "P0340": "Camshaft Position Sensor Circuit Malfunction",
        "P0341": "Camshaft Position Sensor Range/Performance",

        // Catalytic Converter
        "P0420": "Catalyst System Efficiency Below Threshold (Bank 1)",
        "P0421": "Warm Up Catalyst Efficiency Below Threshold (Bank 1)",
        "P0430": "Catalyst System Efficiency Below Threshold (Bank 2)",
        "P0431": "Warm Up Catalyst Efficiency Below Threshold (Bank 2)",
        "P0440": "Evaporative Emission Control System Malfunction",
        "P0441": "EVAP System Incorrect Purge Flow",
        "P0442": "EVAP System Small Leak Detected",
        "P0443": "EVAP System Purge Control Valve Circuit Malfunction",
        "P0446": "EVAP Vent Control Circuit Malfunction",
        "P0449": "EVAP Vent Valve/Solenoid Circuit Malfunction",
        "P0450": "EVAP Pressure Sensor Malfunction",
        "P0451": "EVAP Pressure Sensor Range/Performance",
        "P0452": "EVAP Pressure Sensor Low Input",
        "P0453": "EVAP Pressure Sensor High Input",
        "P0455": "EVAP System Large Leak Detected",
        "P0456": "EVAP System Very Small Leak Detected",

        // Speed/Idle Control
        "P0500": "Vehicle Speed Sensor Malfunction",
        "P0501": "Vehicle Speed Sensor Range/Performance",
        "P0505": "Idle Control System Malfunction",
        "P0506": "Idle Control System RPM Lower Than Expected",
        "P0507": "Idle Control System RPM Higher Than Expected",

        // EGR/Exhaust
        "P0400": "Exhaust Gas Recirculation Flow Malfunction",
        "P0401": "EGR Flow Insufficient Detected",
        "P0402": "EGR Flow Excessive Detected",
        "P0403": "EGR Circuit Malfunction",
        "P0404": "EGR Circuit Range/Performance",

        // Transmission
        "P0700": "Transmission Control System Malfunction",
        "P0705": "Transmission Range Sensor Circuit Malfunction",
        "P0715": "Input/Turbine Speed Sensor Circuit Malfunction",
        "P0720": "Output Speed Sensor Circuit Malfunction",
        "P0725": "Engine Speed Input Circuit Malfunction",
        "P0730": "Incorrect Gear Ratio",
        "P0740": "Torque Converter Clutch Circuit Malfunction",
        "P0741": "Torque Converter Clutch Solenoid Performance/Stuck Off",
        "P0750": "Shift Solenoid A Malfunction",
        "P0755": "Shift Solenoid B Malfunction",
        "P0760": "Shift Solenoid C Malfunction",
        "P0765": "Shift Solenoid D Malfunction",

        // Chassis
        "C0035": "Left Front Wheel Speed Circuit Malfunction",
        "C0040": "Right Front Wheel Speed Circuit Malfunction",
        "C0045": "Left Rear Wheel Speed Circuit Malfunction",
        "C0050": "Right Rear Wheel Speed Circuit Malfunction",
        "C0060": "Left Front ABS Solenoid Circuit Malfunction",
        "C0065": "Right Front ABS Solenoid Circuit Malfunction",
        "C0070": "Left Rear ABS Solenoid Circuit Malfunction",
        "C0075": "Right Rear ABS Solenoid Circuit Malfunction",
        "C0241": "EBCM Control Valve Circuit",
        "C0242": "PCM Indicated TCS Malfunction",
        "C0244": "PWM Delivered TOO Long",
        "C0550": "ECU Performance",

        // Body
        "B0001": "Driver Frontal Stage 1 Deployment Control",
        "B0002": "Driver Frontal Stage 2 Deployment Control",
        "B0003": "Passenger Frontal Stage 1 Deployment Control",
        "B0010": "Driver Side Airbag Deployment",
        "B0100": "Electronic Frontal Sensor 1 Performance",
        "B1000": "ECU Malfunction",
        "B1001": "Option Configuration Error",

        // Network Communication
        "U0001": "High Speed CAN Communication Bus",
        "U0100": "Lost Communication With ECM/PCM A",
        "U0101": "Lost Communication With TCM",
        "U0121": "Lost Communication With ABS",
        "U0140": "Lost Communication With Body Control Module",
        "U0151": "Lost Communication With Restraints Control Module",
        "U0155": "Lost Communication With Instrument Panel Cluster",
        "U0164": "Lost Communication With HVAC Control Module",
        "U0401": "Invalid Data Received From ECM/PCM A",
    ]
}
