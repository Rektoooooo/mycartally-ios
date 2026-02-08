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

            DiagnosticsView()
                .tabItem {
                    Label("OBD2", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(3)

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(AppDesign.Colors.accent)
    }
}

#Preview {
    MainTabView()
}
