import SwiftUI

@main
struct WealthWiseApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
                } else {
                    AuthContainerView()
                }
            }
            .environmentObject(authManager)
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
