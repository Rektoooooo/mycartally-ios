//
//  AddReminderView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let settings = UserSettings.shared

    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]

    var reminderToEdit: Reminder?
    var preselectedCar: Car?

    @State private var selectedCar: Car?
    @State private var reminderType: ReminderType = .inspection
    @State private var customTitle = ""
    @State private var dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var hasDueDate = true
    @State private var dueOdometer = ""
    @State private var hasDueOdometer = false
    @State private var notifyDaysBefore = 7
    @State private var notifyKmBefore = ""
    @State private var isRecurring = false
    @State private var recurringMonths = 12
    @State private var recurringKm = ""
    @State private var notes = ""
    @State private var showingCarPicker = false

    var isEditing: Bool { reminderToEdit != nil }

    let notifyDaysOptions = [1, 3, 7, 14, 30]

    var isValid: Bool {
        selectedCar != nil && (hasDueDate || hasDueOdometer)
    }

    var title: String {
        if reminderType == .custom && !customTitle.isEmpty {
            return customTitle
        }
        return reminderType.defaultTitle
    }

    var body: some View {
        NavigationStack {
            Form {
                // Car Selection
                Section {
                    if let car = selectedCar {
                        Button {
                            showingCarPicker = true
                        } label: {
                            HStack(spacing: AppDesign.Spacing.sm) {
                                Image(systemName: "car.fill")
                                    .iconBadge(color: AppDesign.Colors.accent, size: 50, cornerRadius: AppDesign.Radius.sm)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(car.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(car.licensePlate)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, AppDesign.Spacing.xxs)
                        }
                    } else {
                        Button {
                            showingCarPicker = true
                        } label: {
                            HStack {
                                Text("Select Car")
                                Spacer()
                                Text("Required")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Reminder Type
                Section {
                    Picker("Type", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .onChange(of: reminderType) { _, newType in
                        // Set default recurring values based on type
                        if let months = newType.defaultRecurringMonths {
                            recurringMonths = months
                        }
                        if let km = newType.defaultRecurringKm {
                            recurringKm = "\(km)"
                            hasDueOdometer = true
                        }
                    }

                    if reminderType == .custom {
                        HStack {
                            Text("Title")
                                .foregroundStyle(.secondary)
                            TextField("Enter title", text: $customTitle)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } header: {
                    Text("Reminder")
                }

                // Due Date
                Section {
                    Toggle("Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    }

                    Toggle("Due at Odometer", isOn: $hasDueOdometer)

                    if hasDueOdometer {
                        HStack {
                            Text("At")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0", text: $dueOdometer)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text(settings.distanceUnit.abbreviation)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("When")
                } footer: {
                    Text("Set a date, odometer reading, or both")
                }

                // Notification
                Section {
                    Picker("Notify Before", selection: $notifyDaysBefore) {
                        ForEach(notifyDaysOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }

                    if hasDueOdometer {
                        HStack {
                            Text("Or at")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("500", text: $notifyKmBefore)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("km before")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Notification")
                }

                // Recurring
                Section {
                    Toggle("Repeat", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Every", selection: $recurringMonths) {
                            Text("6 months").tag(6)
                            Text("12 months").tag(12)
                            Text("24 months").tag(24)
                            Text("36 months").tag(36)
                        }

                        HStack {
                            Text("Or every")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("15000", text: $recurringKm)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(settings.distanceUnit.abbreviation)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Recurring")
                } footer: {
                    if isRecurring {
                        Text("The reminder will automatically reschedule after completion")
                    }
                }

                // Notes
                Section {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingCarPicker) {
                CarPickerView(selectedCar: $selectedCar, cars: cars)
            }
            .onAppear {
                setupInitialState()
            }
        }
    }

    private func setupInitialState() {
        if let reminder = reminderToEdit {
            selectedCar = reminder.car
            reminderType = reminder.type
            customTitle = reminder.type == .custom ? reminder.title : ""
            if let date = reminder.dueDate {
                hasDueDate = true
                dueDate = date
            } else {
                hasDueDate = false
            }
            if let odo = reminder.dueOdometer {
                hasDueOdometer = true
                dueOdometer = "\(odo)"
            }
            notifyDaysBefore = reminder.notifyDaysBefore
            if let kmBefore = reminder.notifyKmBefore {
                notifyKmBefore = "\(kmBefore)"
            }
            isRecurring = reminder.isRecurring
            if let months = reminder.recurringIntervalMonths {
                recurringMonths = months
            }
            if let km = reminder.recurringIntervalKm {
                recurringKm = "\(km)"
            }
            notes = reminder.notes ?? ""
        } else if let car = preselectedCar {
            selectedCar = car
        } else if let car = appState.getSelectedCar(from: cars) {
            selectedCar = car
        } else if let firstCar = cars.first {
            selectedCar = firstCar
        }
    }

    private func saveReminder() {
        guard let car = selectedCar else { return }

        let dueOdometerValue = Int(dueOdometer)
        let notifyKmValue = Int(notifyKmBefore)
        let recurringKmValue = Int(recurringKm)

        if let reminder = reminderToEdit {
            reminder.type = reminderType
            reminder.title = title
            reminder.dueDate = hasDueDate ? dueDate : nil
            reminder.dueOdometer = hasDueOdometer ? dueOdometerValue : nil
            reminder.notifyDaysBefore = notifyDaysBefore
            reminder.notifyKmBefore = notifyKmValue
            reminder.isRecurring = isRecurring
            reminder.recurringIntervalMonths = isRecurring ? recurringMonths : nil
            reminder.recurringIntervalKm = isRecurring ? recurringKmValue : nil
            reminder.notes = notes.isEmpty ? nil : notes
            reminder.car = car

            // Reschedule notification
            NotificationService.shared.scheduleReminderNotification(for: reminder, car: car)
        } else {
            let newReminder = Reminder(
                type: reminderType,
                title: title,
                notes: notes.isEmpty ? nil : notes,
                dueDate: hasDueDate ? dueDate : nil,
                dueOdometer: hasDueOdometer ? dueOdometerValue : nil,
                notifyDaysBefore: notifyDaysBefore,
                notifyKmBefore: notifyKmValue,
                isRecurring: isRecurring,
                recurringIntervalMonths: isRecurring ? recurringMonths : nil,
                recurringIntervalKm: isRecurring ? recurringKmValue : nil,
                car: car
            )
            modelContext.insert(newReminder)

            // Schedule notification
            NotificationService.shared.scheduleReminderNotification(for: newReminder, car: car)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddReminderView()
        .modelContainer(for: [Car.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
