//
//  CarDetailView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct CarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let car: Car

    @Query private var fuelEntries: [FuelEntry]
    @Query private var expenses: [Expense]
    @Query private var reminders: [Reminder]

    @State private var selectedSegment = 0
    @State private var showingEditCar = false
    @State private var showingDeleteConfirm = false

    init(car: Car) {
        self.car = car
        let carId = car.id
        _fuelEntries = Query(filter: #Predicate<FuelEntry> { $0.car?.id == carId }, sort: \FuelEntry.date, order: .reverse)
        _expenses = Query(filter: #Predicate<Expense> { $0.car?.id == carId }, sort: \Expense.date, order: .reverse)
        _reminders = Query(filter: #Predicate<Reminder> { $0.car?.id == carId && !$0.isCompleted }, sort: \Reminder.dueDate)
    }

    var averageConsumption: Double? {
        CalculationService.averageConsumption(entries: fuelEntries)
    }

    var totalCost: Double {
        CalculationService.totalCostOfOwnership(fuelEntries: fuelEntries, expenses: expenses)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.lg) {
                // Car Header
                CarHeaderView(
                    car: car,
                    averageConsumption: averageConsumption,
                    totalCost: totalCost
                )

                // Segment Picker
                Picker("View", selection: $selectedSegment) {
                    Text("Overview").tag(0)
                    Text("Fuel").tag(1)
                    Text("Expenses").tag(2)
                    Text("Validity").tag(3)
                    Text("Reminders").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Content based on selection
                switch selectedSegment {
                case 0:
                    CarOverviewSection(car: car, fuelEntries: fuelEntries, expenses: expenses)
                case 1:
                    CarFuelSection(car: car, fuelEntries: fuelEntries)
                case 2:
                    CarExpensesSection(car: car, expenses: expenses)
                case 3:
                    CarValiditySection(car: car, expenses: expenses)
                case 4:
                    CarRemindersSection(car: car, reminders: reminders)
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, AppDesign.Spacing.lg)
        }
        .background(AppDesign.Colors.background)
        .navigationTitle(car.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditCar = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditCar) {
            AddCarView(carToEdit: car)
        }
        .alert("Delete Car?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCar()
            }
        } message: {
            Text("This will delete all fuel entries, expenses, and reminders for this car. This action cannot be undone.")
        }
    }

    private func deleteCar() {
        modelContext.delete(car)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Car Header

struct CarHeaderView: View {
    let car: Car
    let averageConsumption: Double?
    let totalCost: Double
    let settings = UserSettings.shared

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // Car Image
            ZStack {
                LinearGradient(
                    colors: [AppDesign.Colors.accent.opacity(0.4), AppDesign.Colors.accent.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let photoData = car.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppDesign.Colors.accent)
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.lg))
            .padding(.horizontal)

            // License Plate
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(AppDesign.Colors.accent)
                Text("EU")
                    .fontWeight(.bold)

                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 1, height: 20)

                Text(car.licensePlate)
                    .font(.title3)
                    .fontWeight(.bold)
                    .kerning(2)
            }
            .padding(.horizontal, AppDesign.Spacing.lg)
            .padding(.vertical, 10)
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.xs))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)

            // Quick Stats
            HStack(spacing: 0) {
                QuickStatItem(
                    value: "\(car.currentOdometer.formatted())",
                    label: settings.distanceUnit.abbreviation,
                    icon: "speedometer"
                )

                Divider()
                    .frame(height: 40)

                QuickStatItem(
                    value: averageConsumption != nil ? String(format: "%.1f", averageConsumption!) : "--",
                    label: settings.distanceUnit.consumptionLabel,
                    icon: "drop.fill"
                )

                Divider()
                    .frame(height: 40)

                QuickStatItem(
                    value: String(format: "%.0f \(settings.currency.symbol)", totalCost),
                    label: "Total Cost",
                    icon: "eurosign.circle.fill"
                )
            }
            .padding(.vertical, AppDesign.Spacing.sm)
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
            .padding(.horizontal)
        }
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: AppDesign.Spacing.xxs + 2) {
            HStack(spacing: AppDesign.Spacing.xxs) {
                Image(systemName: icon)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.accent)
                Text(value)
                    .font(AppDesign.Typography.headline)
            }
            Text(label)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Section

