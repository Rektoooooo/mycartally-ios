//
//  ExpenseWorryStepView.swift
//  CarTracker
//

import SwiftUI

struct ExpenseWorryStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var chipsAppeared: [Bool] = Array(repeating: false, count: ExpenseWorry.allCases.count)

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "What worries you\nmost about car costs?",
                subtitle: "Select all that apply — we'll help with each one"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // Worry cards as 2-column grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
                    GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
                ],
                spacing: OnboardingDesign.Spacing.sm
            ) {
                ForEach(Array(ExpenseWorry.allCases.enumerated()), id: \.element.id) { index, worry in
                    let isSelected = viewModel.expenseWorries.contains(worry)

                    Button {
                        withAnimation(OnboardingDesign.Animation.bouncy) {
                            if isSelected {
                                viewModel.expenseWorries.remove(worry)
                            } else {
                                viewModel.expenseWorries.insert(worry)
                            }
                        }
                    } label: {
                        VStack(spacing: OnboardingDesign.Spacing.sm) {
                            Text(worry.emoji)
                                .font(.system(size: 32))

                            Text(worry.rawValue)
                                .font(OnboardingDesign.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(isSelected
                                                 ? OnboardingDesign.Colors.textOnAccent
                                                 : OnboardingDesign.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OnboardingDesign.Spacing.lg)
                        .padding(.horizontal, OnboardingDesign.Spacing.sm)
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
                    .opacity(chipsAppeared[index] ? 1 : 0)
                    .scaleEffect(chipsAppeared[index] ? 1 : 0.8)
                    .accessibilityLabel(worry.rawValue)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()

            // Selection count
            if !viewModel.expenseWorries.isEmpty {
                Text("\(viewModel.expenseWorries.count) selected")
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
                    .padding(.bottom, OnboardingDesign.Spacing.sm)
                    .transition(.opacity)
            }

            // CTA
            OnboardingCTAButton(
                title: "Continue",
                isEnabled: !viewModel.expenseWorries.isEmpty
            ) {
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
            for i in ExpenseWorry.allCases.indices {
                withAnimation(OnboardingDesign.Animation.bouncy.delay(0.25 + Double(i) * 0.07)) {
                    chipsAppeared[i] = true
                }
            }
        }
    }
}

#Preview {
    ExpenseWorryStepView(viewModel: OnboardingViewModel()) { }
}
