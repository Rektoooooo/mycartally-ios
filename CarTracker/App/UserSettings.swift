//
//  UserSettings.swift
//  CarTracker
//

import SwiftUI

// MARK: - Enums

enum DistanceUnit: String, CaseIterable, Codable {
    case kilometers = "Kilometers"
    case miles = "Miles"

    var abbreviation: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }

    var consumptionLabel: String {
        switch self {
        case .kilometers: return "L/100km"
        case .miles: return "MPG"
        }
    }
}

enum VolumeUnit: String, CaseIterable, Codable {
    case liters = "Liters"
    case gallons = "Gallons (US)"
    case gallonsUK = "Gallons (UK)"

    var abbreviation: String {
        switch self {
        case .liters: return "L"
        case .gallons: return "gal"
        case .gallonsUK: return "gal"
        }
    }
}

enum Currency: String, CaseIterable, Codable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case chf = "CHF"
    case pln = "PLN"
    case czk = "CZK"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"
    case huf = "HUF"

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .chf: return "CHF"
        case .pln: return "zł"
        case .czk: return "Kč"
        case .sek: return "kr"
        case .nok: return "kr"
        case .dkk: return "kr"
        case .huf: return "Ft"
        }
    }

    var displayName: String {
        switch self {
        case .eur: return "Euro (€)"
        case .usd: return "US Dollar ($)"
        case .gbp: return "British Pound (£)"
        case .chf: return "Swiss Franc (CHF)"
        case .pln: return "Polish Złoty (zł)"
        case .czk: return "Czech Koruna (Kč)"
        case .sek: return "Swedish Krona (kr)"
        case .nok: return "Norwegian Krone (kr)"
        case .dkk: return "Danish Krone (kr)"
        case .huf: return "Hungarian Forint (Ft)"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - UserSettings

@Observable
class UserSettings {
    static let shared = UserSettings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let distanceUnit = "distanceUnit"
        static let volumeUnit = "volumeUnit"
        static let currency = "currency"
        static let theme = "appTheme"
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
        static let defaultCarId = "defaultCarId"
    }

    // MARK: - Properties

    var distanceUnit: DistanceUnit {
        didSet { save(distanceUnit.rawValue, forKey: Keys.distanceUnit) }
    }

    var volumeUnit: VolumeUnit {
        didSet { save(volumeUnit.rawValue, forKey: Keys.volumeUnit) }
    }

    var currency: Currency {
        didSet { save(currency.rawValue, forKey: Keys.currency) }
    }

    var theme: AppTheme {
        didSet { save(theme.rawValue, forKey: Keys.theme) }
    }

    var notificationsEnabled: Bool {
        didSet { save(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    var reminderHour: Int {
        didSet { save(reminderHour, forKey: Keys.reminderHour) }
    }

    var reminderMinute: Int {
        didSet { save(reminderMinute, forKey: Keys.reminderMinute) }
    }

    var defaultCarId: UUID? {
        didSet {
            if let id = defaultCarId {
                save(id.uuidString, forKey: Keys.defaultCarId)
            } else {
                defaults.removeObject(forKey: Keys.defaultCarId)
            }
        }
    }

    // MARK: - Computed Properties

    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 9
            reminderMinute = components.minute ?? 0
        }
    }

    var unitsDisplayString: String {
        "\(distanceUnit.abbreviation), \(volumeUnit.abbreviation)"
    }

    // MARK: - Init

    private init() {
        // Load saved values or use defaults
        if let raw = defaults.string(forKey: Keys.distanceUnit),
           let unit = DistanceUnit(rawValue: raw) {
            distanceUnit = unit
        } else {
            distanceUnit = .kilometers
        }

        if let raw = defaults.string(forKey: Keys.volumeUnit),
           let unit = VolumeUnit(rawValue: raw) {
            volumeUnit = unit
        } else {
            volumeUnit = .liters
        }

        if let raw = defaults.string(forKey: Keys.currency),
           let curr = Currency(rawValue: raw) {
            currency = curr
        } else {
            currency = .eur
        }

        if let raw = defaults.string(forKey: Keys.theme),
           let appTheme = AppTheme(rawValue: raw) {
            theme = appTheme
        } else {
            theme = .system
        }

        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        reminderHour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 9
        reminderMinute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0

        if let idString = defaults.string(forKey: Keys.defaultCarId) {
            defaultCarId = UUID(uuidString: idString)
        } else {
            defaultCarId = nil
        }
    }

    // MARK: - Helpers

    private func save(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Formatting Helpers

    func formatDistance(_ value: Int) -> String {
        "\(value.formatted()) \(distanceUnit.abbreviation)"
    }

    func formatVolume(_ value: Double) -> String {
        String(format: "%.1f \(volumeUnit.abbreviation)", value)
    }

    func formatCurrency(_ value: Double) -> String {
        String(format: "\(currency.symbol)%.2f", value)
    }

    func formatConsumption(_ value: Double) -> String {
        if distanceUnit == .miles {
            // Convert L/100km to MPG
            let mpg = 235.215 / value
            return String(format: "%.1f MPG", mpg)
        } else {
            return String(format: "%.1f L/100km", value)
        }
    }
}
