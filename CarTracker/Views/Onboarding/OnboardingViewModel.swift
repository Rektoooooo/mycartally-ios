//
//  OnboardingViewModel.swift
//  CarTracker
//

import SwiftUI

// MARK: - User Selection Types

enum CarUsage: String, CaseIterable, Identifiable {
    case dailyCommute = "Daily Commute"
    case family = "Family Car"
    case business = "Business"
    case weekend = "Weekend / Fun"
    case multipleCars = "Multiple Cars"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dailyCommute: return "road.lanes"
        case .family: return "figure.2.and.child.holdinghands"
        case .business: return "briefcase.fill"
        case .weekend: return "flag.checkered"
        case .multipleCars: return "car.2.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .dailyCommute: return "Work, errands, everyday driving"
        case .family: return "School runs, groceries, family trips"
        case .business: return "Client visits, deliveries, company car"
        case .weekend: return "Pleasure drives, road trips"
        case .multipleCars: return "Managing a household fleet"
        }
    }
}

enum ExpenseWorry: String, CaseIterable, Identifiable {
    case fuel = "Fuel Costs"
    case maintenance = "Surprise Repairs"
    case insurance = "Insurance & Tax"
    case depreciation = "Losing Value"
    case overspending = "Overspending"
    case forgetting = "Forgetting Services"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.fill"
        case .depreciation: return "arrow.down.right"
        case .overspending: return "creditcard.fill"
        case .forgetting: return "bell.slash.fill"
        }
    }

    var emoji: String {
        switch self {
        case .fuel: return "⛽"
        case .maintenance: return "🔧"
        case .insurance: return "🛡️"
        case .depreciation: return "📉"
        case .overspending: return "💸"
        case .forgetting: return "⏰"
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
class OnboardingViewModel {
    // User selections
    var carUsage: CarUsage?
    var expenseWorries: Set<ExpenseWorry> = []
    var selectedCurrency: Currency = .eur
    var distanceUnit: DistanceUnit = .kilometers
    var volumeUnit: VolumeUnit = .liters

    // MARK: - Calculated Savings

    var estimatedYearlySavings: Int {
        var savings = 420

        switch carUsage {
        case .dailyCommute: savings += 320
        case .business: savings += 540
        case .family: savings += 280
        case .multipleCars: savings += 680
        case .weekend: savings += 180
        case .none: savings += 200
        }

        if expenseWorries.contains(.fuel) { savings += 160 }
        if expenseWorries.contains(.maintenance) { savings += 220 }
        if expenseWorries.contains(.overspending) { savings += 180 }
        if expenseWorries.contains(.insurance) { savings += 90 }
        if expenseWorries.contains(.forgetting) { savings += 240 }
        if expenseWorries.contains(.depreciation) { savings += 130 }

        return Int(Double(savings) * currencyMultiplier)
    }

    var estimatedResaleBoostPercent: Int {
        switch carUsage {
        case .business: return 15
        case .multipleCars: return 12
        case .dailyCommute: return 10
        case .family: return 10
        default: return 8
        }
    }

    var hoursPerYearSaved: Int {
        switch carUsage {
        case .business: return 12
        case .multipleCars: return 15
        case .dailyCommute: return 8
        default: return 6
        }
    }

    var avoidedRepairCost: Int {
        var cost = 800
        if expenseWorries.contains(.maintenance) { cost += 400 }
        if expenseWorries.contains(.forgetting) { cost += 600 }
        return Int(Double(cost) * currencyMultiplier)
    }

    var savingsCurrencySymbol: String {
        selectedCurrency.symbol
    }

    /// Approximate multiplier to convert EUR-based estimates to the selected currency
    private var currencyMultiplier: Double {
        switch selectedCurrency {
        case .eur: return 1.0
        case .usd: return 1.1
        case .gbp: return 0.85
        case .chf: return 0.95
        case .czk: return 25.0
        case .pln: return 4.3
        case .huf: return 390.0
        case .sek: return 11.5
        case .nok: return 11.5
        case .dkk: return 7.5
        }
    }

    /// Convert a EUR amount to the selected currency (formatted with thousands separator)
    func convertAmount(_ eurAmount: Int) -> String {
        let converted = Int(Double(eurAmount) * currencyMultiplier)
        return formatNumber(converted)
    }

    /// Format a number with thousands separator
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var formattedYearlySavings: String {
        formatNumber(estimatedYearlySavings)
    }

    var formattedAvoidedRepairCost: String {
        formatNumber(avoidedRepairCost)
    }

    // MARK: - Apply

    func applySettings() {
        let settings = UserSettings.shared
        settings.currency = selectedCurrency
        settings.distanceUnit = distanceUnit
        settings.volumeUnit = volumeUnit
    }
}
