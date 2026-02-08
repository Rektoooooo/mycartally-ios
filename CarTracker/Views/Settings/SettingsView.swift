//
//  SettingsView.swift
//  CarTracker
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(OBDConnectionManager.self) private var obdManager
    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]
    @Query(sort: \FuelEntry.date, order: .reverse) private var allFuelEntries: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \Reminder.dueDate) private var allReminders: [Reminder]

    private var settings = UserSettings.shared
    private var proManager = ProManager.shared

    @State private var showingProUpgrade = false
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Pro Banner (only show if not pro)
                if !proManager.isPro {
                    Section {
                        ProUpgradeBanner {
                            showingProUpgrade = true
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                // General
                Section {
                    NavigationLink {
                        UnitsSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "ruler",
                            title: "Units",
                            subtitle: settings.unitsDisplayString,
                            color: AppDesign.Colors.accent
                        )
                    }

                    NavigationLink {
                        CurrencySettingsView()
                    } label: {
                        SettingsRow(
                            icon: "eurosign.circle.fill",
                            title: "Currency",
                            subtitle: settings.currency.displayName,
                            color: AppDesign.Colors.stats
                        )
                    }

                    NavigationLink {
                        DefaultCarSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "car.fill",
                            title: "Default Car",
                            subtitle: defaultCarName,
                            color: AppDesign.Colors.fuel
                        )
                    }
                } header: {
                    Text("General")
                }

                // Notifications
                Section {
                    Toggle(isOn: Bindable(settings).notificationsEnabled) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            subtitle: nil,
                            color: .red
                        )
                    }

                    if settings.notificationsEnabled {
                        NavigationLink {
                            ReminderTimeSettingsView()
                        } label: {
                            SettingsRow(
                                icon: "clock.fill",
                                title: "Reminder Time",
                                subtitle: reminderTimeString,
                                color: AppDesign.Colors.reminders
                            )
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                // Data
                Section {
                    Button {
                        if proManager.canUseFeature(.iCloudSync) {
                            // iCloud sync settings
                        } else {
                            showingProUpgrade = true
                        }
                    } label: {
                        SettingsRow(
                            icon: "icloud.fill",
                            title: "iCloud Sync",
                            subtitle: proManager.isPro ? "Enabled" : "Pro",
                            color: .cyan,
                            isPro: !proManager.isPro
                        )
                    }

                    Button {
                        showingExportSheet = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            title: "Export Data",
                            subtitle: "CSV, PDF",
                            color: .indigo
                        )
                    }
                } header: {
                    Text("Data")
                }

                // Appearance
                Section {
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            title: "Theme",
                            subtitle: settings.theme.rawValue,
                            color: .pink
                        )
                    }
                } header: {
                    Text("Appearance")
                }

                // Support
                Section {
                    Button {
                        requestAppReview()
                    } label: {
                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate CarTracker",
                            subtitle: nil,
                            color: .yellow
                        )
                    }

                    Link(destination: URL(string: "mailto:support@cartracker.app")!) {
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            subtitle: nil,
                            color: AppDesign.Colors.accent
                        )
                    }
                } header: {
                    Text("Support")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    if proManager.isPro {
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: AppDesign.Spacing.xxs) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Pro")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("Privacy Policy")
                    }

                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Text("Terms of Service")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Made with care in the EU")
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppDesign.Spacing.md)
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete All Data")
                        }
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Danger Zone")
                }

                // OBD2 Diagnostics
                Section {
                    NavigationLink {
                        OBDSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "OBD2 Diagnostics",
                            subtitle: obdStatusText,
                            color: AppDesign.Colors.diagnostics
                        )
                    }
                } header: {
                    Text("Diagnostics")
                }

                #if DEBUG
                // Debug Section
                Section {
                    Button("Unlock Pro (Debug)") {
                        proManager.debugUnlockPro()
                    }
                    Button("Lock Pro (Debug)") {
                        proManager.debugLockPro()
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeSheet()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataSheet(
                    cars: cars,
                    fuelEntries: allFuelEntries,
                    expenses: allExpenses,
                    reminders: allReminders
                )
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all cars, fuel entries, expenses, and reminders. This action cannot be undone.")
            }
        }
    }

    private var defaultCarName: String {
        if let id = settings.defaultCarId,
           let car = cars.first(where: { $0.id == id }) {
            return car.displayName
        }
        return "None"
    }

    private var reminderTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: settings.reminderTime)
    }

    private var obdStatusText: String {
        if obdManager.isDemoMode { return "Demo Mode" }
        if obdManager.connectionState.isConnected { return "Connected" }
        return "Not Connected"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func requestAppReview() {
        requestReview()
    }

    private func deleteAllData() {
        for car in cars {
            modelContext.delete(car)
        }
        for entry in allFuelEntries {
            modelContext.delete(entry)
        }
        for expense in allExpenses {
            modelContext.delete(expense)
        }
        for reminder in allReminders {
            modelContext.delete(reminder)
        }
        try? modelContext.save()
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    var isPro: Bool = false

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppDesign.Radius.xs)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            if let subtitle = subtitle {
                HStack(spacing: AppDesign.Spacing.xxs) {
                    if isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                    }
                    Text(subtitle)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pro Upgrade Banner

struct ProUpgradeBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.xxs) {
                        HStack {
                            Text("CarTracker")
                                .font(.headline)
                            Text("PRO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, AppDesign.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Text("Unlock all features")
                            .font(.subheadline)
                            .opacity(0.9)
                    }

                    Spacer()

                    Image(systemName: "crown.fill")
                        .font(.title)
                        .opacity(0.9)
                }

                HStack(spacing: AppDesign.Spacing.sm) {
                    ProFeatureTag(icon: "car.2.fill", text: "Multi-car")
                    ProFeatureTag(icon: "icloud.fill", text: "Sync")
                    ProFeatureTag(icon: "doc.fill", text: "PDF")
                    ProFeatureTag(icon: "square.stack.3d.up.fill", text: "Widgets")
                }

                Text("Upgrade for €10")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppDesign.Spacing.sm)
                    .background(Color.white)
                    .foregroundStyle(AppDesign.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.sm))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [AppDesign.Colors.accent, AppDesign.Colors.reminders],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppDesign.Radius.lg))
            .padding(.horizontal)
            .padding(.vertical, AppDesign.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

struct ProFeatureTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppDesign.Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, AppDesign.Spacing.xs)
        .padding(.vertical, AppDesign.Spacing.xxs)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Units Settings View

