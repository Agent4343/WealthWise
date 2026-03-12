const express = require('express');
const router = express.Router();
const { verifyAdminKey } = require('../middleware/auth');
const { generateWeeklyBriefs } = require('../jobs/weeklyBriefGenerator');

// POST /admin/generate — Manually trigger AI brief generation (dev/test)
// Note: authMiddleware is applied at the router level in index.js,
// so requests must have a valid user JWT AND a valid admin key.
router.post('/generate', async (req, res) => {
  const adminKey = req.headers['x-admin-key'];

  if (!verifyAdminKey(adminKey)) {
    return res.status(401).json({ error: 'Invalid admin key' });
  }

  try {
    console.log('[ADMIN] Manual brief generation triggered');
    const result = await generateWeeklyBriefs();
    res.json({ success: true, result });
  } catch (error) {
    console.error('[ADMIN] Manual generation error:', error);
    res.status(500).json({ error: 'Generation failed', message: error.message });
  }
});

module.exports = router;
