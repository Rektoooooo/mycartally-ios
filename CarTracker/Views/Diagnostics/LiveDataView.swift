//
//  LiveDataView.swift
//  CarTracker
//

import SwiftUI

struct LiveDataView: View {
    @Environment(OBDConnectionManager.self) private var obdManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.lg) {
                // Primary Gauges - RPM and Speed
                HStack(spacing: AppDesign.Spacing.sm) {
                    CircularGaugeView(
                        value: obdManager.liveData.rpm ?? 0,
                        maxValue: 8000,
                        label: "RPM",
                        format: "%.0f",
                        color: rpmColor(obdManager.liveData.rpm ?? 0)
                    )

                    CircularGaugeView(
                        value: obdManager.liveData.speed ?? 0,
                        maxValue: 260,
                        label: "km/h",
                        format: "%.0f",
                        color: AppDesign.Colors.accent
                    )
                }
                .padding(.horizontal, AppDesign.Spacing.md)

                // Oil Temperature - full width below gauges
                if let oilTemp = obdManager.liveData.oilTemp {
                    TemperatureCardView(
                        title: "Oil Temperature",
                        temp: oilTemp,
                        icon: "drop.fill",
                        color: tempColor(oilTemp)
                    )
                    .padding(.horizontal, AppDesign.Spacing.md)
                }

                // Secondary Metrics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppDesign.Spacing.sm),
                    GridItem(.flexible(), spacing: AppDesign.Spacing.sm),
                ], spacing: AppDesign.Spacing.sm) {
                    DataTileView(
                        title: "Coolant",
                        value: obdManager.liveData.coolantTemp,
                        unit: "\u{00B0}C",
                        icon: "thermometer.medium",
                        color: tempColor(obdManager.liveData.coolantTemp ?? 0),
                        format: "%.0f",
                        maxValue: 130
                    )

                    DataTileView(
                        title: "Throttle",
                        value: obdManager.liveData.throttlePosition,
                        unit: "%",
                        icon: "pedal.accelerator",
                        color: AppDesign.Colors.accent,
                        format: "%.0f",
                        maxValue: 100
                    )

                    DataTileView(
                        title: "Engine Load",
                        value: obdManager.liveData.engineLoad,
                        unit: "%",
                        icon: "gauge.with.dots.needle.67percent",
                        color: loadColor(obdManager.liveData.engineLoad ?? 0),
                        format: "%.0f",
                        maxValue: 100
                    )

                    if obdManager.liveData.voltage != nil {
                        DataTileView(
                            title: "Voltage",
                            value: obdManager.liveData.voltage,
                            unit: "V",
                            icon: "bolt.fill",
                            color: voltageColor(obdManager.liveData.voltage ?? 0),
                            format: "%.1f",
                            maxValue: 16
                        )
                    }

                    if obdManager.liveData.intakeAirTemp != nil {
                        DataTileView(
                            title: "Intake Air",
                            value: obdManager.liveData.intakeAirTemp,
                            unit: "\u{00B0}C",
                            icon: "wind",
                            color: .cyan,
                            format: "%.0f",
                            maxValue: 80
                        )
                    }

                    if obdManager.liveData.fuelLevel != nil {
                        DataTileView(
                            title: "Fuel Level",
                            value: obdManager.liveData.fuelLevel,
                            unit: "%",
                            icon: "fuelpump.fill",
                            color: fuelColor(obdManager.liveData.fuelLevel ?? 100),
                            format: "%.0f",
                            maxValue: 100
                        )
                    }

                    if obdManager.liveData.fuelRate != nil {
                        DataTileView(
                            title: "Fuel Rate",
                            value: obdManager.liveData.fuelRate,
                            unit: "L/h",
                            icon: "flame.fill",
                            color: AppDesign.Colors.fuel,
                            format: "%.1f",
                            maxValue: 20
                        )
                    }
                }
                .padding(.horizontal, AppDesign.Spacing.md)

                // Last Updated
                if obdManager.liveData.hasAnyData {
                    Text("Updated \(obdManager.liveData.lastUpdated, style: .relative) ago")
                        .font(AppDesign.Typography.caption2)
                        .foregroundStyle(AppDesign.Colors.textTertiary)
                        .padding(.bottom, AppDesign.Spacing.lg)
                }
            }
            .padding(.top, AppDesign.Spacing.sm)
        }
        .onAppear {
            if obdManager.connectionState.isConnectedToVehicle && !obdManager.isPolling {
                obdManager.startLiveDataPolling()
            }
        }
        .onDisappear {
            obdManager.stopPolling()
        }
    }

    // MARK: - Color Helpers

    private func rpmColor(_ rpm: Double) -> Color {
        if rpm > 6000 { return AppDesign.Colors.error }
        if rpm > 4500 { return AppDesign.Colors.warning }
        return AppDesign.Colors.success
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 110 { return AppDesign.Colors.error }
        if temp > 100 { return AppDesign.Colors.warning }
        if temp < 50 { return .cyan }
        return AppDesign.Colors.success
    }

    private func fuelColor(_ level: Double) -> Color {
        if level < 10 { return AppDesign.Colors.error }
        if level < 25 { return AppDesign.Colors.warning }
        return AppDesign.Colors.fuel
    }

    private func loadColor(_ load: Double) -> Color {
        if load > 85 { return AppDesign.Colors.error }
        if load > 60 { return AppDesign.Colors.warning }
        return AppDesign.Colors.success
    }

    private func voltageColor(_ voltage: Double) -> Color {
        if voltage < 12.0 { return AppDesign.Colors.error }
        if voltage < 12.6 { return AppDesign.Colors.warning }
        return AppDesign.Colors.success
    }
}

