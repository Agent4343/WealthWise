import Foundation
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private let supabase = SupabaseClientManager.shared.client

    private init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            await APIService.shared.setAuthToken(session.accessToken)
            isAuthenticated = true
            await loadUser()
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func signUp(email: String, password: String, fullName: String?) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: fullName.map { ["full_name": .string($0)] } ?? [:]
        )
        await APIService.shared.setAuthToken(response.session?.accessToken)
        isAuthenticated = true

        try? await APIService.shared.syncAuth()
        await loadUser()
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        await APIService.shared.setAuthToken(session.accessToken)
        isAuthenticated = true

        try? await APIService.shared.syncAuth()
        await loadUser()
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        await APIService.shared.setAuthToken(nil)
        isAuthenticated = false
        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    private func loadUser() async {
        do {
            let response: AppUser = try await supabase
                .from("app_users")
                .select()
                .eq("id", value: supabase.auth.session.user.id.uuidString)
                .single()
                .execute()
                .value
            currentUser = response
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}
