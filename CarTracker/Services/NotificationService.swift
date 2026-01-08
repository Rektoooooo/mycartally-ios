//
//  NotificationService.swift
//  CarTracker
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleReminderNotification(for reminder: Reminder, car: Car?) {
        guard let dueDate = reminder.dueDate else { return }

        // Calculate notification date (N days before due)
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(
            byAdding: .day,
            value: -reminder.notifyDaysBefore,
            to: dueDate
        ) else { return }

        // Don't schedule if notification date is in the past
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.sound = .default

        if let car = car {
            content.body = "\(car.displayName) - Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            content.body = "Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        }

        // Create date components for trigger
        let triggerComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: notificationDate) ?? notificationDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func cancelNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.id.uuidString]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Reschedule All

    func rescheduleAllReminders(_ reminders: [Reminder], cars: [Car]) {
        // Cancel existing
        cancelAllNotifications()

        // Schedule new
        for reminder in reminders where !reminder.isCompleted {
            let car = cars.first { $0.id == reminder.car?.id }
            scheduleReminderNotification(for: reminder, car: car)
        }
    }
}
