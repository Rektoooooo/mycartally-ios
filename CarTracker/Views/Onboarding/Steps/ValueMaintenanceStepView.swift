//
//  ValueMaintenanceStepView.swift
//  CarTracker
//

import SwiftUI

struct ValueMaintenanceStepView: View {
    let viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var timelineStep = 0

    private var sym: String { viewModel.savingsCurrencySymbol }

    private var timelineItems: [(icon: String, color: Color, title: String, cost: String, isGood: Bool)] {
        [
            ("bell.badge.fill", .purple, "MyCarTally reminds you", "Free", true),
            ("drop.fill", .brown, "Oil change on time", "\(sym)\(viewModel.convertAmount(50))", true),
            ("checkmark.seal.fill", .green, "Engine stays healthy", "\(sym)0", true),
        ]
    }

    private var badTimeline: [(icon: String, color: Color, title: String, cost: String)] {
        [
            ("bell.slash.fill", .gray, "No reminder set", ""),
            ("xmark.circle.fill", .orange, "Oil change forgotten", ""),
            ("exclamationmark.triangle.fill", .red, "Engine damage", "\(sym)\(viewModel.convertAmount(2800))"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "Avoid costly\nsurprises",
                subtitle: nil
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.md) {
                // Bad scenario
                VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Without reminders")
                            .font(OnboardingDesign.Typography.bodyMedium)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    }

                    ForEach(Array(badTimeline.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: OnboardingDesign.Spacing.sm) {
                            // Timeline line
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(item.color.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: item.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(item.color)
                                    )
                                if index < badTimeline.count - 1 {
                                    Rectangle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 2, height: 16)
                                }
                            }

                            Text(item.title)
                                .font(OnboardingDesign.Typography.footnote)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                            Spacer()

                            if !item.cost.isEmpty {
                                Text(item.cost)
                                    .font(OnboardingDesign.Typography.bodyMedium)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .padding(OnboardingDesign.Spacing.md)
                .background(Color.red.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
                .opacity(appeared ? 1 : 0)

                // Good scenario
                VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OnboardingDesign.Colors.stats)
                        Text("With MyCarTally")
                            .font(OnboardingDesign.Typography.bodyMedium)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    }

                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: OnboardingDesign.Spacing.sm) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(item.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: item.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(item.color)
                                    )
                                    .scaleEffect(timelineStep > index ? 1 : 0.5)
                                    .opacity(timelineStep > index ? 1 : 0.3)

                                if index < timelineItems.count - 1 {
                                    Rectangle()
                                        .fill(OnboardingDesign.Colors.stats.opacity(0.3))
                                        .frame(width: 2, height: 16)
                                }
                            }

                            Text(item.title)
                                .font(OnboardingDesign.Typography.footnote)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                            Spacer()

                            Text(item.cost)
                                .font(OnboardingDesign.Typography.bodyMedium)
                                .foregroundStyle(OnboardingDesign.Colors.stats)
                        }
                        .opacity(timelineStep > index ? 1 : 0.4)
                    }
                }
                .padding(OnboardingDesign.Spacing.md)
                .background(OnboardingDesign.Colors.stats.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                        .stroke(OnboardingDesign.Colors.stats.opacity(0.2), lineWidth: 1)
                )

                // Savings highlight
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You save")
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        Text("\(sym)\(viewModel.convertAmount(2750))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.stats)
                    }

                    Spacer()

                    Text("on a single missed\noil change alone")
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
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
            // Animate timeline steps
            for i in 0..<timelineItems.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.4) {
                    withAnimation(OnboardingDesign.Animation.bouncy) {
                        timelineStep = i + 1
                    }
                }
            }
        }
    }
}

#Preview {
    ValueMaintenanceStepView(viewModel: OnboardingViewModel()) { }
}
