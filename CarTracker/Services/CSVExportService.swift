//
//  CSVExportService.swift
//  CarTracker
//

import Foundation

class CSVExportService {
    static let shared = CSVExportService()

    private init() {}

    // MARK: - Export Fuel Entries

    func exportFuelEntries(_ entries: [FuelEntry], carName: String? = nil) -> String {
        var csv = "Date,Odometer (km),Liters,Price per Liter,Total Cost,Full Tank,Station,Notes"
        if carName == nil {
            csv = "Car," + csv
        }
        csv += "\n"

        let sortedEntries = entries.sorted { $0.date > $1.date }

        for entry in sortedEntries {
            var row: [String] = []

            if carName == nil {
                row.append(escapeCSV(entry.car?.displayName ?? "Unknown"))
            }

            row.append(formatDate(entry.date))
            row.append("\(entry.odometer)")
            row.append(String(format: "%.2f", entry.liters))
            row.append(String(format: "%.3f", entry.pricePerLiter))
            row.append(String(format: "%.2f", entry.totalCost))
            row.append(entry.isFullTank ? "Yes" : "No")
            row.append(escapeCSV(entry.stationName ?? ""))
            row.append(escapeCSV(entry.notes ?? ""))

            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    // MARK: - Export Expenses

    func exportExpenses(_ expenses: [Expense], carName: String? = nil) -> String {
        var csv = "Date,Category,Subcategory,Amount,Odometer (km),Provider,Notes"
        if carName == nil {
            csv = "Car," + csv
        }
        csv += "\n"

        let sortedExpenses = expenses.sorted { $0.date > $1.date }

        for expense in sortedExpenses {
            var row: [String] = []

            if carName == nil {
                row.append(escapeCSV(expense.car?.displayName ?? "Unknown"))
            }

            row.append(formatDate(expense.date))
            row.append(escapeCSV(expense.category.rawValue))
            row.append(escapeCSV(expense.subcategory ?? ""))
            row.append(String(format: "%.2f", expense.amount))
            row.append(expense.odometer != nil ? "\(expense.odometer!)" : "")
            row.append(escapeCSV(expense.serviceProvider ?? ""))
            row.append(escapeCSV(expense.notes ?? ""))

            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    // MARK: - Export Reminders

    func exportReminders(_ reminders: [Reminder], carName: String? = nil) -> String {
        var csv = "Type,Title,Due Date,Due Odometer,Recurring,Completed,Completed Date,Notes"
        if carName == nil {
            csv = "Car," + csv
        }
        csv += "\n"

        let sortedReminders = reminders.sorted { ($0.dueDate ?? .distantFuture) > ($1.dueDate ?? .distantFuture) }

        for reminder in sortedReminders {
            var row: [String] = []

            if carName == nil {
                row.append(escapeCSV(reminder.car?.displayName ?? "Unknown"))
            }

            row.append(escapeCSV(reminder.type.rawValue))
            row.append(escapeCSV(reminder.title))
            row.append(reminder.dueDate != nil ? formatDate(reminder.dueDate!) : "")
            row.append(reminder.dueOdometer != nil ? "\(reminder.dueOdometer!)" : "")
            row.append(reminder.isRecurring ? "Yes" : "No")
            row.append(reminder.isCompleted ? "Yes" : "No")
            row.append(reminder.completedDate != nil ? formatDate(reminder.completedDate!) : "")
            row.append(escapeCSV(reminder.notes ?? ""))

            csv += row.joined(separator: ",") + "\n"
        }

        return csv
    }

    // MARK: - Export All Data

    func exportAllData(
        cars: [Car],
        fuelEntries: [FuelEntry],
        expenses: [Expense],
        reminders: [Reminder]
    ) -> String {
        var csv = "=== CARS ===\n"
        csv += "Name,Make,Model,Year,License Plate,VIN,Fuel Type,Current Odometer,Created\n"

        for car in cars {
            let row = [
                escapeCSV(car.displayName),
                escapeCSV(car.make),
                escapeCSV(car.model),
                "\(car.year)",
                escapeCSV(car.licensePlate),
                escapeCSV(car.vin ?? ""),
                escapeCSV(car.fuelType.rawValue),
                "\(car.currentOdometer)",
                formatDate(car.createdAt)
            ]
            csv += row.joined(separator: ",") + "\n"
        }

        csv += "\n=== FUEL ENTRIES ===\n"
        csv += exportFuelEntries(fuelEntries)

        csv += "\n=== EXPENSES ===\n"
        csv += exportExpenses(expenses)

        csv += "\n=== REMINDERS ===\n"
        csv += exportReminders(reminders)

        return csv
    }

    // MARK: - Helpers

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Export Helper Extension

extension String {
    func toCSVData() -> Data {
        Data(self.utf8)
    }
}
