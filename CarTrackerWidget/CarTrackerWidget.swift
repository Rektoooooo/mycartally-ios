//
//  CarTrackerWidget.swift
//  CarTrackerWidget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CarTrackerTimelineProvider: TimelineProvider {
    typealias Entry = CarTrackerWidgetEntry

    func placeholder(in context: Context) -> CarTrackerWidgetEntry {
        CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
    }

    func getSnapshot(in context: Context, completion: @escaping (CarTrackerWidgetEntry) -> Void) {
        let data = WidgetDataService.shared.loadWidgetData() ?? WidgetDataService.previewData
        let entry = CarTrackerWidgetEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CarTrackerWidgetEntry>) -> Void) {
        let data = WidgetDataService.shared.loadWidgetData() ?? WidgetDataService.previewData
        let entry = CarTrackerWidgetEntry(date: Date(), data: data)

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// MARK: - Widget Entry

struct CarTrackerWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                Text("CarTracker")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Next reminder
            if let reminder = entry.data.upcomingReminders.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if let days = reminder.daysUntilDue {
                        HStack(spacing: 4) {
                            Image(systemName: reminder.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                .font(.caption2)
                            Text(reminder.isOverdue ? "Overdue" : "in \(days) days")
                                .font(.caption)
                        }
                        .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                    }
                }
            } else {
                Text("No upcoming reminders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Fuel info
            if let consumption = entry.data.fuelData.averageConsumption {
                HStack {
                    Image(systemName: "fuelpump.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f L/100km", consumption))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Next reminder
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.purple)
                    Text("Next Service")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if let reminder = entry.data.upcomingReminders.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.headline)
                            .lineLimit(1)

                        if let days = reminder.daysUntilDue {
                            Text(reminder.isOverdue ? "Overdue!" : "in \(days) days")
                                .font(.subheadline)
                                .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                        }

                        if let carName = reminder.carName {
                            Text(carName)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    Text("No reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Right side - Fuel stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "fuelpump.fill")
                        .foregroundStyle(.orange)
                    Text("Fuel")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let consumption = entry.data.fuelData.averageConsumption {
                        HStack {
                            Text("Avg:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f L/100km", consumption))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    HStack {
                        Text("This month:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "€%.0f", entry.data.fuelData.totalCostThisMonth))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let price = entry.data.fuelData.lastPricePerLiter {
                        HStack {
                            Text("Last price:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "€%.3f/L", price))
                                .font(.caption)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                Text("CarTracker")
                    .font(.headline)

                Spacer()

                if let car = entry.data.cars.first {
                    Text(car.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Upcoming Reminders
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.purple)
                    Text("Upcoming")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                if entry.data.upcomingReminders.isEmpty {
                    Text("No upcoming reminders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(entry.data.upcomingReminders.prefix(3), id: \.id) { reminder in
                        HStack {
                            Circle()
                                .fill(reminder.isOverdue ? .red : .blue)
                                .frame(width: 8, height: 8)

                            Text(reminder.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()

                            if let days = reminder.daysUntilDue {
                                Text(reminder.isOverdue ? "Overdue" : "\(days)d")
                                    .font(.caption)
                                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            // Fuel Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "gauge")
                            .foregroundStyle(.green)
                        Text("Consumption")
                            .font(.caption)
                    }
                    if let consumption = entry.data.fuelData.averageConsumption {
                        Text(String(format: "%.1f L/100km", consumption))
                            .font(.title3)
                            .fontWeight(.bold)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "eurosign.circle")
                            .foregroundStyle(.orange)
                        Text("This Month")
                            .font(.caption)
                    }
                    Text(String(format: "€%.0f", entry.data.fuelData.totalCostThisMonth))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()
            }

            Spacer()

            // Last updated
            Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Lock Screen Widget Views

struct AccessoryCircularView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if let reminder = entry.data.upcomingReminders.first,
               let days = reminder.daysUntilDue {
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("days")
                        .font(.caption2)
                }
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        if let reminder = entry.data.upcomingReminders.first {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: reminder.isOverdue ? "exclamationmark.triangle.fill" : "bell.fill")
                    Text(reminder.title)
                        .fontWeight(.semibold)
                }
                .font(.headline)

                if let days = reminder.daysUntilDue {
                    Text(reminder.isOverdue ? "Overdue!" : "Due in \(days) days")
                        .font(.caption)
                }

                if let carName = reminder.carName {
                    Text(carName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "car.fill")
                    Text("CarTracker")
                        .fontWeight(.semibold)
                }
                Text("No upcoming reminders")
                    .font(.caption)
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: CarTrackerWidgetEntry

    var body: some View {
        if let reminder = entry.data.upcomingReminders.first {
            if let days = reminder.daysUntilDue {
                Label(
                    reminder.isOverdue ? "\(reminder.title) overdue!" : "\(reminder.title) in \(days)d",
                    systemImage: reminder.isOverdue ? "exclamationmark.triangle" : "bell"
                )
            } else {
                Label(reminder.title, systemImage: "bell")
            }
        } else {
            Label("No reminders", systemImage: "checkmark.circle")
        }
    }
}

// MARK: - Main Widget

struct CarTrackerHomeWidget: Widget {
    let kind: String = "CarTrackerHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CarTrackerTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetContentView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetContentView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("CarTracker")
        .description("View upcoming reminders and fuel statistics.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetContentView: View {
    @Environment(\.widgetFamily) var family
    let entry: CarTrackerWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widget

struct CarTrackerLockScreenWidget: Widget {
    let kind: String = "CarTrackerLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CarTrackerTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Service")
        .description("See your next upcoming service reminder.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CarTrackerWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            AccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct CarTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CarTrackerHomeWidget()
        CarTrackerLockScreenWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    CarTrackerHomeWidget()
} timeline: {
    CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
}

#Preview("Medium", as: .systemMedium) {
    CarTrackerHomeWidget()
} timeline: {
    CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
}

#Preview("Large", as: .systemLarge) {
    CarTrackerHomeWidget()
} timeline: {
    CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
}

#Preview("Circular", as: .accessoryCircular) {
    CarTrackerLockScreenWidget()
} timeline: {
    CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    CarTrackerLockScreenWidget()
} timeline: {
    CarTrackerWidgetEntry(date: Date(), data: WidgetDataService.previewData)
}
