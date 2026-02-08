//
//  CurrencyStepView.swift
//  CarTracker
//

import SwiftUI

struct CurrencyStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false

    private let currencies: [(currency: Currency, flag: String)] = [
        (.eur, "🇪🇺"), (.usd, "🇺🇸"), (.gbp, "🇬🇧"), (.chf, "🇨🇭"),
        (.czk, "🇨🇿"), (.pln, "🇵🇱"), (.huf, "🇭🇺"), (.sek, "🇸🇪"),
        (.nok, "🇳🇴"), (.dkk, "🇩🇰"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "Your currency",
                subtitle: "We'll use this for all cost tracking"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            // Currency grid in ScrollView
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
                        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
                    ],
                    spacing: OnboardingDesign.Spacing.sm
                ) {
                    ForEach(currencies, id: \.currency) { item in
                        let isSelected = viewModel.selectedCurrency == item.currency

                        Button {
                            withAnimation(OnboardingDesign.Animation.bouncy) {
                                viewModel.selectedCurrency = item.currency
                            }
                        } label: {
                            VStack(spacing: OnboardingDesign.Spacing.xxs) {
                                Text(item.flag)
                                    .font(.system(size: 28))

                                Text(item.currency.rawValue)
                                    .font(OnboardingDesign.Typography.bodyMedium)
                                    .foregroundStyle(isSelected
                                                     ? OnboardingDesign.Colors.textOnAccent
                                                     : OnboardingDesign.Colors.textPrimary)
                                Text(item.currency.symbol)
                                    .font(OnboardingDesign.Typography.footnote)
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
                            .overlay(
                                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                                    .stroke(isSelected ? OnboardingDesign.Colors.accent : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(OnboardingScaleButtonStyle())
                        .accessibilityLabel("\(item.currency.displayName)")
                        .accessibilityValue(isSelected ? "Selected" : "")
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.xl)
                .padding(.top, OnboardingDesign.Spacing.lg)
                .padding(.bottom, OnboardingDesign.Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

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

#Preview {
    CurrencyStepView(viewModel: OnboardingViewModel()) { }
}
