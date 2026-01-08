//
//  WidgetDataService.swift
//  CarTracker
//

import Foundation
import WidgetKit

// MARK: - Widget Data Models

struct WidgetCarData: Codable {
    let id: UUID
    let displayName: String
    let currentOdometer: Int?
    let fuelType: String
    let imageData: Data?
}

struct WidgetReminderData: Codable {
    let id: UUID
    let title: String
    let type: String
    let dueDate: Date?
    let daysUntilDue: Int?
    let isOverdue: Bool
    let carName: String?
}

struct WidgetFuelData: Codable {
    let lastFillUpDate: Date?
    let lastConsumption: Double?
    let averageConsumption: Double?
    let totalCostThisMonth: Double
    let lastPricePerLiter: Double?
}

struct WidgetData: Codable {
    let cars: [WidgetCarData]
    let upcomingReminders: [WidgetReminderData]
    let fuelData: WidgetFuelData
    let selectedCarId: UUID?
    let lastUpdated: Date
}

// MARK: - Widget Data Service

class WidgetDataService {
    static let shared = WidgetDataService()

    private let appGroupIdentifier = "group.com.cartracker.shared"
    private let widgetDataKey = "widgetData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Save Data for Widget

    func updateWidgetData(
        cars: [Car],
        reminders: [Reminder],
        fuelEntries: [FuelEntry],
        selectedCarId: UUID?
    ) {
        // Map cars
        let widgetCars = cars.map { car in
            WidgetCarData(
                id: car.id,
                displayName: car.displayName,
                currentOdometer: car.currentOdometer,
                fuelType: car.fuelType.rawValue,
                imageData: car.photoData
            )
        }

        // Get upcoming reminders (not completed, sorted by due date)
        let upcomingReminders = reminders
            .filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(5)
            .map { reminder in
                WidgetReminderData(
                    id: reminder.id,
                    title: reminder.title,
                    type: reminder.type.rawValue,
                    dueDate: reminder.dueDate,
                    daysUntilDue: reminder.daysUntilDue,
                    isOverdue: reminder.isOverdue,
                    carName: reminder.car?.displayName
                )
            }

        // Calculate fuel data
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let thisMonthEntries = fuelEntries.filter { $0.date >= startOfMonth }
        let totalCostThisMonth = thisMonthEntries.reduce(0) { $0 + $1.totalCost }

        let sortedEntries = fuelEntries.sorted { $0.date > $1.date }
        let lastEntry = sortedEntries.first

        // Calculate last consumption
        var lastConsumption: Double?
        if let last = lastEntry, let previous = sortedEntries.dropFirst().first {
            if last.isFullTank && previous.isFullTank {
                let distance = last.odometer - previous.odometer
                if distance > 0 {
                    lastConsumption = (last.liters / Double(distance)) * 100
                }
            }
        }

        // Calculate average consumption
        let avgConsumption = CalculationService.averageConsumption(entries: Array(fuelEntries))

        let fuelData = WidgetFuelData(
            lastFillUpDate: lastEntry?.date,
            lastConsumption: lastConsumption,
            averageConsumption: avgConsumption,
            totalCostThisMonth: totalCostThisMonth,
            lastPricePerLiter: lastEntry?.pricePerLiter
        )

        let widgetData = WidgetData(
            cars: widgetCars,
            upcomingReminders: Array(upcomingReminders),
            fuelData: fuelData,
            selectedCarId: selectedCarId,
            lastUpdated: Date()
        )

        // Save to shared defaults
        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults?.set(encoded, forKey: widgetDataKey)
        }

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Load Data for Widget

    func loadWidgetData() -> WidgetData? {
        guard let data = sharedDefaults?.data(forKey: widgetDataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return widgetData
    }

    // MARK: - Preview Data

    static var previewData: WidgetData {
        WidgetData(
            cars: [
                WidgetCarData(
                    id: UUID(),
                    displayName: "VW Golf",
                    currentOdometer: 125000,
                    fuelType: "Petrol E10",
                    imageData: nil
                )
            ],
            upcomingReminders: [
                WidgetReminderData(
                    id: UUID(),
                    title: "TÜV Inspection",
                    type: "Inspection",
                    dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                    daysUntilDue: 15,
                    isOverdue: false,
                    carName: "VW Golf"
                ),
                WidgetReminderData(
                    id: UUID(),
                    title: "Oil Change",
                    type: "Oil Change",
                    dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                    daysUntilDue: 30,
                    isOverdue: false,
                    carName: "VW Golf"
                )
            ],
            fuelData: WidgetFuelData(
                lastFillUpDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                lastConsumption: 7.2,
                averageConsumption: 7.5,
                totalCostThisMonth: 156.50,
                lastPricePerLiter: 1.589
            ),
            selectedCarId: nil,
            lastUpdated: Date()
        )
    }
}
