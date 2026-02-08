//
//  LogView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \FuelEntry.date, order: .reverse) private var allFuelEntries: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var showingAddFuel = false
    @State private var showingAddExpense = false
    @State private var showingAddReminder = false
    @State private var showingReceiptScan = false
    @State private var showingAddFuelWithReceipt = false
    @State private var pendingReceiptData: ExtractedReceiptData?
    @State private var pendingReceiptImage: Data?
    @State private var fuelEntryToEdit: FuelEntry?
    @State private var expenseToEdit: Expense?
    @State private var showingAllLogs = false

    var selectedCar: Car? {
        appState.getSelectedCar(from: cars)
    }

    var recentFuelEntries: [FuelEntry] {
        guard let car = selectedCar else { return Array(allFuelEntries.prefix(10)) }
        return allFuelEntries.filter { $0.car?.id == car.id }.prefix(10).map { $0 }
    }

    var recentExpenses: [Expense] {
        guard let car = selectedCar else { return Array(allExpenses.prefix(10)) }
        return allExpenses.filter { $0.car?.id == car.id }.prefix(10).map { $0 }
    }

    var recentItems: [(id: UUID, type: String, icon: String, title: String, subtitle: String, amount: String, time: String, color: Color, date: Date, validity: ValidityStatus?)] {
        var items: [(id: UUID, type: String, icon: String, title: String, subtitle: String, amount: String, time: String, color: Color, date: Date, validity: ValidityStatus?)] = []

        for entry in recentFuelEntries {
            items.append((
                id: entry.id,
                type: "fuel",
                icon: "fuelpump.fill",
                title: entry.stationName ?? "Fuel",
                subtitle: "\(String(format: "%.1f", entry.liters)) L • \(entry.car?.displayName ?? "")",
                amount: entry.formattedCost,
                time: entry.date.timeAgoDisplay(),
                color: AppDesign.Colors.fuel,
                date: entry.date,
                validity: nil
            ))
        }

        for expense in recentExpenses {
            items.append((
                id: expense.id,
                type: "expense",
                icon: expense.category.icon,
                title: expense.subcategory ?? expense.category.rawValue,
                subtitle: "\(expense.serviceProvider ?? expense.category.rawValue) • \(expense.car?.displayName ?? "")",
                amount: expense.formattedAmount,
                time: expense.date.timeAgoDisplay(),
                color: expense.category.color,
                date: expense.date,
                validity: expense.validityStatus
            ))
        }

        return items.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppDesign.Spacing.xl) {
                    // Scan Receipt - prominent CTA
                    Button {
                        showingReceiptScan = true
                    } label: {
                        HStack(spacing: AppDesign.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "camera.viewfinder")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                                Text("Scan Receipt")
                                    .font(AppDesign.Typography.headline)
                                    .foregroundStyle(.white)
                                Text("Snap a photo and auto-fill fuel data")
                                    .font(AppDesign.Typography.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(AppDesign.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [AppDesign.Colors.accent, AppDesign.Colors.accentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
                        .shadow(color: AppDesign.Colors.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Log Type Cards
                    VStack(spacing: AppDesign.Spacing.md) {
                        LogTypeCard(
                            icon: "fuelpump.fill",
                            title: "Add Fuel",
                            subtitle: "Log a fill-up with price and consumption",
                            color: AppDesign.Colors.fuel
                        ) {
                            showingAddFuel = true
                        }

                        LogTypeCard(
                            icon: "wrench.and.screwdriver.fill",
                            title: "Add Expense",
                            subtitle: "Track maintenance, repairs, insurance & more",
                            color: AppDesign.Colors.accent
                        ) {
                            showingAddExpense = true
                        }

                        LogTypeCard(
                            icon: "bell.fill",
                            title: "Add Reminder",
                            subtitle: "Set up service and inspection reminders",
                            color: AppDesign.Colors.reminders
                        ) {
                            showingAddReminder = true
                        }
                    }
                    .padding(.horizontal)

                    // Recent Entries
                    if !recentItems.isEmpty {
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                            HStack {
                                Text("Recent Entries")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    showingAllLogs = true
                                } label: {
                                    Text("View All")
                                        .font(.subheadline)
                                        .foregroundStyle(AppDesign.Colors.accent)
                                }
                            }
                            .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, entry in
                                    Button {
                                        if entry.type == "fuel",
                                           let fuelEntry = allFuelEntries.first(where: { $0.id == entry.id }) {
                                            fuelEntryToEdit = fuelEntry
                                        } else if entry.type == "expense",
                                                  let expense = allExpenses.first(where: { $0.id == entry.id }) {
                                            expenseToEdit = expense
                                        }
                                    } label: {
                                        RecentLogEntry(
                                            icon: entry.icon,
                                            title: entry.title,
                                            subtitle: entry.subtitle,
                                            amount: entry.amount,
                                            time: entry.time,
                                            color: entry.color,
                                            validityStatus: entry.validity
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteEntry(id: entry.id, type: entry.type)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                    if index < recentItems.count - 1 {
                                        Divider().padding(.leading, 64)
                                    }
                                }
                            }
                            .premiumCard()
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(AppDesign.Colors.background)
            .navigationTitle("Log")
            .sheet(isPresented: $showingAddFuel) {
                AddFuelView(preselectedCar: selectedCar)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(preselectedCar: selectedCar)
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(preselectedCar: selectedCar)
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
            .sheet(item: $fuelEntryToEdit) { entry in
                AddFuelView(entryToEdit: entry)
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseToEdit: expense)
            }
            .sheet(isPresented: $showingAllLogs) {
                AllLogsView()
            }
        }
    }

    private func deleteEntry(id: UUID, type: String) {
        if type == "fuel", let entry = allFuelEntries.first(where: { $0.id == id }) {
            modelContext.delete(entry)
        } else if type == "expense", let expense = allExpenses.first(where: { $0.id == id }) {
            modelContext.delete(expense)
        }
        try? modelContext.save()
    }
}

struct LogTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppDesign.Spacing.md) {
                Image(systemName: icon)
                    .iconBadge(color: color, size: 56, iconSize: .title2, cornerRadius: AppDesign.Radius.sm)

                VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .premiumCard()
        }
        .buttonStyle(.plain)
    }
}

