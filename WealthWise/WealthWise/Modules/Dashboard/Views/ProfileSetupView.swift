import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("About You") {
                    Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 18...80)

                    Stepper("Retirement Age: \(viewModel.retirementAge)",
                            value: $viewModel.retirementAge, in: 45...80)

                    Picker("Province", selection: $viewModel.selectedProvince) {
                        ForEach(Province.allCases, id: \.self) { province in
                            Text(province.displayName).tag(province)
                        }
                    }

                    Picker("Income Bracket", selection: $viewModel.selectedIncomeBracket) {
                        ForEach(IncomeBracket.allCases, id: \.self) { bracket in
                            Text(bracket.displayName).tag(bracket)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Total Savings & Investments")
                        Spacer()
                        TextField("$0", text: $viewModel.currentSavings)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    Text("Include everything: TFSA + RRSP + RESP + non-registered + cash savings")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Your Accounts")
                } footer: {
                    Text("Enter your total above, then break out how much is in each account below.")
                }

                Section("Account Breakdown") {
                    HStack {
                        Text("In RRSP")
                        Spacer()
                        TextField("$0", text: $viewModel.rrspRoomUsed)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("In TFSA")
                        Spacer()
                        TextField("$0", text: $viewModel.tfsaRoomUsed)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("Monthly Contribution")
                        Spacer()
                        TextField("$0", text: $viewModel.monthlyContribution)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }

                Section("Risk Tolerance") {
                    Picker("Risk Tolerance", selection: $viewModel.riskTolerance) {
                        ForEach(RiskTolerance.allCases, id: \.self) { tolerance in
                            VStack(alignment: .leading) {
                                Text(tolerance.displayName)
                            }
                            .tag(tolerance)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(viewModel.riskTolerance.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        Task { await viewModel.saveProfile() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Profile")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Financial Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
