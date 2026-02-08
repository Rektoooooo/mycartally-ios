//
//  PDFExportService.swift
//  CarTracker
//

import SwiftUI
import PDFKit

class PDFExportService {
    static let shared = PDFExportService()

    private let settings = UserSettings.shared

    private init() {}

    // MARK: - Generate PDF

    func generateCarHistoryPDF(
        car: Car,
        fuelEntries: [FuelEntry],
        expenses: [Expense],
        reminders: [Reminder]
    ) -> Data? {
        let pageWidth: CGFloat = 612  // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)

        let pdfMetaData = [
            kCGPDFContextCreator: "CarTracker",
            kCGPDFContextAuthor: "CarTracker App",
            kCGPDFContextTitle: "\(car.displayName) - Service History"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            var currentY: CGFloat = margin

            // Helper to add new page if needed
            func checkPageBreak(height: CGFloat) {
                if currentY + height > pageHeight - margin {
                    context.beginPage()
                    currentY = margin
                }
            }

            // Start first page
            context.beginPage()

            // MARK: - Header
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)

            // Title
            let title = "Vehicle Service History"
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttr)
            currentY += 35

            // Car name
            let carName = car.displayName
            let carNameAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            carName.draw(at: CGPoint(x: margin, y: currentY), withAttributes: carNameAttr)
            currentY += 25