// MARK: - Circular Gauge View

struct CircularGaugeView: View {
    let value: Double
    let maxValue: Double
    let label: String
    let format: String
    let color: Color

    private var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.08), lineWidth: 14)

            // Value arc with glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 6)
                .animation(AppDesign.Animation.smooth, value: progress)

            // Center value
            VStack(spacing: 2) {
                Text(String(format: format, value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(label)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.textSecondary)
                    .textCase(.uppercase)
            }
        }
        .frame(height: 150)
        .premiumCard()
    }
}

// MARK: - Temperature Card View

struct TemperatureCardView: View {
    let title: String
    let temp: Double
    let icon: String
    let color: Color

    private var normalizedTemp: Double {
        min(max((temp - 20) / 130.0, 0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Text(title)
                    .font(AppDesign.Typography.subheadline)
                    .foregroundStyle(AppDesign.Colors.textSecondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", temp))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("\u{00B0}C")
                        .font(AppDesign.Typography.footnote)
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }
            }

            // Temperature gradient bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.15), .green.opacity(0.15), .orange.opacity(0.15), .red.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * normalizedTemp, 4))
                        .animation(AppDesign.Animation.smooth, value: normalizedTemp)
                }
            }
            .frame(height: 6)
        }
        .premiumCard()
    }
}

// MARK: - Data Tile View

struct DataTileView: View {
    let title: String
    let value: Double?
    let unit: String
    let icon: String
    let color: Color
    let format: String
    var maxValue: Double = 100

    private var progress: Double {
        guard let v = value else { return 0 }
        return min(v / maxValue, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            // Icon with colored background
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            // Value
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: format, value))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(AppDesign.Typography.caption2)
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }
            } else {
                Text("--")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppDesign.Colors.textTertiary)
            }

            // Title
            Text(title)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(AppDesign.Colors.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max(geo.size.width * progress, value != nil ? 2 : 0))
                        .animation(AppDesign.Animation.smooth, value: progress)
                }
            }
            .frame(height: 3)
        }
        .premiumCard()
    }
}
