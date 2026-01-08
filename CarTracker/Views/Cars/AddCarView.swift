//
//  AddCarView.swift
//  CarTracker
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddCarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let settings = UserSettings.shared

    // Car being edited (nil for new car)
    var carToEdit: Car?

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var variant = ""
    @State private var licensePlate = ""
    @State private var vin = ""
    @State private var fuelType: FuelType = .petrolE10
    @State private var odometer = ""
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var hasPurchaseInfo = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    private let currentYear = Calendar.current.component(.year, from: Date())

    var isEditing: Bool { carToEdit != nil }

    var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                if let photoData = selectedPhotoData,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 120, height: 90)

                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundStyle(.blue)
                                    }
                                }

                                Text(selectedPhotoData == nil ? "Add Photo" : "Change Photo")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                }

                // Basic Info
                Section {
                    HStack {
                        Text("Make")
                            .foregroundStyle(.secondary)
                        TextField("e.g., Volkswagen", text: $make)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                    }

                    HStack {
                        Text("Model")
                            .foregroundStyle(.secondary)
                        TextField("e.g., Golf", text: $model)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                    }

                    Picker("Year", selection: $year) {
                        ForEach((1980...currentYear + 1).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    HStack {
                        Text("Variant")
                            .foregroundStyle(.secondary)
                        TextField("e.g., 1.5 TSI (Optional)", text: $variant)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Vehicle")
                } footer: {
                    Text("Enter your car's basic information")
                }

                // Identification
                Section {
                    HStack {
                        Text("License Plate")
                            .foregroundStyle(.secondary)
                        TextField("e.g., 1AB 2345", text: $licensePlate)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }

                    HStack {
                        Text("VIN")
                            .foregroundStyle(.secondary)
                        TextField("17 characters (Optional)", text: $vin)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Identification")
                }

                // Fuel & Odometer
                Section {
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    HStack {
                        Text("Current Odometer")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $odometer)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        Text(settings.distanceUnit.abbreviation)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Specifications")
                }

                // Purchase Info
                Section {
                    Toggle("Add Purchase Info", isOn: $hasPurchaseInfo)

                    if hasPurchaseInfo {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)

                        HStack {
                            Text("Purchase Price")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0", text: $purchasePrice)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Purchase (Optional)")
                }
            }
            .navigationTitle(isEditing ? "Edit Car" : "Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCar()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let car = carToEdit {
                    loadCarData(car)
                }
            }
        }
    }

    private func loadCarData(_ car: Car) {
        make = car.make
        model = car.model
        year = car.year
        variant = car.variant ?? ""
        licensePlate = car.licensePlate
        vin = car.vin ?? ""
        fuelType = car.fuelType
        odometer = "\(car.currentOdometer)"
        selectedPhotoData = car.photoData

        if let date = car.purchaseDate {
            hasPurchaseInfo = true
            purchaseDate = date
            if let price = car.purchasePrice {
                purchasePrice = "\(price)"
            }
        }
    }

    private func saveCar() {
        let odometerValue = Int(odometer) ?? 0
        let priceValue = Double(purchasePrice.replacingOccurrences(of: ",", with: "."))

        if let car = carToEdit {
            // Update existing car
            car.make = make.trimmingCharacters(in: .whitespaces)
            car.model = model.trimmingCharacters(in: .whitespaces)
            car.year = year
            car.variant = variant.isEmpty ? nil : variant.trimmingCharacters(in: .whitespaces)
            car.licensePlate = licensePlate.trimmingCharacters(in: .whitespaces).uppercased()
            car.vin = vin.isEmpty ? nil : vin.trimmingCharacters(in: .whitespaces).uppercased()
            car.fuelType = fuelType
            car.currentOdometer = odometerValue
            car.photoData = selectedPhotoData
            car.purchaseDate = hasPurchaseInfo ? purchaseDate : nil
            car.purchasePrice = hasPurchaseInfo ? priceValue : nil
        } else {
            // Create new car
            let newCar = Car(
                make: make.trimmingCharacters(in: .whitespaces),
                model: model.trimmingCharacters(in: .whitespaces),
                year: year,
                variant: variant.isEmpty ? nil : variant.trimmingCharacters(in: .whitespaces),
                licensePlate: licensePlate.trimmingCharacters(in: .whitespaces).uppercased(),
                vin: vin.isEmpty ? nil : vin.trimmingCharacters(in: .whitespaces).uppercased(),
                fuelType: fuelType,
                purchaseDate: hasPurchaseInfo ? purchaseDate : nil,
                purchasePrice: hasPurchaseInfo ? priceValue : nil,
                currentOdometer: odometerValue,
                photoData: selectedPhotoData
            )
            modelContext.insert(newCar)

            // Auto-select the new car
            appState.selectCar(newCar)
        }

        dismiss()
    }
}

#Preview {
    AddCarView()
        .modelContainer(for: Car.self, inMemory: true)
        .environment(AppState())
}
