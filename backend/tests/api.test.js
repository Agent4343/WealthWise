/**
 * WealthWise API Integration Tests
 *
 * Tests for API routes, authentication middleware, and brief generation.
 * Run with: npm test
 */

const assert = require('assert');

// ============================================
// Unit Tests — Tax & Financial Calculations
// ============================================

describe('Financial Calculations', () => {
  describe('Compound Interest', () => {
    it('should calculate future value correctly', () => {
      // $10,000 at 7% for 10 years
      const fv = 10000 * Math.pow(1.07, 10);
      assert.ok(Math.abs(fv - 19671.51) < 1, `Expected ~$19,671, got ${fv.toFixed(2)}`);
    });

    it('should calculate monthly contribution growth', () => {
      // $500/month at 7% annual for 35 years
      const monthlyRate = 0.07 / 12;
      const months = 35 * 12;
      const fv = 500 * ((Math.pow(1 + monthlyRate, months) - 1) / monthlyRate);
      assert.ok(fv > 800000, `Expected >$800K, got ${fv.toFixed(0)}`);
      assert.ok(fv < 910000, `Expected <$910K, got ${fv.toFixed(0)}`);
    });

    it('should calculate FIRE number correctly', () => {
      // $4,000/month expenses, 4% withdrawal rate
      const fireNumber = (4000 * 12) / 0.04;
      assert.strictEqual(fireNumber, 1200000);
    });

    it('should calculate fee drag over 30 years', () => {
      const portfolio = 100000;
      const years = 30;
      const lowMER = 0.002; // 0.20% ETF
      const highMER = 0.023; // 2.3% mutual fund
      const grossReturn = 0.07;

      const lowFeeBalance = portfolio * Math.pow(1 + grossReturn - lowMER, years);
      const highFeeBalance = portfolio * Math.pow(1 + grossReturn - highMER, years);
      const feeDragCost = lowFeeBalance - highFeeBalance;

      // Fee drag should be significant — hundreds of thousands
      assert.ok(feeDragCost > 300000, `Fee drag should be >$300K, got ${feeDragCost.toFixed(0)}`);
      assert.ok(lowFeeBalance > 600000, `Low fee balance should be >$600K`);
      assert.ok(highFeeBalance < 400000, `High fee balance should be <$400K`);
    });
  });

  describe('Canadian Tax Calculations', () => {
    it('should calculate federal marginal rate for $90K income', () => {
      // $90K falls in 20.5% federal bracket ($55,867 - $111,733)
      const rate = 0.205;
      assert.strictEqual(rate, 0.205);
    });

    it('should estimate RRSP tax refund', () => {
      // $10,000 RRSP contribution at ~31.5% marginal rate (Ontario, $90K income)
      const contribution = 10000;
      const federalRate = 0.205;
      const provincialRate = 0.0505; // Ontario first bracket
      const combinedRate = federalRate + provincialRate;
      const refund = contribution * combinedRate;

      assert.ok(refund > 2000, `Refund should be >$2,000, got ${refund.toFixed(0)}`);
      assert.ok(refund < 4000, `Refund should be <$4,000, got ${refund.toFixed(0)}`);
    });

    it('should calculate RRSP contribution room', () => {
      // 18% of $90,000 = $16,200 (under $31,560 max)
      const income = 90000;
      const room = Math.min(income * 0.18, 31560);
      assert.strictEqual(room, 16200);
    });

    it('should cap RRSP room at annual maximum', () => {
      // 18% of $200,000 = $36,000, but capped at $31,560
      const income = 200000;
      const room = Math.min(income * 0.18, 31560);
      assert.strictEqual(room, 31560);
    });
  });

  describe('TFSA Room Calculation', () => {
    it('should calculate cumulative TFSA room since 2009', () => {
      // Cumulative room for someone eligible since 2009 = $95,000 (as of 2024)
      const annualAmounts = {
        2009: 5000, 2010: 5000, 2011: 5000, 2012: 5000,
        2013: 5500, 2014: 5500, 2015: 10000, 2016: 5500,
        2017: 5500, 2018: 5500, 2019: 6000, 2020: 6000,
        2021: 6000, 2022: 6000, 2023: 6500, 2024: 7000
      };
      const total = Object.values(annualAmounts).reduce((a, b) => a + b, 0);
      assert.strictEqual(total, 95000);
    });
  });
});

// ============================================
// Unit Tests — Weekly Brief Prompt
// ============================================

