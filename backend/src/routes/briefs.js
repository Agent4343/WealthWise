const express = require('express');
const supabase = require('../config/supabase');
const { authMiddleware, premiumMiddleware } = require('../middleware/auth');

const router = express.Router();

// All brief routes require authentication + Premium
router.use(authMiddleware);
router.use(premiumMiddleware);

/**
 * GET /briefs
 * Returns a paginated list of Weekly Briefs for the authenticated Premium user.
 * Query params: page (default 1), limit (default 10, max 20)
 */
router.get('/', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(20, Math.max(1, parseInt(req.query.limit, 10) || 10));
    const offset = (page - 1) * limit;

    const { data, error, count } = await supabase
      .from('user_reports')
      .select('id, week_start_date, generated_at, title, summary_snippet', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('generated_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      console.error('Briefs list error:', error);
      return res.status(500).json({ error: 'Failed to fetch briefs' });
    }

    return res.status(200).json({
      briefs: data || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        total_pages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (err) {
    console.error('Briefs GET exception:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /briefs/:id
 * Returns a single Weekly Brief by ID for the authenticated Premium user.
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({ error: 'Invalid brief ID format' });
    }

    const { data, error } = await supabase
      .from('user_reports')
      .select('*')
      .eq('id', id)
      .eq('user_id', req.user.id)
      .single();

    if (error && error.code === 'PGRST116') {
      return res.status(404).json({ error: 'Brief not found' });
    }

    if (error) {
      console.error('Brief fetch error:', error);
      return res.status(500).json({ error: 'Failed to fetch brief' });
    }

    return res.status(200).json({ brief: data });
  } catch (err) {
    console.error('Brief GET/:id exception:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
