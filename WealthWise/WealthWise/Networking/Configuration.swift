import Foundation

enum Configuration {
    // MARK: - Supabase
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://vvlvmgakrrdkzurdaymi.supabase.co"
    }

    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bHZtZ2FrcnJka3p1cmRheW1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxODI1NzUsImV4cCI6MjA4ODc1ODU3NX0.5qJbY4oxI2pPdP1mitdIzR0_AHM6znNxkvybiWBpKzg"
    }

    // MARK: - API
    static var apiBaseURL: String {
        ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://wealthwise-production-ed51.up.railway.app"
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
