//
//  SavingsPlanStepView.swift
//  CarTracker
//

import SwiftUI

struct SavingsPlanStepView: View {
    let viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardsAppeared: [Bool] = [false, false, false, false]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Headline
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("Your savings plan\nis ready")
                    .font(OnboardingDesign.Typography.largeTitle)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Based on your profile, here's what you can expect")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Stats grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
                    GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
                ],
                spacing: OnboardingDesign.Spacing.sm
            ) {
                // Yearly savings
                SavingsCard(
                    icon: "arrow.down.circle.fill",
                    color: OnboardingDesign.Colors.stats,
                    value: "\(viewModel.savingsCurrencySymbol)\(viewModel.formattedYearlySavings)",
                    label: "Estimated yearly savings",
                    isLarge: true
                )
                .opacity(cardsAppeared[0] ? 1 : 0)
                .scaleEffect(cardsAppeared[0] ? 1 : 0.8)

                // Resale boost
                SavingsCard(
                    icon: "chart.line.uptrend.xyaxis",
                    color: OnboardingDesign.Colors.accent,
                    value: "+\(viewModel.estimatedResaleBoostPercent)%",
                    label: "Resale value boost",
                    isLarge: true
                )
                .opacity(cardsAppeared[1] ? 1 : 0)
                .scaleEffect(cardsAppeared[1] ? 1 : 0.8)

                // Hours saved
                SavingsCard(
                    icon: "clock.fill",
                    color: .orange,
                    value: "\(viewModel.hoursPerYearSaved) hrs",
                    label: "Saved per year",
                    isLarge: false
                )
                .opacity(cardsAppeared[2] ? 1 : 0)
                .scaleEffect(cardsAppeared[2] ? 1 : 0.8)

                // Repairs avoided
                SavingsCard(
                    icon: "shield.checkered",
                    color: .purple,
                    value: "\(viewModel.savingsCurrencySymbol)\(viewModel.formattedAvoidedRepairCost)",
                    label: "Repair costs avoided",
                    isLarge: false
                )
                .opacity(cardsAppeared[3] ? 1 : 0)
                .scaleEffect(cardsAppeared[3] ? 1 : 0.8)
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Pro hint
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)

                Text("Unlock PDF exports, multi-car support & more with Pro")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
            .padding(OnboardingDesign.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(OnboardingDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm))
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .opacity(appeared ? 1 : 0)

            Spacer()

            OnboardingCTAButton(title: "Let's Set Up Your Car", isEnabled: true) {
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
            for i in 0..<4 {
                withAnimation(OnboardingDesign.Animation.bouncy.delay(0.3 + Double(i) * 0.15)) {
                    cardsAppeared[i] = true
                }
            }
        }
    }
}

// MARK: - Savings Card

private struct SavingsCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    let isLarge: Bool

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 24 : 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: isLarge ? 28 : 22, weight: .bold))
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Text(label)
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OnboardingDesign.Spacing.lg)
        .padding(.horizontal, OnboardingDesign.Spacing.sm)
        .background(OnboardingDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
    }
}

#Preview {
    SavingsPlanStepView(viewModel: OnboardingViewModel()) { }
}
