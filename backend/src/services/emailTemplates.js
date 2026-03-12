/**
 * WealthWise Email Templates
 * HTML email templates for Weekly Brief delivery via Resend
 */

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function weeklyBriefEmail(brief, userName, weekOfFormatted) {
  const greeting = userName ? `Hi ${escapeHtml(userName)},` : 'Good morning,';

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WealthWise Weekly Brief — ${weekOfFormatted}</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f5f5f7; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; }
    .header { background: linear-gradient(135deg, #1e9660 0%, #2cb576 100%); padding: 32px 24px; text-align: center; }
    .header h1 { color: #ffffff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 24px; margin: 0; }
    .header p { color: rgba(255,255,255,0.85); font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 14px; margin: 8px 0 0 0; }
    .content { padding: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    .greeting { font-size: 16px; color: #333; margin-bottom: 20px; line-height: 1.5; }
    .section { margin-bottom: 24px; border-radius: 12px; overflow: hidden; }
    .section-header { padding: 12px 16px; display: flex; align-items: center; }
    .section-number { display: inline-block; width: 24px; height: 24px; border-radius: 12px; text-align: center; line-height: 24px; font-size: 12px; font-weight: 700; color: #fff; margin-right: 10px; }
    .section-title { font-size: 15px; font-weight: 600; color: #1a1a1a; }
    .section-body { padding: 0 16px 16px 16px; font-size: 14px; line-height: 1.6; color: #444; }

    .s1 .section-header { background: #e8f4fd; }
    .s1 .section-number { background: #0066cc; }
    .s2 .section-header { background: #e8f8e8; }
    .s2 .section-number { background: #008800; }
    .s3 .section-header { background: #f0e8fd; }
    .s3 .section-number { background: #6600cc; }
    .s4 .section-header { background: #fef3e8; }
    .s4 .section-number { background: #cc6600; }
    .s5 .section-header { background: #e8fefe; }
    .s5 .section-number { background: #008888; }

    .cta { text-align: center; padding: 24px; }
    .cta a { display: inline-block; background: #1e9660; color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 15px; }
    .divider { border: none; border-top: 1px solid #eee; margin: 24px 0; }
    .disclaimer { padding: 16px 24px; background: #f9f9f9; font-size: 11px; line-height: 1.6; color: #999; }
    .footer { padding: 16px 24px; text-align: center; font-size: 12px; color: #999; }
    .footer a { color: #1e9660; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <h1>WealthWise Weekly Brief</h1>
      <p>Week of ${weekOfFormatted}</p>
    </div>

    <!-- Content -->
    <div class="content">
      <p class="greeting">${greeting}<br>Here's your personalized financial briefing for this week.</p>

      <!-- Section 1: Week at a Glance -->
      <div class="section s1">
        <div class="section-header">
          <span class="section-number">1</span>
          <span class="section-title">Your Week at a Glance</span>
        </div>
        <div class="section-body">
          ${escapeHtml(brief.section_1_snapshot)}
        </div>
      </div>

      <!-- Section 2: Canadian Economic Pulse -->
      <div class="section s2">
        <div class="section-header">
          <span class="section-number">2</span>
          <span class="section-title">The Canadian Economic Pulse</span>
        </div>
        <div class="section-body">
          ${escapeHtml(brief.section_2_market)}
        </div>
      </div>

      <!-- Section 3: Your Accounts -->
      <div class="section s3">
        <div class="section-header">
          <span class="section-number">3</span>
          <span class="section-title">Your Accounts This Week</span>
        </div>
        <div class="section-body">
          ${escapeHtml(brief.section_3_accounts)}
        </div>
      </div>

      <!-- Section 4: What to Think About -->
      <div class="section s4">
        <div class="section-header">
          <span class="section-number">4</span>
          <span class="section-title">What to Think About</span>
        </div>
        <div class="section-body">
          ${escapeHtml(brief.section_4_learn)}
        </div>
      </div>

      <!-- Section 5: Monday Action Item -->
      <div class="section s5">
        <div class="section-header">
          <span class="section-number">5</span>
          <span class="section-title">Your Monday Action Item</span>
        </div>
        <div class="section-body">
          ${escapeHtml(brief.section_5_action)}
        </div>
      </div>

      <!-- CTA -->
      <div class="cta">
        <a href="https://apps.apple.com/ca/app/wealthwise/id0000000000">Open in WealthWise</a>
      </div>
    </div>

    <!-- Disclaimer -->
    <div class="disclaimer">
      WealthWise Weekly Brief is educational guidance only and does not constitute
      personalized financial, investment, or tax advice under OSC regulations. Past
      performance does not guarantee future results. Consult a Certified Financial
      Planner (CFP) for advice specific to your situation. The information provided
      is based on general Canadian financial principles and current market conditions
      available at the time of generation.
    </div>

    <!-- Footer -->
    <div class="footer">
      <p>The Money School Inc. | <a href="https://wealthwise.ca">wealthwise.ca</a></p>
      <p>You're receiving this because you're a WealthWise Premium subscriber.</p>
      <p><a href="https://wealthwise.ca/unsubscribe">Email Preferences</a> | <a href="https://wealthwise.ca/privacy">Privacy Policy</a></p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

function welcomeEmail(userName) {
  const greeting = userName ? `Welcome, ${userName}!` : 'Welcome to WealthWise!';

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to WealthWise</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f5f5f7; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    .header { background: linear-gradient(135deg, #1e9660 0%, #2cb576 100%); padding: 40px 24px; text-align: center; }
    .header h1 { color: #ffffff; font-size: 28px; margin: 0; }
    .header p { color: rgba(255,255,255,0.85); font-size: 16px; margin: 12px 0 0 0; }
    .content { padding: 32px 24px; }
    .content h2 { font-size: 20px; color: #1a1a1a; margin-top: 0; }
    .content p { font-size: 15px; line-height: 1.6; color: #444; }
    .step { display: flex; align-items: flex-start; margin-bottom: 16px; }
    .step-num { background: #1e9660; color: #fff; width: 28px; height: 28px; border-radius: 14px; text-align: center; line-height: 28px; font-weight: 700; font-size: 14px; margin-right: 12px; flex-shrink: 0; }
    .step-text { font-size: 15px; line-height: 1.5; color: #333; }
    .cta { text-align: center; padding: 24px 0; }
    .cta a { display: inline-block; background: #1e9660; color: #fff; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 15px; }
    .footer { padding: 16px 24px; text-align: center; font-size: 12px; color: #999; border-top: 1px solid #eee; }
    .footer a { color: #1e9660; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${greeting}</h1>
      <p>The financial education app Canada never had.</p>
    </div>

    <div class="content">
      <h2>Here's how to get started:</h2>

      <div class="step">
        <span class="step-num">1</span>
        <span class="step-text"><strong>Start with Chapter 1</strong> — Learn what school never taught you about compound interest and the savings account trap.</span>
      </div>

      <div class="step">
        <span class="step-num">2</span>
        <span class="step-text"><strong>Try the Retirement Calculator</strong> — See what $200/month today becomes at 65. The result will surprise you.</span>
      </div>

      <div class="step">
        <span class="step-num">3</span>
        <span class="step-text"><strong>Set up your profile</strong> — Enter your RRSP and TFSA contribution room to unlock your personalized dashboard.</span>
      </div>

      <p>WealthWise will show you in 15 minutes what no school, bank, or financial advisor ever bothered to explain clearly.</p>

      <div class="cta">
        <a href="https://apps.apple.com/ca/app/wealthwise/id0000000000">Open WealthWise</a>
      </div>
    </div>

    <div class="footer">
      <p>The Money School Inc. | <a href="https://wealthwise.ca">wealthwise.ca</a></p>
      <p><a href="https://wealthwise.ca/privacy">Privacy Policy</a> | <a href="https://wealthwise.ca/terms">Terms of Service</a></p>
    </div>
  </div>
</body>
</html>
  `.trim();
}

module.exports = { weeklyBriefEmail, welcomeEmail };
