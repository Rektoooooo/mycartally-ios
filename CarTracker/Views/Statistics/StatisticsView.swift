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
    @State private var appeared = false

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
                VStack(spacing: AppDesign.Spacing.lg) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(0..<periods.count, id: \.self) { index in
                            Text(periods[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppDesign.Spacing.md)

                    if filteredFuelEntries.isEmpty && filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.bar",
                            description: Text("Add fuel entries and expenses to see statistics")
                        )
                        .padding(.top, AppDesign.Spacing.xxxl)
                    } else {
                        // Summary Cards
                        SummaryCardsView(
                            totalSpent: totalFuelCost + totalExpensesCost,
                            fuelCost: totalFuelCost,
                            consumption: averageConsumption,
                            distance: totalDistance
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                        // Fuel Cost Chart
                        if !filteredFuelEntries.isEmpty {
                            FuelCostChartView(entries: filteredFuelEntries)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                        }

                        // Consumption Chart
                        if let _ = averageConsumption {
                            ConsumptionChartView(entries: filteredFuelEntries)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                        }

                        // Expense Breakdown
                        if !filteredExpenses.isEmpty {
                            ExpenseBreakdownView(expenses: filteredExpenses)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                        }

                        // Cost Analysis
                        if totalDistance > 0 {
                            CostPerKmView(
                                costPerKm: (totalFuelCost + totalExpensesCost) / Double(totalDistance),
                                monthlyAvg: (totalFuelCost + totalExpensesCost) / max(1, Double(monthsInPeriod))
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        }
                    }
                }
                .padding(.vertical)
                .animation(.easeInOut(duration: 0.3), value: selectedPeriod)
            }
            .background(AppDesign.Colors.background)
            .navigationTitle("Statistics")
            .onAppear {
                withAnimation(AppDesign.Animation.bouncy.delay(0.15)) {
                    appeared = true
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    appeared = false
                }
                withAnimation(AppDesign.Animation.bouncy.delay(0.2)) {
                    appeared = true
                }
            }
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppDesign.Spacing.sm) {
            SummaryCard(
                title: "Total Spent",
                value: String(format: "%.0f \(settings.currency.symbol)", totalSpent),
                icon: "eurosign.circle.fill",
                color: AppDesign.Colors.accent,
                subtitle: "This period"
            )

            SummaryCard(
                title: "Fuel Cost",
                value: String(format: "%.0f \(settings.currency.symbol)", fuelCost),
                icon: "fuelpump.fill",
                color: AppDesign.Colors.fuel,
                subtitle: "\(fuelPercentage)% of total"
            )

            SummaryCard(
                title: "Avg. Consumption",
                value: consumption != nil ? String(format: "%.1f", consumption!) : "--",
                icon: "gauge.with.dots.needle.67percent",
                color: AppDesign.Colors.stats,
                subtitle: settings.distanceUnit.consumptionLabel
            )

            SummaryCard(
                title: "Distance",
                value: distance.formatted(),
                icon: "road.lanes",
                color: AppDesign.Colors.reminders,
                subtitle: "\(settings.distanceUnit.abbreviation) driven"
            )
        }
        .padding(.horizontal, AppDesign.Spacing.md)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .iconBadge(color: color, size: 42, iconSize: .callout, cornerRadius: AppDesign.Radius.xs)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.textSecondary)
                Text(subtitle)
                    .font(AppDesign.Typography.caption2)
                    .foregroundStyle(AppDesign.Colors.textTertiary)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        .background(
            ZStack(alignment: .top) {
                AppDesign.Colors.cardBackground
                color.frame(height: 3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "fuelpump.fill")
                        .font(.caption)
                        .foregroundStyle(AppDesign.Colors.fuel)
                    Text("Fuel Costs")
                        .font(AppDesign.Typography.headline)
                }
                Spacer()
                Text(String(format: "%.0f \(settings.currency.symbol)", total))
                    .font(AppDesign.Typography.bodyMedium)
                    .foregroundStyle(AppDesign.Colors.fuel)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, AppDesign.Spacing.md)

            VStack(spacing: 0) {
                Chart {
                    ForEach(monthlyData, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Cost", item.cost)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppDesign.Colors.fuel, AppDesign.Colors.fuel.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: true))
                .animation(.easeInOut(duration: 0.4), value: monthlyData.map(\.cost))
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(AppDesign.Colors.textTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(AppDesign.Colors.textSecondary)
                    }
                }
                .padding(AppDesign.Spacing.md)
            }
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .padding(.horizontal, AppDesign.Spacing.md)
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
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.caption)
                        .foregroundStyle(AppDesign.Colors.stats)
                    Text("Fuel Consumption")
                        .font(AppDesign.Typography.headline)
                }
                Spacer()
                HStack(spacing: AppDesign.Spacing.xxs) {
                    Text("Avg:")
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                    Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", average))
                        .fontWeight(.medium)
                        .foregroundStyle(AppDesign.Colors.stats)
                        .contentTransition(.numericText())
                }
                .font(AppDesign.Typography.subheadline)
            }
            .padding(.horizontal, AppDesign.Spacing.md)

            if !consumptionData.isEmpty {
                VStack(spacing: 0) {
                    Chart {
                        ForEach(consumptionData, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Consumption", item.consumption)
                            )
                            .foregroundStyle(AppDesign.Colors.stats)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .symbol(.circle)

                            AreaMark(
                                x: .value("Date", item.date),
                                y: .value("Consumption", item.consumption)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppDesign.Colors.stats.opacity(0.2), AppDesign.Colors.stats.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }

                        RuleMark(y: .value("Average", average))
                            .foregroundStyle(AppDesign.Colors.stats.opacity(0.4))
                            .lineStyle(StrokeStyle(dash: [5, 5]))
                    }
                    .animation(.easeInOut(duration: 0.4), value: consumptionData.map(\.consumption))
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(AppDesign.Colors.textTertiary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(AppDesign.Colors.textSecondary)
                        }
                    }
                    .padding(AppDesign.Spacing.md)
                }
                .background(AppDesign.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                .padding(.horizontal, AppDesign.Spacing.md)
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
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                HStack(spacing: AppDesign.Spacing.xs) {
                    Image(systemName: "chart.pie.fill")
                        .font(.caption)
                        .foregroundStyle(AppDesign.Colors.accent)
                    Text("Expense Breakdown")
                        .font(AppDesign.Typography.headline)
                }
                Spacer()
                Text(String(format: "%.0f \(settings.currency.symbol)", total))
                    .font(AppDesign.Typography.bodyMedium)
                    .foregroundStyle(AppDesign.Colors.accent)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, AppDesign.Spacing.md)

            VStack(spacing: AppDesign.Spacing.md) {
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
                    .animation(.easeInOut(duration: 0.4), value: byCategory.map(\.amount))
                    .frame(height: 180)
                }

                // Legend
                VStack(spacing: AppDesign.Spacing.xs) {
                    ForEach(byCategory.prefix(6), id: \.category) { item in
                        HStack(spacing: AppDesign.Spacing.sm) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.color)
                                .frame(width: 14, height: 14)

                            Text(item.category.rawValue)
                                .font(AppDesign.Typography.subheadline)
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "%.0f \(settings.currency.symbol)", item.amount))
                                .font(AppDesign.Typography.subheadline)
                                .fontWeight(.medium)

                            if total > 0 {
                                Text(String(format: "%.0f%%", (item.amount / total) * 100))
                                    .font(AppDesign.Typography.caption)
                                    .foregroundStyle(AppDesign.Colors.textTertiary)
                                    .frame(width: 36, alignment: .trailing)
                            }
                        }

                        if item.category != byCategory.prefix(6).last?.category {
                            Divider()
                        }
                    }
                }
            }
            .padding(AppDesign.Spacing.md)
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .padding(.horizontal, AppDesign.Spacing.md)
        }
    }
}

