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

// PUT /profile — Update financial profile
router.put('/', async (req, res) => {
  try {
    const {
      age, retirement_age, income_bracket,
      rrsp_room_used, tfsa_room_used, current_savings,
      monthly_contribution, risk_tolerance
    } = req.body;

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
