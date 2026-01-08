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
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "car.fill")
                                        .foregroundStyle(.blue)
                                }

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
                            .padding(.vertical, 4)
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

        if let expense = expenseToEdit {
            expense.date = date
            expense.category = category
            expense.subcategory = subcategory.isEmpty ? nil : subcategory
            expense.amount = amountValue
            expense.odometer = odometerValue
            expense.serviceProvider = serviceProvider.isEmpty ? nil : serviceProvider
            expense.notes = notes.isEmpty ? nil : notes
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
                car: car
            )
            modelContext.insert(newExpense)

            // Update car's odometer if provided and higher
            if let odo = odometerValue, odo > car.currentOdometer {
                car.currentOdometer = odo
            }
        }

        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [Car.self, Expense.self], inMemory: true)
        .environment(AppState())
}
