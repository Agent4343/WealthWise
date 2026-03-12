const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// GET /calculator/money-score — Calculate Money Score from user profile
router.get('/money-score', async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('financial_profiles')
      .select('*')
      .eq('user_id', req.userId)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'Profile not found. Complete your profile first.' });
    }

    const score = calculateMoneyScore(profile);
    res.json(score);
  } catch (error) {
    console.error('Money score error:', error);
    res.status(500).json({ error: 'Failed to calculate money score' });
  }
});

// GET /calculator/retirement-projection — Calculate retirement projection
router.get('/retirement-projection', async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('financial_profiles')
      .select('*')
      .eq('user_id', req.userId)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'Profile not found. Complete your profile first.' });
    }

    const projection = calculateRetirementProjection(profile);
    res.json(projection);
  } catch (error) {
    console.error('Retirement projection error:', error);
    res.status(500).json({ error: 'Failed to calculate retirement projection' });
  }
});

// Money Score calculation — mirrors iOS MoneyScoreCalculator
function calculateMoneyScore(profile) {
  const components = [];

  // 1. Savings Rate (20%)
  const incomeMidpoint = getIncomeMidpoint(profile.income_bracket);
  const monthlyIncome = incomeMidpoint / 12;
  const savingsRate = monthlyIncome > 0 ? (profile.monthly_contribution / monthlyIncome) * 100 : 0;
  const savingsScore = Math.min(Math.round(savingsRate * 5), 100);
  components.push({
    name: 'Savings Rate',
    score: savingsScore,
    weight: 0.20,
    description: `Saving ${savingsRate.toFixed(1)}% of gross income`,
    suggestion: 'Aim for 20% savings rate — automate transfers on payday'
  });

  // 2. Emergency Fund (15%)
  const monthlyExpenses = monthlyIncome * 0.7;
  const emergencyMonths = monthlyExpenses > 0 ? profile.current_savings / monthlyExpenses : 0;
  const emergencyScore = Math.min(Math.round((emergencyMonths / 6) * 100), 100);
  components.push({
    name: 'Emergency Fund',
    score: emergencyScore,
    weight: 0.15,
    description: `${emergencyMonths.toFixed(1)} months of expenses covered`,
    suggestion: 'Build 3-6 months expenses in a HISA'
  });

  // 3. TFSA Usage (15%)
  const tfsaMax = 109000; // Cumulative through 2026
  const tfsaUsage = Math.min((profile.tfsa_room_used / tfsaMax) * 100, 100);
  const tfsaScore = Math.round(tfsaUsage);
  components.push({
    name: 'TFSA Usage',
    score: tfsaScore,
    weight: 0.15,
    description: `$${profile.tfsa_room_used.toLocaleString()} of $${tfsaMax.toLocaleString()} used`,
    suggestion: 'Max your TFSA before non-registered accounts'
  });

  // 4. RRSP Usage (15%)
  const rrspMax = Math.min(incomeMidpoint * 0.18, 33810); // 2026 limit
  const rrspUsage = rrspMax > 0 ? Math.min((profile.rrsp_room_used / rrspMax) * 100, 100) : 0;
  const rrspScore = Math.round(rrspUsage);
  components.push({
    name: 'RRSP Usage',
    score: rrspScore,
    weight: 0.15,
    description: `Using ${rrspUsage.toFixed(0)}% of annual RRSP room`,
    suggestion: 'Contribute to RRSP for immediate tax refund'
  });

  // 5. Investment Fees (10%) — based on risk tolerance as proxy
  const riskTolerance = profile.risk_tolerance || 'balanced';
  const feeScore = riskTolerance === 'growth' ? 85 : riskTolerance === 'balanced' ? 65 : 50;
  components.push({
    name: 'Investment Fees',
    score: feeScore,
    weight: 0.10,
    description: riskTolerance === 'growth' ? 'Growth profile suggests low-cost investing' : 'Consider reviewing your investment fees',
    suggestion: 'Switch to index ETFs with MERs under 0.25%'
  });

  // 6. Diversification (10%) — based on whether using both RRSP and TFSA
  const usesBoth = (profile.tfsa_room_used || 0) > 0 && (profile.rrsp_room_used || 0) > 0;
  const usesEither = (profile.tfsa_room_used || 0) > 0 || (profile.rrsp_room_used || 0) > 0;
  const diversificationScore = usesBoth ? 80 : usesEither ? 50 : 10;
  components.push({
    name: 'Diversification',
    score: diversificationScore,
    weight: 0.10,
    description: usesBoth ? 'Using both RRSP and TFSA accounts' : 'Consider using multiple account types',
    suggestion: 'Use the 1-2 Punch: contribute to RRSP, invest the refund in your TFSA'
  });

  // 7. Net Worth Ratio (15%) — savings vs income
  const savingsToIncome = incomeMidpoint > 0 ? (profile.current_savings || 0) / incomeMidpoint : 0;
  const netWorthScore = savingsToIncome >= 1.0 ? 90 : savingsToIncome >= 0.5 ? 75 : savingsToIncome >= 0.25 ? 60 : 40;
  components.push({
    name: 'Net Worth Ratio',
    score: netWorthScore,
    weight: 0.15,
    description: `Savings-to-income ratio: ${savingsToIncome.toFixed(1)}x`,
    suggestion: 'Aim for total savings equal to at least 1x your annual income'
  });

  let weightedTotal = components.reduce((sum, c) => sum + c.score * c.weight, 0);

  // Critical-failure penalty: if a core metric is near zero, cap the score
  if (savingsScore < 10) weightedTotal = Math.min(weightedTotal, 45);
  if (emergencyScore < 10) weightedTotal = Math.min(weightedTotal, 50);

  const totalScore = Math.round(Math.min(100, weightedTotal));

  const grade = totalScore >= 85 ? 'Excellent'
    : totalScore >= 75 ? 'Great'
    : totalScore >= 60 ? 'Good'
    : totalScore >= 45 ? 'Fair'
    : 'Needs Work';

  const recommendations = [];
  const sorted = [...components].sort((a, b) => a.score - b.score);
  for (const c of sorted.slice(0, 3)) {
    if (c.score < 70) recommendations.push(c.suggestion);
  }

  return {
    total_score: totalScore,
    grade,
    components: components.map(c => ({
      name: c.name,
      score: c.score,
      weight: c.weight,
      weighted: Math.round(c.score * c.weight * 10) / 10,
      description: c.description,
      suggestion: c.suggestion
    })),
    recommendations
  };
}

