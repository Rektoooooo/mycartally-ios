//
//  ReceiptCaptureView.swift
//  CarTracker
//

import SwiftUI
import PhotosUI

struct ReceiptCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    // Callback to pass extracted data back to AddFuelView
    let onDataExtracted: (ExtractedReceiptData, Data?) -> Void

    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var extractedData: ExtractedReceiptData?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingPreview = false

    private let ocrService = ReceiptOCRService()

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Scan Receipt")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Take a photo or select from library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // Processing indicator
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing receipt...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Error message
                if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Camera button
                    if isCameraAvailable {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isProcessing)
                    }

                    // Photo library button
                    PhotosPicker(selection: $selectedPhotoItem,
                                 matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Receipt Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ReceiptCameraView { image in
                    processImage(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        processImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let data = extractedData, let image = capturedImage {
                    ReceiptPreviewView(
                        image: image,
                        extractedData: data,
                        onConfirm: { finalData in
                            let imageData = image.jpegData(compressionQuality: 0.7)
                            onDataExtracted(finalData, imageData)
                            dismiss()
                        },
                        onRetake: {
                            showingPreview = false
                            capturedImage = nil
                            extractedData = nil
                        }
                    )
                }
            }
        }
    }

    private func processImage(_ image: UIImage) {
        capturedImage = image
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let data = try await ocrService.extractData(from: image)
                await MainActor.run {
                    extractedData = data
                    isProcessing = false
                    showingPreview = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Could not read receipt. Please try again with better lighting."
                }
            }
        }
    }
}
