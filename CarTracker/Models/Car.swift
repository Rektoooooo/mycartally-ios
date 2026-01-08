//
//  Car.swift
//  CarTracker
//

import Foundation
import SwiftData

@Model
final class Car {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var variant: String?
    var licensePlate: String
    var vin: String?
    var fuelType: FuelType
    var purchaseDate: Date?
    var purchasePrice: Double?
    var currentOdometer: Int
    var photoData: Data?
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FuelEntry.car)
    var fuelEntries: [FuelEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.car)
    var expenses: [Expense] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.car)
    var reminders: [Reminder] = []

    init(
        make: String,
        model: String,
        year: Int,
        variant: String? = nil,
        licensePlate: String,
        vin: String? = nil,
        fuelType: FuelType = .petrolE10,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        currentOdometer: Int = 0,
        photoData: Data? = nil
    ) {
        self.id = UUID()
        self.make = make
        self.model = model
        self.year = year
        self.variant = variant
        self.licensePlate = licensePlate
        self.vin = vin
        self.fuelType = fuelType
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currentOdometer = currentOdometer
        self.photoData = photoData
        self.isArchived = false
        self.createdAt = Date()
    }

    var displayName: String {
        "\(make) \(model)"
    }

    var fullDisplayName: String {
        if let variant = variant, !variant.isEmpty {
            return "\(make) \(model) \(variant)"
        }
        return "\(make) \(model)"
    }
}

enum FuelType: String, Codable, CaseIterable {
    case petrolE5 = "Petrol E5"
    case petrolE10 = "Petrol E10"
    case diesel = "Diesel"
    case lpg = "LPG"
    case cng = "CNG"
    case hybrid = "Hybrid"
    case pluginHybrid = "Plug-in Hybrid"
    case electric = "Electric"

    var icon: String {
        switch self {
        case .petrolE5, .petrolE10: return "fuelpump.fill"
        case .diesel: return "fuelpump.fill"
        case .lpg, .cng: return "flame.fill"
        case .hybrid, .pluginHybrid: return "leaf.arrow.circlepath"
        case .electric: return "bolt.car.fill"
        }
    }

    var usesLiters: Bool {
        switch self {
        case .electric: return false
        default: return true
        }
    }

    var unit: String {
        switch self {
        case .electric: return "kWh"
        default: return "L"
        }
    }
}
