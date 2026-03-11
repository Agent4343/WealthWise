import Foundation

enum Configuration {
    // MARK: - Supabase
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co"
    }

    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "your-anon-key"
    }

    // MARK: - API
    static var apiBaseURL: String {
        ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://your-railway-app.up.railway.app"
    }

    // MARK: - App
    static let appName = "WealthWise"
    static let bundleID = "com.themileschool.wealthwise"
    static let appStoreID = "" // Set after App Store submission

    // MARK: - Links
    static let privacyPolicyURL = URL(string: "https://wealthwise.ca/privacy")!
    static let termsOfServiceURL = URL(string: "https://wealthwise.ca/terms")!
    static let supportEmail = "support@wealthwise.ca"
}
