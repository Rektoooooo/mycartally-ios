//
//  SocialProofStepView.swift
//  CarTracker
//

import SwiftUI

struct SocialProofStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var statsAppeared: [Bool] = [false, false, false]
    @State private var reviewAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: "You're not alone",
                subtitle: "Thousands of car owners already track smarter"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // Stats row
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                StatBubble(
                    value: "50K+",
                    label: "Car Owners",
                    icon: "person.3.fill",
                    color: OnboardingDesign.Colors.accent
                )
                .opacity(statsAppeared[0] ? 1 : 0)
                .scaleEffect(statsAppeared[0] ? 1 : 0.7)

                StatBubble(
                    value: "€12M+",
                    label: "Tracked",
                    icon: "chart.line.uptrend.xyaxis",
                    color: OnboardingDesign.Colors.stats
                )
                .opacity(statsAppeared[1] ? 1 : 0)
                .scaleEffect(statsAppeared[1] ? 1 : 0.7)

                StatBubble(
                    value: "4.8★",
                    label: "App Store",
                    icon: "star.fill",
                    color: .yellow
                )
                .opacity(statsAppeared[2] ? 1 : 0)
                .scaleEffect(statsAppeared[2] ? 1 : 0.7)
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Testimonial cards
            VStack(spacing: OnboardingDesign.Spacing.md) {
                TestimonialCard(
                    quote: "I had no idea my car was costing me €720/month until I started tracking. Found €200/month in savings in the first week!",
                    author: "Martin K.",
                    role: "Daily commuter",
                    stars: 5
                )

                TestimonialCard(
                    quote: "Sold my car for €2,000 more than expected because I had a complete PDF history of every service and expense.",
                    author: "Anna S.",
                    role: "Family car owner",
                    stars: 5
                )
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .opacity(reviewAppeared ? 1 : 0)
            .offset(y: reviewAppeared ? 0 : 30)

            Spacer()

            // CTA
            OnboardingCTAButton(title: "Let's Get Started", isEnabled: true) {
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
            for i in 0..<3 {
                withAnimation(OnboardingDesign.Animation.bouncy.delay(0.3 + Double(i) * 0.15)) {
                    statsAppeared[i] = true
                }
            }
            withAnimation(OnboardingDesign.Animation.gentle.delay(0.8)) {
                reviewAppeared = true
            }
        }
    }
}

// MARK: - Stat Bubble

private struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Text(label)
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, OnboardingDesign.Spacing.lg)
        .background(OnboardingDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
    }
}

// MARK: - Testimonial Card

private struct TestimonialCard: View {
    let quote: String
    let author: String
    let role: String
    let stars: Int

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
            }

            Text("\"\(quote)\"")
                .font(OnboardingDesign.Typography.footnote)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: OnboardingDesign.Spacing.xs) {
                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(author.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(author)
                        .font(OnboardingDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    Text(role)
                        .font(.system(size: 11))
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingDesign.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
    }
}

#Preview {
    SocialProofStepView { }
}
