//
//  AppState.swift
//  CarTracker
//

import SwiftUI
import SwiftData

@Observable
class AppState {
    var selectedCarId: UUID?
    var showingOnboarding: Bool = false

    init() {
        // Load saved car selection from UserDefaults
        if let idString = UserDefaults.standard.string(forKey: "selectedCarId"),
           let id = UUID(uuidString: idString) {
            self.selectedCarId = id
        }
    }

    func selectCar(_ car: Car) {
        selectedCarId = car.id
        UserDefaults.standard.set(car.id.uuidString, forKey: "selectedCarId")
    }

    func getSelectedCar(from cars: [Car]) -> Car? {
        if let selectedId = selectedCarId {
            return cars.first { $0.id == selectedId }
        }
        return cars.first
    }
}
