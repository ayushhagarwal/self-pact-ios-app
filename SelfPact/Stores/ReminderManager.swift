import Foundation
import UserNotifications

enum ReminderManager {
    static func requestPermissionAndSchedule(for pact: Pact) async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }
            await scheduleReminder(for: pact)
        } catch {
            return
        }
    }

    static func scheduleReminder(for pact: Pact) async {
        await scheduleCheckInReminders(for: pact)
        await scheduleReviewReminder(for: pact)
    }

    static func cancelReminders(for pactId: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: allReminderIdentifiers(for: pactId)
        )
    }

    private static func scheduleCheckInReminders(for pact: Pact) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: checkInReminderIdentifiers(for: pact.id) + legacyReminderIdentifiers(for: pact.id))

        guard pact.status == .sealed || pact.status == .draft else { return }
        guard let weekdays = pact.reminderWeekdays, !weekdays.isEmpty else { return }

        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            dateComponents.weekday = weekday
            dateComponents.hour = 9
            dateComponents.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Check in on your goal"
            content.body = pact.nextAction ?? "Take one small step today."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: checkInReminderIdentifier(for: pact.id, weekday: weekday),
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    private static func scheduleReviewReminder(for pact: Pact) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reviewReminderIdentifier(for: pact.id)])

        guard pact.status == .sealed else { return }
        guard pact.targetDate > Date() else { return }

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: pact.targetDate)
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Review your goal"
        content.body = "\(pact.title) is ready to close the loop."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: reviewReminderIdentifier(for: pact.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private static func checkInReminderIdentifiers(for pactId: String) -> [String] {
        (1...7).map { checkInReminderIdentifier(for: pactId, weekday: $0) }
    }

    private static func legacyReminderIdentifiers(for pactId: String) -> [String] {
        (1...7).map { "goal-reminder-\(pactId)-\($0)" }
    }

    private static func allReminderIdentifiers(for pactId: String) -> [String] {
        checkInReminderIdentifiers(for: pactId) + legacyReminderIdentifiers(for: pactId) + [reviewReminderIdentifier(for: pactId)]
    }

    private static func checkInReminderIdentifier(for pactId: String, weekday: Int) -> String {
        "goal-check-in-reminder-\(pactId)-\(weekday)"
    }

    private static func reviewReminderIdentifier(for pactId: String) -> String {
        "goal-review-reminder-\(pactId)"
    }
}
