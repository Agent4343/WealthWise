import SwiftUI

@main
struct WealthWiseApp: App {
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authManager.isLoading {
                SplashView()
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("WealthWise")
                .font(.largeTitle.bold())

            ProgressView()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager

    private var tier: SubscriptionTier {
        authManager.currentUser?.subscriptionTier ?? .free
    }

    var body: some View {
        TabView {
            ChapterListView()
                .tabItem {
                    Label("School", systemImage: "graduationcap.fill")
                }

            Group {
                if tier.canAccessDashboard {
                    DashboardView()
                } else {
                    LockedTabView(feature: "Dashboard", requiredTier: .basic)
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "slider.horizontal.3")
                }

            Group {
                if tier.canAccessWeeklyBriefs {
                    BriefsListView()
                } else {
                    LockedTabView(feature: "Monday Briefs", requiredTier: .premium)
                }
            }
            .tabItem {
                Label("Briefs", systemImage: "doc.text.fill")
            }
            .badge(tier.canAccessWeeklyBriefs ? nil : "PRO")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Locked Tab View

struct LockedTabView: View {
    let feature: String
    let requiredTier: SubscriptionTier
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(feature + " Locked")
                    .font(.title2.bold())
                Text("Unlock with \(requiredTier.displayName) to access \(feature).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Upgrade to \(requiredTier.displayName)") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showPaywall) {
            PaywallView(requiredTier: requiredTier)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager.shared)
}