struct RecentLogEntry: View {
    let settings = UserSettings.shared

    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let time: String
    let color: Color
    var validityStatus: ValidityStatus? = nil

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let status = validityStatus {
                        ValidityBadge(status: status)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount) \(settings.currency.symbol)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
}

struct ValidityBadge: View {
    let status: ValidityStatus

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: status.icon)
                .font(.system(size: 8))
            Text(status.label)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - All Logs View

struct AllLogsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let settings = UserSettings.shared

    @Query(sort: \FuelEntry.date, order: .reverse) private var allFuelEntries: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var fuelEntryToEdit: FuelEntry?
    @State private var expenseToEdit: Expense?

    struct LogItem: Identifiable {
        let id: UUID
        let type: String
        let icon: String
        let title: String
        let subtitle: String
        let amount: String
        let date: Date
        let color: Color
        let validity: ValidityStatus?
    }

    var allItems: [LogItem] {
        var items: [LogItem] = []

        for entry in allFuelEntries {
            items.append(LogItem(
                id: entry.id,
                type: "fuel",
                icon: "fuelpump.fill",
                title: entry.stationName ?? "Fuel",
                subtitle: "\(String(format: "%.1f", entry.liters)) L • \(entry.car?.displayName ?? "")",
                amount: "\(entry.formattedCost) \(settings.currency.symbol)",
                date: entry.date,
                color: AppDesign.Colors.fuel,
                validity: nil
            ))
        }

        for expense in allExpenses {
            items.append(LogItem(
                id: expense.id,
                type: "expense",
                icon: expense.category.icon,
                title: expense.subcategory ?? expense.category.rawValue,
                subtitle: "\(expense.serviceProvider ?? expense.category.rawValue) • \(expense.car?.displayName ?? "")",
                amount: "\(expense.formattedAmount) \(settings.currency.symbol)",
                date: expense.date,
                color: expense.category.color,
                validity: expense.validityStatus
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    var groupedByMonth: [(key: String, items: [LogItem])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: allItems) { item in
            formatter.string(from: item.date)
        }

        return grouped.map { (key: $0.key, items: $0.value) }
            .sorted { $0.items.first!.date > $1.items.first!.date }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByMonth, id: \.key) { month in
                    Section {
                        ForEach(month.items) { item in
                            Button {
                                if item.type == "fuel",
                                   let entry = allFuelEntries.first(where: { $0.id == item.id }) {
                                    fuelEntryToEdit = entry
                                } else if item.type == "expense",
                                          let expense = allExpenses.first(where: { $0.id == item.id }) {
                                    expenseToEdit = expense
                                }
                            } label: {
                                HStack(spacing: AppDesign.Spacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill(item.color.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: item.icon)
                                            .font(.body)
                                            .foregroundStyle(item.color)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        HStack(spacing: 4) {
                                            Text(item.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                            if let status = item.validity {
                                                ValidityBadge(status: status)
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.amount)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteItem(id: item.id, type: item.type)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(month.key)
                    }
                }
            }
            .navigationTitle("All Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $fuelEntryToEdit) { entry in
                AddFuelView(entryToEdit: entry)
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseToEdit: expense)
            }
            .overlay {
                if allItems.isEmpty {
                    ContentUnavailableView(
                        "No Logs Yet",
                        systemImage: "doc.text",
                        description: Text("Your fuel entries and expenses will appear here")
                    )
                }
            }
        }
    }

    private func deleteItem(id: UUID, type: String) {
        if type == "fuel", let entry = allFuelEntries.first(where: { $0.id == id }) {
            modelContext.delete(entry)
        } else if type == "expense", let expense = allExpenses.first(where: { $0.id == id }) {
            modelContext.delete(expense)
        }
        try? modelContext.save()
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfNow = calendar.startOfDay(for: Date())
        let dayComponents = calendar.dateComponents([.day], from: startOfSelf, to: startOfNow)

        guard let days = dayComponents.day, days >= 0 else {
            return self.formatted(date: .abbreviated, time: .omitted)
        }

        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 14 { return "1 week ago" }
        if days < 28 { return "\(days / 7) weeks ago" }

        return self.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    LogView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
