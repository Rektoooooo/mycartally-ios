//
//  WelcomeStepView.swift
//  CarTracker
//

import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var iconPulse = false
    @State private var numberAnimated = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero area
            VStack(spacing: OnboardingDesign.Spacing.xl) {
                // App icon with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(OnboardingDesign.Colors.accent.opacity(0.06))
                        .frame(width: 160, height: 160)
                        .scaleEffect(iconPulse ? 1.05 : 0.95)

                    // Inner circle
                    Circle()
                        .fill(OnboardingDesign.Colors.accent.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "car.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(OnboardingDesign.Colors.accent)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)

                // Headline
                VStack(spacing: OnboardingDesign.Spacing.sm) {
                    Text("Stop losing money\non your car")
                        .font(OnboardingDesign.Typography.largeTitle)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("The average car owner loses over")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                    // Big number
                    HStack(spacing: 4) {
                        Text("€1,200")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                        Text("/year")
                            .font(OnboardingDesign.Typography.title2)
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    }
                    .opacity(numberAnimated ? 1 : 0)
                    .scaleEffect(numberAnimated ? 1 : 0.8)

                    Text("on unnecessary car expenses.")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 25)
            }

            Spacer()

            // Bottom CTA
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                OnboardingCTAButton(title: "See How Much You Can Save", isEnabled: true) {
                    onContinue()
                }

                OnboardingPrivacyNote(text: "100% private. Your data never leaves your device.")
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.5)) {
                numberAnimated = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) {
                iconPulse = true
            }
        }
    }
}

#Preview {
    WelcomeStepView { }
}