struct CarOverviewSection: View {
    let car: Car
    let fuelEntries: [FuelEntry]
    let expenses: [Expense]
    let settings = UserSettings.shared

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // Vehicle Details
            GroupBox {
                VStack(spacing: AppDesign.Spacing.sm) {
                    DetailRow(label: "Make", value: car.make)
                    Divider()
                    DetailRow(label: "Model", value: car.model)
                    if let variant = car.variant {
                        Divider()
                        DetailRow(label: "Variant", value: variant)
                    }
                    Divider()
                    DetailRow(label: "Year", value: String(car.year))
                    Divider()
                    DetailRow(label: "Fuel Type", value: car.fuelType.rawValue)
                    if let vin = car.vin {
                        Divider()
                        DetailRow(label: "VIN", value: vin)
                    }
                }
            } label: {
                Label("Vehicle Details", systemImage: "car.fill")
                    .font(AppDesign.Typography.headline)
            }
            .padding(.horizontal)

            // Ownership / Purchase Info
            if car.ownershipType == .owned {
                if let purchaseDate = car.purchaseDate {
                    GroupBox {
                        VStack(spacing: AppDesign.Spacing.sm) {
                            DetailRow(label: "Ownership", value: car.ownershipType.rawValue)
                            Divider()
                            DetailRow(label: "Purchase Date", value: purchaseDate.formatted(date: .abbreviated, time: .omitted))
                            if let price = car.purchasePrice {
                                Divider()
                                DetailRow(label: "Purchase Price", value: String(format: "%.0f \(settings.currency.symbol)", price))
                            }
                        }
                    } label: {
                        Label("Purchase Info", systemImage: "bag.fill")
                            .font(AppDesign.Typography.headline)
                    }
                    .padding(.horizontal)
                }
            }

            if car.ownershipType == .leased || car.ownershipType == .financed {
                GroupBox {
                    VStack(spacing: AppDesign.Spacing.sm) {
                        DetailRow(label: "Ownership", value: car.ownershipType.rawValue)
                        if let startDate = car.leasingStartDate {
                            Divider()
                            DetailRow(label: "Start Date", value: startDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        if let endDate = car.leasingEndDate {
                            Divider()
                            DetailRow(label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        if let downPayment = car.downPayment {
                            Divider()
                            DetailRow(label: "Down Payment", value: String(format: "%.0f \(settings.currency.symbol)", downPayment))
                        }
                        if let monthly = car.monthlyPayment {
                            Divider()
                            DetailRow(label: "Monthly Payment", value: String(format: "%.0f \(settings.currency.symbol)", monthly))
                        }
                        if let rate = car.interestRate {
                            Divider()
                            DetailRow(label: "Interest Rate", value: String(format: "%.2f%%", rate))
                        }
                        if let company = car.leasingCompany {
                            Divider()
                            DetailRow(label: car.ownershipType == .leased ? "Leasing Company" : "Finance Company", value: company)
                        }
                    }
                } label: {
                    Label(
                        car.ownershipType == .leased ? "Leasing Info" : "Financing Info",
                        systemImage: car.ownershipType == .leased ? "doc.text.fill" : "banknote.fill"
                    )
                    .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            }

            // Cost Summary
            GroupBox {
                VStack(spacing: AppDesign.Spacing.sm) {
                    DetailRow(label: "Total Fuel Cost", value: String(format: "%.2f \(settings.currency.symbol)", CalculationService.totalFuelCost(entries: fuelEntries)))
                    Divider()
                    DetailRow(label: "Total Expenses", value: String(format: "%.2f \(settings.currency.symbol)", CalculationService.totalExpenses(expenses: expenses)))
                    Divider()
                    DetailRow(label: "Distance Tracked", value: "\(CalculationService.totalDistance(entries: fuelEntries).formatted()) \(settings.distanceUnit.abbreviation)")
                    if let costPerKm = CalculationService.costPerKm(fuelEntries: fuelEntries, expenses: expenses) {
                        Divider()
                        DetailRow(label: "Cost per \(settings.distanceUnit.abbreviation)", value: String(format: "%.3f \(settings.currency.symbol)", costPerKm))
                    }
                }
            } label: {
                Label("Cost Summary", systemImage: "eurosign.circle.fill")
                    .font(AppDesign.Typography.headline)
            }
            .padding(.horizontal)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Fuel Section

struct CarFuelSection: View {
    let car: Car
    let fuelEntries: [FuelEntry]
    let settings = UserSettings.shared

    var consumptionHistory: [(entry: FuelEntry, consumption: Double?)] {
        CalculationService.consumptionHistory(entries: fuelEntries)
    }

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // Consumption Summary
            if let avg = CalculationService.averageConsumption(entries: fuelEntries) {
                GroupBox {
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                        HStack {
                            Text("Average Consumption")
                                .font(AppDesign.Typography.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", avg))
                                .font(AppDesign.Typography.headline)
                                .foregroundStyle(AppDesign.Colors.stats)
                        }
                    }
                } label: {
                    Label("Fuel Efficiency", systemImage: "chart.line.uptrend.xyaxis")
                        .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            }

            // Recent Fuel Entries
            if !fuelEntries.isEmpty {
                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(consumptionHistory.prefix(10).enumerated()), id: \.element.entry.id) { index, item in
                            FuelEntryRow(entry: item.entry, consumption: item.consumption)
                            if index < min(9, fuelEntries.count - 1) {
                                Divider()
                                    .padding(.leading, AppDesign.Spacing.xxxl)
                            }
                        }
                    }
                } label: {
                    Label("Fill-ups (\(fuelEntries.count))", systemImage: "fuelpump.fill")
                        .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "No Fuel Entries",
                    systemImage: "fuelpump",
                    description: Text("Add your first fuel entry to start tracking consumption")
                )
            }
        }
    }
}

struct FuelEntryRow: View {
    let entry: FuelEntry
    let consumption: Double?
    let settings = UserSettings.shared

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppDesign.Colors.fuel.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "fuelpump.fill")
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.fuel)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stationName ?? "Fill-up")
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Text(entry.formattedLiters)
                    Text("\u{2022}")
                    Text(entry.formattedPricePerLiter)
                    if let consumption = consumption {
                        Text("\u{2022}")
                        Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", consumption))
                            .foregroundStyle(AppDesign.Colors.stats)
                    }
                }
                .font(AppDesign.Typography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedCost)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.semibold)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppDesign.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppDesign.Spacing.xs)
    }
}

