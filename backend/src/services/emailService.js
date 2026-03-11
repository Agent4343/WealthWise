const { Resend } = require('resend');

// Lazily initialized so tests can require this module without a live API key
let _resend = null;
function getResend() {
  if (!_resend) {
    _resend = new Resend(process.env.RESEND_API_KEY);
  }
  return _resend;
}

const FROM_EMAIL = process.env.FROM_EMAIL || 'WealthWise <briefs@wealthwise.app>';
const DISCLAIMER = 'WealthWise Weekly Brief is educational guidance only and does not constitute personalized financial, investment, or tax advice under OSC regulations. Past performance does not guarantee future results. Consult a Certified Financial Planner (CFP) for advice specific to your situation.';

/**
 * Sends the Weekly Brief HTML email to a Premium subscriber.
 * @param {string} toEmail - Recipient email address
 * @param {Object} brief - The 5-section Weekly Brief object
 * @param {string} weekStartDate - ISO date string for the week (e.g. "2026-03-09")
 * @returns {Promise<Object>} Resend send result
 */
async function sendWeeklyBriefEmail(toEmail, brief, weekStartDate) {
  const formattedDate = new Date(weekStartDate).toLocaleDateString('en-CA', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  const html = buildEmailHtml(brief, formattedDate);
  const text = buildEmailText(brief, formattedDate);

  const result = await getResend().emails.send({
    from: FROM_EMAIL,
    to: toEmail,
    subject: `Your WealthWise Monday Brief — ${formattedDate}`,
    html,
    text,
  });

  return result;
}

/**
 * Builds the HTML email template for the Weekly Brief.
 */
function buildEmailHtml(brief, formattedDate) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WealthWise Monday Brief</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f5f5f7; margin: 0; padding: 0; color: #1d1d1f; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; }
    .header { background: #1d3557; padding: 32px 24px; text-align: center; }
    .header h1 { color: #ffffff; font-size: 24px; margin: 0; font-weight: 700; }
    .header p { color: #a8d8ea; font-size: 14px; margin: 8px 0 0; }
    .section { padding: 24px; border-bottom: 1px solid #f0f0f0; }
    .section h2 { font-size: 16px; font-weight: 600; color: #1d3557; margin: 0 0 12px; text-transform: uppercase; letter-spacing: 0.5px; }
    .section p { font-size: 15px; line-height: 1.6; margin: 0; color: #3d3d3d; }
    .action-box { background: #e8f4fd; border-left: 4px solid #457b9d; padding: 16px 20px; margin: 0; }
    .action-box h2 { color: #1d3557; }
    .footer { background: #f5f5f7; padding: 20px 24px; text-align: center; }
    .footer p { font-size: 11px; color: #888; line-height: 1.5; margin: 0; }
    .badge { display: inline-block; background: #457b9d; color: white; font-size: 11px; padding: 4px 10px; border-radius: 12px; margin-bottom: 16px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>WealthWise</h1>
      <p>Your Monday Morning Brief — ${formattedDate}</p>
    </div>

    <div class="section">
      <span class="badge">Week at a Glance</span>
      <p>${escapeHtml(brief.week_at_a_glance)}</p>
    </div>

    <div class="section">
      <h2>🇨🇦 Canadian Economic Pulse</h2>
      <p>${escapeHtml(brief.canadian_economic_pulse)}</p>
    </div>

    <div class="section">
      <h2>📊 Your Accounts This Week</h2>
      <p>${escapeHtml(brief.accounts_this_week)}</p>
    </div>

    <div class="section">
      <h2>💡 What to Think About</h2>
      <p>${escapeHtml(brief.what_to_think_about)}</p>
    </div>

    <div class="section action-box">
      <h2>✅ Your Monday Action Item</h2>
      <p>${escapeHtml(brief.monday_action_item)}</p>
    </div>

    <div class="footer">
      <p>${escapeHtml(brief.disclaimer || DISCLAIMER)}</p>
      <p style="margin-top: 12px;">© ${new Date().getFullYear()} The Money School Inc. · WealthWise iOS App</p>
    </div>
  </div>
</body>
</html>`;
}

/**
 * Builds the plain-text fallback for the Weekly Brief email.
 */
function buildEmailText(brief, formattedDate) {
  return `WealthWise — Monday Morning Brief
${formattedDate}
${'='.repeat(50)}

WEEK AT A GLANCE
${brief.week_at_a_glance}

CANADIAN ECONOMIC PULSE
${brief.canadian_economic_pulse}

YOUR ACCOUNTS THIS WEEK
${brief.accounts_this_week}

WHAT TO THINK ABOUT
${brief.what_to_think_about}

YOUR MONDAY ACTION ITEM
${brief.monday_action_item}

${'─'.repeat(50)}
${brief.disclaimer || DISCLAIMER}

© ${new Date().getFullYear()} The Money School Inc. · WealthWise iOS App
`;
}

/**
 * Escapes HTML special characters to prevent XSS in email templates.
 */
function escapeHtml(str) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

module.exports = { sendWeeklyBriefEmail, buildEmailHtml, buildEmailText };
