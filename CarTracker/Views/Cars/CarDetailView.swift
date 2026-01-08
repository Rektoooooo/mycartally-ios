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
            VStack(spacing: 20) {
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
                    Text("Reminders").tag(3)
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
                    CarRemindersSection(car: car, reminders: reminders)
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
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
        VStack(spacing: 16) {
            // Car Image
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.4), .blue.opacity(0.1)],
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
                        .foregroundStyle(.blue)
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)

            // License Plate
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.blue)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

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
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
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
        VStack(spacing: 16) {
            // Vehicle Details
            GroupBox {
                VStack(spacing: 12) {
                    DetailRow(label: "Make", value: car.make)
                    Divider()
                    DetailRow(label: "Model", value: car.model)
                    if let variant = car.variant {
                        Divider()
                        DetailRow(label: "Variant", value: variant)
                    }
                    Divider()
                    DetailRow(label: "Year", value: "\(car.year)")
                    Divider()
                    DetailRow(label: "Fuel Type", value: car.fuelType.rawValue)
                    if let vin = car.vin {
                        Divider()
                        DetailRow(label: "VIN", value: vin)
                    }
                }
            } label: {
                Label("Vehicle Details", systemImage: "car.fill")
                    .font(.headline)
            }
            .padding(.horizontal)

            // Purchase Info
            if let purchaseDate = car.purchaseDate {
                GroupBox {
                    VStack(spacing: 12) {
                        DetailRow(label: "Purchase Date", value: purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        if let price = car.purchasePrice {
                            Divider()
                            DetailRow(label: "Purchase Price", value: String(format: "%.0f \(settings.currency.symbol)", price))
                        }
                    }
                } label: {
                    Label("Purchase Info", systemImage: "bag.fill")
                        .font(.headline)
                }
                .padding(.horizontal)
            }

            // Cost Summary
            GroupBox {
                VStack(spacing: 12) {
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
                    .font(.headline)
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
        VStack(spacing: 16) {
            // Consumption Summary
            if let avg = CalculationService.averageConsumption(entries: fuelEntries) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Average Consumption")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", avg))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                    }
                } label: {
                    Label("Fuel Efficiency", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
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
                                    .padding(.leading, 48)
                            }
                        }
                    }
                } label: {
                    Label("Fill-ups (\(fuelEntries.count))", systemImage: "fuelpump.fill")
                        .font(.headline)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "fuelpump.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.stationName ?? "Fill-up")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Text(entry.formattedLiters)
                    Text("•")
                    Text(entry.formattedPricePerLiter)
                    if let consumption = consumption {
                        Text("•")
                        Text(String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", consumption))
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedCost)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
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
        VStack(spacing: 16) {
            // Category Breakdown
            if !expensesByCategory.isEmpty {
                GroupBox {
                    VStack(spacing: 12) {
                        ForEach(expensesByCategory, id: \.category) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundStyle(item.category.color)
                                    .frame(width: 24)

                                Text(item.category.rawValue)
                                    .font(.subheadline)

                                Spacer()

                                Text(String(format: "%.0f \(settings.currency.symbol)", item.amount))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                } label: {
                    Label("By Category", systemImage: "chart.pie.fill")
                        .font(.headline)
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
                                    .padding(.leading, 48)
                            }
                        }
                    }
                } label: {
                    Label("Expenses (\(expenses.count))", systemImage: "creditcard.fill")
                        .font(.headline)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: expense.category.icon)
                    .font(.caption)
                    .foregroundStyle(expense.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.subcategory ?? expense.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(expense.serviceProvider ?? expense.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Reminders Section

struct CarRemindersSection: View {
    let car: Car
    let reminders: [Reminder]

    @State private var showingAddReminder = false

    var body: some View {
        VStack(spacing: 16) {
            if !reminders.isEmpty {
                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                            ReminderDetailRow(reminder: reminder)
                            if index < reminders.count - 1 {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label("Active Reminders", systemImage: "bell.fill")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddReminder = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
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
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(reminder.type.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: reminder.type.icon)
                    .font(.caption)
                    .foregroundStyle(reminder.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let dueDate = reminder.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let days = reminder.daysUntilDue {
                DueBadge(days: days)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        CarDetailView(car: SampleData.sampleCar1)
    }
    .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
    .environment(AppState())
}
