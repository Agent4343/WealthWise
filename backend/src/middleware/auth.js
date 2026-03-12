const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = user;
    req.userId = user.id;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({ error: 'Authentication failed' });
  }
}

async function premiumMiddleware(req, res, next) {
  try {
    const { data: subscription } = await supabase
      .from('subscriptions')
      .select('tier, status')
      .eq('user_id', req.userId)
      .eq('status', 'active')
      .single();

    if (!subscription || subscription.tier !== 'premium') {
      return res.status(403).json({ error: 'Premium subscription required' });
    }

    next();
  } catch (error) {
    return res.status(403).json({ error: 'Premium subscription required' });
  }
}

function verifyAdminKey(providedKey) {
  const expectedKey = process.env.ADMIN_API_KEY;
  if (!providedKey || !expectedKey) return false;

  const providedBuf = Buffer.from(String(providedKey));
  const expectedBuf = Buffer.from(String(expectedKey));

  if (providedBuf.length !== expectedBuf.length) return false;

  return crypto.timingSafeEqual(providedBuf, expectedBuf);
}

module.exports = { authMiddleware, premiumMiddleware, verifyAdminKey };
