//
//  Expense.swift
//  CarTracker
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var id: UUID
    var date: Date
    var category: ExpenseCategory
    var subcategory: String?
    var amount: Double
    var odometer: Int?
    var notes: String?
    var serviceProvider: String?
    var location: String?
    var receiptPhotoData: Data?
    var createdAt: Date

    var car: Car?

    init(
        date: Date = Date(),
        category: ExpenseCategory,
        subcategory: String? = nil,
        amount: Double,
        odometer: Int? = nil,
        notes: String? = nil,
        serviceProvider: String? = nil,
        location: String? = nil,
        receiptPhotoData: Data? = nil,
        car: Car? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.subcategory = subcategory
        self.amount = amount
        self.odometer = odometer
        self.notes = notes
        self.serviceProvider = serviceProvider
        self.location = location
        self.receiptPhotoData = receiptPhotoData
        self.car = car
        self.createdAt = Date()
    }

    var formattedAmount: String {
        String(format: "%.2f", amount)
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case maintenance = "Maintenance"
    case repair = "Repair"
    case insurance = "Insurance"
    case tax = "Tax"
    case inspection = "Inspection"
    case parking = "Parking"
    case toll = "Toll"
    case cleaning = "Cleaning"
    case accessories = "Accessories"
    case tires = "Tires"
    case other = "Other"

    var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .repair: return "hammer.fill"
        case .insurance: return "shield.fill"
        case .tax: return "doc.text.fill"
        case .inspection: return "checkmark.seal.fill"
        case .parking: return "p.square.fill"
        case .toll: return "road.lanes"
        case .cleaning: return "drop.fill"
        case .accessories: return "bag.fill"
        case .tires: return "circle.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .maintenance: return .blue
        case .repair: return .red
        case .insurance: return .green
        case .tax: return .orange
        case .inspection: return .purple
        case .parking: return .cyan
        case .toll: return .brown
        case .cleaning: return .teal
        case .accessories: return .pink
        case .tires: return .gray
        case .other: return .secondary
        }
    }

    var subcategories: [String] {
        switch self {
        case .maintenance:
            return ["Oil Change", "Filter Replacement", "Brake Service", "Battery", "Spark Plugs", "Fluid Top-up", "Other"]
        case .repair:
            return ["Engine", "Transmission", "Suspension", "Electrical", "Body Work", "AC/Heating", "Other"]
        case .insurance:
            return ["Liability", "Comprehensive", "Collision", "GAP", "Other"]
        case .tax:
            return ["Road Tax", "Registration", "Environmental", "Other"]
        case .inspection:
            return ["TÜV/STK/MOT", "Emissions Test", "Safety Check", "Other"]
        case .parking:
            return ["Monthly Permit", "Ticket", "Garage", "Other"]
        case .toll:
            return ["Highway Vignette", "Bridge/Tunnel", "City Toll", "Other"]
        case .cleaning:
            return ["Car Wash", "Interior Cleaning", "Detailing", "Other"]
        case .accessories:
            return ["Floor Mats", "Phone Mount", "Cargo Organizer", "Other"]
        case .tires:
            return ["Summer Tires", "Winter Tires", "All-Season", "Rotation", "Alignment", "Other"]
        case .other:
            return ["Other"]
        }
    }
}
