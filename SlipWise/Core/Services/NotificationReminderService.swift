import Foundation
import UserNotifications

final class NotificationReminderService {
    static let dailyReminderIdentifier = "dailyUpdateReminder"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "SlipDee Reminder"
        content.body = "อย่าลืมบันทึกรายจ่ายวันนี้ใน SlipDee 😊"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: hour, minute: minute),
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
        try await center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyReminderIdentifier])
    }

    func refreshDailyReminderIfNeeded(
        isEnabled: Bool,
        hour: Int,
        minute: Int
    ) async {
        // TODO: Phase 2 can switch to a smarter reminder that only fires when
        // there are no transactions recorded for the current day.
        guard isEnabled else {
            cancelDailyReminder()
            return
        }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            cancelDailyReminder()
            return
        }

        do {
            try await scheduleDailyReminder(hour: hour, minute: minute)
        } catch {
            cancelDailyReminder()
        }
    }
}
