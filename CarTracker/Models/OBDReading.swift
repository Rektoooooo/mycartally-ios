//
//  OBDReading.swift
//  CarTracker
//

import Foundation
import SwiftData

@Model
final class OBDReading {
    var id: UUID
    var timestamp: Date
    var rpm: Double?
    var speed: Double?
    var coolantTemp: Double?
    var fuelLevel: Double?
    var engineLoad: Double?
    var throttlePosition: Double?
    var voltage: Double?
    var oilTemp: Double?

    var car: Car?

    init(
        timestamp: Date = Date(),
        rpm: Double? = nil,
        speed: Double? = nil,
        coolantTemp: Double? = nil,
        fuelLevel: Double? = nil,
        engineLoad: Double? = nil,
        throttlePosition: Double? = nil,
        voltage: Double? = nil,
        oilTemp: Double? = nil,
        car: Car? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.rpm = rpm
        self.speed = speed
        self.coolantTemp = coolantTemp
        self.fuelLevel = fuelLevel
        self.engineLoad = engineLoad
        self.throttlePosition = throttlePosition
        self.voltage = voltage
        self.oilTemp = oilTemp
        self.car = car
    }
}
