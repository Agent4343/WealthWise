import SwiftUI

struct RRSPCalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Annual Income")
                        Spacer()
                        TextField("$85,000", text: $viewModel.rrspIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    Picker("Province", selection: $viewModel.rrspProvince) {
                        ForEach(Province.allCases, id: \.self) { province in
                            Text(province.displayName).tag(province)
                        }
                    }

                    HStack {
                        Text("RRSP Contribution")
                        Spacer()
                        TextField("$10,000", text: $viewModel.rrspContribution)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.calculateRRSP()
                } label: {
                    Text("Calculate Tax Refund")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)

                if let refund = viewModel.rrspTaxRefund, let netCost = viewModel.rrspNetCost {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Estimated Tax Refund")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(refund, compact: true))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                        }

                        Divider()

                        HStack {
                            VStack {
                                Text("Contribution")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(CurrencyFormatter.format(Double(viewModel.rrspContribution) ?? 0, compact: true))
                                    .font(.headline)
                            }
                            Spacer()
                            Image(systemName: "minus")
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack {
                                Text("Tax Refund")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(CurrencyFormatter.format(refund, compact: true))
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                            Image(systemName: "equal")
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack {
                                Text("Net Cost")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(CurrencyFormatter.format(netCost, compact: true))
                                    .font(.headline)
                                    .foregroundStyle(.green)
                            }
                        }

                        Text("The 1-2 Punch: Invest the \(CurrencyFormatter.format(refund, compact: true)) refund into your TFSA for double tax-sheltered growth.")
                            .font(.caption)
                            .foregroundStyle(.accent)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Tax refund estimate based on marginal tax rates. Actual refund depends on total income, deductions, and credits. Consult a tax professional. This is not financial advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("RRSP Tax Saver")
        .onAppear { viewModel.calculateRRSP() }
    }
}
