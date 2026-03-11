const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const { authMiddleware } = require('./middleware/auth');
const profileRoutes = require('./routes/profile');
const briefsRoutes = require('./routes/briefs');
const subscriptionRoutes = require('./routes/subscription');
const webhookRoutes = require('./routes/webhooks');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const { router: pushRoutes } = require('./routes/push');
const calculatorRoutes = require('./routes/calculator');
const { generateWeeklyBriefs } = require('./jobs/weeklyBriefGenerator');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'wealthwise-api', timestamp: new Date().toISOString() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'wealthwise-api', timestamp: new Date().toISOString() });
});

// Public routes
app.use('/auth', authRoutes);
app.use('/webhooks', webhookRoutes);

// Protected routes (require Supabase JWT)
app.use('/profile', authMiddleware, profileRoutes);
app.use('/briefs', authMiddleware, briefsRoutes);
app.use('/subscription', authMiddleware, subscriptionRoutes);
app.use('/push', authMiddleware, pushRoutes);
app.use('/calculator', authMiddleware, calculatorRoutes);
app.use('/admin', adminRoutes);

// Sunday 23:00 EST cron job for Weekly Brief generation
if (process.env.CRON_ENABLED === 'true') {
  // 23:00 EST = 04:00 UTC Monday (during EST), 03:00 UTC Monday (during EDT)
  cron.schedule('0 4 * * 1', async () => {
    console.log('[CRON] Starting Weekly Brief generation batch...');
    try {
      await generateWeeklyBriefs();
      console.log('[CRON] Weekly Brief generation complete.');
    } catch (error) {
      console.error('[CRON] Weekly Brief generation failed:', error);
    }
  }, {
    timezone: 'UTC'
  });
  console.log('[CRON] Weekly Brief generation scheduled for Sunday 23:00 EST');
}

app.listen(PORT, () => {
  console.log(`WealthWise API running on port ${PORT}`);
});
