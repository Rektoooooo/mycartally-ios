//
//  DTCListView.swift
//  CarTracker
//

import SwiftUI

struct DTCListView: View {
    @Environment(OBDConnectionManager.self) private var obdManager

    @State private var isReading = false
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Action buttons
            HStack(spacing: AppDesign.Spacing.sm) {
                Button {
                    isReading = true
                    Task {
                        await obdManager.readDTCs()
                        isReading = false
                    }
                } label: {
                    HStack {
                        if isReading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Read DTCs")
                    }
                    .font(AppDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppDesign.Spacing.sm)
                    .background(AppDesign.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                }
                .disabled(isReading)

                if !obdManager.dtcCodes.isEmpty {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(AppDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppDesign.Spacing.sm)
                        .background(AppDesign.Colors.error.opacity(0.12))
                        .foregroundStyle(AppDesign.Colors.error)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
                    }
                }
            }
            .padding(AppDesign.Spacing.md)

            // DTC List or Empty State
            if obdManager.dtcCodes.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppDesign.Spacing.sm) {
                        ForEach(obdManager.dtcCodes) { dtc in
                            DTCRowView(dtc: dtc)
                        }
                    }
                    .padding(.horizontal, AppDesign.Spacing.md)
                    .padding(.bottom, AppDesign.Spacing.md)
                }
            }
        }
        .alert("Clear Diagnostic Codes?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear DTCs", role: .destructive) {
                Task {
                    await obdManager.clearDTCs()
                }
            }
        } message: {
            Text("This will clear all stored diagnostic trouble codes and turn off the check engine light. The codes may return if the underlying issue is not resolved.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppDesign.Colors.success)

            Text("No Trouble Codes")
                .font(AppDesign.Typography.title3)

            Text("Tap \"Read DTCs\" to scan your vehicle for diagnostic trouble codes.")
                .font(AppDesign.Typography.subheadline)
                .foregroundStyle(AppDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppDesign.Spacing.xxl)
        }
    }
}

// MARK: - DTC Row View

struct DTCRowView: View {
    let dtc: DTCCode

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            // Category icon
            Image(systemName: dtc.categoryIcon)
                .iconBadge(color: severityColor, size: 40, iconSize: .subheadline)

            VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                HStack {
                    Text(dtc.code)
                        .font(AppDesign.Typography.headline)
                        .fontDesign(.monospaced)

                    severityBadge
                }

                Text(dtc.description)
                    .font(AppDesign.Typography.subheadline)
                    .foregroundStyle(AppDesign.Colors.textSecondary)
                    .lineLimit(2)

                Text("\(dtc.category) · \(dtc.ecuName)")
                    .font(AppDesign.Typography.caption)
                    .foregroundStyle(AppDesign.Colors.textTertiary)
            }

            Spacer()
        }
        .premiumCard()
    }

    private var severityBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: dtc.severity.icon)
                .font(.caption2)
            Text(dtc.severity.displayName)
                .font(AppDesign.Typography.caption)
        }
        .padding(.horizontal, AppDesign.Spacing.xs)
        .padding(.vertical, 2)
        .background(severityColor.opacity(0.12))
        .foregroundStyle(severityColor)
        .clipShape(Capsule())
    }

    private var severityColor: Color {
        switch dtc.severity {
        case .info: return AppDesign.Colors.accent
        case .warning: return AppDesign.Colors.warning
        case .critical: return AppDesign.Colors.error
        }
    }
}
