import SwiftUI

struct FIRECalculatorView: View {
    @ObservedObject var viewModel: PlannerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mode Toggle
                Picker("Mode", selection: $viewModel.fireMode) {
                    Text("Just Me").tag(PlannerViewModel.PlanMode.solo)
                    Text("With Partner").tag(PlannerViewModel.PlanMode.couple)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    HStack {
                        Text(viewModel.fireMode == .couple ? "Combined Monthly Expenses" : "Monthly Expenses")
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

                // Your savings for time-to-FIRE
                VStack(spacing: 12) {
                    Text(viewModel.fireMode == .couple ? "YOUR SAVINGS" : "SAVINGS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("Current Savings")
                        Spacer()
                        TextField("$50,000", text: $viewModel.fireCurrentSavings)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("Monthly Contribution")
                        Spacer()
                        TextField("$1,500", text: $viewModel.fireMonthlyContrib)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    Stepper("Current Age: \(viewModel.fireCurrentAge)",
                            value: $viewModel.fireCurrentAge, in: 18...70)

                    VStack(alignment: .leading) {
                        Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.fireReturnRate))")
                            .font(.subheadline)
                        Slider(value: $viewModel.fireReturnRate, in: 0.03...0.12, step: 0.005)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Partner savings
                if viewModel.fireMode == .couple {
                    VStack(spacing: 12) {
                        Text("PARTNER'S SAVINGS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Text("Current Savings")
                            Spacer()
                            TextField("$30,000", text: $viewModel.firePartnerSavings)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        HStack {
                            Text("Monthly Contribution")
                            Spacer()
                            TextField("$1,000", text: $viewModel.firePartnerContrib)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }

                        VStack(alignment: .leading) {
                            Text("Expected Return: \(CurrencyFormatter.formatPercent(viewModel.firePartnerReturn))")
                                .font(.subheadline)
                            Slider(value: $viewModel.firePartnerReturn, in: 0.03...0.12, step: 0.005)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

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
                            Text(viewModel.fireMode == .couple ? "Combined FIRE Number" : "Your FIRE Number")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(fireNumber, compact: true))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }

                        Text(viewModel.fireMode == .couple
                             ? "When your combined portfolio reaches this amount, you can both potentially live off the returns."
                             : "When your investment portfolio reaches this amount, you can potentially live off the returns without working.")
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

                    // Years to FIRE
                    if let yearsToFire = viewModel.fireYearsToTarget {
                        VStack(spacing: 8) {
                            Text("🔥")
                                .font(.system(size: 40))

                            if yearsToFire <= 0 {
                                Text("You've Already Reached FIRE!")
                                    .font(.title3.bold())
                                    .foregroundStyle(.green)
                                Text("Your savings already exceed your FIRE number.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                let fireAge = viewModel.fireCurrentAge + Int(ceil(yearsToFire))
                                Text(viewModel.fireMode == .couple
                                     ? "\(Int(ceil(yearsToFire))) Years to FIRE Together"
                                     : "\(Int(ceil(yearsToFire))) Years to FIRE")
                                    .font(.title3.bold())
                                    .foregroundStyle(yearsToFire <= 15 ? .green : yearsToFire <= 25 ? .yellow : .red)
                                Text(viewModel.fireMode == .couple
                                     ? "At your combined savings rate, you'll reach FIRE around age \(fireAge)."
                                     : "At your current savings rate, you'll reach FIRE at age \(fireAge).")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

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
