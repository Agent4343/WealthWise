const express = require('express');
const router = express.Router();
const { generateWeeklyBriefs } = require('../jobs/weeklyBriefGenerator');

// POST /admin/generate — Manually trigger AI brief generation (dev/test)
router.post('/generate', async (req, res) => {
  const adminKey = req.headers['x-admin-key'];

  if (!adminKey || adminKey !== process.env.ADMIN_API_KEY) {
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
