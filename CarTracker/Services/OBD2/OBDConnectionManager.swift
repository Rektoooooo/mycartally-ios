//
//  OBDConnectionManager.swift
//  CarTracker
//

import SwiftUI
import Combine
import SwiftOBD2
import CoreBluetooth

@Observable
class OBDConnectionManager {

    // MARK: - Public State

    var connectionState: OBDConnectionState = .disconnected
    var liveData = OBDLiveData()
    var dtcCodes: [DTCCode] = []
    var vehicleVIN: String?
    var obdProtocol: String?
    var supportedPIDs: [OBDCommand] = []
    var isPolling = false
    var isDemoMode = false
    var discoveredPeripherals: [CBPeripheral] = []
    var selectedConnectionType: ConnectionType = .bluetooth

    // MARK: - Private

    private var obdService: OBDService?
    private var pollingTask: Task<Void, Never>?
    private var demoTimer: Timer?

    // MARK: - Initialization

    init() {}

    // MARK: - Connection

    func startScanning() async {
        guard !isDemoMode else {
            startDemoMode()
            return
        }

        connectionState = .scanning
        obdService = OBDService(connectionType: selectedConnectionType)

        do {
            try await obdService?.scanForPeripherals()
        } catch {
            connectionState = .error("Scan failed: \(error.localizedDescription)")
        }
    }

    func connect() async {
        guard !isDemoMode else {
            startDemoMode()
            return
        }

        // Always create a fresh service with the currently selected connection type
        obdService?.stopConnection()
        let service = OBDService(connectionType: selectedConnectionType)
        obdService = service

        connectionState = .connecting

        do {
            let info = try await service.startConnection(timeout: 15)
            connectionState = .connectedToVehicle
            vehicleVIN = info.vin
            obdProtocol = info.obdProtocol?.description
            if let pids = info.supportedPIDs {
                supportedPIDs = pids
            }
        } catch {
            let message = friendlyErrorMessage(for: error)
            connectionState = .error(message)
        }
    }

    private func friendlyErrorMessage(for error: Error) -> String {
        if let obdError = error as? OBDServiceError {
            switch obdError {
            case .noAdapterFound:
                if selectedConnectionType == .wifi {
                    return "Could not reach the OBD2 adapter. Make sure your iPhone is connected to the adapter's Wi-Fi network and the adapter is powered on."
                } else {
                    return "No OBD2 adapter found. Make sure the adapter is plugged in and powered on."
                }
            case .notConnectedToVehicle:
                return "Connected to adapter but could not communicate with the vehicle. Is the engine running or ignition on?"
            case .adapterConnectionFailed(let underlying):
                if selectedConnectionType == .wifi {
                    return "Wi-Fi connection failed: \(underlying.localizedDescription). Verify you're on the adapter's Wi-Fi network (usually 192.168.0.10)."
                } else {
                    return "Adapter connection failed: \(underlying.localizedDescription)"
                }
            case .scanFailed(let underlying):
                return "Scan failed: \(underlying.localizedDescription)"
            case .clearFailed(let underlying):
                return "Clear failed: \(underlying.localizedDescription)"
            case .commandFailed(let cmd, let underlying):
                return "Command \(cmd) failed: \(underlying.localizedDescription)"
            }
        }
        return error.localizedDescription
    }

    func disconnect() {
        if isDemoMode {
            stopDemoMode()
            return
        }

        stopPolling()
        obdService?.stopConnection()
        obdService = nil
        connectionState = .disconnected
        liveData = OBDLiveData()
        dtcCodes = []
        vehicleVIN = nil
        obdProtocol = nil
        supportedPIDs = []
        discoveredPeripherals = []
    }

    // MARK: - Live Data Polling

    // Fast PIDs - polled every cycle (responsive to driver input)
    private static let fastPIDs: [OBDCommand] = [
        .mode1(.rpm),
        .mode1(.speed),
        .mode1(.throttlePosD),
        .mode1(.engineLoad),
    ]

    // Slow PIDs - polled every 5th cycle (these values change slowly)
    private static let slowPIDs: [OBDCommand] = [
        .mode1(.engineOilTemp),
        .mode1(.coolantTemp),
        .mode1(.controlModuleVoltage),
        .mode1(.intakeTemp),
        .mode1(.fuelRate),
    ]

