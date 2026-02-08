//
//  OBDDataModels.swift
//  CarTracker
//

import Foundation

struct OBDLiveData {
    var rpm: Double?
    var speed: Double?
    var coolantTemp: Double?
    var fuelLevel: Double?
    var engineLoad: Double?
    var throttlePosition: Double?
    var intakeAirTemp: Double?
    var voltage: Double?
    var oilTemp: Double?
    var fuelRate: Double?
    var lastUpdated: Date = Date()

    var hasAnyData: Bool {
        rpm != nil || speed != nil || coolantTemp != nil ||
        fuelLevel != nil || engineLoad != nil || throttlePosition != nil ||
        intakeAirTemp != nil || voltage != nil || oilTemp != nil || fuelRate != nil
    }
}

enum OBDConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case initializing
    case connectedToAdapter
    case connectedToVehicle
    case error(String)

    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .initializing: return "Initializing..."
        case .connectedToAdapter: return "Connected to Adapter"
        case .connectedToVehicle: return "Connected to Vehicle"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var isConnected: Bool {
        switch self {
        case .connectedToAdapter, .connectedToVehicle:
            return true
        default:
            return false
        }
    }

    var isConnectedToVehicle: Bool {
        if case .connectedToVehicle = self { return true }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .scanning, .connecting, .initializing:
            return true
        default:
            return false
        }
    }
}

struct DTCCode: Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let severity: DTCSeverity
    let ecuName: String

    init(code: String, description: String, severity: DTCSeverity = .warning, ecuName: String = "Engine") {
        self.code = code
        self.description = description
        self.severity = severity
        self.ecuName = ecuName
    }

    var category: String {
        guard let first = code.first else { return "Unknown" }
        switch first {
        case "P": return "Powertrain"
        case "C": return "Chassis"
        case "B": return "Body"
        case "U": return "Network"
        default: return "Unknown"
        }
    }

    var categoryIcon: String {
        guard let first = code.first else { return "questionmark.circle" }
        switch first {
        case "P": return "engine.combustion.fill"
        case "C": return "car.fill"
        case "B": return "car.side.fill"
        case "U": return "network"
        default: return "questionmark.circle"
        }
    }
}

enum DTCSeverity: Comparable {
    case info, warning, critical

    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}