// MARK: - Cost per KM

struct CostPerKmView: View {
    let settings = UserSettings.shared

    let costPerKm: Double
    let monthlyAvg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack(spacing: AppDesign.Spacing.xs) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.caption)
                    .foregroundStyle(AppDesign.Colors.stats)
                Text("Cost Analysis")
                    .font(AppDesign.Typography.headline)
            }
            .padding(.horizontal, AppDesign.Spacing.md)

            HStack(spacing: AppDesign.Spacing.sm) {
                CostMetricCard(
                    title: "Cost per km",
                    value: String(format: "%.2f \(settings.currency.symbol)", costPerKm),
                    icon: "road.lanes",
                    color: AppDesign.Colors.accent
                )

                CostMetricCard(
                    title: "Monthly Avg",
                    value: String(format: "%.0f \(settings.currency.symbol)", monthlyAvg),
                    icon: "calendar",
                    color: AppDesign.Colors.stats
                )
            }
            .padding(.horizontal, AppDesign.Spacing.md)
        }
    }
}

struct CostMetricCard: View {
    let title: String
    let value: String
    var icon: String = ""
    var color: Color = AppDesign.Colors.accent

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(AppDesign.Colors.textSecondary)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        .background(
            ZStack(alignment: .top) {
                AppDesign.Colors.cardBackground
                color.frame(height: 3)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self], inMemory: true)
        .environment(AppState())
}
