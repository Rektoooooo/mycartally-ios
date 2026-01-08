//
//  SampleData.swift
//  CarTracker
//

import Foundation

struct SampleData {

    // MARK: - Sample Cars

    static let sampleCar1 = Car(
        make: "Volkswagen",
        model: "Golf",
        year: 2020,
        variant: "1.5 TSI",
        licensePlate: "1AB 2345",
        vin: "WVWZZZ1KZLW123456",
        fuelType: .petrolE10,
        purchaseDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
        purchasePrice: 22500,
        currentOdometer: 45230
    )

    static let sampleCar2 = Car(
        make: "Škoda",
        model: "Octavia",
        year: 2019,
        variant: "2.0 TDI",
        licensePlate: "2CD 6789",
        fuelType: .diesel,
        purchaseDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
        purchasePrice: 28000,
        currentOdometer: 87650
    )

    static let sampleCar3 = Car(
        make: "Tesla",
        model: "Model 3",
        year: 2023,
        variant: "Long Range",
        licensePlate: "3EV 1234",
        fuelType: .electric,
        purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
        purchasePrice: 48000,
        currentOdometer: 12340
    )

    static var allCars: [Car] {
        [sampleCar1, sampleCar2, sampleCar3]
    }

    // MARK: - Sample Fuel Entries

    static func sampleFuelEntries(for car: Car) -> [FuelEntry] {
        let baseOdometer = car.currentOdometer - 2000
        return [
            FuelEntry(
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                odometer: baseOdometer + 2000,
                liters: 42.5,
                pricePerLiter: 1.459,
                isFullTank: true,
                stationName: "Shell",
                fuelType: car.fuelType,
                car: car
            ),
            FuelEntry(
                date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!,
                odometer: baseOdometer + 1500,
                liters: 38.2,
                pricePerLiter: 1.489,
                isFullTank: true,
                stationName: "OMV",
                fuelType: car.fuelType,
                car: car
            ),
            FuelEntry(
                date: Calendar.current.date(byAdding: .day, value: -22, to: Date())!,
                odometer: baseOdometer + 1000,
                liters: 45.0,
                pricePerLiter: 1.419,
                isFullTank: true,
                stationName: "Benzina",
                fuelType: car.fuelType,
                car: car
            ),
            FuelEntry(
                date: Calendar.current.date(byAdding: .day, value: -35, to: Date())!,
                odometer: baseOdometer + 500,
                liters: 40.8,
                pricePerLiter: 1.449,
                isFullTank: true,
                stationName: "Shell",
                fuelType: car.fuelType,
                car: car
            ),
            FuelEntry(
                date: Calendar.current.date(byAdding: .day, value: -48, to: Date())!,
                odometer: baseOdometer,
                liters: 44.1,
                pricePerLiter: 1.479,
                isFullTank: true,
                stationName: "MOL",
                fuelType: car.fuelType,
                car: car
            )
        ]
    }

    // MARK: - Sample Expenses

    static func sampleExpenses(for car: Car) -> [Expense] {
        [
            Expense(
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                category: .maintenance,
                subcategory: "Oil Change",
                amount: 89.50,
                odometer: car.currentOdometer - 200,
                serviceProvider: "AutoService Plus",
                car: car
            ),
            Expense(
                date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                category: .cleaning,
                subcategory: "Car Wash",
                amount: 15.00,
                car: car
            ),
            Expense(
                date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
                category: .insurance,
                subcategory: "Comprehensive",
                amount: 450.00,
                notes: "Annual premium",
                car: car
            ),
            Expense(
                date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                category: .inspection,
                subcategory: "TÜV/STK/MOT",
                amount: 65.00,
                odometer: car.currentOdometer - 3500,
                serviceProvider: "STK Centrum",
                car: car
            ),
            Expense(
                date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
                category: .tires,
                subcategory: "Winter Tires",
                amount: 320.00,
                notes: "Continental WinterContact",
                car: car
            ),
            Expense(
                date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!,
                category: .toll,
                subcategory: "Highway Vignette",
                amount: 35.00,
                notes: "Annual vignette",
                car: car
            )
        ]
    }

    // MARK: - Sample Reminders

    static func sampleReminders(for car: Car) -> [Reminder] {
        [
            Reminder(
                type: .inspection,
                dueDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()),
                notifyDaysBefore: 14,
                isRecurring: true,
                recurringIntervalMonths: 24,
                car: car
            ),
            Reminder(
                type: .insurance,
                dueDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                notifyDaysBefore: 30,
                isRecurring: true,
                recurringIntervalMonths: 12,
                car: car
            ),
            Reminder(
                type: .oilChange,
                dueDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                dueOdometer: car.currentOdometer + 5000,
                notifyDaysBefore: 7,
                notifyKmBefore: 500,
                isRecurring: true,
                recurringIntervalMonths: 12,
                recurringIntervalKm: 15000,
                car: car
            ),
            Reminder(
                type: .tireChange,
                title: "Switch to Summer Tires",
                dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
                notifyDaysBefore: 7,
                isRecurring: true,
                recurringIntervalMonths: 6,
                car: car
            ),
            Reminder(
                type: .vignette,
                dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                notifyDaysBefore: 14,
                isRecurring: true,
                recurringIntervalMonths: 12,
                car: car
            )
        ]
    }

    // MARK: - Mock Statistics

    static let monthlyFuelCosts: [(month: String, cost: Double)] = [
        ("Jul", 185.50),
        ("Aug", 210.30),
        ("Sep", 178.90),
        ("Oct", 195.20),
        ("Nov", 220.80),
        ("Dec", 245.10)
    ]

    static let fuelConsumption: [(date: String, consumption: Double)] = [
        ("Oct 15", 7.2),
        ("Oct 28", 6.8),
        ("Nov 10", 7.5),
        ("Nov 25", 7.1),
        ("Dec 8", 7.8),
        ("Dec 22", 7.3)
    ]

    static let expensesByCategory: [(category: ExpenseCategory, amount: Double)] = [
        (.maintenance, 450.00),
        (.insurance, 650.00),
        (.tires, 320.00),
        (.inspection, 65.00),
        (.toll, 85.00),
        (.cleaning, 45.00),
        (.parking, 120.00)
    ]

    static var totalMonthlyExpenses: Double {
        monthlyFuelCosts.last?.cost ?? 0 + 150
    }

    static var averageConsumption: Double {
        7.3
    }
}