// MARK: - Expenses Section

struct CarExpensesSection: View {
    let car: Car
    let expenses: [Expense]
    let settings = UserSettings.shared

    var expensesByCategory: [(category: ExpenseCategory, amount: Double)] {
        let grouped = CalculationService.expensesByCategory(expenses: expenses)
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            // Category Breakdown
            if !expensesByCategory.isEmpty {
                GroupBox {
                    VStack(spacing: AppDesign.Spacing.sm) {
                        ForEach(expensesByCategory, id: \.category) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundStyle(item.category.color)
                                    .frame(width: AppDesign.Spacing.xl)

                                Text(item.category.rawValue)
                                    .font(AppDesign.Typography.subheadline)

                                Spacer()

                                Text(String(format: "%.0f \(settings.currency.symbol)", item.amount))
                                    .font(AppDesign.Typography.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                } label: {
                    Label("By Category", systemImage: "chart.pie.fill")
                        .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            }

            // Recent Expenses
            if !expenses.isEmpty {
                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(expenses.prefix(10).enumerated()), id: \.element.id) { index, expense in
                            ExpenseRow(expense: expense)
                            if index < min(9, expenses.count - 1) {
                                Divider()
                                    .padding(.leading, AppDesign.Spacing.xxxl)
                            }
                        }
                    }
                } label: {
                    Label("Expenses (\(expenses.count))", systemImage: "creditcard.fill")
                        .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text("Add expenses to track your car's costs")
                )
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: expense.category.icon)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.subcategory ?? expense.category.rawValue)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(expense.serviceProvider ?? expense.category.rawValue)
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let status = expense.validityStatus {
                        ValidityBadge(status: status)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.formattedAmount)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.semibold)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppDesign.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppDesign.Spacing.xs)
    }
}

// MARK: - Validity Section

struct CarValiditySection: View {
    let car: Car
    let expenses: [Expense]
    let settings = UserSettings.shared