    func startLiveDataPolling() {
        guard !isPolling else { return }
        isPolling = true

        if isDemoMode {
            startDemoPolling()
            return
        }

        guard let service = obdService else { return }

        pollingTask = Task { [weak self] in
            // Physical addressing: send to engine ECU only (7E0→7E8).
            _ = try? await service.sendCommandInternal("AT SH 7E0", retries: 1)
            // Response timeout: 25 × 4ms = 100ms.
            _ = try? await service.sendCommandInternal("ATST 19", retries: 1)

            var cycle = 0
            while !Task.isCancelled {
                // Every 5th cycle add temperatures; otherwise just fast PIDs
                let pids: [OBDCommand]
                if cycle % 5 == 0 {
                    pids = Self.fastPIDs + Self.slowPIDs
                } else {
                    pids = Self.fastPIDs
                }
                cycle += 1

                do {
                    let results = try await service.requestPIDs(pids, unit: .metric)
                    await MainActor.run {
                        self?.processLiveDataResults(results)
                    }
                } catch {
                    await MainActor.run {
                        self?.connectionState = .error(error.localizedDescription)
                        self?.isPolling = false
                    }
                    break
                }
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
        demoTimer?.invalidate()
        demoTimer = nil
        // Restore broadcast addressing so DTC scanning works with all ECUs
        if let service = obdService {
            Task { _ = try? await service.sendCommandInternal("AT SH 7DF", retries: 1) }
        }
    }

    private func processLiveDataResults(_ results: [OBDCommand: MeasurementResult]) {
        for (command, result) in results {
            switch command {
            case .mode1(.rpm):
                liveData.rpm = result.value
            case .mode1(.speed):
                liveData.speed = result.value
            case .mode1(.coolantTemp):
                liveData.coolantTemp = result.value
            case .mode1(.fuelLevel):
                liveData.fuelLevel = result.value
            case .mode1(.engineLoad):
                liveData.engineLoad = result.value
            case .mode1(.throttlePosD):
                // PID 0x49 has ~15% baseline from pedal sensor voltage; normalize to 0-100%
                liveData.throttlePosition = max(0, ((result.value - 15.0) / 85.0) * 100.0)
            case .mode1(.throttlePos), .mode1(.relativeThrottlePos):
                liveData.throttlePosition = result.value
            case .mode1(.intakeTemp):
                liveData.intakeAirTemp = result.value
            case .mode1(.controlModuleVoltage):
                liveData.voltage = result.value
            case .mode1(.engineOilTemp):
                liveData.oilTemp = result.value
            case .mode1(.fuelRate):
                liveData.fuelRate = result.value
            default:
                break
            }
        }
        liveData.lastUpdated = Date()
    }

    // MARK: - Diagnostics

    func readDTCs() async {
        if isDemoMode {
            dtcCodes = [
                DTCCode(code: "P0301", description: "Cylinder 1 Misfire Detected", severity: .critical, ecuName: "Engine"),
                DTCCode(code: "P0420", description: "Catalyst System Efficiency Below Threshold (Bank 1)", severity: .critical, ecuName: "Engine"),
                DTCCode(code: "P0171", description: "System Too Lean (Bank 1)", severity: .warning, ecuName: "Engine"),
            ]
            return
        }

        guard let service = obdService else { return }

        do {
            let ecuCodes = try await service.scanForTroubleCodes()
            var allCodes: [DTCCode] = []

            for (ecu, troubleCodes) in ecuCodes {
                let ecuName: String
                switch ecu {
                case .engine: ecuName = "Engine"
                case .transmission: ecuName = "Transmission"
                default: ecuName = "Unknown"
                }

                for tc in troubleCodes {
                    let desc = tc.description.isEmpty
                        ? OBDDiagnosticCodes.description(for: tc.code)
                        : tc.description
                    let sev = OBDDiagnosticCodes.severity(for: tc.code)
                    allCodes.append(DTCCode(code: tc.code, description: desc, severity: sev, ecuName: ecuName))
                }
            }

            dtcCodes = allCodes.sorted { $0.severity > $1.severity }
        } catch {
            connectionState = .error("Failed to read DTCs: \(error.localizedDescription)")
        }
    }

    func clearDTCs() async {
        if isDemoMode {
            dtcCodes = []
            return
        }

        guard let service = obdService else { return }

        do {
            try await service.clearTroubleCodes()
            dtcCodes = []
        } catch {
            connectionState = .error("Failed to clear DTCs: \(error.localizedDescription)")
        }
    }

    func readVIN() async -> String? {
        if isDemoMode {
            let demoVIN = "WVWZZZ3CZWE123456"
            vehicleVIN = demoVIN
            return demoVIN
        }

        guard let service = obdService else { return nil }

        do {
            let result = try await service.sendCommand(.mode9(.VIN))
            if case .success(let decoded) = result,
               case .stringResult(let vin) = decoded {
                vehicleVIN = vin
                return vin
            }
        } catch {
            // VIN read failed silently
        }
        return vehicleVIN
    }

    // MARK: - Demo Mode

    func startDemoMode() {
        isDemoMode = true
        connectionState = .connectedToVehicle
        vehicleVIN = "WVWZZZ3CZWE123456"
        obdProtocol = "ISO 15765-4 CAN (11 bit, 500K)"
        supportedPIDs = [
            .mode1(.rpm), .mode1(.speed), .mode1(.coolantTemp),
            .mode1(.fuelLevel), .mode1(.engineLoad),
            .mode1(.throttlePos), .mode1(.intakeTemp),
            .mode1(.controlModuleVoltage), .mode1(.engineOilTemp),
        ]
    }

    func stopDemoMode() {
        isDemoMode = false
        stopPolling()
        connectionState = .disconnected
        liveData = OBDLiveData()
        dtcCodes = []
        vehicleVIN = nil
        obdProtocol = nil
        supportedPIDs = []
    }

    private func startDemoPolling() {
        demoTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.generateDemoData()
        }
    }

    private func generateDemoData() {
        let baseRPM = 850.0
        let rpmVariation = Double.random(in: -50...200)
        liveData.rpm = baseRPM + rpmVariation

        liveData.speed = 0
        liveData.coolantTemp = 85 + Double.random(in: -2...5)
        liveData.fuelLevel = max(0, min(100, (liveData.fuelLevel ?? 65) + Double.random(in: -0.1...0.05)))
        liveData.engineLoad = 15 + Double.random(in: -5...10)
        liveData.throttlePosition = 12 + Double.random(in: -3...8)
        liveData.intakeAirTemp = 25 + Double.random(in: -2...3)
        liveData.voltage = 14.2 + Double.random(in: -0.3...0.3)
        liveData.oilTemp = 90 + Double.random(in: -3...5)
        liveData.fuelRate = 0.8 + Double.random(in: -0.2...0.3)
        liveData.lastUpdated = Date()
    }
}
