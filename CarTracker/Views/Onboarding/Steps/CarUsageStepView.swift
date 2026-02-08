//
//  CarUsageStepView.swift
//  CarTracker
//

import SwiftUI

struct CarUsageStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardsAppeared: [Bool] = Array(repeating: false, count: CarUsage.allCases.count)

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "How do you use\nyour car?",
                subtitle: "This helps us personalize your savings plan"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // Selection cards
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(Array(CarUsage.allCases.enumerated()), id: \.element.id) { index, usage in
                    let isSelected = viewModel.carUsage == usage

                    Button {
                        withAnimation(OnboardingDesign.Animation.bouncy) {
                            viewModel.carUsage = usage
                        }
                    } label: {
                        HStack(spacing: OnboardingDesign.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                                    .fill(isSelected
                                          ? OnboardingDesign.Colors.accent.opacity(0.2)
                                          : OnboardingDesign.Colors.cardBackground)
                                    .frame(width: 48, height: 48)

                                Image(systemName: usage.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(isSelected
                                                     ? OnboardingDesign.Colors.accent
                                                     : OnboardingDesign.Colors.textSecondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(usage.rawValue)
                                    .font(OnboardingDesign.Typography.bodyMedium)
                                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                                Text(usage.subtitle)
                                    .font(OnboardingDesign.Typography.footnote)
                                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(OnboardingDesign.Colors.accent)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(OnboardingDesign.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                                .fill(OnboardingDesign.Colors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                                        .stroke(isSelected ? OnboardingDesign.Colors.accent : Color.clear, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        )
                    }
                    .buttonStyle(OnboardingScaleButtonStyle())
                    .opacity(cardsAppeared[index] ? 1 : 0)
                    .offset(x: cardsAppeared[index] ? 0 : 40)
                    .accessibilityLabel("\(usage.rawValue). \(usage.subtitle)")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()

            // CTA
            OnboardingCTAButton(title: "Continue", isEnabled: viewModel.carUsage != nil) {
                onContinue()
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
            for i in CarUsage.allCases.indices {
                withAnimation(OnboardingDesign.Animation.gentle.delay(0.2 + Double(i) * 0.08)) {
                    cardsAppeared[i] = true
                }
            }
        }
    }
}

#Preview {
    CarUsageStepView(viewModel: OnboardingViewModel()) { }
}
