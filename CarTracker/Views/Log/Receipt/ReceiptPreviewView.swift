//
//  ReceiptPreviewView.swift
//  CarTracker
//

import SwiftUI

struct ReceiptPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let extractedData: ExtractedReceiptData
    let onConfirm: (ExtractedReceiptData) -> Void
    let onRetake: () -> Void

    // Editable fields
    @State private var date: Date
    @State private var liters: String
    @State private var pricePerLiter: String
    @State private var totalCost: String
    @State private var stationName: String
    @State private var showingRawText = false

    init(image: UIImage, extractedData: ExtractedReceiptData,
         onConfirm: @escaping (ExtractedReceiptData) -> Void,
         onRetake: @escaping () -> Void) {
        self.image = image
        self.extractedData = extractedData
        self.onConfirm = onConfirm
        self.onRetake = onRetake

        // Initialize state from extracted data
        _date = State(initialValue: extractedData.date ?? Date())
        _liters = State(initialValue: extractedData.liters.map {
            String(format: "%.2f", $0)
        } ?? "")
        _pricePerLiter = State(initialValue: extractedData.pricePerLiter.map {
            String(format: "%.3f", $0)
        } ?? "")
        _totalCost = State(initialValue: extractedData.totalCost.map {
            String(format: "%.2f", $0)
        } ?? "")
        _stationName = State(initialValue: extractedData.stationName ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Receipt image preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .padding(.horizontal)

                    // Status indicator
                    HStack {
                        Image(systemName: extractedData.hasAnyData ?
                              "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(extractedData.hasAnyData ? .green : .orange)
                        Text(extractedData.hasAnyData ?
                             "Data extracted successfully" : "Limited data extracted")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Extracted fields form
                    VStack(spacing: 0) {
                        // Date
                        ReceiptFieldRow(
                            icon: "calendar",
                            label: "Date",
                            extracted: extractedData.date != nil
                        ) {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Divider().padding(.leading, 52)

                        // Liters
                        ReceiptFieldRow(
                            icon: "drop.fill",
                            label: "Amount (L)",
                            extracted: extractedData.liters != nil
                        ) {
                            TextField("0.00", text: $liters)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.leading, 52)

                        // Price per liter
                        ReceiptFieldRow(
                            icon: "eurosign",
                            label: "Price/L",
                            extracted: extractedData.pricePerLiter != nil
                        ) {
                            TextField("0.000", text: $pricePerLiter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.leading, 52)

                        // Total cost
                        ReceiptFieldRow(
                            icon: "creditcard.fill",
                            label: "Total",
                            extracted: extractedData.totalCost != nil
                        ) {
                            TextField("0.00", text: $totalCost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.leading, 52)

                        // Station name
                        ReceiptFieldRow(
                            icon: "building.2.fill",
                            label: "Station",
                            extracted: extractedData.stationName != nil
                        ) {
                            TextField("Station name", text: $stationName)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Debug: Show raw text
                    Button {
                        showingRawText.toggle()
                    } label: {
                        Label(showingRawText ? "Hide Raw Text" : "Show Raw Text",
                              systemImage: "doc.text.magnifyingglass")
                            .font(.caption)
                    }
                    .padding(.top, 8)

                    if showingRawText {
                        Text(extractedData.rawText)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Review Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retake") {
                        onRetake()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyData()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyData() {
        var finalData = extractedData
        finalData.date = date
        finalData.liters = Double(liters.replacingOccurrences(of: ",", with: "."))
        finalData.pricePerLiter = Double(pricePerLiter.replacingOccurrences(of: ",", with: "."))
        finalData.totalCost = Double(totalCost.replacingOccurrences(of: ",", with: "."))
        finalData.stationName = stationName.isEmpty ? nil : stationName

        onConfirm(finalData)
    }
}

// MARK: - Field Row Component

struct ReceiptFieldRow<Content: View>: View {
    let icon: String
    let label: String
    let extracted: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(extracted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(extracted ? .green : .secondary)
            }

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            content
                .frame(minWidth: 100)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