            // Date generated
            let dateStr = "Generated: \(Date().formatted(date: .long, time: .shortened))"
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: smallFont,
                .foregroundColor: UIColor.gray
            ]
            dateStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: dateAttr)
            currentY += 30

            // Divider
            drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
            currentY += 20

            // MARK: - Vehicle Info
            let vehicleHeader = "Vehicle Information"
            vehicleHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ])
            currentY += 25

            let vehicleInfo = [
                ("Make", car.make),
                ("Model", car.model),
                ("Year", "\(car.year)"),
                ("License Plate", car.licensePlate),
                ("VIN", car.vin ?? "N/A"),
                ("Fuel Type", car.fuelType.rawValue),
                ("Current Odometer", "\(car.currentOdometer.formatted()) \(settings.distanceUnit.abbreviation)")
            ]

            for (label, value) in vehicleInfo {
                let line = "\(label): \(value)"
                line.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ])
                currentY += 18
            }
            currentY += 15

            // MARK: - Summary Statistics
            drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
            currentY += 20

            let statsHeader = "Summary Statistics"
            statsHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ])
            currentY += 25

            let totalFuelCost = CalculationService.totalFuelCost(entries: fuelEntries)
            let totalExpenses = CalculationService.totalExpenses(expenses: expenses)
            let totalDistance = CalculationService.totalDistance(entries: fuelEntries)
            let avgConsumption = CalculationService.averageConsumption(entries: fuelEntries)

            let stats = [
                ("Total Fuel Cost", String(format: "%.2f \(settings.currency.symbol)", totalFuelCost)),
                ("Total Other Expenses", String(format: "%.2f \(settings.currency.symbol)", totalExpenses)),
                ("Total Cost", String(format: "%.2f \(settings.currency.symbol)", totalFuelCost + totalExpenses)),
                ("Total Distance", "\(totalDistance.formatted()) \(settings.distanceUnit.abbreviation)"),
                ("Average Consumption", avgConsumption != nil ? String(format: "%.1f \(settings.distanceUnit.consumptionLabel)", avgConsumption!) : "N/A"),
                ("Number of Fill-ups", "\(fuelEntries.count)"),
                ("Number of Expenses", "\(expenses.count)")
            ]

            for (label, value) in stats {
                let line = "\(label): \(value)"
                line.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ])
                currentY += 18
            }
            currentY += 15

            // MARK: - Fuel History
            if !fuelEntries.isEmpty {
                checkPageBreak(height: 100)
                drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
                currentY += 20

                let fuelHeader = "Fuel History"
                fuelHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ])
                currentY += 25

                // Table header
                let colWidths: [CGFloat] = [80, 70, 60, 80, 80, 80]
                let headers = ["Date", "Odometer", settings.volumeUnit.abbreviation, "Price/\(settings.volumeUnit.abbreviation)", "Total", "Station"]

                var xPos = margin
                for (i, header) in headers.enumerated() {
                    header.draw(at: CGPoint(x: xPos, y: currentY), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                        .foregroundColor: UIColor.black
                    ])
                    xPos += colWidths[i]
                }
                currentY += 18

                // Table rows
                let sortedEntries = fuelEntries.sorted { $0.date > $1.date }
                for entry in sortedEntries.prefix(50) {
                    checkPageBreak(height: 20)

                    xPos = margin
                    let rowData = [
                        entry.date.formatted(date: .numeric, time: .omitted),
                        "\(entry.odometer.formatted()) \(settings.distanceUnit.abbreviation)",
                        String(format: "%.1f \(settings.volumeUnit.abbreviation)", entry.liters),
                        String(format: "%.3f \(settings.currency.symbol)", entry.pricePerLiter),
                        String(format: "%.2f \(settings.currency.symbol)", entry.totalCost),
                        entry.stationName ?? "-"
                    ]

                    for (i, text) in rowData.enumerated() {
                        let truncated = String(text.prefix(12))
                        truncated.draw(at: CGPoint(x: xPos, y: currentY), withAttributes: [
                            .font: smallFont,
                            .foregroundColor: UIColor.darkGray
                        ])
                        xPos += colWidths[i]
                    }
                    currentY += 16
                }
                currentY += 10
            }

            // MARK: - Expense History
            if !expenses.isEmpty {
                checkPageBreak(height: 100)
                drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
                currentY += 20

                let expenseHeader = "Expense History"
                expenseHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ])
                currentY += 25

                // Table header
                let colWidths: [CGFloat] = [80, 100, 80, 80, 80]
                let headers = ["Date", "Category", "Amount", "Odometer", "Provider"]

                var xPos = margin
                for (i, header) in headers.enumerated() {
                    header.draw(at: CGPoint(x: xPos, y: currentY), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                        .foregroundColor: UIColor.black
                    ])
                    xPos += colWidths[i]
                }
                currentY += 18

                // Table rows
                let sortedExpenses = expenses.sorted { $0.date > $1.date }
                for expense in sortedExpenses.prefix(50) {
                    checkPageBreak(height: 20)

                    xPos = margin
                    let rowData = [
                        expense.date.formatted(date: .numeric, time: .omitted),
                        expense.category.rawValue,
                        String(format: "%.2f \(settings.currency.symbol)", expense.amount),
                        expense.odometer != nil ? "\(expense.odometer!.formatted()) \(settings.distanceUnit.abbreviation)" : "-",
                        expense.serviceProvider ?? "-"
                    ]

                    for (i, text) in rowData.enumerated() {
                        let truncated = String(text.prefix(15))
                        truncated.draw(at: CGPoint(x: xPos, y: currentY), withAttributes: [
                            .font: smallFont,
                            .foregroundColor: UIColor.darkGray
                        ])
                        xPos += colWidths[i]
                    }
                    currentY += 16
                }
                currentY += 10
            }

            // MARK: - Reminders
            let completedReminders = reminders.filter { $0.isCompleted }
            if !completedReminders.isEmpty {
                checkPageBreak(height: 100)
                drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
                currentY += 20

                let reminderHeader = "Completed Services"
                reminderHeader.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ])
                currentY += 25

                let sortedReminders = completedReminders.sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
                for reminder in sortedReminders.prefix(30) {
                    checkPageBreak(height: 20)

                    let dateStr = reminder.completedDate?.formatted(date: .numeric, time: .omitted) ?? "-"
                    let line = "\(dateStr) - \(reminder.type.rawValue): \(reminder.title)"
                    line.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    currentY += 16
                }
            }

            // MARK: - Footer
            checkPageBreak(height: 50)
            currentY += 30
            drawLine(context: context.cgContext, y: currentY, width: contentWidth, margin: margin)
            currentY += 15

            let footer = "This document was generated by CarTracker. All data is self-reported by the vehicle owner."
            footer.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                .foregroundColor: UIColor.gray
            ])
        }

        return data
    }

    private func drawLine(context: CGContext, y: CGFloat, width: CGFloat, margin: CGFloat) {
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + width, y: y))
        context.strokePath()
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("PDF Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: pdfData, preview: SharePreview("Car History.pdf", image: Image(systemName: "doc.fill")))
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
