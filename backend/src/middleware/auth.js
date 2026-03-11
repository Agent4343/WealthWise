const { createClient } = require('@supabase/supabase-js');

/**
 * Middleware to verify Supabase JWT Bearer tokens.
 * Attaches the decoded user to req.user on success.
 */
async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.slice(7);

  try {
    // Use anon key to verify tokens — service role key is only for server-side DB operations
    const supabaseAnon = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_ANON_KEY,
    );

    const { data: { user }, error } = await supabaseAnon.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = user;
    req.token = token;
    next();
  } catch (err) {
    console.error('Auth middleware error:', err);
    return res.status(500).json({ error: 'Authentication service unavailable' });
  }
}

/**
 * Middleware that enforces Premium subscription tier.
 * Must be used after authMiddleware.
 */
async function premiumMiddleware(req, res, next) {
  const supabase = require('../config/supabase');

  try {
    const { data, error } = await supabase
      .from('app_users')
      .select('subscription_tier, subscription_expires_at')
      .eq('id', req.user.id)
      .single();

    if (error || !data) {
      return res.status(403).json({ error: 'Could not verify subscription status' });
    }

    const isPremium = data.subscription_tier === 'premium' &&
      (!data.subscription_expires_at || new Date(data.subscription_expires_at) > new Date());

    if (!isPremium) {
      return res.status(403).json({
        error: 'Premium subscription required',
        upgrade_url: 'wealthwise://paywall',
      });
    }

    req.subscriptionTier = data.subscription_tier;
    next();
  } catch (err) {
    console.error('Premium middleware error:', err);
    return res.status(500).json({ error: 'Subscription verification failed' });
  }
}

/**
 * Middleware that enforces Basic or Premium subscription tier.
 * Must be used after authMiddleware.
 */
async function basicMiddleware(req, res, next) {
  const supabase = require('../config/supabase');

  try {
    const { data, error } = await supabase
      .from('app_users')
      .select('subscription_tier, subscription_expires_at')
      .eq('id', req.user.id)
      .single();

    if (error || !data) {
      return res.status(403).json({ error: 'Could not verify subscription status' });
    }

    const validTiers = ['basic', 'premium'];
    const isActive = validTiers.includes(data.subscription_tier) &&
      (!data.subscription_expires_at || new Date(data.subscription_expires_at) > new Date());

    if (!isActive) {
      return res.status(403).json({
        error: 'Basic or Premium subscription required',
        upgrade_url: 'wealthwise://paywall',
      });
    }

    req.subscriptionTier = data.subscription_tier;
    next();
  } catch (err) {
    console.error('Basic middleware error:', err);
    return res.status(500).json({ error: 'Subscription verification failed' });
  }
}

module.exports = { authMiddleware, premiumMiddleware, basicMiddleware };
