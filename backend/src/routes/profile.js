const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// GET /profile — Fetch user financial profile
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('financial_profiles')
      .select('*')
      .eq('user_id', req.userId)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json(data);
  } catch (error) {
    console.error('Fetch profile error:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Valid income bracket values
const VALID_INCOME_BRACKETS = [
  'under_30k', '30k_50k', '50k_75k', '75k_100k',
  '100k_150k', '150k_200k', 'over_200k'
];

const VALID_RISK_TOLERANCES = ['conservative', 'balanced', 'growth'];

// PUT /profile — Update financial profile
router.put('/', async (req, res) => {
  try {
    const {
      age, retirement_age, income_bracket,
      rrsp_room_used, tfsa_room_used, current_savings,
      monthly_contribution, risk_tolerance
    } = req.body;

    // Input validation
    const errors = [];

    if (age !== undefined) {
      if (!Number.isInteger(age) || age < 16 || age > 100) {
        errors.push('age must be an integer between 16 and 100');
      }
    }

    if (retirement_age !== undefined) {
      if (!Number.isInteger(retirement_age) || retirement_age > 100) {
        errors.push('retirement_age must be an integer with a maximum of 100');
      } else if (age !== undefined && retirement_age <= age) {
        errors.push('retirement_age must be greater than current age');
      }
    }

    if (income_bracket !== undefined) {
      if (!VALID_INCOME_BRACKETS.includes(income_bracket)) {
        errors.push(`income_bracket must be one of: ${VALID_INCOME_BRACKETS.join(', ')}`);
      }
    }

    if (monthly_contribution !== undefined) {
      if (typeof monthly_contribution !== 'number' || monthly_contribution < 0) {
        errors.push('monthly_contribution must be a number >= 0');
      }
    }

    if (current_savings !== undefined) {
      if (typeof current_savings !== 'number' || current_savings < 0) {
        errors.push('current_savings must be a number >= 0');
      }
    }

    if (tfsa_room_used !== undefined) {
      if (typeof tfsa_room_used !== 'number' || tfsa_room_used < 0) {
        errors.push('tfsa_room_used must be a number >= 0');
      }
    }

    if (rrsp_room_used !== undefined) {
      if (typeof rrsp_room_used !== 'number' || rrsp_room_used < 0) {
        errors.push('rrsp_room_used must be a number >= 0');
      }
    }

    if (risk_tolerance !== undefined) {
      if (!VALID_RISK_TOLERANCES.includes(risk_tolerance)) {
        errors.push(`risk_tolerance must be one of: ${VALID_RISK_TOLERANCES.join(', ')}`);
      }
    }

    if (errors.length > 0) {
      return res.status(400).json({ error: 'Validation failed', details: errors });
    }

    // Check if profile exists
    const { data: existing } = await supabase
      .from('financial_profiles')
      .select('id')
      .eq('user_id', req.userId)
      .single();

    const profileData = {
      user_id: req.userId,
      age,
      retirement_age,
      income_bracket,
      rrsp_room_used,
      tfsa_room_used,
      current_savings,
      monthly_contribution,
      risk_tolerance,
      updated_at: new Date().toISOString()
    };

    let result;
    if (existing) {
      result = await supabase
        .from('financial_profiles')
        .update(profileData)
        .eq('user_id', req.userId)
        .select()
        .single();
    } else {
      result = await supabase
        .from('financial_profiles')
        .insert(profileData)
        .select()
        .single();
    }

    if (result.error) throw result.error;
    res.json(result.data);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

module.exports = router;
