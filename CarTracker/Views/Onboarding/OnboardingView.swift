//
//  OnboardingView.swift
//  CarTracker
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    let onComplete: () -> Void

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    image: "car.fill",
                    title: "Track Your Vehicle",
                    description: "Keep all your car's information in one place. Track fuel consumption, maintenance costs, and service history.",
                    color: .blue
                )
                .tag(0)

                OnboardingPage(
                    image: "fuelpump.fill",
                    title: "Log Fuel & Expenses",
                    description: "Record every fill-up and expense. See your real fuel consumption and track where your money goes.",
                    color: .orange
                )
                .tag(1)

                OnboardingPage(
                    image: "bell.fill",
                    title: "Never Miss a Service",
                    description: "Set reminders for inspections, insurance renewals, oil changes, and more. Get notified before they're due.",
                    color: .purple
                )
                .tag(2)

                OnboardingPage(
                    image: "chart.bar.fill",
                    title: "Analyze Your Costs",
                    description: "View detailed statistics and charts. Know exactly how much your car costs per kilometer and per month.",
                    color: .green
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 20)

            // Buttons
            VStack(spacing: 12) {
                if currentPage < 3 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        onComplete()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 180, height: 180)

                Image(systemName: image)
                    .font(.system(size: 70))
                    .foregroundStyle(color)
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Manager

@Observable
class OnboardingManager {
    static let shared = OnboardingManager()

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private init() {}

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    #if DEBUG
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    #endif
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
