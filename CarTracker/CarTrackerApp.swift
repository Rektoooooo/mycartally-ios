//
//  CarTrackerApp.swift
//  CarTracker
//
//  Created by Sebastián Kučera on 02.01.2026.
//

import SwiftUI
import SwiftData

@main
struct CarTrackerApp: App {
    @State private var appState = AppState()
    @State private var showOnboarding = false
    private var settings = UserSettings.shared
    private var onboardingManager = OnboardingManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Car.self,
            FuelEntry.self,
            Expense.self,
            Reminder.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .preferredColorScheme(settings.theme.colorScheme)
                .task {
                    // Request notification permissions on first launch
                    await NotificationService.shared.requestAuthorization()
                }
                .onAppear {
                    if !onboardingManager.hasCompletedOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        onboardingManager.completeOnboarding()
                        showOnboarding = false
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
