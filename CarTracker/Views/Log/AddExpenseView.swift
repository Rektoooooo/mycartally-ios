//
//  AddExpenseView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let settings = UserSettings.shared

    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]

    // Entry being edited (nil for new entry)
    var expenseToEdit: Expense?
    var preselectedCar: Car?

    @State private var selectedCar: Car?
    @State private var date = Date()
    @State private var category: ExpenseCategory = .maintenance
    @State private var subcategory = ""
    @State private var amount = ""
    @State private var odometer = ""
    @State private var serviceProvider = ""
    @State private var notes = ""
    @State private var showingCarPicker = false
    @State private var hasValidity = false
    @State private var validFrom = Date()
    @State private var validUntil = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var createReminder = true

    var isEditing: Bool { expenseToEdit != nil }

    var isValid: Bool {
        selectedCar != nil &&
        !amount.isEmpty &&
        (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
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

                // Date & Amount
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        Label("Amount", systemImage: "eurosign.circle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("\(settings.currency.symbol)")
                            .foregroundStyle(.secondary)
                    }
                }

                // Category
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundStyle(cat.color)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                    .onChange(of: category) { _, _ in
                        subcategory = ""
                    }

                    if !category.subcategories.isEmpty {
                        Picker("Type", selection: $subcategory) {
                            Text("Select...").tag("")
                            ForEach(category.subcategories, id: \.self) { sub in
                                Text(sub).tag(sub)
                            }
                        }
                    }
                } header: {
                    Text("Category")
                }

                // Validity Period (for insurance, tax, inspection, toll)
                if category.hasValidityPeriod {
                    Section {
                        Toggle("Has Validity Period", isOn: $hasValidity.animation())

                        if hasValidity {
                            DatePicker("Valid From", selection: $validFrom, displayedComponents: .date)
                            DatePicker("Valid Until", selection: $validUntil, displayedComponents: .date)

                            Toggle("Remind Before Expiry", isOn: $createReminder)
                        }
                    } header: {
                        Text("Validity")
                    } footer: {
                        if hasValidity {
                            Text("Track when this \(category.rawValue.lowercased()) expires")
                        }
                    }
                }

                // Additional Details
                Section {
                    HStack {
                        Label("Odometer", systemImage: "speedometer")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Optional", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(settings.distanceUnit.abbreviation)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Provider", systemImage: "building.2.fill")
                            .foregroundStyle(.secondary)
                        TextField("Service provider (Optional)", text: $serviceProvider)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Details (Optional)")
                }

                // Notes
                Section {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
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
        if let expense = expenseToEdit {
            selectedCar = expense.car
            date = expense.date
            category = expense.category
            subcategory = expense.subcategory ?? ""
            amount = String(format: "%.2f", expense.amount)
            if let odo = expense.odometer {
                odometer = "\(odo)"
            }
            serviceProvider = expense.serviceProvider ?? ""
            notes = expense.notes ?? ""
            if let from = expense.validFrom {
                hasValidity = true
                validFrom = from
            }
            if let until = expense.validUntil {
                hasValidity = true
                validUntil = until
            }
            createReminder = false // Don't auto-create when editing
        } else if let car = preselectedCar {
            selectedCar = car
        } else if let car = appState.getSelectedCar(from: cars) {
            selectedCar = car
        } else if let firstCar = cars.first {
            selectedCar = firstCar
        }
    }

    private func saveExpense() {
        guard let car = selectedCar else { return }

        let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let odometerValue = Int(odometer)

        let effectiveValidFrom = hasValidity ? validFrom : nil
        let effectiveValidUntil = hasValidity ? validUntil : nil

        if let expense = expenseToEdit {
            expense.date = date
            expense.category = category
            expense.subcategory = subcategory.isEmpty ? nil : subcategory
            expense.amount = amountValue
            expense.odometer = odometerValue
            expense.serviceProvider = serviceProvider.isEmpty ? nil : serviceProvider
            expense.notes = notes.isEmpty ? nil : notes
            expense.validFrom = effectiveValidFrom
            expense.validUntil = effectiveValidUntil
            expense.car = car
        } else {
            let newExpense = Expense(
                date: date,
                category: category,
                subcategory: subcategory.isEmpty ? nil : subcategory,
                amount: amountValue,
                odometer: odometerValue,
                notes: notes.isEmpty ? nil : notes,
                serviceProvider: serviceProvider.isEmpty ? nil : serviceProvider,
                validFrom: effectiveValidFrom,
                validUntil: effectiveValidUntil,
                car: car
            )
            modelContext.insert(newExpense)

            // Update car's odometer if provided and higher
            if let odo = odometerValue, odo > car.currentOdometer {
                car.currentOdometer = odo
            }

            // Auto-create reminder for expiry
            if hasValidity && createReminder, let until = effectiveValidUntil {
                let reminderType = reminderTypeForCategory(category)
                let title = subcategory.isEmpty
                    ? "\(category.rawValue) Renewal"
                    : "\(subcategory) Renewal"
                let reminder = Reminder(
                    type: reminderType,
                    title: title,
                    dueDate: until,
                    notifyDaysBefore: 30,
                    car: car
                )
                modelContext.insert(reminder)
                NotificationService.shared.scheduleReminderNotification(for: reminder, car: car)
            }
        }

        try? modelContext.save()
        dismiss()
    }

    private func reminderTypeForCategory(_ category: ExpenseCategory) -> ReminderType {
        switch category {
        case .insurance: return .insurance
        case .tax: return .roadTax
        case .inspection: return .inspection
        case .toll: return .vignette
        default: return .custom
        }
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Car.self, Expense.self], inMemory: true)
        .environment(AppState())
}
