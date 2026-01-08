//
//  ReceiptOCRService.swift
//  CarTracker
//

import Vision
import UIKit

@Observable
class ReceiptOCRService {

    enum OCRError: Error {
        case imageConversionFailed
        case noTextFound
        case processingFailed(Error)
    }

    // MARK: - OCR Processing

    func extractData(from image: UIImage) async throws -> ExtractedReceiptData {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }

        let rawText = try await performOCR(on: cgImage)
        return parseReceiptText(rawText)
    }

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.processingFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "cs-CZ", "de-DE", "sk-SK"]

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }

    // MARK: - Text Parsing

    private func parseReceiptText(_ text: String) -> ExtractedReceiptData {
        let lines = text.components(separatedBy: .newlines)

        // Debug: Print raw OCR text
        print("\n" + String(repeating: "=", count: 50))
        print("📄 RAW OCR TEXT:")
        print(String(repeating: "-", count: 50))
        print(text)
        print(String(repeating: "=", count: 50))

        let date = extractDate(from: lines)
        let liters = extractLiters(from: lines)
        let pricePerLiter = extractPricePerLiter(from: lines)
        let totalCost = extractTotalCost(from: lines)
        let stationName = extractStationName(from: lines)

        // Debug: Print extracted values BEFORE reconciliation
        print("\n📊 EXTRACTED VALUES (before reconciliation):")
        print("  📅 Date: \(date?.description ?? "nil")")
        print("  ⛽ Liters: \(liters?.description ?? "nil")")
        print("  💰 Price/L: \(pricePerLiter?.description ?? "nil")")
        print("  💵 Total: \(totalCost?.description ?? "nil")")
        print("  🏪 Station: \(stationName ?? "nil")")

        var data = ExtractedReceiptData(
            date: date,
            liters: liters,
            pricePerLiter: pricePerLiter,
            totalCost: totalCost,
            stationName: stationName,
            rawText: text
        )

        // Apply cross-validation and reconciliation
        data = reconcileExtractedData(data)

        // Debug: Print final values AFTER reconciliation
        print("\n✅ FINAL VALUES (after reconciliation):")
        print("  📅 Date: \(data.date?.description ?? "nil")")
        print("  ⛽ Liters: \(data.liters?.description ?? "nil")")
        print("  💰 Price/L: \(data.pricePerLiter?.description ?? "nil")")
        print("  💵 Total: \(data.totalCost?.description ?? "nil")")
        print("  🏪 Station: \(data.stationName ?? "nil")")
        print(String(repeating: "=", count: 50) + "\n")

        return data
    }

    /// Cross-validate and reconcile extracted data
    /// If we have 2 of 3 values (liters, pricePerLiter, totalCost), calculate the third
    private func reconcileExtractedData(_ data: ExtractedReceiptData) -> ExtractedReceiptData {
        var result = data

        let liters = data.liters
        let pricePerLiter = data.pricePerLiter
        let totalCost = data.totalCost

        // Count how many values we have
        let hasLiters = liters != nil
        let hasPricePerLiter = pricePerLiter != nil
        let hasTotalCost = totalCost != nil

        // If we have all three, validate they're consistent (within 5% tolerance)
        if hasLiters && hasPricePerLiter && hasTotalCost {
            let calculatedTotal = liters! * pricePerLiter!
            let tolerance = calculatedTotal * 0.05
            if abs(calculatedTotal - totalCost!) > tolerance {
                // Values don't match - recalculate total from liters and price
                // (liters and price/L are usually more reliable than OCR'd total)
                result.totalCost = round(calculatedTotal * 100) / 100
            }
        }
        // If we have liters and pricePerLiter but no total, calculate it
        else if hasLiters && hasPricePerLiter && !hasTotalCost {
            let calculatedTotal = liters! * pricePerLiter!
            result.totalCost = round(calculatedTotal * 100) / 100
        }
        // If we have liters and total but no pricePerLiter, calculate it
        else if hasLiters && !hasPricePerLiter && hasTotalCost {
            let calculatedPrice = totalCost! / liters!
            // Validate it's in reasonable range (20-100 CZK/L)
            if calculatedPrice >= 20.0 && calculatedPrice <= 100.0 {
                result.pricePerLiter = round(calculatedPrice * 100) / 100
            }
        }
        // If we have pricePerLiter and total but no liters, calculate it
        else if !hasLiters && hasPricePerLiter && hasTotalCost {
            let calculatedLiters = totalCost! / pricePerLiter!
            // Validate it's in reasonable range (1-200 L)
            if calculatedLiters >= 1.0 && calculatedLiters <= 200.0 {
                result.liters = round(calculatedLiters * 1000) / 1000
            }
        }

        return result
    }

    // MARK: - Field Extraction Methods

    private func extractDate(from lines: [String]) -> Date? {
        // Look for lines containing "Datum" (Czech for Date) first
        for line in lines {
            let lowerLine = line.lowercased()
            if lowerLine.contains("datum") || lowerLine.contains("date") {
                // Try to find date pattern in this line or nearby
                if let date = findDateInString(line) {
                    return date
                }
            }
        }

        // Common date patterns on receipts
        for line in lines {
            if let date = findDateInString(line) {
                return date
            }
        }
        return nil
    }

    private func findDateInString(_ text: String) -> Date? {
        let datePatterns = [
            // DD.MM.YYYY HH:MM:SS or DD.MM.YYYY
            "\\b(\\d{1,2})[./\\-](\\d{1,2})[./\\-](\\d{4})\\b",
            // YYYY-MM-DD
            "\\b(\\d{4})[./\\-](\\d{1,2})[./\\-](\\d{1,2})\\b",
            // DD.MM.YY
            "\\b(\\d{1,2})[./\\-](\\d{1,2})[./\\-](\\d{2})\\b"
        ]

        for pattern in datePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let dateString = String(text[match])
                if let date = parseDate(dateString) {
                    return date
                }
            }
        }
        return nil
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("dd.MM.yyyy"),
            createFormatter("dd/MM/yyyy"),
            createFormatter("dd-MM-yyyy"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("dd.MM.yy"),
            createFormatter("dd/MM/yy")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    private func extractLiters(from lines: [String]) -> Double? {
        // OCR often confuses L with 1, I, |, or ] - include all variants
        // Also handles formats like "( 14.42 ]" or "( 40.00 1"

        // First, look for fuel-specific lines and extract liters from context
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            // Look for fuel keywords
            if lowerLine.contains("diesel") || lowerLine.contains("benzin") ||
               lowerLine.contains("natural") || lowerLine.contains("petrol") ||
               lowerLine.contains("nafta") || lowerLine.contains("efecta") {

                // Check this line and next few lines for liter patterns
                for checkIndex in index...(min(index + 2, lines.count - 1)) {
                    let checkLine = lines[checkIndex]

                    // Pattern: "( 14.42 ]" or "(20,060 |" or "( 40.00 1" - OCR variants
                    if let regex = try? NSRegularExpression(pattern: "\\(?\\s*(\\d+[,.]\\d{2,3})\\s*[\\]|1ILl]", options: []),
                       let match = regex.firstMatch(in: checkLine, range: NSRange(checkLine.startIndex..., in: checkLine)) {
                        if let captureRange = Range(match.range(at: 1), in: checkLine) {
                            let numString = String(checkLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                                return value
                            }
                        }
                    }

                    // Pattern: "21% 37.47" - percentage followed by liters
                    if let regex = try? NSRegularExpression(pattern: "\\d+%\\s*(\\d+[,.]\\d{2})", options: []),
                       let match = regex.firstMatch(in: checkLine, range: NSRange(checkLine.startIndex..., in: checkLine)) {
                        if let captureRange = Range(match.range(at: 1), in: checkLine) {
                            let numString = String(checkLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                                return value
                            }
                        }
                    }
                }
            }
        }

        // Look for "množství:" (quantity) pattern
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            if lowerLine.contains("množství") || lowerLine.contains("mnozstvi") || lowerLine.contains("mnoz") {
                // Check this line and next line
                for checkIndex in index...(min(index + 1, lines.count - 1)) {
                    if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2,3})", options: []),
                       let match = regex.firstMatch(in: lines[checkIndex], range: NSRange(lines[checkIndex].startIndex..., in: lines[checkIndex])) {
                        if let captureRange = Range(match.range(at: 1), in: lines[checkIndex]) {
                            let numString = String(lines[checkIndex][captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                                return value
                            }
                        }
                    }
                }
            }
        }

        // Pattern: "( XX.XX 1" or "( XX.XX ]" with brackets - common OCR pattern
        for line in lines {
            if let regex = try? NSRegularExpression(pattern: "\\(\\s*(\\d+[,.]\\d{2})\\s*[\\]|1ILl]", options: []),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let captureRange = Range(match.range(at: 1), in: line) {
                    let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                    if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                        return value
                    }
                }
            }
        }

        // Fallback: Look for number followed by L variants
        for line in lines {
            if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2,3})\\s*[Ll1I|\\]](?:\\s|$|[^a-zA-Z0-9])", options: []),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let captureRange = Range(match.range(at: 1), in: line) {
                    let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                    if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                        return value
                    }
                }
            }
        }

        return nil
    }

    private func extractLiterValue(from text: String) -> Double? {
        // Pattern handles OCR confusion: L can appear as 1, I, |, or ]
        if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2,3})\\s*[Ll1I|\\]](?:\\s|$|[^a-zA-Z0-9])", options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let captureRange = Range(match.range(at: 1), in: text) {
                let numString = String(text[captureRange]).replacingOccurrences(of: ",", with: ".")
                if let value = Double(numString), value >= 1.0 && value <= 200.0 {
                    return value
                }
            }
        }
        return nil
    }

    private func extractPricePerLiter(from lines: [String]) -> Double? {
        // Price per liter ranges (currency-agnostic):
        // CZK: ~25-50, EUR: ~1.20-2.50, USD: ~3-6
        // We use a broad range and rely on context (fuel keywords) to find correct value

        // PRIORITY 1: Look for price on fuel-specific lines (Diesel, Nafta, Benzin, Efecta)
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            if lowerLine.contains("diesel") || lowerLine.contains("nafta") ||
               lowerLine.contains("benzin") || lowerLine.contains("efecta") ||
               lowerLine.contains("natural") {

                // Check this line and next 2 lines for price patterns
                for checkIndex in index...(min(index + 2, lines.count - 1)) {
                    let checkLine = lines[checkIndex]

                    // Pattern: "31.90 CZK)" or "1,85 EUR)" - price with currency and closing paren
                    if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:Kč|CZK|€|EUR)\\s*\\)", options: []),
                       let match = regex.firstMatch(in: checkLine, range: NSRange(checkLine.startIndex..., in: checkLine)) {
                        if let captureRange = Range(match.range(at: 1), in: checkLine) {
                            let numString = String(checkLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), isReasonablePricePerLiter(value, in: checkLine) {
                                return value
                            }
                        }
                    }

                    // Pattern: "x 34,90 CZK" or "x 1,85 EUR" - multiplication pattern
                    if let regex = try? NSRegularExpression(pattern: "[xX]\\s*(\\d+[,.]\\d{2})\\s*(?:Kč|CZK|€|EUR)?", options: []),
                       let match = regex.firstMatch(in: checkLine, range: NSRange(checkLine.startIndex..., in: checkLine)) {
                        if let captureRange = Range(match.range(at: 1), in: checkLine) {
                            let numString = String(checkLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), isReasonablePricePerLiter(value, in: checkLine) {
                                return value
                            }
                        }
                    }

                    // Pattern: "31.90 CZK/" - price per unit
                    if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:Kč|CZK|€|EUR)?\\s*/", options: []),
                       let match = regex.firstMatch(in: checkLine, range: NSRange(checkLine.startIndex..., in: checkLine)) {
                        if let captureRange = Range(match.range(at: 1), in: checkLine) {
                            let numString = String(checkLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), isReasonablePricePerLiter(value, in: checkLine) {
                                return value
                            }
                        }
                    }
                }
            }
        }

        // PRIORITY 2: Look for "Cena/mj" or "Cena/Mj." pattern
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            if lowerLine.contains("cena/mj") || lowerLine.contains("cena/l") || lowerLine.contains("price") {
                for checkIndex in index...(min(index + 2, lines.count - 1)) {
                    if let value = extractPriceValue(from: lines[checkIndex]), isReasonablePricePerLiter(value, in: lines[checkIndex]) {
                        return value
                    }
                }
            }
        }

        // PRIORITY 3: Pattern "( XX.XX 1 31.90 CZK)" - liters followed by price
        for line in lines {
            if let regex = try? NSRegularExpression(pattern: "\\d+[,.]\\d{2}\\s*[\\]|1ILl]\\s*(\\d+[,.]\\d{2})\\s*(?:Kč|CZK|€|EUR)", options: []),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let captureRange = Range(match.range(at: 1), in: line) {
                    let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                    if let value = Double(numString), isReasonablePricePerLiter(value, in: line) {
                        return value
                    }
                }
            }
        }

        return nil
    }

    /// Check if a value is a reasonable price per liter based on currency context
    private func isReasonablePricePerLiter(_ value: Double, in line: String) -> Bool {
        let lowerLine = line.lowercased()

        // If EUR context, expect 1-3 EUR/L
        if lowerLine.contains("eur") || lowerLine.contains("€") {
            return value >= 1.0 && value <= 5.0
        }

        // If CZK context or default, expect 20-60 CZK/L
        if lowerLine.contains("czk") || lowerLine.contains("kč") {
            return value >= 20.0 && value <= 60.0
        }

        // No currency indicator - accept both ranges
        return (value >= 1.0 && value <= 5.0) || (value >= 20.0 && value <= 60.0)
    }

    /// Helper to extract price value from a line
    private func extractPriceValue(from text: String) -> Double? {
        if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:Kč|CZK|€|EUR)?", options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let captureRange = Range(match.range(at: 1), in: text) {
                let numString = String(text[captureRange]).replacingOccurrences(of: ",", with: ".")
                return Double(numString)
            }
        }
        return nil
    }

    private func extractTotalCost(from lines: [String]) -> Double? {
        // Total must be larger than typical liter amounts (>50) to avoid confusion
        // Works for both CZK (100-5000) and EUR (20-500)

        // PRIORITY 1: Look for "Celkem:" followed by amount with currency
        for (index, line) in lines.enumerated() {
            let lowerLine = line.lowercased()
            // Match "Celkem:" but not "Bez DPH" lines
            if lowerLine.contains("celkem") && !lowerLine.contains("bez") && !lowerLine.contains("dph %") {

                // Check this line for amount with currency
                if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:CZK|Kč|EUR|€)", options: []),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let captureRange = Range(match.range(at: 1), in: line) {
                        let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(numString), isReasonableTotal(value, in: line) {
                            return value
                        }
                    }
                }

                // Check next lines for amount
                for nextIndex in (index + 1)...min(index + 3, lines.count - 1) {
                    let nextLine = lines[nextIndex]
                    if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:CZK|Kč|EUR|€)?", options: []),
                       let match = regex.firstMatch(in: nextLine, range: NSRange(nextLine.startIndex..., in: nextLine)) {
                        if let captureRange = Range(match.range(at: 1), in: nextLine) {
                            let numString = String(nextLine[captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), isReasonableTotal(value, in: nextLine) {
                                return value
                            }
                        }
                    }
                }
            }
        }

        // PRIORITY 2: Look for "Hotovost" (cash payment) or "Total" line
        for line in lines {
            let lowerLine = line.lowercased()
            if lowerLine.contains("hotovost") || lowerLine.contains("total") || lowerLine.contains("to pay") {
                if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:CZK|Kč|EUR|€)?", options: []),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let captureRange = Range(match.range(at: 1), in: line) {
                        let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(numString), isReasonableTotal(value, in: line) {
                            return value
                        }
                    }
                }
            }
        }

        // PRIORITY 3: Look for "*CELKEM" pattern (CS PRIM style)
        for (index, line) in lines.enumerated() {
            if line.contains("*CELKEM") || line.uppercased().contains("CELKEM (CZK)") || line.uppercased().contains("CELKEM (EUR)") {
                for checkIndex in index...(min(index + 1, lines.count - 1)) {
                    if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})", options: []),
                       let match = regex.firstMatch(in: lines[checkIndex], range: NSRange(lines[checkIndex].startIndex..., in: lines[checkIndex])) {
                        if let captureRange = Range(match.range(at: 1), in: lines[checkIndex]) {
                            let numString = String(lines[checkIndex][captureRange]).replacingOccurrences(of: ",", with: ".")
                            if let value = Double(numString), isReasonableTotal(value, in: lines[checkIndex]) {
                                return value
                            }
                        }
                    }
                }
            }
        }

        // PRIORITY 4: Look for standalone amounts with currency at end of line
        for line in lines {
            if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:CZK|Kč|EUR|€)\\s*$", options: []),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let captureRange = Range(match.range(at: 1), in: line) {
                    let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                    if let value = Double(numString), isReasonableTotal(value, in: line) {
                        return value
                    }
                }
            }
        }

        // PRIORITY 5: Look for fuel line total with asterisk (e.g., "1000,00*")
        for line in lines {
            let lowerLine = line.lowercased()
            if lowerLine.contains("diesel") || lowerLine.contains("nafta") ||
               lowerLine.contains("benzin") || lowerLine.contains("efecta") {
                if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\*", options: []),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let captureRange = Range(match.range(at: 1), in: line) {
                        let numString = String(line[captureRange]).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(numString), isReasonableTotal(value, in: line) {
                            return value
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Check if a value is a reasonable total based on currency context
    private func isReasonableTotal(_ value: Double, in line: String) -> Bool {
        let lowerLine = line.lowercased()

        // If EUR context, expect 10-1000 EUR total
        if lowerLine.contains("eur") || lowerLine.contains("€") {
            return value >= 10.0 && value <= 1000.0
        }

        // If CZK context or default, expect 50-10000 CZK total
        // (50 CZK min to avoid confusing with liters like 20.06)
        return value >= 50.0 && value <= 10000.0
    }

    /// Helper to extract currency value from a line
    private func extractCurrencyValue(from text: String) -> Double? {
        if let regex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})\\s*(?:CZK|Kč|EUR|€)?", options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let captureRange = Range(match.range(at: 1), in: text) {
                let numString = String(text[captureRange]).replacingOccurrences(of: ",", with: ".")
                return Double(numString)
            }
        }
        return nil
    }

    private func extractStationName(from lines: [String]) -> String? {
        // Known fuel station brands
        let knownStations = [
            "Shell", "OMV", "Benzina", "MOL", "EuroOil", "Orlen",
            "BP", "Esso", "Aral", "Total", "Agip", "Q8", "Jet",
            "Circle K", "Lukoil", "Avia", "Tesco", "Globus"
        ]

        // Check first 5 lines for station names (usually at top)
        for line in lines.prefix(5) {
            let uppercased = line.uppercased()
            for station in knownStations {
                if uppercased.contains(station.uppercased()) {
                    return station
                }
            }
        }

        // If no known station, return first non-empty line that looks like a name
        for line in lines.prefix(3) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count > 3 && trimmed.count < 40 &&
               !trimmed.contains(where: { $0.isNumber }) {
                return trimmed
            }
        }

        return nil
    }

    private func extractNumber(from lines: [String], patterns: [String],
                               range: ClosedRange<Double>) -> Double? {
        for line in lines {
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {

                    if let captureRange = Range(match.range(at: 1), in: line) {
                        let numString = String(line[captureRange])
                            .replacingOccurrences(of: ",", with: ".")

                        if let value = Double(numString), range.contains(value) {
                            return value
                        }
                    }
                }
            }
        }
        return nil
    }
}
