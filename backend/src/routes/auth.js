const express = require('express');
const supabase = require('../config/supabase');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /auth/sync
 * Syncs a Supabase auth user to the app_users table on first login.
 * Called by the iOS app immediately after sign-in or sign-up.
 */
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const { id: userId, email } = req.user;

    // Upsert the user record — safe to call on every login
    const { data, error } = await supabase
      .from('app_users')
      .upsert(
        {
          id: userId,
          email,
          subscription_tier: 'free',
          updated_at: new Date().toISOString(),
        },
        {
          onConflict: 'id',
          ignoreDuplicates: false,
        },
      )
      .select()
      .single();

    if (error) {
      console.error('Auth sync error:', error);
      return res.status(500).json({ error: 'Failed to sync user record' });
    }

    return res.status(200).json({
      user: {
        id: data.id,
        email: data.email,
        subscription_tier: data.subscription_tier,
        created_at: data.created_at,
      },
    });
  } catch (err) {
    console.error('Auth sync exception:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
