//
//  RemindersListView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct RemindersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Reminder.dueDate) private var allReminders: [Reminder]
    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]

    @State private var selectedFilter = 0
    @State private var showingAddReminder = false
    @State private var reminderToEdit: Reminder?

    var selectedCar: Car? {
        appState.getSelectedCar(from: cars)
    }

    var activeReminders: [Reminder] {
        allReminders.filter { !$0.isCompleted }
    }

    var filteredReminders: [Reminder] {
        var reminders = activeReminders

        // Filter by selected car if one is selected
        if let car = selectedCar {
            reminders = reminders.filter { $0.car?.id == car.id }
        }

        switch selectedFilter {
        case 1: // Overdue
            return reminders.filter { $0.isOverdue }
        case 2: // Upcoming (within 30 days)
            return reminders.filter { ($0.daysUntilDue ?? 999) <= 30 && !$0.isOverdue }
        default: // All
            return reminders.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(0)
                    Text("Overdue").tag(1)
                    Text("Upcoming").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                if filteredReminders.isEmpty {
                    EmptyRemindersView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReminders) { reminder in
                                ReminderCard(
                                    reminder: reminder,
                                    onComplete: { completeReminder(reminder) },
                                    onEdit: { reminderToEdit = reminder }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(preselectedCar: selectedCar)
            }
            .sheet(item: $reminderToEdit) { reminder in
                AddReminderView(reminderToEdit: reminder)
            }
        }
    }

    private func completeReminder(_ reminder: Reminder) {
        withAnimation {
            reminder.isCompleted = true
            reminder.completedDate = Date()

            // Cancel notification
            NotificationService.shared.cancelNotification(for: reminder)

            // If recurring, create next reminder
            if reminder.isRecurring {
                createNextRecurrence(for: reminder)
            }
        }
    }

    private func createNextRecurrence(for reminder: Reminder) {
        var nextDueDate: Date?
        var nextDueOdometer: Int?

        if let currentDueDate = reminder.dueDate,
           let months = reminder.recurringIntervalMonths {
            nextDueDate = Calendar.current.date(byAdding: .month, value: months, to: currentDueDate)
        }

        if let currentOdo = reminder.dueOdometer,
           let kmInterval = reminder.recurringIntervalKm {
            nextDueOdometer = currentOdo + kmInterval
        }

        let newReminder = Reminder(
            type: reminder.type,
            title: reminder.title,
            notes: reminder.notes,
            dueDate: nextDueDate,
            dueOdometer: nextDueOdometer,
            notifyDaysBefore: reminder.notifyDaysBefore,
            notifyKmBefore: reminder.notifyKmBefore,
            isRecurring: true,
            recurringIntervalMonths: reminder.recurringIntervalMonths,
            recurringIntervalKm: reminder.recurringIntervalKm,
            car: reminder.car
        )

        modelContext.insert(newReminder)
        NotificationService.shared.scheduleReminderNotification(for: newReminder, car: reminder.car)
    }
}

// MARK: - Empty State

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Reminders")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Add reminders for service,\ninspection, and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

// MARK: - Reminder Card

struct ReminderCard: View {
    let reminder: Reminder
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(reminder.type.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: reminder.type.icon)
                    .font(.title3)
                    .foregroundStyle(reminder.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let dueDate = reminder.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if let dueOdometer = reminder.dueOdometer {
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.caption2)
                            Text("\(dueOdometer.formatted()) km")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if reminder.isRecurring {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                        Text("Recurring")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let carName = reminder.car?.displayName {
                    Text(carName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Status Badge & Actions
            VStack(alignment: .trailing, spacing: 8) {
                if let days = reminder.daysUntilDue {
                    DueBadge(days: days)
                }

                HStack(spacing: 12) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Button {
                        onComplete()
                    } label: {
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    RemindersListView()
        .modelContainer(for: [Car.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
