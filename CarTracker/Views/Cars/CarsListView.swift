//
//  CarsListView.swift
//  CarTracker
//

import SwiftUI
import SwiftData

struct CarsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Car.createdAt, order: .reverse) private var cars: [Car]
    @State private var showingAddCar = false

    var activeCars: [Car] {
        cars.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppDesign.Spacing.md) {
                    if activeCars.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(activeCars) { car in
                            NavigationLink(destination: CarDetailView(car: car)) {
                                CarCard(car: car)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Add Car Button
                    AddCarCard()
                        .onTapGesture {
                            showingAddCar = true
                        }
                }
                .padding()
            }
            .background(AppDesign.Colors.background)
            .navigationTitle("My Cars")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCar = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCar) {
                AddCarView()
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Cars Yet")
                .font(AppDesign.Typography.title2)

            Text("Add your first car to start tracking\nfuel, expenses, and reminders")
                .font(AppDesign.Typography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Car Card

struct CarCard: View {
    let car: Car
    let settings = UserSettings.shared
    @Query private var fuelEntries: [FuelEntry]

    init(car: Car) {
        self.car = car
        let carId = car.id
        _fuelEntries = Query(filter: #Predicate<FuelEntry> { entry in
            entry.car?.id == carId
        }, sort: \FuelEntry.date, order: .reverse)
    }

    var averageConsumption: Double? {
        CalculationService.averageConsumption(entries: fuelEntries)
    }

    var totalFuelCost: Double {
        fuelEntries.reduce(0) { $0 + $1.totalCost }
    }

    var totalFillUps: Int {
        fuelEntries.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero image / placeholder banner
            ZStack(alignment: .bottomLeading) {
                if let photoData = car.photoData,
                   let uiImage = UIImage(data: photoData) {
                    GeometryReader { geo in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    .frame(height: 160)
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.55), .black.opacity(0.15), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                    // Name overlay on photo
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                        Text(car.fullDisplayName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text(String(car.year))
                            .font(AppDesign.Typography.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(AppDesign.Spacing.md)
                } else {
                    // No photo - gradient banner with icon
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [AppDesign.Colors.accent, AppDesign.Colors.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        .overlay(alignment: .trailing) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.white.opacity(0.12))
                                .padding(.trailing, AppDesign.Spacing.lg)
                        }

                        VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                            Text(car.fullDisplayName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            Text(String(car.year))
                                .font(AppDesign.Typography.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(AppDesign.Spacing.md)
                    }
                }
            }

            // Info section
            VStack(spacing: AppDesign.Spacing.xs) {
                // Top row: plate, fuel type, odometer
                HStack(spacing: AppDesign.Spacing.sm) {
                    // License plate badge
                    Text(car.licensePlate)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, AppDesign.Spacing.xs)
                        .padding(.vertical, AppDesign.Spacing.xxs)
                        .background(AppDesign.Colors.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Fuel type
                    HStack(spacing: 4) {
                        Image(systemName: car.fuelType.icon)
                            .font(.system(size: 10))
                        Text(car.fuelType.rawValue)
                            .font(AppDesign.Typography.caption2)
                    }
                    .foregroundStyle(AppDesign.Colors.textSecondary)

                    Spacer()

                    // Odometer
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 10))
                        Text("\(car.currentOdometer.formatted()) \(settings.distanceUnit.abbreviation)")
                            .font(AppDesign.Typography.caption)
                    }
                    .foregroundStyle(AppDesign.Colors.textSecondary)
                }

                // Stats row
                if totalFillUps > 0 {
                    Divider()

                    HStack(spacing: 0) {
                        // Consumption
                        CarCardStat(
                            icon: "gauge.with.dots.needle.67percent",
                            label: "Avg",
                            value: averageConsumption != nil ? String(format: "%.1f", averageConsumption!) : "--",
                            unit: settings.distanceUnit.consumptionLabel,
                            color: AppDesign.Colors.stats
                        )

                        Divider().frame(height: 28)

                        // Total fuel cost
                        CarCardStat(
                            icon: "fuelpump.fill",
                            label: "Fuel",
                            value: String(format: "%.0f", totalFuelCost),
                            unit: settings.currency.symbol,
                            color: AppDesign.Colors.fuel
                        )

                        Divider().frame(height: 28)

                        // Fill-ups
                        CarCardStat(
                            icon: "drop.fill",
                            label: "Fill-ups",
                            value: "\(totalFillUps)",
                            unit: "",
                            color: AppDesign.Colors.accent
                        )
                    }
                }
            }
            .padding(AppDesign.Spacing.sm)
        }
        .background(AppDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

struct CarCardStat: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundStyle(AppDesign.Colors.textTertiary)
                }
            }
            Text(label)
                .font(AppDesign.Typography.caption2)
                .foregroundStyle(AppDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Car Card

struct AddCarCard: View {
    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Text("Add New Car")
                .font(AppDesign.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppDesign.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.Radius.lg)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(.secondary.opacity(0.3))
        )
    }
}

#Preview {
    CarsListView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self], inMemory: true)
        .environment(AppState())
}
