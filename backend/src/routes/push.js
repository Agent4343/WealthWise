const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const http2 = require('http2');
const jwt = require('jsonwebtoken');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// POST /push/register — Register APNs device token
router.post('/register', async (req, res) => {
  const { device_token, platform } = req.body;
  const userId = req.userId;

  if (!device_token) {
    return res.status(400).json({ error: 'device_token is required' });
  }

  try {
    const { error } = await supabase
      .from('device_tokens')
      .upsert({
        user_id: userId,
        device_token,
        platform: platform || 'ios',
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'user_id,device_token'
      });

    if (error) throw error;

    res.json({ success: true });
  } catch (error) {
    console.error('[PUSH] Token registration error:', error);
    res.status(500).json({ error: 'Failed to register token' });
  }
});

// APNs Push Notification Service
class APNsService {
  constructor() {
    this.teamId = process.env.APNS_TEAM_ID;
    this.keyId = process.env.APNS_KEY_ID;
    this.privateKey = process.env.APNS_PRIVATE_KEY;
    this.bundleId = process.env.APPLE_BUNDLE_ID || 'com.themileschool.wealthwise';
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  /**
   * Generate a short-lived JWT for APNs authentication
   */
  generateToken() {
    const header = {
      alg: 'ES256',
      kid: this.keyId
    };

    const claims = {
      iss: this.teamId,
      iat: Math.floor(Date.now() / 1000)
    };

    return jwt.sign(claims, this.privateKey, {
      algorithm: 'ES256',
      header
    });
  }

  /**
   * Send a push notification to a single device
   */
  async sendNotification(deviceToken, payload) {
    const host = this.isProduction
      ? 'api.push.apple.com'
      : 'api.sandbox.push.apple.com';

    return new Promise((resolve, reject) => {
      const client = http2.connect(`https://${host}`);

      const token = this.generateToken();
      const body = JSON.stringify(payload);

      const headers = {
        ':method': 'POST',
        ':path': `/3/device/${deviceToken}`,
        'authorization': `bearer ${token}`,
        'apns-topic': this.bundleId,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(body)
      };

      const req = client.request(headers);

      let responseData = '';
      let statusCode;

      req.on('response', (headers) => {
        statusCode = headers[':status'];
      });

      req.on('data', (chunk) => {
        responseData += chunk;
      });

      req.on('end', () => {
        client.close();
        if (statusCode === 200) {
          resolve({ success: true, deviceToken });
        } else {
          const error = responseData ? JSON.parse(responseData) : {};
          console.error(`[APNS] Push failed for ${deviceToken}:`, statusCode, error);
          resolve({ success: false, deviceToken, statusCode, error });
        }
      });

      req.on('error', (error) => {
        client.close();
        reject(error);
      });

      req.write(body);
      req.end();
    });
  }

  /**
   * Send Weekly Brief notification to a user
   */
  async sendBriefNotification(deviceToken, weekOf) {
    const payload = {
      aps: {
        alert: {
          title: 'Your Weekly Brief Is Ready',
          subtitle: `Week of ${weekOf}`,
          body: 'Your personalized Monday morning financial briefing is waiting for you.'
        },
        sound: 'default',
        badge: 1,
        category: 'WEEKLY_BRIEF',
        'thread-id': 'weekly-brief'
      },
      briefWeekOf: weekOf
    };

    return this.sendNotification(deviceToken, payload);
  }

  /**
   * Send brief-ready notifications to all Premium subscribers
   */
  async notifyAllPremiumUsers(weekOf) {
    try {
      // Get all device tokens for premium users
      const { data: tokens, error } = await supabase
        .from('device_tokens')
        .select('device_token, user_id')
        .in('user_id',
          supabase
            .from('subscriptions')
            .select('user_id')
            .eq('tier', 'premium')
            .eq('status', 'active')
        );

      if (error) {
        console.error('[APNS] Failed to fetch device tokens:', error);
        return { sent: 0, failed: 0 };
      }

      if (!tokens || tokens.length === 0) {
        console.log('[APNS] No device tokens to notify');
        return { sent: 0, failed: 0 };
      }

      let sent = 0;
      let failed = 0;

      // Send in batches of 50
      const BATCH_SIZE = 50;
      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const batch = tokens.slice(i, i + BATCH_SIZE);

        const results = await Promise.allSettled(
          batch.map(t => this.sendBriefNotification(t.device_token, weekOf))
        );

        for (const result of results) {
          if (result.status === 'fulfilled' && result.value.success) {
            sent++;
          } else {
            failed++;
          }
        }

        // Small delay between batches
        if (i + BATCH_SIZE < tokens.length) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      console.log(`[APNS] Notifications sent: ${sent}, failed: ${failed}`);
      return { sent, failed };
    } catch (error) {
      console.error('[APNS] Bulk notification error:', error);
      return { sent: 0, failed: 0, error: error.message };
    }
  }
}

const apnsService = new APNsService();

module.exports = { router, apnsService };
