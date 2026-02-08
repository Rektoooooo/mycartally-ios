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
    var openCameraImmediately = false

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

    @State private var cameraWasDismissed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppDesign.Spacing.xl) {
                if openCameraImmediately && !cameraWasDismissed && !isProcessing {
                    // Minimal placeholder while camera is about to open
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    // Header
                    VStack(spacing: AppDesign.Spacing.xs) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundStyle(AppDesign.Colors.accent)

                        Text("Scan Receipt")
                            .font(AppDesign.Typography.title2)

                        Text("Take a photo or select from library")
                            .font(AppDesign.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, AppDesign.Spacing.xxxl)

                    Spacer()

                    // Processing indicator
                    if isProcessing {
                        VStack(spacing: AppDesign.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing receipt...")
                                .font(AppDesign.Typography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Error message
                    if let error = errorMessage {
                        VStack(spacing: AppDesign.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(AppDesign.Colors.fuel)
                            Text(error)
                                .font(AppDesign.Typography.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(AppDesign.Colors.fuel.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Action buttons
                    VStack(spacing: AppDesign.Spacing.md) {
                        // Camera button
                        if isCameraAvailable {
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera.fill")
                                    .font(AppDesign.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppDesign.Colors.accent)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                            }
                            .disabled(isProcessing)
                        }

                        // Photo library button
                        PhotosPicker(selection: $selectedPhotoItem,
                                     matching: .images) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                                .font(AppDesign.Typography.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, AppDesign.Spacing.xxl)
                }
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
            .onAppear {
                if openCameraImmediately && isCameraAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingCamera = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera, onDismiss: {
                cameraWasDismissed = true
            }) {
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
