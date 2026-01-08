//
//  DashboardView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \Reminder.dueDate) private var allReminders: [Reminder]
    @Query(sort: \FuelEntry.date, order: .reverse) private var allFuelEntries: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var showingCarPicker = false
    @State private var showingAddFuel = false
    @State private var showingAddExpense = false
    @State private var showingAddReminder = false
    @State private var showingAddCar = false

    var selectedCar: Car? {
        appState.getSelectedCar(from: cars)
    }

    var carReminders: [Reminder] {
        guard let car = selectedCar else { return [] }
        return allReminders.filter { $0.car?.id == car.id && !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var carFuelEntries: [FuelEntry] {
        guard let car = selectedCar else { return [] }
        return allFuelEntries.filter { $0.car?.id == car.id }
    }

    var carExpenses: [Expense] {
        guard let car = selectedCar else { return [] }
        return allExpenses.filter { $0.car?.id == car.id }
    }

    var thisMonthFuelCost: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: Date())
        return carFuelEntries
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.totalCost }
    }

    var thisMonthExpenses: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: Date())
        return carExpenses
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if cars.isEmpty {
                        // Empty State
                        EmptyDashboardView {
                            showingAddCar = true
                        }
                    } else {
                        // Car Selector
                        if let car = selectedCar {
                            CarSelectorCard(car: car)
                                .onTapGesture {
                                    if cars.count > 1 {
                                        showingCarPicker = true
                                    }
                                }
                        }

                        // Quick Actions
                        QuickActionsView(
                            onAddFuel: { showingAddFuel = true },
                            onAddExpense: { showingAddExpense = true },
                            onAddReminder: { showingAddReminder = true }
                        )

                        // Upcoming Reminders
                        if !carReminders.isEmpty {
                            UpcomingRemindersCard(reminders: Array(carReminders.prefix(3)))
                        }

                        // This Month Stats
                        MonthStatsCard(
                            fuelCost: thisMonthFuelCost,
                            expensesCost: thisMonthExpenses
                        )

                        // Recent Activity
                        RecentActivityCard(
                            fuelEntries: Array(carFuelEntries.prefix(2)),
                            expenses: Array(carExpenses.prefix(2))
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingCarPicker) {
                CarPickerSheet(cars: cars, selectedCar: selectedCar) { car in
                    appState.selectCar(car)
                }
            }
            .sheet(isPresented: $showingAddFuel) {
                AddFuelView(preselectedCar: selectedCar)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(preselectedCar: selectedCar)
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(preselectedCar: selectedCar)
            }
            .sheet(isPresented: $showingAddCar) {
                AddCarView()
            }
            .onAppear {
                updateWidgetData()
            }
            .onChange(of: allFuelEntries.count) { _, _ in
                updateWidgetData()
            }
            .onChange(of: allExpenses.count) { _, _ in
                updateWidgetData()
            }
            .onChange(of: allReminders.count) { _, _ in
                updateWidgetData()
            }
        }
    }

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidgetData(
            cars: cars,
            reminders: allReminders,
            fuelEntries: allFuelEntries,
            selectedCarId: selectedCar?.id
        )
    }
}

// MARK: - Empty Dashboard

struct EmptyDashboardView: View {
    let onAddCar: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 70))
                .foregroundStyle(.blue.opacity(0.6))

            VStack(spacing: 8) {
                Text("Welcome to CarTracker")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add your first car to start tracking\nfuel, expenses, and service reminders")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAddCar()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your Car")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(.blue)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Car Selector Card

struct CarSelectorCard: View {
    let car: Car

    var body: some View {
        HStack(spacing: 16) {
            // Car Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))

                if let photoData = car.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "car.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(car.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(car.licensePlate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.caption)
                    Text("\(car.currentOdometer.formatted()) km")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Car Picker Sheet

struct CarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cars: [Car]
    let selectedCar: Car?
    let onSelect: (Car) -> Void

    var body: some View {
        NavigationStack {
            List(cars) { car in
                Button {
                    onSelect(car)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "car.fill")
                                .foregroundStyle(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(car.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(car.licensePlate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedCar?.id == car.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Select Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let onAddFuel: () -> Void
    let onAddExpense: () -> Void
    let onAddReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "fuelpump.fill",
                    title: "Add Fuel",
                    color: .orange,
                    action: onAddFuel
                )

                QuickActionButton(
                    icon: "wrench.fill",
                    title: "Expense",
                    color: .blue,
                    action: onAddExpense
                )

                QuickActionButton(
                    icon: "bell.fill",
                    title: "Reminder",
                    color: .purple,
                    action: onAddReminder
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Reminders Card

struct UpcomingRemindersCard: View {
    let reminders: [Reminder]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: RemindersListView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(reminder.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: reminder.type.icon)
                    .font(.body)
                    .foregroundStyle(reminder.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let dueDate = reminder.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let days = reminder.daysUntilDue {
                DueBadge(days: days)
            }
        }
    }
}

struct DueBadge: View {
    let days: Int

    var text: String {
        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days)d"
        }
    }

    var color: Color {
        if days < 0 { return .red }
        if days <= 7 { return .orange }
        if days <= 30 { return .yellow }
        return .green
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Month Stats Card

struct MonthStatsCard: View {
    let settings = UserSettings.shared
    let fuelCost: Double
    let expensesCost: Double

    var total: Double { fuelCost + expensesCost }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                StatCard(
                    title: "Fuel",
                    value: String(format: "%.0f", fuelCost),
                    currency: settings.currency.symbol,
                    icon: "fuelpump.fill",
                    color: .orange
                )

                StatCard(
                    title: "Expenses",
                    value: String(format: "%.0f", expensesCost),
                    currency: settings.currency.symbol,
                    icon: "creditcard.fill",
                    color: .blue
                )

                StatCard(
                    title: "Total",
                    value: String(format: "%.0f", total),
                    currency: settings.currency.symbol,
                    icon: "eurosign.circle.fill",
                    color: .green
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let currency: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(currency)
                    .font(.system(size: 10))
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let settings = UserSettings.shared


    let fuelEntries: [FuelEntry]
    let expenses: [Expense]

    var recentItems: [(id: UUID, icon: String, title: String, subtitle: String, amount: String, color: Color, date: Date)] {
        var items: [(id: UUID, icon: String, title: String, subtitle: String, amount: String, color: Color, date: Date)] = []

        for entry in fuelEntries {
            items.append((
                id: entry.id,
                icon: "fuelpump.fill",
                title: entry.stationName ?? "Fuel",
                subtitle: "\(String(format: "%.1f", entry.liters)) L",
                amount: entry.formattedCost,
                color: .orange,
                date: entry.date
            ))
        }

        for expense in expenses {
            items.append((
                id: expense.id,
                icon: expense.category.icon,
                title: expense.subcategory ?? expense.category.rawValue,
                subtitle: expense.serviceProvider ?? expense.category.rawValue,
                amount: expense.formattedAmount,
                color: expense.category.color,
                date: expense.date
            ))
        }

        return items.sorted { $0.date > $1.date }.prefix(4).map { $0 }
    }

    var body: some View {
        if !recentItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(item.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: item.icon)
                                    .font(.body)
                                    .foregroundStyle(item.color)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.amount) \(settings.currency.symbol)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 12)

                        if index < recentItems.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
