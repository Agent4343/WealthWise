const express = require('express');
const supabase = require('../config/supabase');
const { authMiddleware, basicMiddleware } = require('../middleware/auth');

const router = express.Router();

// All profile routes require authentication
router.use(authMiddleware);

/**
 * GET /profile
 * Returns the authenticated user's financial profile.
 */
router.get('/', basicMiddleware, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('financial_profiles')
      .select('*')
      .eq('user_id', req.user.id)
      .single();

    if (error && error.code === 'PGRST116') {
      // No profile yet — return empty shell
      return res.status(200).json({ profile: null });
    }

    if (error) {
      console.error('Profile fetch error:', error);
      return res.status(500).json({ error: 'Failed to fetch profile' });
    }

    return res.status(200).json({ profile: data });
  } catch (err) {
    console.error('Profile GET exception:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /profile
 * Creates or updates the authenticated user's financial profile.
 * Validates input fields before persisting.
 */
router.put('/', basicMiddleware, async (req, res) => {
  try {
    const {
      current_age,
      target_retirement_age,
      province,
      income_bracket,
      tfsa_room_used,
      rrsp_room_available,
      current_savings_balance,
      current_rrsp_balance,
      current_tfsa_balance,
      monthly_savings_amount,
      monthly_savings_target,
      risk_tolerance,
    } = req.body;

    // Validate required fields
    if (current_age !== undefined && (current_age < 18 || current_age > 100)) {
      return res.status(400).json({ error: 'current_age must be between 18 and 100' });
    }

    if (target_retirement_age !== undefined && (target_retirement_age < 45 || target_retirement_age > 80)) {
      return res.status(400).json({ error: 'target_retirement_age must be between 45 and 80' });
    }

    const validProvinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];
    if (province !== undefined && !validProvinces.includes(province)) {
      return res.status(400).json({ error: `province must be one of: ${validProvinces.join(', ')}` });
    }

    const validRiskTolerances = ['conservative', 'balanced', 'growth'];
    if (risk_tolerance !== undefined && !validRiskTolerances.includes(risk_tolerance)) {
      return res.status(400).json({ error: 'risk_tolerance must be conservative, balanced, or growth' });
    }

    const profileData = {
      user_id: req.user.id,
      updated_at: new Date().toISOString(),
    };

    // Only include defined fields
    const fields = {
      current_age,
      target_retirement_age,
      province,
      income_bracket,
      tfsa_room_used,
      rrsp_room_available,
      current_savings_balance,
      current_rrsp_balance,
      current_tfsa_balance,
      monthly_savings_amount,
      monthly_savings_target,
      risk_tolerance,
    };

    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        profileData[key] = value;
      }
    }

    const { data, error } = await supabase
      .from('financial_profiles')
      .upsert(profileData, { onConflict: 'user_id' })
      .select()
      .single();

    if (error) {
      console.error('Profile update error:', error);
      return res.status(500).json({ error: 'Failed to update profile' });
    }

    return res.status(200).json({ profile: data });
  } catch (err) {
    console.error('Profile PUT exception:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
