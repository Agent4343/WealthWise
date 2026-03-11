import Foundation

// MARK: - Configuration

enum Config {
    /// Base URL for the WealthWise Railway API.
    /// Override by setting WEALTHWISE_API_URL in the scheme environment or Info.plist.
    static var apiBaseURL: String {
        if let override = Bundle.main.infoDictionary?["WEALTHWISE_API_URL"] as? String,
           !override.isEmpty {
            return override
        }
#if DEBUG
        return "http://localhost:3000"
#else
        return "https://api.wealthwise.app"
#endif
    }

    /// Supabase project URL
    static var supabaseURL: String {
        Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    }

    /// Supabase anon (public) key — safe to include in the app bundle
    static var supabaseAnonKey: String {
        Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    }
}
