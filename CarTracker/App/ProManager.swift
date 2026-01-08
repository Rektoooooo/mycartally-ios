//
//  ProManager.swift
//  CarTracker
//

import SwiftUI
import StoreKit

// MARK: - Pro Features

enum ProFeature: String, CaseIterable {
    case multiCar = "Multi-car support"
    case iCloudSync = "iCloud Sync"
    case pdfExport = "PDF Export"
    case widgets = "Widgets"
    case unlimitedReminders = "Unlimited Reminders"
    case advancedStats = "Advanced Statistics"

    var icon: String {
        switch self {
        case .multiCar: return "car.2.fill"
        case .iCloudSync: return "icloud.fill"
        case .pdfExport: return "doc.fill"
        case .widgets: return "square.stack.3d.up.fill"
        case .unlimitedReminders: return "bell.badge.fill"
        case .advancedStats: return "chart.bar.xaxis"
        }
    }

    var description: String {
        switch self {
        case .multiCar: return "Track multiple vehicles"
        case .iCloudSync: return "Sync across all devices"
        case .pdfExport: return "Export car history as PDF"
        case .widgets: return "Home & Lock screen widgets"
        case .unlimitedReminders: return "Create unlimited reminders"
        case .advancedStats: return "Detailed analytics & charts"
        }
    }
}

// MARK: - Pro Manager

@Observable
class ProManager {
    static let shared = ProManager()

    private let defaults = UserDefaults.standard
    private let proKey = "isProUnlocked"
    private let productId = "com.cartracker.pro"

    // MARK: - Properties

    var isPro: Bool {
        didSet {
            defaults.set(isPro, forKey: proKey)
        }
    }

    var isLoading = false
    var errorMessage: String?

    // Free tier limits
    let maxFreeCars = 1
    let maxFreeReminders = 5

    // MARK: - Init

    private init() {
        isPro = defaults.bool(forKey: proKey)
    }

    // MARK: - Feature Checks

    func canAddCar(currentCount: Int) -> Bool {
        isPro || currentCount < maxFreeCars
    }

    func canAddReminder(currentCount: Int) -> Bool {
        isPro || currentCount < maxFreeReminders
    }

    func canUseFeature(_ feature: ProFeature) -> Bool {
        isPro
    }

    func carsRemaining(currentCount: Int) -> Int {
        max(0, maxFreeCars - currentCount)
    }

    func remindersRemaining(currentCount: Int) -> Int {
        max(0, maxFreeReminders - currentCount)
    }

    // MARK: - Purchase

    @MainActor
    func purchase() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch product
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                errorMessage = "Product not found"
                isLoading = false
                return
            }

            // Purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    isPro = true
                case .unverified:
                    errorMessage = "Purchase verification failed"
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase pending approval"
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()

            // Check current entitlements
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == productId {
                        isPro = true
                        isLoading = false
                        return
                    }
                }
            }

            errorMessage = "No purchases to restore"
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Debug (for testing)

    #if DEBUG
    func debugUnlockPro() {
        isPro = true
    }

    func debugLockPro() {
        isPro = false
    }
    #endif
}

// MARK: - Pro Upgrade Sheet

struct ProUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let proManager = ProManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            ))

                        Text("CarTracker Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Unlock all features with a one-time purchase")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(spacing: 16) {
                        ForEach(ProFeature.allCases, id: \.self) { feature in
                            ProFeatureRow(feature: feature)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Price
                    VStack(spacing: 8) {
                        Text("€10")
                            .font(.system(size: 48, weight: .bold))

                        Text("One-time purchase")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("No subscription, yours forever")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Purchase Button
                    Button {
                        Task {
                            await proManager.purchase()
                            if proManager.isPro {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if proManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Upgrade Now")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(proManager.isLoading)
                    .padding(.horizontal)

                    // Restore
                    Button {
                        Task {
                            await proManager.restorePurchases()
                            if proManager.isPro {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .disabled(proManager.isLoading)

                    if let error = proManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(.headline)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Pro Required View

struct ProRequiredView: View {
    let feature: String
    @State private var showingUpgrade = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Pro Feature")
                .font(.headline)

            Text("\(feature) requires CarTracker Pro")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Upgrade to Pro") {
                showingUpgrade = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $showingUpgrade) {
            ProUpgradeSheet()
        }
    }
}

#Preview("Upgrade Sheet") {
    ProUpgradeSheet()
}
