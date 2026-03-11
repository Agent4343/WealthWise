process.env.NODE_ENV = 'test';

const { buildUserContext } = require('../src/services/aiEngine');
const { buildEmailText, buildEmailHtml } = require('../src/services/emailService');
const { getMondayDate } = require('../src/jobs/weeklyBrief');

describe('buildUserContext', () => {
  it('returns general guidance message for null profile', () => {
    const result = buildUserContext(null);
    expect(result).toContain('no financial profile');
  });

  it('includes age and retirement info when present', () => {
    const profile = { current_age: 32, target_retirement_age: 65, province: 'ON', risk_tolerance: 'balanced' };
    const result = buildUserContext(profile);
    expect(result).toContain('32');
    expect(result).toContain('65');
    expect(result).toContain('ON');
    expect(result).toContain('balanced');
  });

  it('includes financial balances when present', () => {
    const profile = {
      current_age: 40,
      rrsp_room_available: 25000,
      tfsa_room_used: 40000,
      current_rrsp_balance: 80000,
      current_tfsa_balance: 30000,
      monthly_savings_amount: 1000,
    };
    const result = buildUserContext(profile);
    expect(result).toContain('25,000');
    expect(result).toContain('40,000');
    expect(result).toContain('80,000');
    expect(result).toContain('30,000');
    expect(result).toContain('1,000');
  });

  it('handles empty profile object gracefully', () => {
    const result = buildUserContext({});
    expect(result).toContain('partially complete');
  });
});

describe('buildEmailText', () => {
  const sampleBrief = {
    week_at_a_glance: 'This week is looking solid.',
    canadian_economic_pulse: 'Bank of Canada held rates steady.',
    accounts_this_week: 'Your RRSP room is still available.',
    what_to_think_about: 'Consider index fund diversification.',
    monday_action_item: 'Log into your CRA My Account to confirm RRSP room.',
    disclaimer: 'Educational guidance only.',
  };

  it('includes all 5 sections', () => {
    const text = buildEmailText(sampleBrief, 'Monday, March 9, 2026');
    expect(text).toContain('This week is looking solid.');
    expect(text).toContain('Bank of Canada held rates steady.');
    expect(text).toContain('Your RRSP room is still available.');
    expect(text).toContain('Consider index fund diversification.');
    expect(text).toContain('Log into your CRA My Account');
    expect(text).toContain('Educational guidance only.');
  });

  it('includes the formatted date in header', () => {
    const text = buildEmailText(sampleBrief, 'Monday, March 9, 2026');
    expect(text).toContain('Monday, March 9, 2026');
  });
});

describe('buildEmailHtml', () => {
  const sampleBrief = {
    week_at_a_glance: 'Solid week ahead.',
    canadian_economic_pulse: 'Rates stable.',
    accounts_this_week: 'Good standing.',
    what_to_think_about: 'Index funds.',
    monday_action_item: 'Check RRSP room.',
    disclaimer: 'Educational only.',
  };

  it('produces valid HTML with all sections', () => {
    const html = buildEmailHtml(sampleBrief, 'March 9, 2026');
    expect(html).toContain('<!DOCTYPE html>');
    expect(html).toContain('Solid week ahead.');
    expect(html).toContain('Rates stable.');
    expect(html).toContain('Good standing.');
    expect(html).toContain('Index funds.');
    expect(html).toContain('Check RRSP room.');
    expect(html).toContain('Educational only.');
  });

  it('escapes HTML characters in brief content', () => {
    const briefWithHtml = {
      ...sampleBrief,
      week_at_a_glance: '<script>alert("xss")</script>',
    };
    const html = buildEmailHtml(briefWithHtml, 'March 9, 2026');
    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;');
  });
});

describe('getMondayDate', () => {
  it('returns a valid ISO date string', () => {
    const date = getMondayDate();
    expect(date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('returns a Monday date', () => {
    const date = getMondayDate();
    const dayOfWeek = new Date(date + 'T12:00:00Z').getUTCDay();
    expect(dayOfWeek).toBe(1); // 1 = Monday
  });
});
