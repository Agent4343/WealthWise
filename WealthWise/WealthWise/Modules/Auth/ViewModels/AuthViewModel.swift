import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authManager = AuthManager.shared

    var isValidEmail: Bool {
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: emailRegex) != nil
    }

    var isValidPassword: Bool {
        password.count >= 8
    }

    var canSignIn: Bool {
        isValidEmail && isValidPassword && !isLoading
    }

    var canSignUp: Bool {
        isValidEmail && isValidPassword && !fullName.isEmpty && !isLoading
    }

    func signIn() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func signUp() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authManager.signUp(
                email: email,
                password: password,
                fullName: fullName.isEmpty ? nil : fullName
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func resetPassword() async {
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }

        isLoading = true
        do {
            try await authManager.resetPassword(email: email)
            errorMessage = "Password reset email sent. Check your inbox."
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
