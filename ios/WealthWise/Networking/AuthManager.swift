import Foundation
import Security

// MARK: - AuthManager
// Manages authentication state, Supabase session persistence, and token storage.
// Uses Keychain for secure token storage.

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AppUser?
    @Published var isLoading: Bool = false

    private let keychainService = "com.themoneyschool.wealthwise"
    private let accessTokenKey = "wealthwise_access_token"
    private let refreshTokenKey = "wealthwise_refresh_token"

    private init() {
        // Restore session from Keychain on app launch
        Task {
            await restoreSession()
        }
    }

    // MARK: - Session Restoration

    private func restoreSession() async {
        guard let token = readFromKeychain(key: accessTokenKey), !token.isEmpty else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await APIService.shared.syncUser(token: token)
            self.currentUser = user
            self.isAuthenticated = true
        } catch APIError.unauthorized {
            // Token expired — clear stored credentials
            clearKeychain()
        } catch {
            // Network error — still restore auth state optimistically
            self.isAuthenticated = true
        }
    }

    // MARK: - Sign In / Sign Up

    /// Called after successful Supabase sign-in. Stores the token and syncs with backend.
    func handleSignIn(accessToken: String, refreshToken: String) async throws {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        saveToKeychain(key: refreshTokenKey, value: refreshToken)

        let user = try await APIService.shared.syncUser(token: accessToken)
        self.currentUser = user
        self.isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() {
        clearKeychain()
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Token Access

    var accessToken: String? {
        readFromKeychain(key: accessTokenKey)
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: key,
        ]

        // Delete existing before adding
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func clearKeychain() {
        for key in [accessTokenKey, refreshTokenKey] {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccount: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
