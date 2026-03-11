import Foundation

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var profile: FinancialProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showProfileSetup: Bool = false

    private let authManager = AuthManager.shared

    func loadProfile() async {
        guard let token = authManager.accessToken else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profile = try await APIService.shared.getProfile(token: token)
            if profile == nil {
                showProfileSetup = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile(_ updates: ProfileUpdateRequest) async {
        guard let token = authManager.accessToken else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profile = try await APIService.shared.updateProfile(token: token, updates: updates)
            showProfileSetup = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Derived Metrics

    var netWorth: Double {
        let rrsp = profile?.currentRrspBalance ?? 0
        let tfsa = profile?.currentTfsaBalance ?? 0
        let other = profile?.currentSavingsBalance ?? 0
        return rrsp + tfsa + other
    }

    var savingsRate: Double? {
        guard let monthly = profile?.monthlySavingsAmount,
              let target = profile?.monthlySavingsTarget,
              target > 0 else { return nil }
        return monthly / target
    }

    var tfsaRoomRemaining: Double? {
        // TFSA cumulative room from 2009 — updated to 2025: $95,000 total
        let totalRoom = 95_000.0
        guard let used = profile?.tfsaRoomUsed else { return nil }
        return max(0, totalRoom - used)
    }
}
