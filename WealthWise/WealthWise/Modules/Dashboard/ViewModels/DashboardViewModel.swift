import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var profile: FinancialProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showProfileSetup = false

    // Profile form fields
    @Published var age: Int = 30
    @Published var retirementAge: Int = 65
    @Published var selectedProvince: Province = .on
    @Published var selectedIncomeBracket: IncomeBracket = .fiftyTo75k
    @Published var rrspRoomUsed: String = ""
    @Published var tfsaRoomUsed: String = ""
    @Published var currentSavings: String = ""
    @Published var monthlyContribution: String = ""
    @Published var riskTolerance: RiskTolerance = .balanced

    var yearsToRetirement: Int {
        max(0, retirementAge - age)
    }

    var projectedRetirement: CompoundInterestCalculator.RetirementResult? {
        guard let profile = profile else { return nil }
        return CompoundInterestCalculator.retirementBuilder(
            currentAge: profile.age,
            retirementAge: profile.retirementAge,
            monthlyContribution: profile.monthlyContribution,
            annualReturn: profile.riskTolerance.expectedReturn,
            existingSavings: profile.currentSavings
        )
    }

    // TFSA max room based on eligibility since 2009
    var tfsaMaxRoom: Double {
        TaxCalculator.tfsaCumulativeRoom // $102,000 through 2026
    }

    var tfsaRoomRemaining: Double {
        tfsaMaxRoom - (profile?.tfsaRoomUsed ?? 0)
    }

    // RRSP: 18% of previous year income up to $33,810 (2026)
    var estimatedRrspRoom: Double {
        guard let profile = profile else { return 0 }
        let bracketMidpoint = IncomeBracket(rawValue: profile.incomeBracket)?.midpoint ?? 75_000
        return min(bracketMidpoint * 0.18, TaxCalculator.rrspMaxDeduction)
    }

    var rrspRoomRemaining: Double {
        estimatedRrspRoom - (profile?.rrspRoomUsed ?? 0)
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedProfile = try await APIService.shared.fetchProfile()
            profile = fetchedProfile
            populateFormFromProfile(fetchedProfile)
        } catch {
            // No profile yet — show setup
            showProfileSetup = true
        }
    }

    func saveProfile() async {
        isLoading = true
        defer { isLoading = false }

        let newProfile = FinancialProfile(
            id: profile?.id ?? UUID(),
            userId: profile?.userId ?? UUID(),
            age: age,
            retirementAge: retirementAge,
            incomeBracket: selectedIncomeBracket.rawValue,
            rrspRoomUsed: Double(rrspRoomUsed) ?? 0,
            tfsaRoomUsed: Double(tfsaRoomUsed) ?? 0,
            currentSavings: Double(currentSavings) ?? 0,
            monthlyContribution: Double(monthlyContribution) ?? 0,
            riskTolerance: riskTolerance,
            updatedAt: Date()
        )

        do {
            let updated = try await APIService.shared.updateProfile(newProfile)
            profile = updated
            showProfileSetup = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func populateFormFromProfile(_ profile: FinancialProfile) {
        age = profile.age
        retirementAge = profile.retirementAge
        selectedProvince = Province(rawValue: "") ?? .on
        selectedIncomeBracket = IncomeBracket(rawValue: profile.incomeBracket) ?? .fiftyTo75k
        rrspRoomUsed = String(format: "%.0f", profile.rrspRoomUsed)
        tfsaRoomUsed = String(format: "%.0f", profile.tfsaRoomUsed)
        currentSavings = String(format: "%.0f", profile.currentSavings)
        monthlyContribution = String(format: "%.0f", profile.monthlyContribution)
        riskTolerance = profile.riskTolerance
    }
}
