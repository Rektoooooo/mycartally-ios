//
//  FuelEntry.swift
//  CarTracker
//

import Foundation
import SwiftData

@Model
final class FuelEntry {
    var id: UUID
    var date: Date
    var odometer: Int
    var liters: Double
    var pricePerLiter: Double
    var totalCost: Double
    var isFullTank: Bool
    var stationName: String?
    var stationLocation: String?
    var fuelType: FuelType
    var notes: String?
    var receiptPhotoData: Data?
    var createdAt: Date

    var car: Car?

    init(
        date: Date = Date(),
        odometer: Int,
        liters: Double,
        pricePerLiter: Double,
        totalCost: Double? = nil,
        isFullTank: Bool = true,
        stationName: String? = nil,
        stationLocation: String? = nil,
        fuelType: FuelType = .petrolE10,
        notes: String? = nil,
        receiptPhotoData: Data? = nil,
        car: Car? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.odometer = odometer
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.totalCost = totalCost ?? (liters * pricePerLiter)
        self.isFullTank = isFullTank
        self.stationName = stationName
        self.stationLocation = stationLocation
        self.fuelType = fuelType
        self.notes = notes
        self.receiptPhotoData = receiptPhotoData
        self.car = car
        self.createdAt = Date()
    }

    var formattedCost: String {
        String(format: "%.2f", totalCost)
    }

    var formattedLiters: String {
        String(format: "%.2f \(UserSettings.shared.volumeUnit.abbreviation)", liters)
    }

    var formattedPricePerLiter: String {
        String(format: "%.3f \(UserSettings.shared.currency.symbol)/\(UserSettings.shared.volumeUnit.abbreviation)", pricePerLiter)
    }
}
