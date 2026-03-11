import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Binding var showSignUp: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.accent)

                    Text("Welcome Back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue your financial journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("your@email.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("••••••••", text: $viewModel.password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button("Forgot password?") {
                        Task { await viewModel.resetPassword() }
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)

                // Sign In Button
                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSignIn ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!viewModel.canSignIn)
                .padding(.horizontal)

                // Switch to Sign Up
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Create one") {
                        showSignUp = true
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
        }
        .alert("Notice", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
