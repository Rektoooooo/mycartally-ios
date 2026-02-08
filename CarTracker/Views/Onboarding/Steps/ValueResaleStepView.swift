//
//  ValueResaleStepView.swift
//  CarTracker
//

import SwiftUI

struct ValueResaleStepView: View {
    let viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var percentAnimated = false
    @State private var pdfAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "Boost your car's\nresale value",
                subtitle: nil
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            VStack(spacing: OnboardingDesign.Spacing.xl) {
                // Big percentage
                VStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("up to")
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("+\(viewModel.estimatedResaleBoostPercent)")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.stats)
                        Text("%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.stats)
                    }
                    .opacity(percentAnimated ? 1 : 0)
                    .scaleEffect(percentAnimated ? 1 : 0.5)

                    Text("higher resale price with complete records")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Mock PDF card
                VStack(spacing: 0) {
                    // PDF header
                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vehicle History Report")
                                .font(OnboardingDesign.Typography.bodyMedium)
                                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                            Text("Complete PDF with all records")
                                .font(OnboardingDesign.Typography.footnote)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                    }
                    .padding(OnboardingDesign.Spacing.md)

                    Divider()
                        .padding(.horizontal, OnboardingDesign.Spacing.md)

                    // PDF contents preview
                    VStack(spacing: OnboardingDesign.Spacing.sm) {
                        PDFContentRow(icon: "fuelpump.fill", color: .orange, text: "127 fuel entries", detail: "Full consumption history")
                        PDFContentRow(icon: "wrench.fill", color: .blue, text: "34 service records", detail: "Every maintenance logged")
                        PDFContentRow(icon: "chart.bar.fill", color: .green, text: "Cost analytics", detail: "Total cost of ownership")
                        PDFContentRow(icon: "photo.fill", color: .purple, text: "Receipt photos", detail: "Proof of all expenses")
                    }
                    .padding(OnboardingDesign.Spacing.md)
                }
                .background(OnboardingDesign.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg))
                .opacity(pdfAppeared ? 1 : 0)
                .offset(y: pdfAppeared ? 0 : 30)

                // Quote
                HStack(spacing: OnboardingDesign.Spacing.sm) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14))
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    Text("Buyers pay more when they see a full service history with receipts.")
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .italic()
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
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.4)) {
                percentAnimated = true
            }
            withAnimation(OnboardingDesign.Animation.gentle.delay(0.7)) {
                pdfAppeared = true
            }
        }
    }
}

// MARK: - PDF Content Row

private struct PDFContentRow: View {
    let icon: String
    let color: Color
    let text: String
    let detail: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(OnboardingDesign.Typography.footnote)
                .fontWeight(.medium)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Spacer()

            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    ValueResaleStepView(viewModel: OnboardingViewModel()) { }
}
