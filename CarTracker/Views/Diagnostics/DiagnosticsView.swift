//
//  DiagnosticsView.swift
//  CarTracker
//

import SwiftUI
import SwiftOBD2

struct DiagnosticsView: View {
    @Environment(OBDConnectionManager.self) private var obdManager

    @State private var showingConnectionSetup = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            Group {
                if obdManager.connectionState.isConnected {
                    connectedContent
                } else {
                    disconnectedContent
                }
            }
            .navigationTitle("OBD2")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingConnectionSetup = true
                    } label: {
                        Image(systemName: connectionToolbarIcon)
                            .foregroundStyle(connectionToolbarColor)
                    }
                }
            }
            .sheet(isPresented: $showingConnectionSetup) {
                ConnectionSetupView()
            }
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        VStack(spacing: 0) {
            // Connection banner
            connectionBanner
                .padding(.horizontal, AppDesign.Spacing.md)
                .padding(.top, AppDesign.Spacing.xs)

            // Segment picker
            Picker("View", selection: $selectedTab) {
                Text("Live Data").tag(0)
                Text("DTCs").tag(1)
                Text("Vehicle Info").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppDesign.Spacing.md)
            .padding(.vertical, AppDesign.Spacing.sm)

            // Content
            switch selectedTab {
            case 0:
                LiveDataView()
            case 1:
                DTCListView()
            case 2:
                vehicleInfoContent
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Disconnected Content

    private var disconnectedContent: some View {
        VStack(spacing: AppDesign.Spacing.xxl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(AppDesign.Colors.diagnostics.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(AppDesign.Colors.diagnostics)
            }

            // Text
            VStack(spacing: AppDesign.Spacing.sm) {
                Text("Vehicle Diagnostics")
                    .font(AppDesign.Typography.title2)

                Text("Connect an OBD2 adapter to read live engine data, diagnostic codes, and vehicle information.")
                    .font(AppDesign.Typography.subheadline)
                    .foregroundStyle(AppDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppDesign.Spacing.xxl)
            }

            // Connect button
            Button {
                showingConnectionSetup = true
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Connect OBD2 Adapter")
                }
                .font(AppDesign.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppDesign.Spacing.md)
                .background(AppDesign.Colors.diagnostics)
                .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
            }
            .padding(.horizontal, AppDesign.Spacing.xxl)

            // Features list
            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                featureRow(icon: "gauge.with.dots.needle.67percent", title: "Live Data", subtitle: "RPM, speed, temperature, fuel level & more")
                featureRow(icon: "exclamationmark.triangle", title: "Trouble Codes", subtitle: "Read and clear check engine light codes")
                featureRow(icon: "info.circle", title: "Vehicle Info", subtitle: "VIN, protocol, and supported parameters")
            }
            .padding(.horizontal, AppDesign.Spacing.xxl)

            Spacer()
        }
    }

    // MARK: - Vehicle Info Content

    private var vehicleInfoContent: some View {
        List {
            Section {
                if let vin = obdManager.vehicleVIN {
                    HStack {
                        Text("VIN")
                        Spacer()
                        Text(vin)
                            .font(AppDesign.Typography.subheadline)
                            .fontDesign(.monospaced)
                            .foregroundStyle(AppDesign.Colors.textSecondary)
                            .textSelection(.enabled)
                    }
                } else {
                    Button {
                        Task {
                            _ = await obdManager.readVIN()
                        }
                    } label: {
                        Label("Read VIN", systemImage: "barcode")
                    }
                }

                if let proto = obdManager.obdProtocol {
                    HStack {
                        Text("OBD Protocol")
                        Spacer()
                        Text(proto)
                            .font(AppDesign.Typography.caption)
                            .foregroundStyle(AppDesign.Colors.textSecondary)
                    }
                }
            } header: {
                Text("Vehicle")
            }

            Section {
                HStack {
                    Text("Supported PIDs")
                    Spacer()
                    Text("\(obdManager.supportedPIDs.count)")
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }

                HStack {
                    Text("Connection Type")
                    Spacer()
                    Text(obdManager.selectedConnectionType.rawValue)
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                }

                if obdManager.isDemoMode {
                    HStack {
                        Text("Mode")
                        Spacer()
                        HStack(spacing: AppDesign.Spacing.xxs) {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(AppDesign.Colors.stats)
                            Text("Demo")
                        }
                        .foregroundStyle(AppDesign.Colors.textSecondary)
                    }
                }
            } header: {
                Text("Adapter")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Components

    private var connectionBanner: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Circle()
                .fill(AppDesign.Colors.success)
                .frame(width: 8, height: 8)

            Text(obdManager.isDemoMode ? "Demo Mode" : "Connected")
                .font(AppDesign.Typography.caption)
                .foregroundStyle(AppDesign.Colors.success)

            Spacer()

            if obdManager.isPolling {
                HStack(spacing: AppDesign.Spacing.xxs) {
                    Circle()
                        .fill(AppDesign.Colors.success)
                        .frame(width: 6, height: 6)
                        .opacity(0.6)
                    Text("Live")
                        .font(AppDesign.Typography.caption)
                        .foregroundStyle(AppDesign.Colors.success)
                }
            }
        }
        .padding(.horizontal, AppDesign.Spacing.sm)
        .padding(.vertical, AppDesign.Spacing.xs)
        .background(AppDesign.Colors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.xs))
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: icon)
                .iconBadge(color: AppDesign.Colors.diagnostics, size: 36, iconSize: .subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.textSecondary)
            }
        }
    }

    private var connectionToolbarIcon: String {
        obdManager.connectionState.isConnected
            ? "antenna.radiowaves.left.and.right"
            : "antenna.radiowaves.left.and.right.slash"
    }

    private var connectionToolbarColor: Color {
        obdManager.connectionState.isConnected
            ? AppDesign.Colors.success
            : AppDesign.Colors.textSecondary
    }
}
