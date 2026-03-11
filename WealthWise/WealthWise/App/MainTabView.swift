import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var subscriptionVM: SubscriptionViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(subscriptionVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ChapterListView()
                .environmentObject(subscriptionVM)
                .tabItem {
                    Label("School", systemImage: "book.fill")
                }
                .tag(1)

            PlannerTabView()
                .environmentObject(subscriptionVM)
                .tabItem {
                    Label("Planner", systemImage: "function")
                }
                .tag(2)

            BriefListView()
                .environmentObject(subscriptionVM)
                .tabItem {
                    Label("Briefs", systemImage: "newspaper.fill")
                }
                .tag(3)

            SettingsView()
                .environmentObject(subscriptionVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.accent)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBriefs)) { _ in
            selectedTab = 3
        }
    }
}
