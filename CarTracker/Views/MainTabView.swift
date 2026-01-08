//
//  MainTabView.swift
//  CarTracker
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(0)

            CarsListView()
                .tabItem {
                    Label("My Cars", systemImage: "car.fill")
                }
                .tag(1)

            LogView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
                .tag(2)

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
