import SwiftUI

@main
struct WealthWiseApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    splashView
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(subscriptionVM)
                        .sheet(isPresented: $subscriptionVM.showPaywall) {
                            PaywallView()
                                .environmentObject(subscriptionVM)
                        }
                        .onAppear {
                            notificationManager.resetEngagementReminder()
                            if subscriptionVM.currentTier >= .premium {
                                notificationManager.scheduleMondayBriefReminder()
                            }
                        }
                        .onChange(of: subscriptionVM.currentTier) { _, newTier in
                            if newTier >= .premium {
                                notificationManager.scheduleMondayBriefReminder()
                            } else {
                                notificationManager.cancelMondayBriefReminder()
                            }
                        }
                } else {
                    AuthContainerView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(notificationManager)
        }
    }

    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            Text("WealthWise")
                .font(.largeTitle.bold())

            Text("The Financial Education App\nCanada Never Had")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ProgressView()
                .padding(.top, 24)
        }
    }
}

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.registerNotificationCategories()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNS] Failed to register: \(error)")
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        switch categoryIdentifier {
        case "WEEKLY_BRIEF":
            // Navigate to Briefs tab
            NotificationCenter.default.post(name: .navigateToBriefs, object: nil)
        default:
            break
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let navigateToBriefs = Notification.Name("navigateToBriefs")
}
