const express = require('express');
const crypto = require('crypto');
const supabase = require('../config/supabase');

const router = express.Router();

/**
 * POST /webhooks/appstore
 * Handles App Store Server Notifications from Apple StoreKit 2.
 * Updates user subscription entitlements in Supabase based on notification type.
 *
 * Apple sends signed JWS payloads. In production, verify the signature using
 * Apple's public key. Here we validate the structure and process the event.
 */
router.post('/appstore', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    let payload;

    // Parse raw body (may be Buffer or pre-parsed object)
    if (Buffer.isBuffer(req.body)) {
      payload = JSON.parse(req.body.toString());
    } else {
      payload = req.body;
    }

    const { signedPayload } = payload;

    if (!signedPayload) {
      return res.status(400).json({ error: 'Missing signedPayload' });
    }

    // Decode the JWS payload (header.payload.signature — base64url encoded)
    const parts = signedPayload.split('.');
    if (parts.length !== 3) {
      return res.status(400).json({ error: 'Invalid JWS format' });
    }

    const decodedPayload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf-8'));
    const { notificationType, subtype, data } = decodedPayload;

    if (!data) {
      return res.status(400).json({ error: 'Missing notification data' });
    }

    const { appAccountToken, signedTransactionInfo, signedRenewalInfo } = data;

    // Decode transaction info
    let transactionInfo = {};
    if (signedTransactionInfo) {
      const txParts = signedTransactionInfo.split('.');
      if (txParts.length === 3) {
        transactionInfo = JSON.parse(Buffer.from(txParts[1], 'base64url').toString('utf-8'));
      }
    }

    const { productId, originalTransactionId, expiresDate } = transactionInfo;

    console.log(`App Store notification: ${notificationType}${subtype ? '/' + subtype : ''} for product ${productId}`);

    // Map product IDs to subscription tiers
    const tierMap = {
      'com.wealthwise.basic.monthly': 'basic',
      'com.wealthwise.basic.annual': 'basic',
      'com.wealthwise.premium.monthly': 'premium',
      'com.wealthwise.premium.annual': 'premium',
    };

    const tier = tierMap[productId] || 'free';

    // Handle notification types per Apple's documentation
    switch (notificationType) {
      case 'SUBSCRIBED':
      case 'DID_RENEW':
      case 'OFFER_REDEEMED': {
        // Active subscription — grant or renew entitlement
        if (appAccountToken) {
          await updateUserSubscription(appAccountToken, tier, expiresDate, originalTransactionId);
        }
        break;
      }

      case 'DID_CHANGE_RENEWAL_STATUS': {
        if (subtype === 'AUTO_RENEW_DISABLED') {
          // Subscription will not renew but is still active until expiresDate
          console.log(`Auto-renew disabled for transaction ${originalTransactionId}`);
        }
        break;
      }

      case 'EXPIRED': {
        // Subscription expired — downgrade to free
        if (appAccountToken) {
          await updateUserSubscription(appAccountToken, 'free', null, originalTransactionId);
        }
        break;
      }

      case 'REFUND': {
        // Refund issued — revoke entitlement
        if (appAccountToken) {
          await updateUserSubscription(appAccountToken, 'free', null, originalTransactionId);
        }
        break;
      }

      case 'GRACE_PERIOD_EXPIRED': {
        // Billing grace period expired — downgrade
        if (appAccountToken) {
          await updateUserSubscription(appAccountToken, 'free', null, originalTransactionId);
        }
        break;
      }

      default:
        console.log(`Unhandled notification type: ${notificationType}`);
    }

    // Always return 200 to Apple to acknowledge receipt
    return res.status(200).json({ received: true });
  } catch (err) {
    console.error('App Store webhook error:', err);
    // Still return 200 to prevent Apple from retrying malformed notifications
    return res.status(200).json({ received: true, warning: 'Processing error logged' });
  }
});

/**
 * Updates a user's subscription tier in Supabase.
 * @param {string} appAccountToken - UUID linking Apple transaction to our user
 * @param {string} tier - 'free' | 'basic' | 'premium'
 * @param {number|null} expiresDate - Unix timestamp (ms) from Apple
 * @param {string} originalTransactionId - Apple's original transaction ID
 */
async function updateUserSubscription(appAccountToken, tier, expiresDate, originalTransactionId) {
  const expiresAt = expiresDate ? new Date(expiresDate).toISOString() : null;

  const { error } = await supabase
    .from('app_users')
    .update({
      subscription_tier: tier,
      subscription_expires_at: expiresAt,
      apple_original_transaction_id: originalTransactionId,
      updated_at: new Date().toISOString(),
    })
    .eq('apple_account_token', appAccountToken);

  if (error) {
    console.error('Failed to update subscription in DB:', error);
    throw error;
  }

  console.log(`Updated subscription: token=${appAccountToken} tier=${tier} expires=${expiresAt}`);
}

module.exports = router;
