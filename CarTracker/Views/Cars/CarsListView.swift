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
                LazyVStack(spacing: 16) {
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
            .background(Color(.systemGroupedBackground))
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
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Cars Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first car to start tracking\nfuel, expenses, and reminders")
                .font(.subheadline)
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

    var body: some View {
        VStack(spacing: 0) {
            // Car Image Section
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let photoData = car.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                }
            }
            .frame(height: 120)
            .clipped()

            // Car Info Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(car.fullDisplayName)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("\(car.year)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // License Plate Badge
                    Text(car.licensePlate)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Divider()

                // Stats Row
                HStack(spacing: 20) {
                    CarStatItem(
                        icon: "speedometer",
                        value: "\(car.currentOdometer.formatted())",
                        unit: settings.distanceUnit.abbreviation
                    )

                    CarStatItem(
                        icon: car.fuelType.icon,
                        value: car.fuelType.rawValue,
                        unit: ""
                    )

                    Spacer()

                    // Fuel Efficiency
                    if let consumption = averageConsumption {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f", consumption))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text(settings.distanceUnit.consumptionLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("--")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(settings.distanceUnit.consumptionLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

struct CarStatItem: View {
    let icon: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Add Car Card

struct AddCarCard: View {
    var body: some View {
        VStack(spacing: 12) {
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
