import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                registerForRemoteNotifications()
            }
            return granted
        } catch {
            print("[NOTIFICATIONS] Authorization request failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Remote Notifications (APNs for Weekly Brief)

    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called from AppDelegate when APNs device token is received
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[NOTIFICATIONS] APNs device token: \(token)")
        // Send token to Railway backend for push delivery
        Task {
            await sendTokenToServer(token)
        }
    }

    private func sendTokenToServer(_ token: String) async {
        // Store device token on server for Monday morning push delivery
        do {
            struct TokenPayload: Encodable {
                let deviceToken: String
                let platform: String = "ios"
            }
            // API endpoint to register push token
            guard let url = URL(string: "\(Configuration.apiBaseURL)/push/register") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(TokenPayload(deviceToken: token))

            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            print("[NOTIFICATIONS] Failed to register token with server: \(error)")
        }
    }

    // MARK: - Local Notifications (Engagement Nudges)

    /// Schedule a reminder if the user hasn't opened the app in 7 days
    func scheduleEngagementReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Your Money Doesn't Take Days Off"
        content.body = "You haven't checked WealthWise in a while. Your weekly progress and financial insights are waiting."
        content.sound = .default
        content.categoryIdentifier = "ENGAGEMENT_REMINDER"

        // Fire 7 days from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7 * 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "engagement_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NOTIFICATIONS] Failed to schedule engagement reminder: \(error)")
            }
        }
    }

    /// Reschedule the engagement reminder — call on every app open
    func resetEngagementReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["engagement_reminder"]
        )
        scheduleEngagementReminder()
    }

    /// Schedule a local notification for Monday morning brief (backup for push)
    func scheduleMondayBriefReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Brief Is Ready"
        content.body = "Your personalized Monday morning financial briefing is waiting for you in WealthWise."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_BRIEF"

        // Every Monday at 7:00 AM local time
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monday_brief_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NOTIFICATIONS] Failed to schedule Monday reminder: \(error)")
            }
        }
    }

    /// Remove Monday brief notification (when user downgrades from Premium)
    func cancelMondayBriefReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["monday_brief_reminder"]
        )
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let briefCategory = UNNotificationCategory(
            identifier: "WEEKLY_BRIEF",
            actions: [
                UNNotificationAction(identifier: "VIEW_BRIEF", title: "View Brief", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        let engagementCategory = UNNotificationCategory(
            identifier: "ENGAGEMENT_REMINDER",
            actions: [
                UNNotificationAction(identifier: "OPEN_APP", title: "Open WealthWise", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            briefCategory,
            engagementCategory
        ])
    }
}
