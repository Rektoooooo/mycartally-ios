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
    @State private var showingSettings = false
    @State private var showingReceiptScan = false
    @State private var showingAddFuelWithReceipt = false
    @State private var pendingReceiptData: ExtractedReceiptData?
    @State private var pendingReceiptImage: Data?

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
                VStack(spacing: AppDesign.Spacing.lg) {
                    if cars.isEmpty {
                        // Empty State
                        EmptyDashboardView {
                            showingAddCar = true
                        }
                    } else {
                        // Car Selector
                        if let car = selectedCar {
                            NavigationLink(destination: CarDetailView(car: car)) {
                                CarSelectorCard(car: car, hasMultipleCars: cars.count > 1) {
                                    showingCarPicker = true
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Quick Actions
                        QuickActionsView(
                            onAddFuel: { showingAddFuel = true },
                            onAddExpense: { showingAddExpense = true },
                            onAddReminder: { showingAddReminder = true },
                            onScanReceipt: { showingReceiptScan = true }
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
            .background(AppDesign.Colors.background)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
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
            .sheet(isPresented: $showingReceiptScan) {
                ReceiptCaptureView(onDataExtracted: { data, imageData in
                    pendingReceiptData = data
                    pendingReceiptImage = imageData
                    showingReceiptScan = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showingAddFuelWithReceipt = true
                    }
                }, openCameraImmediately: true)
            }
            .sheet(isPresented: $showingAddFuelWithReceipt) {
                AddFuelView(
                    preselectedCar: selectedCar,
                    preExtractedData: pendingReceiptData,
                    preExtractedReceiptImage: pendingReceiptImage
                )
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
        VStack(spacing: AppDesign.Spacing.xl) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 70))
                .foregroundStyle(AppDesign.Colors.accent.opacity(0.6))

            VStack(spacing: AppDesign.Spacing.xs) {
                Text("Welcome to CarTracker")
                    .font(AppDesign.Typography.title2)

                Text("Add your first car to start tracking\nfuel, expenses, and service reminders")
                    .font(AppDesign.Typography.subheadline)
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
                .font(AppDesign.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppDesign.Spacing.xxl)
                .padding(.vertical, 14)
                .background(AppDesign.Colors.accent)
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
    var hasMultipleCars: Bool = false
    var onSwitchCar: (() -> Void)? = nil
    let settings = UserSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Hero image / placeholder banner
            ZStack(alignment: .bottomLeading) {
                if let photoData = car.photoData,
                   let uiImage = UIImage(data: photoData) {
                    GeometryReader { geo in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    .frame(height: 170)
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.55), .black.opacity(0.15), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                    // Name overlay on photo
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                            Text(car.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            Text(String(car.year))
                                .font(AppDesign.Typography.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        if hasMultipleCars, let onSwitch = onSwitchCar {
                            Button {
                                onSwitch()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Switch")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppDesign.Spacing.md)
                } else {
                    // No photo - gradient banner with icon
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [AppDesign.Colors.accent, AppDesign.Colors.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 130)
                        .overlay(alignment: .trailing) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.white.opacity(0.12))
                                .padding(.trailing, AppDesign.Spacing.lg)
                        }

                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                                Text(car.displayName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(String(car.year))
                                    .font(AppDesign.Typography.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }

                            Spacer()

                            if hasMultipleCars, let onSwitch = onSwitchCar {
                                Button {
                                    onSwitch()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 11, weight: .semibold))
                                        Text("Switch")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(AppDesign.Spacing.md)
                    }
                }
            }

            // Info row
            HStack(spacing: AppDesign.Spacing.sm) {
                // License plate badge
                Text(car.licensePlate)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, AppDesign.Spacing.xs)
                    .padding(.vertical, AppDesign.Spacing.xxs)
                    .background(AppDesign.Colors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Fuel type
                HStack(spacing: 4) {
                    Image(systemName: car.fuelType.icon)
                        .font(.system(size: 10))
                    Text(car.fuelType.rawValue)
                        .font(AppDesign.Typography.caption2)
                }
                .foregroundStyle(AppDesign.Colors.textSecondary)

                Spacer()

                // Odometer
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10))
                    Text("\(car.currentOdometer.formatted()) \(settings.distanceUnit.abbreviation)")
                        .font(AppDesign.Typography.caption)
                }
                .foregroundStyle(AppDesign.Colors.textSecondary)
            }
            .padding(AppDesign.Spacing.sm)
        }
        .background(AppDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
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
                    HStack(spacing: AppDesign.Spacing.sm) {
                        Image(systemName: "car.fill")
                            .iconBadge(color: AppDesign.Colors.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(car.displayName)
                                .font(AppDesign.Typography.headline)
                                .foregroundStyle(.primary)
                            Text(car.licensePlate)
                                .font(AppDesign.Typography.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedCar?.id == car.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppDesign.Colors.accent)
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
    let onScanReceipt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Quick Actions")
                .font(AppDesign.Typography.headline)
                .padding(.horizontal, AppDesign.Spacing.xxs)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppDesign.Spacing.sm),
                GridItem(.flexible(), spacing: AppDesign.Spacing.sm)
            ], spacing: AppDesign.Spacing.sm) {
                QuickActionButton(
                    icon: "camera.viewfinder",
                    title: "Scan Receipt",
                    color: AppDesign.Colors.accent,
                    isHighlighted: true,
                    action: onScanReceipt
                )

                QuickActionButton(
                    icon: "fuelpump.fill",
                    title: "Add Fuel",
                    color: AppDesign.Colors.fuel,
                    action: onAddFuel
                )

                QuickActionButton(
                    icon: "wrench.fill",
                    title: "Expense",
                    color: AppDesign.Colors.accent,
                    action: onAddExpense
                )

                QuickActionButton(
                    icon: "bell.fill",
                    title: "Reminder",
                    color: AppDesign.Colors.reminders,
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
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppDesign.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(isHighlighted ? color : color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isHighlighted ? .white : color)
                }
                Text(title)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppDesign.Spacing.md)
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Reminders Card

struct UpcomingRemindersCard: View {
    let reminders: [Reminder]

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                Text("Upcoming")
                    .font(AppDesign.Typography.headline)
                Spacer()
                NavigationLink(destination: RemindersListView()) {
                    Text("See All")
                        .font(AppDesign.Typography.subheadline)
                        .foregroundStyle(AppDesign.Colors.accent)
                }
            }
            .padding(.horizontal, AppDesign.Spacing.xxs)

            VStack(spacing: AppDesign.Spacing.xs) {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
            .premiumCard()
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: reminder.type.icon)
                .iconBadge(color: reminder.type.color, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)

                if let dueDate = reminder.dueDate {
                    Text(dueDate, style: .date)
                        .font(AppDesign.Typography.caption)
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
            .font(AppDesign.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, AppDesign.Spacing.xxs)
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
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("This Month")
                .font(AppDesign.Typography.headline)
                .padding(.horizontal, AppDesign.Spacing.xxs)

            HStack(spacing: AppDesign.Spacing.sm) {
                StatCard(
                    title: "Fuel",
                    value: String(format: "%.0f", fuelCost),
                    currency: settings.currency.symbol,
                    icon: "fuelpump.fill",
                    color: AppDesign.Colors.fuel
                )

                StatCard(
                    title: "Expenses",
                    value: String(format: "%.0f", expensesCost),
                    currency: settings.currency.symbol,
                    icon: "creditcard.fill",
                    color: AppDesign.Colors.accent
                )

                StatCard(
                    title: "Total",
                    value: String(format: "%.0f", total),
                    currency: settings.currency.symbol,
                    icon: "eurosign.circle.fill",
                    color: AppDesign.Colors.stats
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
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppDesign.Typography.title2)
                Spacer()
                Text(currency)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(.secondary)
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
                color: AppDesign.Colors.fuel,
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
            VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                Text("Recent Activity")
                    .font(AppDesign.Typography.headline)
                    .padding(.horizontal, AppDesign.Spacing.xxs)

                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: AppDesign.Spacing.sm) {
                            Image(systemName: item.icon)
                                .iconBadge(color: item.color, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(AppDesign.Typography.subheadline)
                                    .fontWeight(.medium)
                                Text(item.subtitle)
                                    .font(AppDesign.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.amount) \(settings.currency.symbol)")
                                    .font(AppDesign.Typography.subheadline)
                                    .fontWeight(.semibold)
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppDesign.Typography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, AppDesign.Spacing.sm)

                        if index < recentItems.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal)
                .background(AppDesign.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
