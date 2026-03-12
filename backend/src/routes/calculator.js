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

  // 5. Investment Fees (10%) — assume moderate score without detailed data
  const feeScore = 65;
  components.push({
    name: 'Investment Fees',
    score: feeScore,
    weight: 0.10,
    description: 'Fee assessment based on general profile',
    suggestion: 'Switch to index ETFs with MERs under 0.25%'
  });

  // 6. Diversification (10%)
  const diversificationScore = 60;
  components.push({
    name: 'Diversification',
    score: diversificationScore,
    weight: 0.10,
    description: 'Diversification assessment based on profile',
    suggestion: 'Use a single all-in-one ETF like XBAL or VGRO'
  });

  // 7. Net Worth Ratio (15%) — savings vs income
  const netWorthScore = 70;
  components.push({
    name: 'Net Worth Ratio',
    score: netWorthScore,
    weight: 0.15,
    description: 'Savings-to-income assessment based on general profile',
    suggestion: 'Aim for total savings equal to at least 1x your annual income'
  });

  const totalScore = Math.round(
    components.reduce((sum, c) => sum + c.score * c.weight, 0)
  );

  const grade = totalScore >= 85 ? 'Excellent'
    : totalScore >= 70 ? 'Great'
    : totalScore >= 55 ? 'Good'
    : totalScore >= 40 ? 'Fair'
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
      balance = balance * (1 + monthlyRate) + (profile.monthly_contribution || 0);
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
    'over_150k': 200000
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