    var validityExpenses: [Expense] {
        expenses.filter { $0.hasValidity }
            .sorted { expense1, expense2 in
                let status1 = expense1.validityStatus
                let status2 = expense2.validityStatus
                return sortOrder(status1) < sortOrder(status2)
            }
    }

    private func sortOrder(_ status: ValidityStatus?) -> Int {
        switch status {
        case .expired: return 0
        case .expiringSoon: return 1
        case .valid: return 2
        case nil: return 3
        }
    }

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            if !validityExpenses.isEmpty {
                // Summary cards
                let expired = validityExpenses.filter {
                    if case .expired = $0.validityStatus { return true }
                    return false
                }
                let expiringSoon = validityExpenses.filter {
                    if case .expiringSoon = $0.validityStatus { return true }
                    return false
                }
                let valid = validityExpenses.filter {
                    if case .valid = $0.validityStatus { return true }
                    return false
                }

                if !expired.isEmpty || !expiringSoon.isEmpty {
                    HStack(spacing: AppDesign.Spacing.sm) {
                        if !expired.isEmpty {
                            ValiditySummaryCard(
                                count: expired.count,
                                label: "Expired",
                                color: .red,
                                icon: "xmark.shield.fill"
                            )
                        }
                        if !expiringSoon.isEmpty {
                            ValiditySummaryCard(
                                count: expiringSoon.count,
                                label: "Expiring Soon",
                                color: .orange,
                                icon: "exclamationmark.triangle.fill"
                            )
                        }
                        if !valid.isEmpty {
                            ValiditySummaryCard(
                                count: valid.count,
                                label: "Valid",
                                color: .green,
                                icon: "checkmark.shield.fill"
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Expense list with validity info
                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(validityExpenses.enumerated()), id: \.element.id) { index, expense in
                            ValidityExpenseRow(expense: expense)
                            if index < validityExpenses.count - 1 {
                                Divider()
                                    .padding(.leading, AppDesign.Spacing.xxxl)
                            }
                        }
                    }
                } label: {
                    Label("Tracked Items (\(validityExpenses.count))", systemImage: "checkmark.shield.fill")
                        .font(AppDesign.Typography.headline)
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "No Validity Items",
                    systemImage: "checkmark.shield",
                    description: Text("Add expenses with validity periods (insurance, tax, inspection, toll) to track their expiry")
                )
            }
        }
    }
}

struct ValiditySummaryCard: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: AppDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(count)")
                .font(AppDesign.Typography.headline)
            Text(label)
                .font(AppDesign.Typography.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppDesign.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
    }
}

struct ValidityExpenseRow: View {
    let expense: Expense
    let settings = UserSettings.shared

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: expense.category.icon)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.subcategory ?? expense.category.rawValue)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    if let from = expense.validFrom, let until = expense.validUntil {
                        Text("\(from.formatted(date: .abbreviated, time: .omitted)) – \(until.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppDesign.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let status = expense.validityStatus {
                ValidityBadge(status: status)
            }
        }
        .padding(.vertical, AppDesign.Spacing.xs)
    }
}

// MARK: - Reminders Section

struct CarRemindersSection: View {
    let car: Car
    let reminders: [Reminder]

    @State private var showingAddReminder = false

    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            if !reminders.isEmpty {
                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                            ReminderDetailRow(reminder: reminder)
                            if index < reminders.count - 1 {
                                Divider()
                                    .padding(.leading, AppDesign.Spacing.xxxl)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label("Active Reminders", systemImage: "bell.fill")
                            .font(AppDesign.Typography.headline)
                        Spacer()
                        Button {
                            showingAddReminder = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppDesign.Colors.accent)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "No Reminders",
                    systemImage: "bell",
                    description: Text("Add reminders for service and inspections")
                )

                Button {
                    showingAddReminder = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Reminder")
                    }
                    .font(AppDesign.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppDesign.Spacing.xl)
                    .padding(.vertical, AppDesign.Spacing.sm)
                    .background(AppDesign.Colors.accent)
                    .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(preselectedCar: car)
        }
    }
}

struct ReminderDetailRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(reminder.type.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: reminder.type.icon)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(reminder.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let days = reminder.daysUntilDue {
                DueBadge(days: days)
            }
        }
        .padding(.vertical, AppDesign.Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        CarDetailView(car: SampleData.sampleCar1)
    }
    .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
    .environment(AppState())
}
