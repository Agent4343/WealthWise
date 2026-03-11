import SwiftUI

struct FIRECalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Monthly Expenses")
                        Spacer()
                        TextField("$4,000", text: $viewModel.fireMonthlyExpenses)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    VStack(alignment: .leading) {
                        Text("Withdrawal Rate: \(CurrencyFormatter.formatPercent(viewModel.fireWithdrawalRate))")
                            .font(.subheadline)
                        Slider(value: $viewModel.fireWithdrawalRate, in: 0.03...0.05, step: 0.0025)
                    }

                    Text("The 4% rule: withdraw 4% of your portfolio annually, adjusting for inflation. Historically, this has sustained portfolios for 30+ years.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.calculateFIRE()
                } label: {
                    Text("Calculate FIRE Number")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)

                if let fireNumber = viewModel.fireNumber {
                    VStack(spacing: 16) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)

                        VStack(spacing: 4) {
                            Text("Your FIRE Number")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(fireNumber, compact: true))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }

                        Text("When your investment portfolio reaches this amount, you can potentially live off the returns without working.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Divider()

                        VStack(spacing: 8) {
                            HStack {
                                Text("Annual Expenses")
                                Spacer()
                                Text(CurrencyFormatter.format((Double(viewModel.fireMonthlyExpenses) ?? 0) * 12, compact: true))
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Safe Withdrawal Rate")
                                Spacer()
                                Text(CurrencyFormatter.formatPercent(viewModel.fireWithdrawalRate))
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Annual Investment Income")
                                Spacer()
                                Text(CurrencyFormatter.format(fireNumber * viewModel.fireWithdrawalRate, compact: true))
                                    .foregroundStyle(.green)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("FIRE calculations are based on the Trinity Study and historical market data. Actual results depend on market conditions, inflation, and personal circumstances. This is not financial advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("FIRE Calculator")
        .onAppear { viewModel.calculateFIRE() }
    }
}
