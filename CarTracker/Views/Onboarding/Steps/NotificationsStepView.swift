//
//  NotificationsStepView.swift
//  CarTracker
//

import SwiftUI

struct NotificationsStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var bellBounce = false
    @State private var notificationsGranted: Bool?

    private let reminderExamples: [(icon: String, color: Color, title: String, due: String)] = [
        ("drop.fill", .brown, "Oil Change", "In 12 days"),
        ("checkmark.seal.fill", .purple, "Vehicle Inspection", "In 28 days"),
        ("shield.fill", .green, "Insurance Renewal", "In 45 days"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                title: "Stay on schedule",
                subtitle: "Get notified before services are due"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.top, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // Bell icon
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.reminders.opacity(0.12))
                    .frame(width: 90, height: 90)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(OnboardingDesign.Colors.reminders)
                    .symbolEffect(.bounce, value: bellBounce)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.7)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Mock reminder notifications
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(Array(reminderExamples.enumerated()), id: \.offset) { index, reminder in
                    HStack(spacing: OnboardingDesign.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(reminder.color.opacity(0.12))
                                .frame(width: 40, height: 40)

                            Image(systemName: reminder.icon)
                                .font(.body)
                                .foregroundStyle(reminder.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.title)
                                .font(OnboardingDesign.Typography.bodyMedium)
                                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                                .lineLimit(1)
                            Text("Upcoming reminder")
                                .font(OnboardingDesign.Typography.footnote)
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        }

                        Spacer()

                        Text(reminder.due)
                            .font(OnboardingDesign.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(OnboardingDesign.Spacing.md)
                    .background(OnboardingDesign.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : CGFloat(20 + index * 10))
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)

            Spacer()

            // CTA
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                if notificationsGranted == nil {
                    OnboardingCTAButton(title: "Enable Notifications", isEnabled: true) {
                        Task {
                            let granted = await NotificationService.shared.requestAuthorization()
                            notificationsGranted = granted
                        }
                    }

                    OnboardingSecondaryButton(title: "Not now") {
                        notificationsGranted = false
                    }
                } else {
                    HStack(spacing: OnboardingDesign.Spacing.xs) {
                        Image(systemName: notificationsGranted == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(notificationsGranted == true ? .green : OnboardingDesign.Colors.textTertiary)
                        Text(notificationsGranted == true ? "Notifications enabled!" : "You can enable later in Settings")
                            .font(OnboardingDesign.Typography.subheadline)
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    }

                    OnboardingCTAButton(title: "Continue", isEnabled: true) {
                        onContinue()
                    }
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
            // Bounce bell after appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                bellBounce.toggle()
            }
        }
    }
}

#Preview {
    NotificationsStepView { }
}
