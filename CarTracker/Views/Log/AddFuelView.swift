//
//  AddFuelView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct AddFuelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let settings = UserSettings.shared

    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]

    // Entry being edited (nil for new entry)
    var entryToEdit: FuelEntry?
    var preselectedCar: Car?
    var startWithReceiptScan = false
    var preExtractedData: ExtractedReceiptData?
    var preExtractedReceiptImage: Data?

    @State private var selectedCar: Car?
    @State private var date = Date()
    @State private var odometer = ""
    @State private var liters = ""
    @State private var pricePerLiter = ""
    @State private var totalCost = ""
    @State private var isFullTank = true
    @State private var stationName = ""
    @State private var notes = ""
    @State private var calculateTotal = true
    @State private var showingCarPicker = false
    @State private var showingReceiptCapture = false
    @State private var receiptImageData: Data?

    var isEditing: Bool { entryToEdit != nil }

    var calculatedTotal: Double {
        let l = Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0
        let p = Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0
        return l * p
    }

    var isValid: Bool {
        selectedCar != nil &&
        !liters.isEmpty &&
        (Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        !pricePerLiter.isEmpty &&
        (Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
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

                // Date & Odometer
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        Label("Odometer (Optional)", systemImage: "speedometer")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField(selectedCar != nil ? "\(selectedCar!.currentOdometer)" : "0", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(settings.distanceUnit.abbreviation)
                            .foregroundStyle(.secondary)
                    }
                }

                // Fuel Details
                Section {
                    HStack {
                        Label("Amount", systemImage: "drop.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0.00", text: $liters)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(selectedCar?.fuelType.unit ?? "L")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Price/\(selectedCar?.fuelType.unit ?? "L")", systemImage: "eurosign")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0.000", text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("\(settings.currency.symbol)")
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Calculate Total", isOn: $calculateTotal)

                    HStack {
                        Label("Total Cost", systemImage: "creditcard.fill")
                            .foregroundStyle(calculateTotal ? .secondary : .primary)
                        Spacer()
                        if calculateTotal {
                            Text(String(format: "%.2f", calculatedTotal))
                                .fontWeight(.semibold)
                        } else {
                            TextField("0.00", text: $totalCost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        Text("\(settings.currency.symbol)")
                            .foregroundStyle(.secondary)
                    }

                    Toggle(isOn: $isFullTank) {
                        Label("Full Tank", systemImage: "fuelpump.fill")
                    }
                } header: {
                    Text("Fuel")
                } footer: {
                    Text("Full tank is needed to calculate fuel consumption accurately")
                }

                // Station
                Section {
                    HStack {
                        Label("Station", systemImage: "building.2.fill")
                            .foregroundStyle(.secondary)
                        TextField("e.g., Shell, OMV (Optional)", text: $stationName)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Station (Optional)")
                }

                // Notes
                Section {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle(isEditing ? "Edit Fuel" : "Add Fuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingReceiptCapture = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingCarPicker) {
                CarPickerView(selectedCar: $selectedCar, cars: cars)
            }
            .sheet(isPresented: $showingReceiptCapture) {
                ReceiptCaptureView(onDataExtracted: { extractedData, imageData in
                    applyExtractedData(extractedData)
                    receiptImageData = imageData
                }, openCameraImmediately: startWithReceiptScan)
            }
            .onAppear {
                setupInitialState()
                if startWithReceiptScan {
                    showingReceiptCapture = true
                }
            }
        }
    }

    private func setupInitialState() {
        if let entry = entryToEdit {
            // Editing existing entry
            selectedCar = entry.car
            date = entry.date
            odometer = "\(entry.odometer)"
            liters = String(format: "%.2f", entry.liters)
            pricePerLiter = String(format: "%.3f", entry.pricePerLiter)
            totalCost = String(format: "%.2f", entry.totalCost)
            isFullTank = entry.isFullTank
            stationName = entry.stationName ?? ""
            notes = entry.notes ?? ""
            calculateTotal = false
            receiptImageData = entry.receiptPhotoData
        } else {
            if let car = preselectedCar {
                selectedCar = car
            } else if let car = appState.getSelectedCar(from: cars) {
                selectedCar = car
            } else if let firstCar = cars.first {
                selectedCar = firstCar
            }

            // Apply pre-extracted receipt data if available
            if let data = preExtractedData {
                applyExtractedData(data)
                receiptImageData = preExtractedReceiptImage
            }
        }
    }

    private func applyExtractedData(_ data: ExtractedReceiptData) {
        if let extractedDate = data.date {
            date = extractedDate
        }
        if let extractedLiters = data.liters {
            liters = String(format: "%.2f", extractedLiters)
        }
        if let extractedPrice = data.pricePerLiter {
            pricePerLiter = String(format: "%.3f", extractedPrice)
        }
        if let extractedTotal = data.totalCost {
            totalCost = String(format: "%.2f", extractedTotal)
            calculateTotal = false
        }
        if let extractedStation = data.stationName {
            stationName = extractedStation
        }
    }

    private func saveEntry() {
        guard let car = selectedCar else { return }

        let odometerValue = Int(odometer) ?? 0
        let litersValue = Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0
        let priceValue = Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0
        let totalValue = calculateTotal ? calculatedTotal : (Double(totalCost.replacingOccurrences(of: ",", with: ".")) ?? calculatedTotal)

        if let entry = entryToEdit {
            // Update existing entry
            entry.date = date
            entry.odometer = odometerValue
            entry.liters = litersValue
            entry.pricePerLiter = priceValue
            entry.totalCost = totalValue
            entry.isFullTank = isFullTank
            entry.stationName = stationName.isEmpty ? nil : stationName
            entry.notes = notes.isEmpty ? nil : notes
            entry.car = car
        } else {
            // Create new entry
            let newEntry = FuelEntry(
                date: date,
                odometer: odometerValue,
                liters: litersValue,
                pricePerLiter: priceValue,
                totalCost: totalValue,
                isFullTank: isFullTank,
                stationName: stationName.isEmpty ? nil : stationName,
                fuelType: car.fuelType,
                notes: notes.isEmpty ? nil : notes,
                receiptPhotoData: receiptImageData,
                car: car
            )
            modelContext.insert(newEntry)

            // Update car's odometer if this is higher
            if odometerValue > car.currentOdometer {
                car.currentOdometer = odometerValue
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Car Picker

struct CarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCar: Car?
    let cars: [Car]

    var body: some View {
        NavigationStack {
            List(cars) { car in
                Button {
                    selectedCar = car
                    dismiss()
                } label: {
                    HStack(spacing: AppDesign.Spacing.sm) {
                        Image(systemName: "car.fill")
                            .iconBadge(color: AppDesign.Colors.accent, size: 44, cornerRadius: AppDesign.Radius.xs)

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
    }
}

#Preview {
    AddFuelView()
        .modelContainer(for: [Car.self, FuelEntry.self], inMemory: true)
        .environment(AppState())
}
