//
//  OnboardingComponents.swift
//  CarTracker
//

import SwiftUI

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingDesign.Colors.progressBackground)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingDesign.Colors.progressFill)
                    .frame(
                        width: max(0, geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps)),
                        height: 4
                    )
                    .animation(OnboardingDesign.Animation.smooth, value: currentStep)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Back Button

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(OnboardingDesign.Colors.cardBackground)
                .clipShape(Circle())
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

// MARK: - CTA Button

struct OnboardingCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(isEnabled ? OnboardingDesign.Colors.textOnAccent : OnboardingDesign.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, OnboardingDesign.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                        .fill(isEnabled ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.progressBackground)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityHint(isEnabled ? "Double tap to continue" : "Complete the current step first")
    }
}

// MARK: - Secondary Button

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

// MARK: - Step Header

struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xs) {
            Text(title)
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Feature Row

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    @State private var appeared = false

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text(description)
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Notification Permission Card

struct OnboardingPermissionCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
            }

            VStack(spacing: OnboardingDesign.Spacing.xs) {
                Text(title)
                    .font(OnboardingDesign.Typography.title2)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text(description)
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Privacy Note

struct OnboardingPrivacyNote: View {
    let text: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.xs) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text(text)
                .font(OnboardingDesign.Typography.caption)
        }
        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scale Button Style

struct OnboardingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(OnboardingDesign.Animation.quick, value: configuration.isPressed)
    }
}
