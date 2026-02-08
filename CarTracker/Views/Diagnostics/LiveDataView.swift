//
//  LiveDataView.swift
//  CarTracker
//

import SwiftUI

struct LiveDataView: View {
    @Environment(OBDConnectionManager.self) private var obdManager

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.Spacing.md) {
                // Primary Gauges - RPM and Speed
                HStack(spacing: AppDesign.Spacing.md) {
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

                // Secondary Gauges Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppDesign.Spacing.sm),
                    GridItem(.flexible(), spacing: AppDesign.Spacing.sm),
                ], spacing: AppDesign.Spacing.sm) {
                    DataTileView(
                        title: "Coolant Temp",
                        value: obdManager.liveData.coolantTemp,
                        unit: "°C",
                        icon: "thermometer.medium",
                        color: tempColor(obdManager.liveData.coolantTemp ?? 0),
                        format: "%.0f"
                    )

                    DataTileView(
                        title: "Fuel Level",
                        value: obdManager.liveData.fuelLevel,
                        unit: "%",
                        icon: "fuelpump.fill",
                        color: fuelColor(obdManager.liveData.fuelLevel ?? 100),
                        format: "%.0f"
                    )

                    DataTileView(
                        title: "Engine Load",
                        value: obdManager.liveData.engineLoad,
                        unit: "%",
                        icon: "gauge.with.dots.needle.67percent",
                        color: loadColor(obdManager.liveData.engineLoad ?? 0),
                        format: "%.0f"
                    )

                    DataTileView(
                        title: "Throttle",
                        value: obdManager.liveData.throttlePosition,
                        unit: "%",
                        icon: "pedal.accelerator",
                        color: AppDesign.Colors.accent,
                        format: "%.0f"
                    )

                    DataTileView(
                        title: "Intake Air",
                        value: obdManager.liveData.intakeAirTemp,
                        unit: "°C",
                        icon: "wind",
                        color: .cyan,
                        format: "%.0f"
                    )

                    DataTileView(
                        title: "Voltage",
                        value: obdManager.liveData.voltage,
                        unit: "V",
                        icon: "bolt.fill",
                        color: voltageColor(obdManager.liveData.voltage ?? 14),
                        format: "%.1f"
                    )

                    if obdManager.liveData.oilTemp != nil {
                        DataTileView(
                            title: "Oil Temp",
                            value: obdManager.liveData.oilTemp,
                            unit: "°C",
                            icon: "drop.fill",
                            color: tempColor(obdManager.liveData.oilTemp ?? 0),
                            format: "%.0f"
                        )
                    }

                    if obdManager.liveData.fuelRate != nil {
                        DataTileView(
                            title: "Fuel Rate",
                            value: obdManager.liveData.fuelRate,
                            unit: "L/h",
                            icon: "flame.fill",
                            color: AppDesign.Colors.fuel,
                            format: "%.1f"
                        )
                    }
                }
                .padding(.horizontal, AppDesign.Spacing.md)

                // Last Updated
                if obdManager.liveData.hasAnyData {
                    Text("Updated \(obdManager.liveData.lastUpdated, style: .relative) ago")
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(AppDesign.Colors.textTertiary)
                        .padding(.bottom, AppDesign.Spacing.md)
                }
            }
            .padding(.top, AppDesign.Spacing.md)
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
        VStack(spacing: AppDesign.Spacing.xs) {
            ZStack {
                // Background track
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 12)

                // Value arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppDesign.Animation.smooth, value: progress)

                // Value text
                VStack(spacing: 2) {
                    Text(String(format: format, value))
                        .font(AppDesign.Typography.title2)
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                    Text(label)
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }
            }
            .frame(height: 140)
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Spacer()
            }

            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: format, value))
                        .font(AppDesign.Typography.title3)
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }
            } else {
                Text("--")
                    .font(AppDesign.Typography.title3)
                    .foregroundStyle(AppDesign.Colors.textTertiary)
            }

            Text(title)
                .font(AppDesign.Typography.caption)
                .foregroundStyle(AppDesign.Colors.textSecondary)
        }
        .premiumCard()
    }
}
