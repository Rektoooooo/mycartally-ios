//
//  OnboardingDesign.swift
//  CarTracker
//

import SwiftUI
import UIKit

enum OnboardingDesign {

    // MARK: - Colors

    enum Colors {
        // Primary brand
        static let accent = Color(hex: "0066FF")
        static let accentLight = Color(hex: "0066FF").opacity(0.12)
        static let accentDark = Color(hex: "0052CC")

        // Backgrounds
        static let background = Color(UIColor.systemBackground)
        static let backgroundSecondary = Color(UIColor.systemGroupedBackground)
        static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)

        // Feature colors (matching app)
        static let fuel = Color.orange
        static let reminders = Color.purple
        static let stats = Color.green
        static let car = Color(hex: "0066FF")

        // Text hierarchy
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        static let textOnAccent = Color.white

        // Progress
        static let progressBackground = Color(UIColor.systemGray5)
        static let progressFill = Color(hex: "0066FF")
    }

    // MARK: - Spacing

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
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let full: CGFloat = 100
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 17, weight: .medium)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }

    // MARK: - Animations

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
        static let stepTransition = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 1.0)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
