//
//  AppDesign.swift
//  CarTracker
//
//  App-wide design system for consistent premium UI
//

import SwiftUI

enum AppDesign {

    // MARK: - Colors

    enum Colors {
        // Brand
        static let accent = Color(hex: "0066FF")
        static let accentLight = Color(hex: "0066FF").opacity(0.12)
        static let accentDark = Color(hex: "0052CC")

        // Backgrounds
        static let background = Color(.systemGroupedBackground)
        static let backgroundElevated = Color(.systemBackground)
        static let cardBackground = Color(.systemBackground)

        // Feature colors
        static let fuel = Color.orange
        static let expenses = Color(hex: "0066FF")
        static let reminders = Color.purple
        static let stats = Color.green
        static let diagnostics = Color(hex: "00C853")

        // Text hierarchy
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let textOnAccent = Color.white

        // Status
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }

    // MARK: - Spacing Scale

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 17, weight: .medium)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
    }
}

// MARK: - Premium Card Style

struct PremiumCardModifier: ViewModifier {
    var padding: CGFloat = AppDesign.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppDesign.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.md))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Icon Badge Style

struct IconBadgeModifier: ViewModifier {
    let color: Color
    var size: CGFloat = 44
    var iconSize: Font = .body
    var cornerRadius: CGFloat = AppDesign.Radius.sm

    func body(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)

            content
                .font(iconSize)
                .foregroundStyle(color)
        }
    }
}

extension View {
    func premiumCard(padding: CGFloat = AppDesign.Spacing.md) -> some View {
        modifier(PremiumCardModifier(padding: padding))
    }

    func iconBadge(color: Color, size: CGFloat = 44, iconSize: Font = .body, cornerRadius: CGFloat = AppDesign.Radius.sm) -> some View {
        modifier(IconBadgeModifier(color: color, size: size, iconSize: iconSize, cornerRadius: cornerRadius))
    }
}
