const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
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

// Validate required environment variables
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'SUPABASE_JWT_SECRET'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.error(`FATAL: Missing required environment variable: ${envVar}`);
    process.exit(1);
  }
}

const app = express();
const PORT = process.env.PORT || 3000;

// Security headers
app.use(helmet());

// CORS configuration
const allowedOrigins = ['https://wealthwise.ca', 'https://www.wealthwise.ca'];
app.use(cors({
  origin: process.env.NODE_ENV === 'development'
    ? true
    : allowedOrigins
}));

// Body parsing with size limit
app.use(express.json({ limit: '10kb' }));

// General rate limiter: 100 requests per 15 minutes per IP
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' }
});
app.use(generalLimiter);

// Admin rate limiter: 5 requests per 15 minutes per IP
const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many admin requests, please try again later' }
});

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'wealthwise-api', timestamp: new Date().toISOString() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'wealthwise-api', timestamp: new Date().toISOString() });
});

// Waitlist email collection (public, no auth required)
app.post('/api/waitlist', async (req, res) => {
  const { email } = req.body;
  if (!email || typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: 'Valid email is required' });
  }

  try {
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
    await supabase
      .from('waitlist')
      .upsert({ email: email.toLowerCase().trim(), created_at: new Date().toISOString() }, { onConflict: 'email' });
    res.json({ success: true });
  } catch (error) {
    console.error('Waitlist error:', error);
    res.status(500).json({ error: 'Failed to save email' });
  }
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
app.use('/admin', adminLimiter, authMiddleware, adminRoutes);

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
