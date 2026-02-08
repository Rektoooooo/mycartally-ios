//
//  AddCarView.swift
//  CarTracker
//

import SwiftUI
import SwiftData
import PhotosUI

struct CropImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct AddCarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(OBDConnectionManager.self) private var obdManager

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
    @State private var ownershipType: OwnershipType = .owned
    @State private var purchaseDate = Date()
    @State private var purchasePrice = ""
    @State private var hasPurchaseInfo = false
    @State private var downPayment = ""
    @State private var monthlyPayment = ""
    @State private var interestRate = ""
    @State private var leasingEndDate = Date()
    @State private var leasingCompany = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var cropItem: CropImageItem?
    @State private var isReadingVIN = false

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
                        VStack(spacing: AppDesign.Spacing.xs) {
                            if let photoData = selectedPhotoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppDesign.Radius.sm)
                                        .fill(AppDesign.Colors.accent.opacity(0.08))
                                        .frame(height: 140)
                                        .frame(maxWidth: .infinity)

                                    VStack(spacing: AppDesign.Spacing.xs) {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundStyle(AppDesign.Colors.accent)
                                        Text("Add Photo")
                                            .font(AppDesign.Typography.subheadline)
                                            .foregroundStyle(AppDesign.Colors.accent)
                                    }
                                }
                            }

                            if selectedPhotoData != nil {
                                Text("Change Photo")
                                    .font(AppDesign.Typography.caption)
                                    .foregroundStyle(AppDesign.Colors.accent)
                            }
                        }
                        .padding(.vertical, AppDesign.Spacing.xxs)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                cropItem = CropImageItem(image: uiImage)
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

                    if obdManager.connectionState.isConnectedToVehicle {
                        Button {
                            isReadingVIN = true
                            Task {
                                if let readVin = await obdManager.readVIN() {
                                    vin = readVin
                                }
                                isReadingVIN = false
                            }
                        } label: {
                            HStack {
                                if isReadingVIN {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                }
                                Text("Auto-fill from OBD2")
                            }
                            .font(AppDesign.Typography.subheadline)
                            .foregroundStyle(AppDesign.Colors.diagnostics)
                        }
                        .disabled(isReadingVIN)
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

                // Ownership & Purchase Info
                Section {
                    Picker("Ownership", selection: $ownershipType) {
                        ForEach(OwnershipType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if ownershipType == .owned {
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
                    }

                    if ownershipType == .leased || ownershipType == .financed {
                        DatePicker("Start Date", selection: $purchaseDate, displayedComponents: .date)

                        HStack {
                            Text("Down Payment")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0", text: $downPayment)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Monthly Payment")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0", text: $monthlyPayment)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Interest Rate")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("0.0", text: $interestRate)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                            Text("%")
                                .foregroundStyle(.secondary)
                        }

                        DatePicker("End Date", selection: $leasingEndDate, displayedComponents: .date)

                        HStack {
                            Text(ownershipType == .leased ? "Leasing Company" : "Finance Company")
                                .foregroundStyle(.secondary)
                            TextField("Optional", text: $leasingCompany)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                        }
                    }
                } header: {
                    switch ownershipType {
                    case .owned: Text("Purchase (Optional)")
                    case .leased: Text("Leasing Details")
                    case .financed: Text("Financing Details")
                    }
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
            .fullScreenCover(item: $cropItem) { item in
                PhotoCropView(image: item.image) { croppedData in
                    selectedPhotoData = croppedData
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
        ownershipType = car.ownershipType

        if let date = car.purchaseDate {
            hasPurchaseInfo = true
            purchaseDate = date
            if let price = car.purchasePrice {
                purchasePrice = "\(price)"
            }
        }

        if let dp = car.downPayment { downPayment = "\(dp)" }
        if let mp = car.monthlyPayment { monthlyPayment = "\(mp)" }
        if let ir = car.interestRate { interestRate = "\(ir)" }
        if let startDate = car.leasingStartDate { purchaseDate = startDate }
        if let endDate = car.leasingEndDate { leasingEndDate = endDate }
        leasingCompany = car.leasingCompany ?? ""
    }

    private func saveCar() {
        let odometerValue = Int(odometer) ?? 0
        let priceValue = Double(purchasePrice.replacingOccurrences(of: ",", with: "."))
        let downPaymentValue = Double(downPayment.replacingOccurrences(of: ",", with: "."))
        let monthlyPaymentValue = Double(monthlyPayment.replacingOccurrences(of: ",", with: "."))
        let interestRateValue = Double(interestRate.replacingOccurrences(of: ",", with: "."))

        let isLeasedOrFinanced = ownershipType == .leased || ownershipType == .financed

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
            car.ownershipType = ownershipType

            if ownershipType == .owned {
                car.purchaseDate = hasPurchaseInfo ? purchaseDate : nil
                car.purchasePrice = hasPurchaseInfo ? priceValue : nil
                car.downPayment = nil
                car.monthlyPayment = nil
                car.interestRate = nil
                car.leasingStartDate = nil
                car.leasingEndDate = nil
                car.leasingCompany = nil
            } else {
                car.purchaseDate = nil
                car.purchasePrice = nil
                car.leasingStartDate = purchaseDate
                car.downPayment = downPaymentValue
                car.monthlyPayment = monthlyPaymentValue
                car.interestRate = interestRateValue
                car.leasingEndDate = leasingEndDate
                car.leasingCompany = leasingCompany.isEmpty ? nil : leasingCompany.trimmingCharacters(in: .whitespaces)
            }
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
                purchaseDate: ownershipType == .owned && hasPurchaseInfo ? purchaseDate : nil,
                purchasePrice: ownershipType == .owned && hasPurchaseInfo ? priceValue : nil,
                ownershipType: ownershipType,
                downPayment: isLeasedOrFinanced ? downPaymentValue : nil,
                monthlyPayment: isLeasedOrFinanced ? monthlyPaymentValue : nil,
                interestRate: isLeasedOrFinanced ? interestRateValue : nil,
                leasingStartDate: isLeasedOrFinanced ? purchaseDate : nil,
                leasingEndDate: isLeasedOrFinanced ? leasingEndDate : nil,
                leasingCompany: isLeasedOrFinanced && !leasingCompany.isEmpty ? leasingCompany.trimmingCharacters(in: .whitespaces) : nil,
                currentOdometer: odometerValue,
                photoData: selectedPhotoData
            )
            modelContext.insert(newCar)

            // Auto-select the new car
            appState.selectCar(newCar)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddCarView()
        .modelContainer(for: Car.self, inMemory: true)
        .environment(AppState())
        .environment(OBDConnectionManager())
}