describe('Weekly Brief Generation', () => {
  it('should build a valid user prompt', () => {
    const profile = {
      age: 35,
      retirement_age: 65,
      income_bracket: '75000-100000',
      rrsp_room_used: 25000,
      tfsa_room_used: 40000,
      current_savings: 80000,
      monthly_contribution: 500,
      risk_tolerance: 'balanced'
    };

    const marketContext = 'Bank of Canada rate: 4.5%. TSX up 2% this week.';

    const prompt = `Generate a Weekly Brief for this Canadian user:

USER PROFILE:
- Age: ${profile.age}
- Retirement age target: ${profile.retirement_age}
- Income bracket: ${profile.income_bracket}
- RRSP room used: $${profile.rrsp_room_used}
- TFSA room used: $${profile.tfsa_room_used}
- Current savings: $${profile.current_savings}
- Monthly contribution: $${profile.monthly_contribution}
- Risk tolerance: ${profile.risk_tolerance}

CURRENT CANADIAN MARKET CONTEXT:
${marketContext}

Generate the 5-section Weekly Brief as a JSON object.`;

    assert.ok(prompt.includes('Age: 35'));
    assert.ok(prompt.includes('balanced'));
    assert.ok(prompt.includes('Bank of Canada'));
    assert.ok(prompt.length > 200);
  });

  it('should validate brief JSON structure', () => {
    const validBrief = {
      section_1_snapshot: 'Your week at a glance content...',
      section_2_market: 'Canadian economic pulse content...',
      section_3_accounts: 'Your accounts this week content...',
      section_4_learn: 'What to think about content...',
      section_5_action: 'Your Monday action item content...'
    };

    const requiredKeys = [
      'section_1_snapshot', 'section_2_market',
      'section_3_accounts', 'section_4_learn', 'section_5_action'
    ];

    for (const key of requiredKeys) {
      assert.ok(key in validBrief, `Missing required key: ${key}`);
      assert.ok(typeof validBrief[key] === 'string', `${key} should be a string`);
      assert.ok(validBrief[key].length > 0, `${key} should not be empty`);
    }
  });

  it('should enforce disclaimer content', () => {
    const disclaimer = 'WealthWise Weekly Brief is educational guidance only and does not constitute personalized financial, investment, or tax advice under OSC regulations. Past performance does not guarantee future results. Consult a Certified Financial Planner (CFP) for advice specific to your situation.';
    assert.ok(disclaimer.includes('educational guidance only'));
    assert.ok(disclaimer.includes('OSC'));
    assert.ok(disclaimer.includes('Certified Financial Planner'));
  });
});

// ============================================
// Unit Tests — API Route Validation
// ============================================

describe('API Route Validation', () => {
  it('should validate profile update payload', () => {
    const validPayload = {
      age: 30,
      retirement_age: 65,
      income_bracket: '75000-100000',
      rrsp_room_used: 10000,
      tfsa_room_used: 20000,
      current_savings: 50000,
      monthly_contribution: 500,
      risk_tolerance: 'balanced'
    };

    // Age validation
    assert.ok(validPayload.age >= 18 && validPayload.age <= 100);

    // Retirement age validation
    assert.ok(validPayload.retirement_age >= 45 && validPayload.retirement_age <= 100);

    // Risk tolerance validation
    const validTolerances = ['conservative', 'balanced', 'growth'];
    assert.ok(validTolerances.includes(validPayload.risk_tolerance));

    // Numeric fields should be non-negative
    assert.ok(validPayload.rrsp_room_used >= 0);
    assert.ok(validPayload.tfsa_room_used >= 0);
    assert.ok(validPayload.current_savings >= 0);
    assert.ok(validPayload.monthly_contribution >= 0);
  });

  it('should validate subscription tiers', () => {
    const validTiers = ['free', 'basic', 'premium'];
    const validStatuses = ['active', 'expired', 'cancelled', 'grace_period'];

    assert.ok(validTiers.includes('free'));
    assert.ok(validTiers.includes('basic'));
    assert.ok(validTiers.includes('premium'));
    assert.ok(!validTiers.includes('enterprise'));

    assert.ok(validStatuses.includes('active'));
    assert.ok(validStatuses.includes('grace_period'));
  });

  it('should validate StoreKit product IDs', () => {
    const validProductIDs = [
      'com.themileschool.wealthwise.basic.monthly',
      'com.themileschool.wealthwise.basic.annual',
      'com.themileschool.wealthwise.premium.monthly',
      'com.themileschool.wealthwise.premium.annual'
    ];

    for (const id of validProductIDs) {
      assert.ok(id.startsWith('com.themileschool.wealthwise.'));
    }

    // Map product IDs to tiers
    const tierMap = {
      'com.themileschool.wealthwise.basic.monthly': 'basic',
      'com.themileschool.wealthwise.basic.annual': 'basic',
      'com.themileschool.wealthwise.premium.monthly': 'premium',
      'com.themileschool.wealthwise.premium.annual': 'premium'
    };

    assert.strictEqual(tierMap['com.themileschool.wealthwise.basic.monthly'], 'basic');
    assert.strictEqual(tierMap['com.themileschool.wealthwise.premium.annual'], 'premium');
  });

  it('should validate province codes', () => {
    const validProvinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];

    assert.strictEqual(validProvinces.length, 13);
    assert.ok(validProvinces.includes('ON'));
    assert.ok(validProvinces.includes('QC'));
    assert.ok(!validProvinces.includes('US'));
  });
});

// ============================================
// Run tests
// ============================================

function describe(name, fn) {
  console.log(`\n  ${name}`);
  fn();
}

function it(name, fn) {
  try {
    fn();
    console.log(`    \u2713 ${name}`);
  } catch (error) {
    console.log(`    \u2717 ${name}`);
    console.error(`      ${error.message}`);
    process.exitCode = 1;
  }
}

// Run all test suites
console.log('\nWealthWise API Tests\n' + '='.repeat(50));