struct UnitsSettingsView: View {
    private var settings = UserSettings.shared

    var body: some View {
        List {
            Section {
                Picker("Distance", selection: Bindable(settings).distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }

                Picker("Volume", selection: Bindable(settings).volumeUnit) {
                    ForEach(VolumeUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
            } footer: {
                Text("These settings affect how values are displayed throughout the app.")
            }
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency Settings View

struct CurrencySettingsView: View {
    private var settings = UserSettings.shared

    var body: some View {
        List {
            Section {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button {
                        settings.currency = currency
                    } label: {
                        HStack {
                            Text(currency.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.currency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppDesign.Colors.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Default Car Settings View

struct DefaultCarSettingsView: View {
    @Query(filter: #Predicate<Car> { !$0.isArchived }, sort: \Car.createdAt) private var cars: [Car]
    private var settings = UserSettings.shared

    var body: some View {
        List {
            Section {
                Button {
                    settings.defaultCarId = nil
                } label: {
                    HStack {
                        Text("None")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.defaultCarId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppDesign.Colors.accent)
                        }
                    }
                }

                ForEach(cars) { car in
                    Button {
                        settings.defaultCarId = car.id
                    } label: {
                        HStack {
                            Text(car.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.defaultCarId == car.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppDesign.Colors.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("The default car will be pre-selected when adding new entries.")
            }
        }
        .navigationTitle("Default Car")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reminder Time Settings View

struct ReminderTimeSettingsView: View {
    private var settings = UserSettings.shared
    @State private var selectedTime: Date

    init() {
        _selectedTime = State(initialValue: UserSettings.shared.reminderTime)
    }

    var body: some View {
        List {
            Section {
                DatePicker(
                    "Reminder Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .onChange(of: selectedTime) { _, newValue in
                    settings.reminderTime = newValue
                }
            } footer: {
                Text("Notifications for upcoming reminders will be sent at this time.")
            }
        }
        .navigationTitle("Reminder Time")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Theme Settings View

struct ThemeSettingsView: View {
    private var settings = UserSettings.shared

    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        settings.theme = theme
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.theme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppDesign.Colors.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cars: [Car]
    let fuelEntries: [FuelEntry]
    let expenses: [Expense]
    let reminders: [Reminder]

    init(
        cars: [Car],
        fuelEntries: [FuelEntry],
        expenses: [Expense],
        reminders: [Reminder]
    ) {
        self.cars = cars
        self.fuelEntries = fuelEntries
        self.expenses = expenses
        self.reminders = reminders
    }

    private var proManager = ProManager.shared

    @State private var selectedCar: Car?
    @State private var exportFormat = "CSV"
    @State private var showingPDFPreview = false
    @State private var pdfData: Data?
    @State private var csvData: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Car", selection: $selectedCar) {
                        Text("All Cars").tag(nil as Car?)
                        ForEach(cars) { car in
                            Text(car.displayName).tag(car as Car?)
                        }
                    }
                } header: {
                    Text("Select Car")
                }

                Section {
                    Picker("Format", selection: $exportFormat) {
                        Text("CSV").tag("CSV")
                        HStack {
                            Text("PDF")
                            if !proManager.isPro {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                            }
                        }.tag("PDF")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Format")
                }

                Section {
                    if exportFormat == "CSV" {
                        Button {
                            generateCSV()
                        } label: {
                            Label("Export CSV", systemImage: "doc.text")
                        }
                    } else {
                        if proManager.isPro {
                            Button {
                                generatePDF()
                            } label: {
                                Label("Generate PDF", systemImage: "doc.fill")
                            }
                        } else {
                            Button {
                                // Show pro upgrade
                            } label: {
                                HStack {
                                    Label("Generate PDF", systemImage: "doc.fill")
                                    Spacer()
                                    Text("Pro")
                                        .font(.caption)
                                        .padding(.horizontal, AppDesign.Spacing.xs)
                                        .padding(.vertical, AppDesign.Spacing.xxs)
                                        .background(AppDesign.Colors.accent)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                } footer: {
                    if exportFormat == "CSV" {
                        Text("Export your data as a CSV file that can be opened in Excel or Google Sheets.")
                    } else {
                        Text("Generate a professional PDF document with your car's complete service history.")
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let data = pdfData {
                    PDFPreviewView(pdfData: data)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let csv = csvData {
                    ShareSheet(items: [csv.toCSVData()])
                }
            }
        }
    }

    private func generateCSV() {
        let filteredFuel = selectedCar != nil
            ? fuelEntries.filter { $0.car?.id == selectedCar?.id }
            : fuelEntries

        let filteredExpenses = selectedCar != nil
            ? expenses.filter { $0.car?.id == selectedCar?.id }
            : expenses

        let filteredReminders = selectedCar != nil
            ? reminders.filter { $0.car?.id == selectedCar?.id }
            : reminders

        if let car = selectedCar {
            csvData = CSVExportService.shared.exportAllData(
                cars: [car],
                fuelEntries: filteredFuel,
                expenses: filteredExpenses,
                reminders: filteredReminders
            )
        } else {
            csvData = CSVExportService.shared.exportAllData(
                cars: cars,
                fuelEntries: fuelEntries,
                expenses: expenses,
                reminders: reminders
            )
        }
        showingShareSheet = true
    }

    private func generatePDF() {
        guard let car = selectedCar else { return }

        let filteredFuel = fuelEntries.filter { $0.car?.id == car.id }
        let filteredExpenses = expenses.filter { $0.car?.id == car.id }
        let filteredReminders = reminders.filter { $0.car?.id == car.id }

        pdfData = PDFExportService.shared.generateCarHistoryPDF(
            car: car,
            fuelEntries: filteredFuel,
            expenses: filteredExpenses,
            reminders: filteredReminders
        )

        if pdfData != nil {
            showingPDFPreview = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Last updated: January 2025")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Data Collection")
                        .font(.headline)
                    Text("CarTracker stores all your data locally on your device. We do not collect, transmit, or store any personal information on external servers.")

                    Text("iCloud Sync")
                        .font(.headline)
                    Text("If you enable iCloud Sync (Pro feature), your data is stored in your personal iCloud account. We do not have access to this data.")

                    Text("Analytics")
                        .font(.headline)
                    Text("We do not use any third-party analytics or tracking services.")

                    Text("Contact")
                        .font(.headline)
                    Text("If you have questions about our privacy practices, contact us at support@cartracker.app")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Last updated: January 2025")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Acceptance")
                        .font(.headline)
                    Text("By using CarTracker, you agree to these terms of service.")

                    Text("License")
                        .font(.headline)
                    Text("CarTracker grants you a limited, non-exclusive license to use the app for personal, non-commercial purposes.")

                    Text("Pro Purchases")
                        .font(.headline)
                    Text("Pro features are unlocked with a one-time purchase. All purchases are final and non-refundable, except as required by applicable law.")

                    Text("Disclaimer")
                        .font(.headline)
                    Text("CarTracker is provided \"as is\" without warranties of any kind. We are not responsible for any data loss or inaccuracies in calculations.")

                    Text("Changes")
                        .font(.headline)
                    Text("We may update these terms from time to time. Continued use of the app constitutes acceptance of the updated terms.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - OBD2 Settings View

struct OBDSettingsView: View {
    @Environment(OBDConnectionManager.self) private var obdManager

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    HStack(spacing: AppDesign.Spacing.xxs) {
                        Circle()
                            .fill(obdManager.connectionState.isConnected ? AppDesign.Colors.success : AppDesign.Colors.textTertiary)
                            .frame(width: 8, height: 8)
                        Text(obdManager.connectionState.displayName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                if let vin = obdManager.vehicleVIN {
                    HStack {
                        Text("VIN")
                        Spacer()
                        Text(vin)
                            .font(.subheadline)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                    }
                }

                if let proto = obdManager.obdProtocol {
                    HStack {
                        Text("Protocol")
                        Spacer()
                        Text(proto)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Connection")
            }

            Section {
                Toggle("Demo Mode", isOn: Binding(
                    get: { obdManager.isDemoMode },
                    set: { newValue in
                        if newValue {
                            obdManager.startDemoMode()
                        } else {
                            obdManager.stopDemoMode()
                        }
                    }
                ))
            } header: {
                Text("Testing")
            } footer: {
                Text("Demo mode simulates a connected vehicle with live data for testing the UI without a physical OBD2 adapter.")
            }

            if obdManager.connectionState.isConnected {
                Section {
                    Button(role: .destructive) {
                        obdManager.disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("OBD2 Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Car.self, FuelEntry.self, Expense.self, Reminder.self, OBDReading.self], inMemory: true)
        .environment(OBDConnectionManager())
}
