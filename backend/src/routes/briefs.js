const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const { premiumMiddleware } = require('../middleware/auth');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// GET /briefs — Fetch paginated list of Weekly Briefs for user
router.get('/', premiumMiddleware, async (req, res) => {
  try {
    const page = Math.max(0, parseInt(req.query.page) || 0);
    const limit = Math.min(Math.max(1, parseInt(req.query.limit) || 20), 50);
    const offset = page * limit;

    const { data, error } = await supabase
      .from('weekly_briefs')
      .select('*')
      .eq('user_id', req.userId)
      .order('week_of', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    console.error('Fetch briefs error:', error);
    res.status(500).json({ error: 'Failed to fetch briefs' });
  }
});

// GET /briefs/:id — Fetch single Weekly Brief
router.get('/:id', premiumMiddleware, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('weekly_briefs')
      .select('*')
      .eq('id', req.params.id)
      .eq('user_id', req.userId)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Brief not found' });
    }

    res.json(data);
  } catch (error) {
    console.error('Fetch brief error:', error);
    res.status(500).json({ error: 'Failed to fetch brief' });
  }
});

module.exports = router;
