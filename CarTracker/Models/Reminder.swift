//
//  Reminder.swift
//  CarTracker
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Reminder {
    var id: UUID
    var type: ReminderType
    var title: String
    var notes: String?
    var dueDate: Date?
    var dueOdometer: Int?
    var notifyDaysBefore: Int
    var notifyKmBefore: Int?
    var isRecurring: Bool
    var recurringIntervalMonths: Int?
    var recurringIntervalKm: Int?
    var isCompleted: Bool
    var completedDate: Date?
    var createdAt: Date

    var car: Car?

    init(
        type: ReminderType,
        title: String? = nil,
        notes: String? = nil,
        dueDate: Date? = nil,
        dueOdometer: Int? = nil,
        notifyDaysBefore: Int = 7,
        notifyKmBefore: Int? = nil,
        isRecurring: Bool = false,
        recurringIntervalMonths: Int? = nil,
        recurringIntervalKm: Int? = nil,
        car: Car? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title ?? type.defaultTitle
        self.notes = notes
        self.dueDate = dueDate
        self.dueOdometer = dueOdometer
        self.notifyDaysBefore = notifyDaysBefore
        self.notifyKmBefore = notifyKmBefore
        self.isRecurring = isRecurring
        self.recurringIntervalMonths = recurringIntervalMonths
        self.recurringIntervalKm = recurringIntervalKm
        self.isCompleted = false
        self.completedDate = nil
        self.car = car
        self.createdAt = Date()
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }

    var urgencyColor: Color {
        guard let days = daysUntilDue else { return .secondary }
        if days < 0 { return .red }
        if days <= 7 { return .orange }
        if days <= 30 { return .yellow }
        return .green
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case inspection = "Technical Inspection"
    case emissions = "Emissions Test"
    case insurance = "Insurance Renewal"
    case roadTax = "Road Tax"
    case oilChange = "Oil Change"
    case tireChange = "Tire Change"
    case timingBelt = "Timing Belt"
    case brakeFluid = "Brake Fluid"
    case coolant = "Coolant"
    case airFilter = "Air Filter"
    case cabinFilter = "Cabin Filter"
    case sparkPlugs = "Spark Plugs"
    case battery = "Battery"
    case warranty = "Warranty Expiry"
    case vignette = "Vignette Expiry"
    case environmentalSticker = "Environmental Sticker"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .inspection: return "checkmark.seal.fill"
        case .emissions: return "smoke.fill"
        case .insurance: return "shield.fill"
        case .roadTax: return "doc.text.fill"
        case .oilChange: return "drop.fill"
        case .tireChange: return "circle.circle.fill"
        case .timingBelt: return "gearshape.2.fill"
        case .brakeFluid: return "exclamationmark.octagon.fill"
        case .coolant: return "thermometer.medium"
        case .airFilter: return "wind"
        case .cabinFilter: return "air.conditioner.horizontal.fill"
        case .sparkPlugs: return "bolt.fill"
        case .battery: return "battery.100.bolt"
        case .warranty: return "calendar.badge.clock"
        case .vignette: return "road.lanes"
        case .environmentalSticker: return "leaf.fill"
        case .custom: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .inspection: return .purple
        case .emissions: return .gray
        case .insurance: return .green
        case .roadTax: return .orange
        case .oilChange: return .brown
        case .tireChange: return .blue
        case .timingBelt: return .red
        case .brakeFluid: return .red
        case .coolant: return .cyan
        case .airFilter: return .mint
        case .cabinFilter: return .teal
        case .sparkPlugs: return .yellow
        case .battery: return .green
        case .warranty: return .indigo
        case .vignette: return .brown
        case .environmentalSticker: return .green
        case .custom: return .blue
        }
    }

    var defaultTitle: String {
        self.rawValue
    }

    var defaultRecurringMonths: Int? {
        switch self {
        case .inspection: return 24
        case .emissions: return 12
        case .insurance: return 12
        case .roadTax: return 12
        case .oilChange: return 12
        case .tireChange: return 6
        case .brakeFluid: return 24
        case .coolant: return 48
        case .vignette: return 12
        default: return nil
        }
    }

    var defaultRecurringKm: Int? {
        switch self {
        case .oilChange: return 15000
        case .timingBelt: return 100000
        case .airFilter: return 30000
        case .cabinFilter: return 20000
        case .sparkPlugs: return 60000
        default: return nil
        }
    }
}
