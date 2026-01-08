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

    var selectedCar: Car? {
        appState.getSelectedCar(from: cars)
    }

    var recentFuelEntries: [FuelEntry] {
        guard let car = selectedCar else { return Array(allFuelEntries.prefix(5)) }
        return allFuelEntries.filter { $0.car?.id == car.id }.prefix(5).map { $0 }
    }

    var recentExpenses: [Expense] {
        guard let car = selectedCar else { return Array(allExpenses.prefix(5)) }
        return allExpenses.filter { $0.car?.id == car.id }.prefix(5).map { $0 }
    }

    var recentItems: [(id: UUID, type: String, icon: String, title: String, subtitle: String, amount: String, time: String, color: Color, date: Date)] {
        var items: [(id: UUID, type: String, icon: String, title: String, subtitle: String, amount: String, time: String, color: Color, date: Date)] = []

        for entry in recentFuelEntries {
            items.append((
                id: entry.id,
                type: "fuel",
                icon: "fuelpump.fill",
                title: entry.stationName ?? "Fuel",
                subtitle: "\(String(format: "%.1f", entry.liters)) L • \(entry.car?.displayName ?? "")",
                amount: entry.formattedCost,
                time: entry.date.timeAgoDisplay(),
                color: .orange,
                date: entry.date
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
                date: expense.date
            ))
        }

        return items.sorted { $0.date > $1.date }.prefix(8).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Log Type Cards
                    VStack(spacing: 16) {
                        LogTypeCard(
                            icon: "fuelpump.fill",
                            title: "Add Fuel",
                            subtitle: "Log a fill-up with price and consumption",
                            color: .orange
                        ) {
                            showingAddFuel = true
                        }

                        LogTypeCard(
                            icon: "wrench.and.screwdriver.fill",
                            title: "Add Expense",
                            subtitle: "Track maintenance, repairs, insurance & more",
                            color: .blue
                        ) {
                            showingAddExpense = true
                        }

                        LogTypeCard(
                            icon: "bell.fill",
                            title: "Add Reminder",
                            subtitle: "Set up service and inspection reminders",
                            color: .purple
                        ) {
                            showingAddReminder = true
                        }
                    }
                    .padding(.horizontal)

                    // Recent Entries
                    if !recentItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Entries")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, entry in
                                    RecentLogEntry(
                                        icon: entry.icon,
                                        title: entry.title,
                                        subtitle: entry.subtitle,
                                        amount: entry.amount,
                                        time: entry.time,
                                        color: entry.color
                                    )

                                    if index < recentItems.count - 1 {
                                        Divider().padding(.leading, 64)
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
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
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
        }
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
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
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
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .weekOfYear], from: self, to: now)

        if let days = components.day {
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days) days ago"
            } else if let weeks = components.weekOfYear, weeks == 1 {
                return "1 week ago"
            } else if let weeks = components.weekOfYear, weeks < 4 {
                return "\(weeks) weeks ago"
            }
        }

        return self.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    LogView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
