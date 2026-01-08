//
//  CalculationService.swift
//  CarTracker
//

import Foundation

struct CalculationService {

    // MARK: - Fuel Consumption

    /// Calculate fuel consumption in L/100km between two fuel entries
    static func calculateConsumption(currentEntry: FuelEntry, previousEntry: FuelEntry) -> Double? {
        guard currentEntry.isFullTank && previousEntry.isFullTank else { return nil }

        let distance = currentEntry.odometer - previousEntry.odometer
        guard distance > 0 else { return nil }

        let consumption = (currentEntry.liters / Double(distance)) * 100
        return consumption
    }

    /// Calculate average consumption from fuel entries
    static func averageConsumption(entries: [FuelEntry]) -> Double? {
        let sortedEntries = entries.sorted { $0.odometer < $1.odometer }

        guard sortedEntries.count >= 2 else { return nil }

        var consumptions: [Double] = []
        consumptions.reserveCapacity(sortedEntries.count - 1)

        for i in 1..<sortedEntries.count {
            if let consumption = calculateConsumption(
                currentEntry: sortedEntries[i],
                previousEntry: sortedEntries[i - 1]
            ) {
                consumptions.append(consumption)
            }
        }

        guard !consumptions.isEmpty else { return nil }
        return consumptions.reduce(0, +) / Double(consumptions.count)
    }

    /// Get consumption for each fill-up
    static func consumptionHistory(entries: [FuelEntry]) -> [(entry: FuelEntry, consumption: Double?)] {
        let sortedEntries = entries.sorted { $0.odometer < $1.odometer }
        var result: [(entry: FuelEntry, consumption: Double?)] = []

        for i in 0..<sortedEntries.count {
            if i == 0 {
                result.append((sortedEntries[i], nil))
            } else {
                let consumption = calculateConsumption(
                    currentEntry: sortedEntries[i],
                    previousEntry: sortedEntries[i-1]
                )
                result.append((sortedEntries[i], consumption))
            }
        }

        return result.reversed() // Most recent first
    }

    // MARK: - Cost Calculations

    /// Total fuel cost for a car
    static func totalFuelCost(entries: [FuelEntry]) -> Double {
        entries.reduce(0) { $0 + $1.totalCost }
    }

    /// Total expenses for a car
    static func totalExpenses(expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Total cost of ownership (fuel + expenses)
    static func totalCostOfOwnership(fuelEntries: [FuelEntry], expenses: [Expense]) -> Double {
        totalFuelCost(entries: fuelEntries) + totalExpenses(expenses: expenses)
    }

    /// Expenses grouped by category
    static func expensesByCategory(expenses: [Expense]) -> [ExpenseCategory: Double] {
        var result: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            result[expense.category, default: 0] += expense.amount
        }
        return result
    }

    /// Monthly costs for the past N months
    static func monthlyCosts(fuelEntries: [FuelEntry], expenses: [Expense], months: Int = 6) -> [(month: Date, fuel: Double, expenses: Double)] {
        let calendar = Calendar.current
        var result: [(month: Date, fuel: Double, expenses: Double)] = []

        for i in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: Date()),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            let startOfMonth = calendar.startOfMonth(for: monthStart)

            let monthFuel = fuelEntries
                .filter { $0.date >= startOfMonth && $0.date < monthEnd }
                .reduce(0) { $0 + $1.totalCost }

            let monthExpenses = expenses
                .filter { $0.date >= startOfMonth && $0.date < monthEnd }
                .reduce(0) { $0 + $1.amount }

            result.append((startOfMonth, monthFuel, monthExpenses))
        }

        return result.reversed()
    }

    /// Cost per kilometer
    static func costPerKm(fuelEntries: [FuelEntry], expenses: [Expense]) -> Double? {
        guard let firstEntry = fuelEntries.min(by: { $0.odometer < $1.odometer }),
              let lastEntry = fuelEntries.max(by: { $0.odometer < $1.odometer }) else { return nil }

        let distance = lastEntry.odometer - firstEntry.odometer
        guard distance > 0 else { return nil }

        let totalCost = totalCostOfOwnership(fuelEntries: fuelEntries, expenses: expenses)
        return totalCost / Double(distance)
    }

    // MARK: - Distance

    /// Total distance driven (from fuel entries)
    static func totalDistance(entries: [FuelEntry]) -> Int {
        guard let first = entries.min(by: { $0.odometer < $1.odometer }),
              let last = entries.max(by: { $0.odometer < $1.odometer }) else { return 0 }
        return last.odometer - first.odometer
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