// Retirement projection — mirrors iOS CompoundInterestCalculator
function calculateRetirementProjection(profile) {
  const yearsToRetirement = (profile.retirement_age || 65) - (profile.age || 30);
  const annualReturn = getExpectedReturn(profile.risk_tolerance);
  const monthlyRate = annualReturn / 12;
  const months = yearsToRetirement * 12;

  let balance = profile.current_savings || 0;
  const yearlyData = [];

  for (let year = 1; year <= yearsToRetirement; year++) {
    for (let m = 0; m < 12; m++) {
      balance = (balance + (profile.monthly_contribution || 0)) * (1 + monthlyRate);
    }
    yearlyData.push({
      year,
      age: (profile.age || 30) + year,
      balance: Math.round(balance)
    });
  }

  const finalBalance = Math.round(balance);
  const monthlyIncomeAt4Percent = Math.round((finalBalance * 0.04) / 12);

  return {
    final_balance: finalBalance,
    monthly_income_at_4_percent: monthlyIncomeAt4Percent,
    years_to_retirement: yearsToRetirement,
    current_savings: profile.current_savings || 0,
    monthly_contribution: profile.monthly_contribution || 0,
    progress_percent: finalBalance > 0 ? Math.round(((profile.current_savings || 0) / finalBalance) * 1000) / 1000 : 0,
    yearly_data: yearlyData
  };
}

function getIncomeMidpoint(bracket) {
  const midpoints = {
    'under_30k': 25000,
    '30k_50k': 40000,
    '50k_75k': 62500,
    '75k_100k': 87500,
    '100k_150k': 125000,
    '150k_200k': 175000,
    'over_200k': 250000
  };
  return midpoints[bracket] || 62500;
}

function getExpectedReturn(tolerance) {
  const returns = {
    'conservative': 0.05,
    'balanced': 0.07,
    'growth': 0.09
  };
  return returns[tolerance] || 0.07;
}

module.exports = router;
