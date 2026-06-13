import UserNotifications

enum NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sendExpiryNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Caffeine session ended"
        content.body = "Your timed session has expired. Your display will now sleep normally."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "caffeine.expiry",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
