import Foundation
import Combine

// MARK: - Auth ViewModel

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showOnboarding: Bool = false

    private let authManager = AuthManager.shared

    // MARK: - Sign In

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Supabase auth is handled via the Supabase Swift SDK on the client side.
        // After successful auth, the iOS app calls handleSignIn with the tokens.
        // This ViewModel coordinates the flow.
        // In the actual implementation, this calls supabase.auth.signInWithPassword(...)
        // For now, this is a placeholder that the Supabase SDK integration will fill.
        do {
            try await performSupabaseSignIn()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await performSupabaseSignUp()
            showOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        authManager.signOut()
    }

    // MARK: - Supabase Integration Stubs
    // These are implemented by integrating the Supabase Swift SDK.

    private func performSupabaseSignIn() async throws {
        // Integration point: supabase.auth.signInWithPassword(email: email, password: password)
        // On success: try await authManager.handleSignIn(accessToken: session.accessToken, refreshToken: session.refreshToken)
        throw AuthError.notImplemented
    }

    private func performSupabaseSignUp() async throws {
        // Integration point: supabase.auth.signUp(email: email, password: password)
        // On success: try await authManager.handleSignIn(accessToken: session.accessToken, refreshToken: session.refreshToken)
        throw AuthError.notImplemented
    }
}

enum AuthError: Error, LocalizedError {
    case notImplemented
    case invalidCredentials
    case networkError

    var errorDescription: String? {
        switch self {
        case .notImplemented: return "Authentication service not yet configured."
        case .invalidCredentials: return "Invalid email or password."
        case .networkError: return "Network error. Please check your connection."
        }
    }
}
