//
//  ExtractedReceiptData.swift
//  CarTracker
//

import Foundation

struct ExtractedReceiptData {
    var date: Date?
    var liters: Double?
    var pricePerLiter: Double?
    var totalCost: Double?
    var stationName: String?
    var rawText: String

    var hasAnyData: Bool {
        date != nil || liters != nil || pricePerLiter != nil ||
        totalCost != nil || stationName != nil
    }

    init(
        date: Date? = nil,
        liters: Double? = nil,
        pricePerLiter: Double? = nil,
        totalCost: Double? = nil,
        stationName: String? = nil,
        rawText: String = ""
    ) {
        self.date = date
        self.liters = liters
        self.pricePerLiter = pricePerLiter
        self.totalCost = totalCost
        self.stationName = stationName
        self.rawText = rawText
    }
}
