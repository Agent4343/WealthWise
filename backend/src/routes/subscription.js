const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// GET /subscription/status — Return current entitlement
router.get('/status', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('user_id', req.userId)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single();

    if (error || !data) {
      return res.json({
        tier: 'free',
        status: 'active',
        user_id: req.userId
      });
    }

    // Check if subscription has expired
    if (data.expires_at && new Date(data.expires_at) < new Date()) {
      if (data.status === 'active') {
        await supabase
          .from('subscriptions')
          .update({ status: 'expired' })
          .eq('id', data.id);
        data.status = 'expired';
        data.tier = 'free';
      }
    }

    res.json(data);
  } catch (error) {
    console.error('Subscription status error:', error);
    res.status(500).json({ error: 'Failed to fetch subscription status' });
  }
});

module.exports = router;
