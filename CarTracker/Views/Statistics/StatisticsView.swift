//
//  StatisticsView.swift
//  CarTracker
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \FuelEntry.date, order: .reverse) private var allFuelEntries: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var selectedPeriod = 0

    let periods = ["Month", "Quarter", "Year", "All"]
    

    var selectedCar: Car? {
        appState.getSelectedCar(from: cars)
    }

    var filteredFuelEntries: [FuelEntry] {
        var entries = allFuelEntries
        if let car = selectedCar {
            entries = entries.filter { $0.car?.id == car.id }
        }
        return filterByPeriod(entries.map { $0.date }, items: entries)
    }

    var filteredExpenses: [Expense] {
        var expenses = allExpenses
        if let car = selectedCar {
            expenses = expenses.filter { $0.car?.id == car.id }
        }
        return filterByPeriod(expenses.map { $0.date }, items: expenses)
    }

    func filterByPeriod<T>(_ dates: [Date], items: [T]) -> [T] {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date

        switch selectedPeriod {
        case 0: // Month
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case 1: // Quarter
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case 2: // Year
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        default: // All
            return items
        }

        return zip(dates, items).filter { $0.0 >= startDate }.map { $0.1 }
    }

    var totalFuelCost: Double {
        CalculationService.totalFuelCost(entries: filteredFuelEntries)
    }

    var totalExpensesCost: Double {
        CalculationService.totalExpenses(expenses: filteredExpenses)
    }

    var totalDistance: Int {
        CalculationService.totalDistance(entries: filteredFuelEntries)
    }

    var averageConsumption: Double? {
        CalculationService.averageConsumption(entries: filteredFuelEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(0..<periods.count, id: \.self) { index in
                            Text(periods[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredFuelEntries.isEmpty && filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.bar",
                            description: Text("Add fuel entries and expenses to see statistics")
                        )
                        .padding(.top, 40)
                    } else {
                        // Summary Cards
                        SummaryCardsView(
                            totalSpent: totalFuelCost + totalExpensesCost,
                            fuelCost: totalFuelCost,
                            consumption: averageConsumption,
                            distance: totalDistance
                        )

                        // Fuel Cost Chart
                        if !filteredFuelEntries.isEmpty {
                            FuelCostChartView(entries: filteredFuelEntries)
                        }

                        // Consumption Chart
                        if let _ = averageConsumption {
                            ConsumptionChartView(entries: filteredFuelEntries)
                        }

                        // Expense Breakdown
                        if !filteredExpenses.isEmpty {
                            ExpenseBreakdownView(expenses: filteredExpenses)
                        }

                        // Cost Analysis
                        if totalDistance > 0 {
                            CostPerKmView(
                                costPerKm: (totalFuelCost + totalExpensesCost) / Double(totalDistance),
                                monthlyAvg: (totalFuelCost + totalExpensesCost) / max(1, Double(monthsInPeriod))
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }

    var monthsInPeriod: Int {
        switch selectedPeriod {
        case 0: return 1
        case 1: return 3
        case 2: return 12
        default: return 12
        }
    }
}

// MARK: - Summary Cards

struct SummaryCardsView: View {
    let totalSpent: Double
    let fuelCost: Double
    let consumption: Double?
    let distance: Int
    
    let settings = UserSettings.shared

    var fuelPercentage: Int {
        guard totalSpent > 0 else { return 0 }
        return Int((fuelCost / totalSpent) * 100)
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Total Spent",
                value: String(format: "%.0f \(settings.currency.symbol)", totalSpent),
                icon: "eurosign.circle.fill",
                color: .blue,
                subtitle: "This period"
            )

            SummaryCard(
                title: "Fuel Cost",
                value: String(format: "%.0f \(settings.currency.symbol)", fuelCost),
                icon: "fuelpump.fill",
                color: .orange,
                subtitle: "\(fuelPercentage)% of total"
            )

            SummaryCard(
                title: "Avg. Consumption",
                value: consumption != nil ? String(format: "%.1f", consumption!) : "--",
                icon: "gauge.with.dots.needle.67percent",
                color: .green,
                subtitle: settings.distanceUnit.consumptionLabel
            )

            SummaryCard(
                title: "Distance",
                value: distance.formatted(),
                icon: "road.lanes",
                color: .purple,
                subtitle: "\(settings.distanceUnit.abbreviation) driven"
            )
        }
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Fuel Cost Chart

struct FuelCostChartView: View {
    let settings = UserSettings.shared

    let entries: [FuelEntry]

    var monthlyData: [(month: String, cost: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var grouped: [String: Double] = [:]

        for entry in entries {
            let monthKey = formatter.string(from: entry.date)
            grouped[monthKey, default: 0] += entry.totalCost
        }

        // Get last 6 months in order
        var result: [(String, Double)] = []
        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let key = formatter.string(from: date)
                result.append((key, grouped[key] ?? 0))
            }
        }

        return result
    }

    var total: Double {
        monthlyData.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fuel Costs")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f \(settings.currency.symbol)", total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Chart {
                ForEach(monthlyData, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Cost", item.cost)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

// MARK: - Consumption Chart

struct ConsumptionChartView: View {
    let entries: [FuelEntry]
    let settings = UserSettings.shared

    var consumptionData: [(date: String, consumption: Double)] {
        let history = CalculationService.consumptionHistory(entries: entries)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return history.compactMap { item -> (String, Double)? in
            guard let consumption = item.consumption else { return nil }
            return (formatter.string(from: item.entry.date), consumption)
        }.prefix(10).reversed().map { $0 }
    }

    var average: Double {
        guard !consumptionData.isEmpty else { return 0 }
        return consumptionData.reduce(0) { $0 + $1.consumption } / Double(consumptionData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fuel Consumption")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text("Avg:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", average))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            if !consumptionData.isEmpty {
                Chart {
                    ForEach(consumptionData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Consumption", item.consumption)
                        )
                        .foregroundStyle(.green)
                        .symbol(.circle)

                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Consumption", item.consumption)
                        )
                        .foregroundStyle(.green.opacity(0.1))
                    }

                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(dash: [5, 5]))
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Expense Breakdown

struct ExpenseBreakdownView: View {
    let settings = UserSettings.shared

    let expenses: [Expense]

    var byCategory: [(category: ExpenseCategory, amount: Double)] {
        let grouped = CalculationService.expensesByCategory(expenses: expenses)
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var total: Double {
        byCategory.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expense Breakdown")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f \(settings.currency.symbol)", total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                // Pie Chart
                if !byCategory.isEmpty {
                    Chart {
                        ForEach(byCategory, id: \.category) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(item.category.color)
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 160)
                }

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(byCategory.prefix(6), id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 10, height: 10)

                            Text(item.category.rawValue)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "%.0f \(settings.currency.symbol)", item.amount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

// MARK: - Cost per KM

struct CostPerKmView: View {
    let settings = UserSettings.shared

    let costPerKm: Double
    let monthlyAvg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Analysis")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                CostMetricCard(
                    title: "Cost per km",
                    value: String(format: "%.2f \(settings.currency.symbol)", costPerKm)
                )

                CostMetricCard(
                    title: "Monthly Avg",
                    value: String(format: "%.0f \(settings.currency.symbol)", monthlyAvg)
                )
            }
            .padding(.horizontal)
        }
    }
}

struct CostMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self], inMemory: true)
        .environment(AppState())
}
