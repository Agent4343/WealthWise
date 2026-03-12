import Foundation

enum Configuration {
    // MARK: - Supabase
    static var supabaseURL: String {
        guard let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !url.isEmpty else {
            fatalError("SUPABASE_URL not configured in Info.plist")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not configured in Info.plist")
        }
        return key
    }

    // MARK: - API
    static var apiBaseURL: String {
        guard let url = Bundle.main.infoDictionary?["API_BASE_URL"] as? String, !url.isEmpty else {
            fatalError("API_BASE_URL not configured in Info.plist")
        }
        return url
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
