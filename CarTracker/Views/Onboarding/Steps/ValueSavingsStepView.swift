//
//  ValueSavingsStepView.swift
//  CarTracker
//

import SwiftUI

struct ValueSavingsStepView: View {
    let viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var barAnimated = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "Know where every\ncent goes",
                subtitle: nil
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.xl) {
                // Before/After comparison
                VStack(spacing: OnboardingDesign.Spacing.lg) {
                    // Without tracking
                    VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xs) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red.opacity(0.8))
                            Text("Without tracking")
                                .font(OnboardingDesign.Typography.bodyMedium)
                                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        }

                        HStack(spacing: OnboardingDesign.Spacing.xs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.red.opacity(0.25))
                                .frame(width: barAnimated ? 280 : 0, height: 32)
                                .overlay(alignment: .trailing) {
                                    Text("\(viewModel.savingsCurrencySymbol)\(viewModel.convertAmount(8400))")
                                        .font(OnboardingDesign.Typography.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                        .padding(.trailing, 8)
                                        .opacity(barAnimated ? 1 : 0)
                                }
                        }

                        Text("Hidden costs, forgotten services, overpaying")
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    }

                    // With MyCarTally
                    VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xs) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(OnboardingDesign.Colors.stats)
                            Text("With MyCarTally")
                                .font(OnboardingDesign.Typography.bodyMedium)
                                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        }

                        HStack(spacing: OnboardingDesign.Spacing.xs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(OnboardingDesign.Colors.stats.opacity(0.25))
                                .frame(width: barAnimated ? 200 : 0, height: 32)
                                .overlay(alignment: .trailing) {
                                    Text("\(viewModel.savingsCurrencySymbol)\(viewModel.convertAmount(7200))")
                                        .font(OnboardingDesign.Typography.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(OnboardingDesign.Colors.stats)
                                        .padding(.trailing, 8)
                                        .opacity(barAnimated ? 1 : 0)
                                }
                        }

                        Text("Full visibility, smart alerts, optimized spending")
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    }
                }
                .padding(OnboardingDesign.Spacing.lg)
                .background(OnboardingDesign.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg))

                // Savings callout
                HStack(spacing: OnboardingDesign.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(OnboardingDesign.Colors.stats.opacity(0.12))
                            .frame(width: 56, height: 56)

                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(OnboardingDesign.Colors.stats)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save up to \(viewModel.savingsCurrencySymbol)\(viewModel.formattedYearlySavings)/year")
                            .font(OnboardingDesign.Typography.title2)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                        Text("by knowing exactly where your money goes")
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Quick benefit pills
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    BenefitPill(icon: "doc.text.viewfinder", text: "AI Receipt Scan")
                    BenefitPill(icon: "chart.bar.fill", text: "Cost Analysis")
                    BenefitPill(icon: "clock.fill", text: "5 sec logging")
                }
                .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()

            OnboardingCTAButton(title: "Continue", isEnabled: true) {
                onContinue()
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.15)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                barAnimated = true
            }
        }
    }
}

// MARK: - Benefit Pill

private struct BenefitPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(OnboardingDesign.Colors.accent)
        .padding(.horizontal, OnboardingDesign.Spacing.sm)
        .padding(.vertical, OnboardingDesign.Spacing.xxs + 2)
        .background(
            Capsule().fill(OnboardingDesign.Colors.accent.opacity(0.1))
        )
    }
}

#Preview {
    ValueSavingsStepView(viewModel: OnboardingViewModel()) { }
}
