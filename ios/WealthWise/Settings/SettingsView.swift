import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showSignOutConfirm = false
    @State private var showPaywall = false

    private var user: AppUser? { authManager.currentUser }
    private var tier: SubscriptionTier { user?.subscriptionTier ?? .free }

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                if let user = user {
                    Section("Account") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(user.email)
                                    .font(.headline)
                                Text(tier.displayName + " Plan")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Subscription Section
                Section("Subscription") {
                    HStack {
                        Label("Current Plan", systemImage: "crown.fill")
                        Spacer()
                        Text(tier.displayName)
                            .foregroundStyle(.secondary)
                    }

                    if tier != .premium {
                        Button(action: { showPaywall = true }) {
                            Label(tier == .free ? "Upgrade to Basic" : "Upgrade to Premium",
                                  systemImage: "arrow.up.circle")
                        }
                    }

                    Button(action: {
                        Task {
                            if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                await UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                }

                // Notifications Section
                Section("Notifications") {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        Label("Notification Settings", systemImage: "bell")
                    }
                }

                // About Section
                Section("About WealthWise") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://wealthwise.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }

                    Link(destination: URL(string: "https://wealthwise.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }

                    Link(destination: URL(string: "https://wealthwise.app/disclaimer")!) {
                        Label("Financial Disclaimer", systemImage: "exclamationmark.triangle")
                    }
                }

                // Disclaimer Section
                Section {
                    Text("WealthWise provides financial education content only. Nothing in this app constitutes personalized financial, investment, or tax advice under OSC regulations. Always consult a Certified Financial Planner (CFP) for advice specific to your situation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(requiredTier: tier == .free ? .basic : .premium)
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Notifications Settings View

struct NotificationsSettingsView: View {
    @State private var weeklyBriefEnabled: Bool = true
    @State private var reminderEnabled: Bool = true

    var body: some View {
        Form {
            Section("WealthWise Notifications") {
                Toggle(isOn: $weeklyBriefEnabled) {
                    VStack(alignment: .leading) {
                        Text("Monday Brief Ready")
                        Text("Notified when your weekly brief is available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $reminderEnabled) {
                    VStack(alignment: .leading) {
                        Text("Weekly Reminder")
                        Text("Nudge if you haven't opened the app in 7 days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("Notification preferences are managed by iOS. You can also manage them in Settings > WealthWise > Notifications.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
