import SwiftUI

struct FeeDragCalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Portfolio Value")
                        Spacer()
                        TextField("$100,000", text: $viewModel.feePortfolioValue)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    VStack(alignment: .leading) {
                        Text("Index ETF MER: \(String(format: "%.2f%%", viewModel.feeLowMER * 100))")
                            .font(.subheadline)
                        Slider(value: $viewModel.feeLowMER, in: 0.0005...0.005, step: 0.0005)
                            .tint(.green)
                    }

                    VStack(alignment: .leading) {
                        Text("Mutual Fund MER: \(String(format: "%.2f%%", viewModel.feeHighMER * 100))")
                            .font(.subheadline)
                        Slider(value: $viewModel.feeHighMER, in: 0.01...0.035, step: 0.001)
                            .tint(.red)
                    }

                    Stepper("Years: \(viewModel.feeYears)",
                            value: $viewModel.feeYears, in: 5...50)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.calculateFeeDrag()
                } label: {
                    Text("Calculate Fee Impact")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)

                if let lowBalance = viewModel.feeLowBalance,
                   let highBalance = viewModel.feeHighBalance,
                   let cost = viewModel.feeDragCost {

                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("Cost of Higher Fees")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(cost, compact: true))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.red)
                            Text("lost to fee drag over \(viewModel.feeYears) years")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            VStack {
                                Label("Index ETF", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(CurrencyFormatter.format(lowBalance, compact: true))
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                Text("\(String(format: "%.2f%%", viewModel.feeLowMER * 100)) MER")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Text("vs")
                                .foregroundStyle(.secondary)
                            Spacer()

                            VStack {
                                Label("Mutual Fund", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Text(CurrencyFormatter.format(highBalance, compact: true))
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                Text("\(String(format: "%.2f%%", viewModel.feeHighMER * 100)) MER")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Calculations assume a 7% gross annual return before fees. Actual returns will vary. This is not financial advice.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Fee Drag Calculator")
        .onAppear { viewModel.calculateFeeDrag() }
    }
}
