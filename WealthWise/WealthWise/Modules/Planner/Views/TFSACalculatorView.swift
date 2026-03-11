import SwiftUI

struct TFSACalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Stepper("Current Age: \(viewModel.tfsaAge)",
                            value: $viewModel.tfsaAge, in: 18...64)

                    HStack {
                        Text("Annual Contribution")
                        Spacer()
                        TextField("$7,000", text: $viewModel.tfsaAnnualContribution)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Existing Balance")
                        Spacer()
                        TextField("$0", text: $viewModel.tfsaExistingBalance)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    VStack(alignment: .leading) {
                        Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.tfsaAnnualReturn))")
                            .font(.subheadline)
                        Slider(value: $viewModel.tfsaAnnualReturn, in: 0.02...0.12, step: 0.005)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.calculateTFSA()
                } label: {
                    Text("Calculate")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)

                if let result = viewModel.tfsaResult {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Tax-Free Value at 65")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(result.finalBalance, compact: true))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.teal)
                        }

                        Divider()

                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Contributed")
                                Spacer()
                                Text(CurrencyFormatter.format(result.totalContributions, compact: true))
                                    .fontWeight(.medium)
                            }
                            HStack {
                                Text("Tax-Free Growth")
                                Spacer()
                                Text(CurrencyFormatter.format(result.totalInterestEarned, compact: true))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.green)
                            }
                            HStack {
                                Text("Tax Saved vs Taxable Account")
                                    .font(.subheadline)
                                Spacer()
                                Text(CurrencyFormatter.format(result.totalInterestEarned * 0.25, compact: true))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.teal)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("All growth inside a TFSA is completely tax-free — including interest, dividends, and capital gains. This is not financial advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("TFSA Optimizer")
        .onAppear { viewModel.calculateTFSA() }
    }
}
