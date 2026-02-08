//
//  AllSetStepView.swift
//  CarTracker
//

import SwiftUI

struct AllSetStepView: View {
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var checkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var confettiAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.xxl) {
                // Celebration icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(OnboardingDesign.Colors.stats.opacity(0.2), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)

                    // Inner filled circle
                    Circle()
                        .fill(OnboardingDesign.Colors.stats.opacity(0.12))
                        .frame(width: 120, height: 120)

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(OnboardingDesign.Colors.stats)
                        .scaleEffect(checkScale)
                }

                // Confetti dots
                if confettiAppeared {
                    HStack(spacing: OnboardingDesign.Spacing.xl) {
                        ConfettiDot(color: OnboardingDesign.Colors.accent, delay: 0)
                        ConfettiDot(color: OnboardingDesign.Colors.fuel, delay: 0.1)
                        ConfettiDot(color: OnboardingDesign.Colors.stats, delay: 0.2)
                        ConfettiDot(color: OnboardingDesign.Colors.reminders, delay: 0.3)
                        ConfettiDot(color: OnboardingDesign.Colors.accent, delay: 0.15)
                    }
                    .transition(.opacity)
                }

                // Text
                VStack(spacing: OnboardingDesign.Spacing.sm) {
                    Text("You're all set!")
                        .font(OnboardingDesign.Typography.largeTitle)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                    Text("Start tracking your car expenses\nand watch the savings add up.")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Quick tips
                VStack(spacing: OnboardingDesign.Spacing.sm) {
                    TipRow(icon: "fuelpump.fill", color: .orange, text: "Log your first fill-up after your next trip")
                    TipRow(icon: "doc.text.viewfinder", color: OnboardingDesign.Colors.accent, text: "Try the AI receipt scanner — it's like magic")
                    TipRow(icon: "bell.badge.fill", color: .purple, text: "Set your first reminder for peace of mind")
                }
                .padding(.horizontal, OnboardingDesign.Spacing.xl)
                .opacity(appeared ? 1 : 0)
            }

            Spacer()

            OnboardingCTAButton(title: "Start Saving", isEnabled: true) {
                onComplete()
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
                ringScale = 1.0
            }
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.5)) {
                checkScale = 1.0
            }
            withAnimation(OnboardingDesign.Animation.gentle.delay(0.7)) {
                confettiAppeared = true
            }
        }
    }
}

// MARK: - Confetti Dot

private struct ConfettiDot: View {
    let color: Color
    let delay: Double

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(y: animate ? -8 : 8)
            .opacity(animate ? 0.8 : 0.3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

// MARK: - Tip Row

private struct TipRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(OnboardingDesign.Typography.footnote)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    AllSetStepView { }
}
