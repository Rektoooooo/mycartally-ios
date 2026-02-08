//
//  PhotoCropView.swift
//  CarTracker
//

import SwiftUI

struct PhotoCropView: View {
    let originalImage: UIImage
    let onCrop: (Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    private let cropAspectRatio: CGFloat = 2.0

    @State private var displayImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isCropping = false
    @State private var viewWidth: CGFloat = 0

    init(image: UIImage, onCrop: @escaping (Data?) -> Void) {
        self.originalImage = image
        self.onCrop = onCrop
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let cropWidth = max(100, geo.size.width - 48)
                let cropHeight = cropWidth / cropAspectRatio

                ZStack {
                    if let img = displayImage {
                        let imageAspect = img.size.width / img.size.height
                        let cropAspect = cropWidth / cropHeight

                        let baseW: CGFloat = imageAspect > cropAspect
                            ? cropHeight * imageAspect
                            : cropWidth
                        let baseH: CGFloat = imageAspect > cropAspect
                            ? cropHeight
                            : cropWidth / imageAspect

                        // Image layer - NOT clipped, extends beyond crop area
                        Image(uiImage: img)
                            .resizable()
                            .frame(width: baseW * scale, height: baseH * scale)
                            .offset(offset)

                        // Semi-transparent overlay with crop cutout
                        CropOverlayShape(
                            holeSize: CGSize(width: cropWidth, height: cropHeight),
                            cornerRadius: 12
                        )
                        .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))
                        .allowsHitTesting(false)

                        // Border on crop area
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.6), lineWidth: 1.5)
                            .frame(width: cropWidth, height: cropHeight)
                            .allowsHitTesting(false)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }

                    // Loading overlay when cropping
                    if isCropping {
                        Color.black.opacity(0.4)
                            .allowsHitTesting(false)
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }

                    // Hint text at bottom
                    if !isCropping {
                        VStack {
                            Spacer()
                            Text("Drag and pinch to adjust")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.bottom, 60)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(dragGesture(cropWidth: cropWidth, cropHeight: cropHeight))
                .simultaneousGesture(pinchGesture(cropWidth: cropWidth, cropHeight: cropHeight))
                .onAppear { viewWidth = geo.size.width }
            }
            .background(Color.black)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCropping)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        cropAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isCropping)
                }
            }
            .task {
                displayImage = Self.downsample(originalImage, maxDimension: 1200)
            }
        }
    }

    // MARK: - Crop & Dismiss

    private func cropAndDismiss() {
        isCropping = true

        let capturedScale = scale
        let capturedOffset = offset
        let capturedImage = originalImage
        let capturedDisplayImage = displayImage
        let aspectRatio = cropAspectRatio
        let screenWidth = viewWidth

        Task.detached {
            let data = Self.cropImage(
                original: capturedImage,
                display: capturedDisplayImage,
                scale: capturedScale,
                offset: capturedOffset,
                aspectRatio: aspectRatio,
                screenWidth: screenWidth
            )

            await MainActor.run {
                onCrop(data)
                dismiss()
            }
        }
    }

    // MARK: - Downsample

    private static func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)

        guard longestSide > maxDimension else { return image }

        let ratio = maxDimension / longestSide
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Gestures

    private func dragGesture(cropWidth: CGFloat, cropHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    clampOffset(cropWidth: cropWidth, cropHeight: cropHeight)
                }
                lastOffset = offset
            }
    }

    private func pinchGesture(cropWidth: CGFloat, cropHeight: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1.0, min(5.0, lastScale * value))
            }
            .onEnded { value in
                scale = max(1.0, min(5.0, lastScale * value))
                lastScale = scale
                withAnimation(.easeOut(duration: 0.2)) {
                    clampOffset(cropWidth: cropWidth, cropHeight: cropHeight)
                }
                lastOffset = offset
            }
    }

    // MARK: - Offset Clamping

    private func clampOffset(cropWidth: CGFloat, cropHeight: CGFloat) {
        guard let img = displayImage else { return }
        let imageAspect = img.size.width / img.size.height
        let cropAspect = cropWidth / cropHeight

        let baseW: CGFloat
        let baseH: CGFloat

        if imageAspect > cropAspect {
            baseH = cropHeight
            baseW = baseH * imageAspect
        } else {
            baseW = cropWidth
            baseH = baseW / imageAspect
        }

        let totalW = baseW * scale
        let totalH = baseH * scale

        let maxX = max(0, (totalW - cropWidth) / 2)
        let maxY = max(0, (totalH - cropHeight) / 2)

        offset.width = min(maxX, max(-maxX, offset.width))
        offset.height = min(maxY, max(-maxY, offset.height))
    }

    // MARK: - Crop (background thread)

    nonisolated private static func cropImage(
        original: UIImage,
        display: UIImage?,
        scale: CGFloat,
        offset: CGSize,
        aspectRatio: CGFloat,
        screenWidth: CGFloat
    ) -> Data? {
        // Normalize image orientation
        let renderer = UIGraphicsImageRenderer(size: original.size)
        let normalized = renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: original.size))
        }

        guard let cgImage = normalized.cgImage else {
            return original.jpegData(compressionQuality: 0.8)
        }

        let cropWidth = max(100, screenWidth - 48)
        let cropHeight = cropWidth / aspectRatio

        guard let img = display else {
            return original.jpegData(compressionQuality: 0.8)
        }

        let imageAspect = img.size.width / img.size.height
        let cropAspect = cropWidth / cropHeight

        let baseW: CGFloat
        let baseH: CGFloat

        if imageAspect > cropAspect {
            baseH = cropHeight
            baseW = baseH * imageAspect
        } else {
            baseW = cropWidth
            baseH = baseW / imageAspect
        }

        let totalW = baseW * scale
        let totalH = baseH * scale

        let visibleX = (totalW - cropWidth) / 2 - offset.width
        let visibleY = (totalH - cropHeight) / 2 - offset.height

        let pixelPerPoint = CGFloat(cgImage.width) / totalW

        let cropRect = CGRect(
            x: max(0, visibleX * pixelPerPoint),
            y: max(0, visibleY * pixelPerPoint),
            width: cropWidth * pixelPerPoint,
            height: cropHeight * pixelPerPoint
        )

        let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let clampedRect = cropRect.intersection(imageBounds)

        guard !clampedRect.isEmpty,
              let croppedCG = cgImage.cropping(to: clampedRect) else {
            return original.jpegData(compressionQuality: 0.8)
        }

        let cropped = UIImage(cgImage: croppedCG)
        return cropped.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Crop Overlay Shape

/// Creates a full-screen fill with a rounded-rect hole in the center
struct CropOverlayShape: Shape {
    let holeSize: CGSize
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)

        let holeRect = CGRect(
            x: (rect.width - holeSize.width) / 2,
            y: (rect.height - holeSize.height) / 2,
            width: holeSize.width,
            height: holeSize.height
        )
        path.addRoundedRect(
            in: holeRect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        return path
    }
}
