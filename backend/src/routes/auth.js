const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const { authMiddleware } = require('../middleware/auth');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// POST /auth/sync — Sync Supabase auth user to app_users table on first login
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    const user = req.user;

    const { data: existing } = await supabase
      .from('app_users')
      .select('id')
      .eq('id', user.id)
      .single();

    if (existing) {
      // Update last active
      await supabase
        .from('app_users')
        .update({ last_active_at: new Date().toISOString() })
        .eq('id', user.id);

      return res.json({ message: 'User synced', created: false });
    }

    // Create new app user
    const { error } = await supabase.from('app_users').insert({
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || null,
      province: null,
      created_at: new Date().toISOString(),
      last_active_at: new Date().toISOString()
    });

    if (error) throw error;

    // Create default free subscription
    await supabase.from('subscriptions').insert({
      user_id: user.id,
      tier: 'free',
      status: 'active'
    });

    res.json({ message: 'User synced', created: true });
  } catch (error) {
    console.error('Auth sync error:', error);
    res.status(500).json({ error: 'Failed to sync user' });
  }
});

module.exports = router;
