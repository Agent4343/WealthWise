import SwiftUI

// MARK: - Profile Setup View

struct ProfileSetupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var currentAge: String = ""
    @State private var retirementAge: String = "65"
    @State private var selectedProvince: CanadianProvince = .on
    @State private var incomeBracket: String = "$50,000–$75,000"
    @State private var tfsaRoomUsed: String = ""
    @State private var rrspRoomAvailable: String = ""
    @State private var rrspBalance: String = ""
    @State private var tfsaBalance: String = ""
    @State private var otherSavings: String = ""
    @State private var monthlySavings: String = ""
    @State private var monthlySavingsTarget: String = ""
    @State private var riskTolerance: RiskTolerance = .balanced

    private let incomeBrackets = [
        "Under $30,000",
        "$30,000–$50,000",
        "$50,000–$75,000",
        "$75,000–$100,000",
        "$100,000–$150,000",
        "$150,000–$200,000",
        "Over $200,000",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("About You") {
                    HStack {
                        Text("Current Age")
                        Spacer()
                        TextField("e.g. 32", text: $currentAge)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Target Retirement Age")
                        Spacer()
                        TextField("e.g. 65", text: $retirementAge)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    Picker("Province", selection: $selectedProvince) {
                        ForEach(CanadianProvince.allCases, id: \.self) { province in
                            Text(province.displayName).tag(province)
                        }
                    }
                    Picker("Income Bracket", selection: $incomeBracket) {
                        ForEach(incomeBrackets, id: \.self) { bracket in
                            Text(bracket).tag(bracket)
                        }
                    }
                }

                Section("Registered Accounts") {
                    LabeledCurrencyField(label: "RRSP Balance", value: $rrspBalance)
                    LabeledCurrencyField(label: "RRSP Room Available", value: $rrspRoomAvailable,
                                        hint: "From your CRA My Account")
                    LabeledCurrencyField(label: "TFSA Balance", value: $tfsaBalance)
                    LabeledCurrencyField(label: "TFSA Room Used", value: $tfsaRoomUsed)
                }

                Section("Other Savings & Goals") {
                    LabeledCurrencyField(label: "Other Savings / Investments", value: $otherSavings)
                    LabeledCurrencyField(label: "Monthly Savings Amount", value: $monthlySavings)
                    LabeledCurrencyField(label: "Monthly Savings Target", value: $monthlySavingsTarget)
                }

                Section("Risk Tolerance") {
                    Picker("Risk Profile", selection: $riskTolerance) {
                        ForEach(RiskTolerance.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Financial Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear(perform: prefillFromProfile)
        }
    }

    private func prefillFromProfile() {
        guard let p = viewModel.profile else { return }
        if let age = p.currentAge { currentAge = "\(age)" }
        if let retAge = p.targetRetirementAge { retirementAge = "\(retAge)" }
        if let prov = p.province { selectedProvince = prov }
        if let ib = p.incomeBracket { incomeBracket = ib }
        if let v = p.tfsaRoomUsed { tfsaRoomUsed = "\(Int(v))" }
        if let v = p.rrspRoomAvailable { rrspRoomAvailable = "\(Int(v))" }
        if let v = p.currentRrspBalance { rrspBalance = "\(Int(v))" }
        if let v = p.currentTfsaBalance { tfsaBalance = "\(Int(v))" }
        if let v = p.currentSavingsBalance { otherSavings = "\(Int(v))" }
        if let v = p.monthlySavingsAmount { monthlySavings = "\(Int(v))" }
        if let v = p.monthlySavingsTarget { monthlySavingsTarget = "\(Int(v))" }
        if let rt = p.riskTolerance { riskTolerance = rt }
    }

    private func save() async {
        var request = ProfileUpdateRequest()
        request.currentAge = Int(currentAge)
        request.targetRetirementAge = Int(retirementAge)
        request.province = selectedProvince.rawValue
        request.incomeBracket = incomeBracket
        request.tfsaRoomUsed = Double(tfsaRoomUsed)
        request.rrspRoomAvailable = Double(rrspRoomAvailable)
        request.currentRrspBalance = Double(rrspBalance)
        request.currentTfsaBalance = Double(tfsaBalance)
        request.currentSavingsBalance = Double(otherSavings)
        request.monthlySavingsAmount = Double(monthlySavings)
        request.monthlySavingsTarget = Double(monthlySavingsTarget)
        request.riskTolerance = riskTolerance.rawValue

        await viewModel.saveProfile(request)
    }
}

// MARK: - Labeled Currency Field

struct LabeledCurrencyField: View {
    let label: String
    @Binding var value: String
    var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                HStack(spacing: 4) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $value)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ProfileSetupView(viewModel: DashboardViewModel())
}
