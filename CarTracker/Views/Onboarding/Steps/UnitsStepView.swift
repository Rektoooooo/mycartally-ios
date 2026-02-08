//
//  UnitsStepView.swift
//  CarTracker
//

import SwiftUI

struct UnitsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "Your preferences",
                subtitle: "How do you measure distance and fuel?"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.xxl) {
                // Distance unit
                VStack(spacing: OnboardingDesign.Spacing.md) {
                    HStack {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 18))
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                        Text("Distance")
                            .font(OnboardingDesign.Typography.headline)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        Spacer()
                    }

                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        UnitOptionButton(
                            title: "Kilometers",
                            subtitle: "km, L/100km",
                            isSelected: viewModel.distanceUnit == .kilometers
                        ) {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.distanceUnit = .kilometers
                            }
                        }

                        UnitOptionButton(
                            title: "Miles",
                            subtitle: "mi, MPG",
                            isSelected: viewModel.distanceUnit == .miles
                        ) {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.distanceUnit = .miles
                            }
                        }
                    }
                }

                // Volume unit
                VStack(spacing: OnboardingDesign.Spacing.md) {
                    HStack {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(OnboardingDesign.Colors.fuel)
                        Text("Fuel Volume")
                            .font(OnboardingDesign.Typography.headline)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        Spacer()
                    }

                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        UnitOptionButton(
                            title: "Liters",
                            subtitle: "L",
                            isSelected: viewModel.volumeUnit == .liters
                        ) {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.volumeUnit = .liters
                            }
                        }

                        UnitOptionButton(
                            title: "Gallons (US)",
                            subtitle: "gal",
                            isSelected: viewModel.volumeUnit == .gallons
                        ) {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.volumeUnit = .gallons
                            }
                        }

                        UnitOptionButton(
                            title: "Gallons (UK)",
                            subtitle: "gal",
                            isSelected: viewModel.volumeUnit == .gallonsUK
                        ) {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.volumeUnit = .gallonsUK
                            }
                        }
                    }
                }

                // Preview
                VStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("Your consumption will show as")
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    Text(viewModel.distanceUnit == .kilometers ? "7.2 L/100km" : "32.6 MPG")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(OnboardingDesign.Colors.accent)
                        .contentTransition(.numericText())
                        .animation(OnboardingDesign.Animation.bouncy, value: viewModel.distanceUnit)
                }
                .padding(.top, OnboardingDesign.Spacing.md)
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

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
        }
    }
}

// MARK: - Unit Option Button

private struct UnitOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: OnboardingDesign.Spacing.xxs) {
                Text(title)
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(isSelected
                                     ? OnboardingDesign.Colors.textOnAccent
                                     : OnboardingDesign.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(isSelected
                                     ? OnboardingDesign.Colors.textOnAccent.opacity(0.7)
                                     : OnboardingDesign.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, OnboardingDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(isSelected
                          ? OnboardingDesign.Colors.accent
                          : OnboardingDesign.Colors.cardBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

#Preview {
    UnitsStepView(viewModel: OnboardingViewModel()) { }
}
