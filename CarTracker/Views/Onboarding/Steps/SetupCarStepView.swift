//
//  SetupCarStepView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct SetupCarStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let settings = UserSettings.shared
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var licensePlate = ""
    @State private var fuelType: FuelType = .petrolE10
    @State private var odometer = ""
    @State private var isSaving = false

    @FocusState private var focusedField: Field?

    enum Field {
        case make, model, licensePlate, odometer
    }

    private let currentYear = Calendar.current.component(.year, from: Date())

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                title: "Add your car",
                subtitle: "Let's set up your first vehicle"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            // Form
            ScrollView {
                VStack(spacing: OnboardingDesign.Spacing.lg) {
                    // Car illustration
                    ZStack {
                        Circle()
                            .fill(OnboardingDesign.Colors.accent.opacity(0.08))
                            .frame(width: 80, height: 80)

                        Image(systemName: "car.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)

                    // Input Fields
                    VStack(spacing: OnboardingDesign.Spacing.md) {
                        OnboardingTextField(
                            label: "Make",
                            placeholder: "e.g., Volkswagen",
                            text: $make,
                            focused: $focusedField,
                            field: .make
                        )

                        OnboardingTextField(
                            label: "Model",
                            placeholder: "e.g., Golf",
                            text: $model,
                            focused: $focusedField,
                            field: .model
                        )

                        // Year Picker
                        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                            Text("Year")
                                .font(OnboardingDesign.Typography.caption)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                            Picker("Year", selection: $year) {
                                ForEach((1980...currentYear + 1).reversed(), id: \.self) { yr in
                                    Text(String(yr)).tag(yr)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(OnboardingDesign.Spacing.sm)
                            .background(OnboardingDesign.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm))
                        }

                        OnboardingTextField(
                            label: "License Plate",
                            placeholder: "e.g., 1AB 2345",
                            text: $licensePlate,
                            focused: $focusedField,
                            field: .licensePlate,
                            capitalization: .characters
                        )

                        // Fuel Type Picker
                        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                            Text("Fuel Type")
                                .font(OnboardingDesign.Typography.caption)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                            Picker("Fuel Type", selection: $fuelType) {
                                ForEach(FuelType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(OnboardingDesign.Spacing.sm)
                            .background(OnboardingDesign.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm))
                        }

                        // Odometer
                        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                            Text("Current Odometer (optional)")
                                .font(OnboardingDesign.Typography.caption)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                            HStack {
                                TextField("0", text: $odometer)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .odometer)

                                Text(settings.distanceUnit.abbreviation)
                                    .font(OnboardingDesign.Typography.subheadline)
                                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                            }
                            .padding(OnboardingDesign.Spacing.sm)
                            .background(OnboardingDesign.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                }
                .padding(.horizontal, OnboardingDesign.Spacing.xl)
                .padding(.top, OnboardingDesign.Spacing.lg)

                // CTA inside ScrollView so it's always reachable
                VStack(spacing: OnboardingDesign.Spacing.sm) {
                    OnboardingCTAButton(
                        title: isSaving ? "Saving..." : "Add Car & Start",
                        isEnabled: isValid && !isSaving
                    ) {
                        saveCar()
                    }

                    OnboardingSecondaryButton(title: "I'll add later") {
                        onComplete()
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.xl)
                .padding(.top, OnboardingDesign.Spacing.lg)
                .padding(.bottom, OnboardingDesign.Spacing.xxl)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private func saveCar() {
        isSaving = true
        let odometerValue = Int(odometer) ?? 0

        let newCar = Car(
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: year,
            licensePlate: licensePlate.trimmingCharacters(in: .whitespaces).uppercased(),
            fuelType: fuelType,
            currentOdometer: odometerValue
        )
        modelContext.insert(newCar)
        try? modelContext.save()
        appState.selectCar(newCar)

        // Brief delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

// MARK: - Onboarding Text Field

private struct OnboardingTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<SetupCarStepView.Field?>.Binding
    let field: SetupCarStepView.Field
    var capitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
            Text(label)
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .focused(focused, equals: field)
                .padding(OnboardingDesign.Spacing.sm)
                .background(OnboardingDesign.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm))
        }
    }
}

#Preview {
    SetupCarStepView { }
        .modelContainer(for: Car.self, inMemory: true)
        .environment(AppState())
}
