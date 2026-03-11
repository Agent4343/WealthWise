const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Product ID to tier mapping
const PRODUCT_TIER_MAP = {
  'com.themileschool.wealthwise.basic.monthly': 'basic',
  'com.themileschool.wealthwise.basic.annual': 'basic',
  'com.themileschool.wealthwise.premium.monthly': 'premium',
  'com.themileschool.wealthwise.premium.annual': 'premium'
};

// POST /webhooks/apple — Receive App Store Server Notifications
router.post('/apple', async (req, res) => {
  try {
    const { signedPayload } = req.body;

    if (!signedPayload) {
      return res.status(400).json({ error: 'Missing signedPayload' });
    }

    // Decode the JWS payload (simplified — production should verify signature)
    const parts = signedPayload.split('.');
    if (parts.length !== 3) {
      return res.status(400).json({ error: 'Invalid JWS format' });
    }

    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    const { notificationType, data } = payload;

    console.log(`[WEBHOOK] Apple notification: ${notificationType}`);

    if (!data?.signedTransactionInfo) {
      return res.status(200).json({ received: true });
    }

    // Decode transaction info
    const txParts = data.signedTransactionInfo.split('.');
    const transactionInfo = JSON.parse(Buffer.from(txParts[1], 'base64url').toString());

    const {
      originalTransactionId,
      productId,
      appAccountToken, // This maps to our user ID
      expiresDate
    } = transactionInfo;

    const tier = PRODUCT_TIER_MAP[productId] || 'free';

    switch (notificationType) {
      case 'SUBSCRIBED':
      case 'DID_RENEW':
        await upsertSubscription(appAccountToken, {
          tier,
          status: 'active',
          apple_original_transaction_id: originalTransactionId,
          apple_product_id: productId,
          expires_at: expiresDate ? new Date(expiresDate).toISOString() : null
        });
        break;

      case 'EXPIRED':
      case 'REVOKE':
        await upsertSubscription(appAccountToken, {
          tier: 'free',
          status: 'expired',
          apple_original_transaction_id: originalTransactionId,
          apple_product_id: productId
        });
        break;

      case 'GRACE_PERIOD_EXPIRED':
        await upsertSubscription(appAccountToken, {
          tier: 'free',
          status: 'grace_period',
          apple_original_transaction_id: originalTransactionId,
          apple_product_id: productId
        });
        break;

      case 'DID_CHANGE_RENEWAL_STATUS':
        // User toggled auto-renew — no immediate tier change
        break;

      default:
        console.log(`[WEBHOOK] Unhandled notification type: ${notificationType}`);
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('[WEBHOOK] Apple notification error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

async function upsertSubscription(userId, data) {
  if (!userId) {
    console.error('[WEBHOOK] No userId (appAccountToken) in transaction');
    return;
  }

  const { data: existing } = await supabase
    .from('subscriptions')
    .select('id')
    .eq('user_id', userId)
    .single();

  const updateData = {
    ...data,
    updated_at: new Date().toISOString()
  };

  if (existing) {
    await supabase
      .from('subscriptions')
      .update(updateData)
      .eq('user_id', userId);
  } else {
    await supabase
      .from('subscriptions')
      .insert({ user_id: userId, ...updateData });
  }
}

module.exports = router;
