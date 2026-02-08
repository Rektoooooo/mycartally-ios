//
//  ConnectionSetupView.swift
//  CarTracker
//

import SwiftUI
import SwiftOBD2

struct ConnectionSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OBDConnectionManager.self) private var obdManager

    var body: some View {
        @Bindable var manager = obdManager

        NavigationStack {
            List {
                // Connection Type
                Section {
                    Picker("Connection Type", selection: $manager.selectedConnectionType) {
                        Text("Bluetooth").tag(ConnectionType.bluetooth)
                        Text("Wi-Fi").tag(ConnectionType.wifi)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Connection Method")
                } footer: {
                    if obdManager.selectedConnectionType == .bluetooth {
                        Text("Make sure your BLE OBD2 adapter is plugged into the vehicle's OBD2 port and the engine is running.")
                    } else {
                        Text("Connect your iPhone to the OBD2 adapter's Wi-Fi network first, then tap Connect.")
                    }
                }

                // Connection Status
                Section {
                    HStack {
                        connectionStatusIcon
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                            Text(obdManager.connectionState.displayName)
                                .font(AppDesign.Typography.headline)
                            if obdManager.connectionState.isConnected {
                                if let proto = obdManager.obdProtocol {
                                    Text(proto)
                                        .font(AppDesign.Typography.caption)
                                        .foregroundStyle(AppDesign.Colors.textSecondary)
                                }
                            }
                        }
                        Spacer()
                        if obdManager.connectionState.isBusy {
                            ProgressView()
                        }
                    }
                } header: {
                    Text("Status")
                }

                // Actions
                Section {
                    if obdManager.connectionState.isConnected {
                        Button(role: .destructive) {
                            obdManager.disconnect()
                        } label: {
                            Label("Disconnect", systemImage: "xmark.circle.fill")
                        }
                    } else if obdManager.connectionState.isBusy {
                        Button(role: .cancel) {
                            obdManager.disconnect()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                    } else {
                        Button {
                            Task {
                                await obdManager.connect()
                            }
                        } label: {
                            Label("Connect to Vehicle", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .tint(AppDesign.Colors.accent)
                    }
                }

                // Demo Mode
                Section {
                    Button {
                        obdManager.startDemoMode()
                        dismiss()
                    } label: {
                        Label("Use Demo Mode", systemImage: "play.circle.fill")
                            .foregroundStyle(AppDesign.Colors.stats)
                    }
                } header: {
                    Text("Testing")
                } footer: {
                    Text("Demo mode simulates a connected vehicle with live data. Useful for testing without a physical OBD2 adapter.")
                }

                // How to Connect — shown expanded when disconnected
                if !obdManager.connectionState.isConnected {
                    Section {
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                            if obdManager.selectedConnectionType == .bluetooth {
                                helpItem(icon: "1.circle.fill", text: "Plug the OBD2 adapter into your car's diagnostic port (usually under the dashboard)")
                                helpItem(icon: "2.circle.fill", text: "Start the engine or turn the ignition to ON")
                                helpItem(icon: "3.circle.fill", text: "The app will find BLE adapters automatically")
                                helpItem(icon: "4.circle.fill", text: "Tap \"Connect to Vehicle\" above and wait for pairing")
                            } else {
                                helpItem(icon: "1.circle.fill", text: "Plug the OBD2 adapter into your car's diagnostic port")
                                helpItem(icon: "2.circle.fill", text: "Start the engine or turn the ignition to ON")
                                helpItem(icon: "3.circle.fill", text: "Open iPhone Settings > Wi-Fi and connect to your adapter's network")
                                helpItem(icon: "4.circle.fill", text: "Return here and tap \"Connect to Vehicle\"")
                            }
                        }
                        .padding(.vertical, AppDesign.Spacing.xs)
                    } header: {
                        Text("How to Connect")
                    }
                }

                // Compatible Adapters & Help
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                            Text("Recommended BLE adapters:")
                                .font(AppDesign.Typography.subheadline)
                                .fontWeight(.medium)
                            helpItem(icon: "checkmark.circle.fill", text: "Vgate iCar Pro BLE (~$30)")
                            helpItem(icon: "checkmark.circle.fill", text: "OBDLink CX (~$80)")
                            helpItem(icon: "checkmark.circle.fill", text: "OBDLink MX+ (~$140)")

                            Text("Note: Classic Bluetooth adapters do not work with iOS. Use BLE or Wi-Fi adapters only.")
                                .font(AppDesign.Typography.caption)
                                .foregroundStyle(AppDesign.Colors.warning)
                                .padding(.top, AppDesign.Spacing.xxs)
                        }
                        .padding(.vertical, AppDesign.Spacing.xs)
                    } label: {
                        Label("Compatible Adapters", systemImage: "cable.connector")
                    }
                } header: {
                    Text("Help")
                }
            }
            .navigationTitle("OBD2 Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var connectionStatusIcon: some View {
        let state = obdManager.connectionState
        ZStack {
            RoundedRectangle(cornerRadius: AppDesign.Radius.xs)
                .fill(statusColor(for: state).opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: statusIcon(for: state))
                .font(.title3)
                .foregroundStyle(statusColor(for: state))
        }
    }

    private func statusColor(for state: OBDConnectionState) -> Color {
        switch state {
        case .connectedToVehicle: return AppDesign.Colors.success
        case .connectedToAdapter: return AppDesign.Colors.warning
        case .error: return AppDesign.Colors.error
        case .scanning, .connecting, .initializing: return AppDesign.Colors.accent
        case .disconnected: return AppDesign.Colors.textSecondary
        }
    }

    private func statusIcon(for state: OBDConnectionState) -> String {
        switch state {
        case .connectedToVehicle: return "checkmark.circle.fill"
        case .connectedToAdapter: return "antenna.radiowaves.left.and.right"
        case .error: return "exclamationmark.triangle.fill"
        case .scanning: return "magnifyingglass"
        case .connecting, .initializing: return "arrow.triangle.2.circlepath"
        case .disconnected: return "antenna.radiowaves.left.and.right.slash"
        }
    }

    private func helpItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(AppDesign.Colors.accent)
                .frame(width: 20)
            Text(text)
                .font(AppDesign.Typography.subheadline)
                .foregroundStyle(AppDesign.Colors.textSecondary)
        }
    }
}
