const https = require('https');
const http2 = require('http2');
const fs = require('fs');
const jwt = require('./apnsJwt');

/**
 * Sends a push notification via Apple Push Notification Service (APNs HTTP/2).
 * @param {string} deviceToken - The APNs device token for the target device
 * @param {Object} notification - The notification payload
 * @param {string} notification.title - Notification title
 * @param {string} notification.body - Notification body
 * @param {Object} [notification.data] - Custom data payload
 * @returns {Promise<Object>} APNs response
 */
async function sendPushNotification(deviceToken, notification) {
  if (!process.env.APNS_KEY_ID || !process.env.APNS_TEAM_ID || !process.env.APNS_PRIVATE_KEY) {
    console.warn('APNs credentials not configured — skipping push notification');
    return { skipped: true, reason: 'APNs not configured' };
  }

  const payload = {
    aps: {
      alert: {
        title: notification.title,
        body: notification.body,
      },
      badge: 1,
      sound: 'default',
    },
    ...(notification.data || {}),
  };

  const bundleId = process.env.APNS_BUNDLE_ID || 'com.themoneyschool.wealthwise';
  const isProduction = process.env.NODE_ENV === 'production';
  const apnsHost = isProduction ? 'api.push.apple.com' : 'api.sandbox.push.apple.com';

  // Build the JWT token for APNs authentication
  const authToken = jwt.generateApnsToken(
    process.env.APNS_PRIVATE_KEY,
    process.env.APNS_KEY_ID,
    process.env.APNS_TEAM_ID,
  );

  return new Promise((resolve, reject) => {
    const client = http2.connect(`https://${apnsHost}`);

    client.on('error', (err) => {
      console.error('APNs HTTP/2 connection error:', err);
      reject(err);
    });

    const requestPath = `/3/device/${deviceToken}`;
    const requestHeaders = {
      ':method': 'POST',
      ':path': requestPath,
      ':scheme': 'https',
      ':authority': apnsHost,
      'authorization': `bearer ${authToken}`,
      'apns-push-type': 'alert',
      'apns-topic': bundleId,
      'content-type': 'application/json',
    };

    const req = client.request(requestHeaders);
    const bodyStr = JSON.stringify(payload);

    let statusCode;
    req.on('response', (headers) => {
      statusCode = headers[':status'];
    });

    let responseData = '';
    req.on('data', (chunk) => {
      responseData += chunk;
    });

    req.on('end', () => {
      client.close();
      if (statusCode === 200) {
        resolve({ success: true, deviceToken });
      } else {
        const error = responseData ? JSON.parse(responseData) : { reason: 'Unknown' };
        console.error(`APNs error ${statusCode} for device ${deviceToken}:`, error);
        resolve({ success: false, statusCode, error, deviceToken });
      }
    });

    req.on('error', (err) => {
      client.close();
      reject(err);
    });

    req.write(bodyStr);
    req.end();
  });
}

/**
 * Sends the Weekly Brief ready notification to a user's registered devices.
 * @param {string[]} deviceTokens - Array of APNs device tokens
 * @param {string} weekDate - Human-readable week date (e.g. "March 9, 2026")
 * @returns {Promise<Object[]>} Array of send results per device
 */
async function sendWeeklyBriefNotification(deviceTokens, weekDate) {
  if (!deviceTokens || deviceTokens.length === 0) {
    return [];
  }

  const notification = {
    title: 'Your Monday Brief is Ready 📊',
    body: `Your personalized WealthWise brief for ${weekDate} is now available.`,
    data: {
      notification_type: 'weekly_brief',
      deep_link: 'wealthwise://briefs',
    },
  };

  const results = await Promise.allSettled(
    deviceTokens.map(token => sendPushNotification(token, notification)),
  );

  return results.map((result, index) => ({
    deviceToken: deviceTokens[index],
    ...(result.status === 'fulfilled' ? result.value : { success: false, error: result.reason?.message }),
  }));
}

module.exports = { sendPushNotification, sendWeeklyBriefNotification };
