const Anthropic = require('@anthropic-ai/sdk');
const { createClient } = require('@supabase/supabase-js');
const { Resend } = require('resend');
const { weeklyBriefEmail } = require('../services/emailTemplates');
const { apnsService } = require('../routes/push');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

const anthropic = process.env.CLAUDE_API_KEY ? new Anthropic({ apiKey: process.env.CLAUDE_API_KEY }) : null;
const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

const SYSTEM_PROMPT = `You are WealthWise, a Canadian financial education assistant. You provide educational guidance — not personalized financial advice. You are knowledgeable about Canadian tax rules, RRSP, TFSA, CPP, OAS, and investment fundamentals.

CRITICAL RULES:
1. You NEVER recommend specific securities, specific funds by name, or specific dollar amounts to invest.
2. You use phrases like "you may want to consider", "historically, investors who...", "one option worth exploring is..."
3. You always note that users should consult a licensed financial advisor (CFP) for personalized advice.
4. You NEVER quote specific future return percentages as guaranteed.
5. You NEVER comment on whether the market will go up or down with certainty.
6. You are warm, direct, judgment-free, and plain-spoken.

You must respond with a JSON object containing exactly these 5 fields:
- section_1_snapshot: "Your Week at a Glance" — 2-3 sentence snapshot relevant to this user
- section_2_market: "The Canadian Economic Pulse" — Bank of Canada rate context, inflation trend, TSX performance, CAD/USD in plain English
- section_3_accounts: "Your Accounts This Week" — Personalized commentary on RRSP room, TFSA room, contribution timing
- section_4_learn: "What to Think About" — 2-3 educational concepts relevant to user's profile and current market
- section_5_action: "Your Monday Action Item" — One specific, achievable action for this week (never a buy/sell directive)`;

const BATCH_SIZE = 10;

async function generateWeeklyBriefs() {
  // Fetch all premium subscribers
  const { data: premiumUsers, error } = await supabase
    .from('subscriptions')
    .select('user_id')
    .eq('tier', 'premium')
    .eq('status', 'active');

  if (error) {
    throw new Error(`Failed to fetch premium users: ${error.message}`);
  }

  if (!premiumUsers || premiumUsers.length === 0) {
    console.log('[BRIEF] No premium subscribers to process');
    return { processed: 0 };
  }

  console.log(`[BRIEF] Processing ${premiumUsers.length} premium subscribers`);

  // Fetch current market context using Claude with web search
  const marketContext = await fetchMarketContext();

  let processed = 0;
  let errors = 0;

  // Process in batches
  for (let i = 0; i < premiumUsers.length; i += BATCH_SIZE) {
    const batch = premiumUsers.slice(i, i + BATCH_SIZE);

    const results = await Promise.allSettled(
      batch.map(sub => generateBriefForUser(sub.user_id, marketContext))
    );

    for (const result of results) {
      if (result.status === 'fulfilled') {
        processed++;
      } else {
        errors++;
        console.error('[BRIEF] User generation failed:', result.reason);
      }
    }

    // Rate limiting between batches
    if (i + BATCH_SIZE < premiumUsers.length) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  console.log(`[BRIEF] Complete: ${processed} generated, ${errors} errors`);
  return { processed, errors, total: premiumUsers.length };
}

async function fetchMarketContext() {
  if (!anthropic) return 'Market data unavailable — CLAUDE_API_KEY not configured.';
  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1500,
      tools: [{
        type: 'web_search_20250305',
        name: 'web_search',
        max_uses: 3
      }],
      messages: [{
        role: 'user',
        content: 'Provide a brief summary of current Canadian financial conditions: Bank of Canada interest rate, recent TSX performance, CAD/USD exchange rate, and Canadian inflation rate. Keep it factual and concise.'
      }]
    });

    // Extract text from response
    const textBlocks = response.content.filter(b => b.type === 'text');
    return textBlocks.map(b => b.text).join('\n');
  } catch (error) {
    console.error('[BRIEF] Market context fetch failed:', error);
    return 'Market data temporarily unavailable. General Canadian financial guidance will be provided based on recent trends.';
  }
}

async function generateBriefForUser(userId, marketContext) {
  // Fetch user profile
  const { data: profile } = await supabase
    .from('financial_profiles')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!profile) {
    console.log(`[BRIEF] No profile for user ${userId}, skipping`);
    return;
  }

  if (!anthropic) {
    console.log(`[BRIEF] CLAUDE_API_KEY not configured, skipping brief generation`);
    return;
  }

  // Fetch user info
  const { data: user } = await supabase
    .from('app_users')
    .select('email, full_name')
    .eq('id', userId)
    .single();

  const userPrompt = buildUserPrompt(profile, marketContext);

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1200,
    system: SYSTEM_PROMPT,
    messages: [{
      role: 'user',
      content: userPrompt
    }]
  });

  const textContent = response.content.find(b => b.type === 'text');
  if (!textContent) throw new Error('No text in AI response');

  // Parse JSON from response
  const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error('No JSON found in AI response');

  const brief = JSON.parse(jsonMatch[0]);
  const tokensUsed = response.usage.input_tokens + response.usage.output_tokens;

  // Calculate the Monday of this week (or today if it's Monday)
  const now = new Date();
  const monday = new Date(now);
  const dayOfWeek = now.getDay(); // 0=Sun, 1=Mon, ...
  const daysFromMonday = dayOfWeek === 0 ? 1 : (dayOfWeek === 1 ? 0 : 8 - dayOfWeek);
  monday.setDate(now.getDate() + daysFromMonday);
  monday.setHours(0, 0, 0, 0);

  // Store in Supabase
  const { error: insertError } = await supabase.from('weekly_briefs').insert({
    user_id: userId,
    week_of: monday.toISOString().split('T')[0],
    section_1_snapshot: brief.section_1_snapshot,
    section_2_market: brief.section_2_market,
    section_3_accounts: brief.section_3_accounts,
    section_4_learn: brief.section_4_learn,
    section_5_action: brief.section_5_action,
    tokens_used: tokensUsed,
    generated_at: new Date().toISOString(),
    delivered_at: new Date().toISOString()
  });

  if (insertError) throw insertError;

  // Send email
  if (user?.email && process.env.RESEND_API_KEY) {
    await sendBriefEmail(user.email, user.full_name, brief, monday);
  }

  // Send push notification
  await sendPushNotifications(monday);

  console.log(`[BRIEF] Generated for user ${userId} (${tokensUsed} tokens)`);
}

function buildUserPrompt(profile, marketContext) {
  return `Generate a Weekly Brief for this Canadian user:

USER PROFILE:
- Age: ${profile.age}
- Retirement age target: ${profile.retirement_age}
- Income bracket: ${profile.income_bracket}
- RRSP room used: $${profile.rrsp_room_used}
- TFSA room used: $${profile.tfsa_room_used}
- Current savings: $${profile.current_savings}
- Monthly contribution: $${profile.monthly_contribution}
- Risk tolerance: ${profile.risk_tolerance}

CURRENT CANADIAN MARKET CONTEXT:
${marketContext}

Generate the 5-section Weekly Brief as a JSON object. Remember: educational guidance only, no specific securities or fund names, no guarantees.`;
}

async function sendBriefEmail(email, name, brief, weekOf) {
  const formattedDate = weekOf.toLocaleDateString('en-CA', {
    month: 'long', day: 'numeric', year: 'numeric'
  });

  try {
    await resend.emails.send({
      from: 'WealthWise <briefs@wealthwise.ca>',
      to: email,
      subject: `Your WealthWise Weekly Brief — ${formattedDate}`,
      html: weeklyBriefEmail(brief, name, formattedDate)
    });
  } catch (error) {
    console.error(`[EMAIL] Failed to send to ${email}:`, error);
  }
}

async function sendPushNotifications(weekOf) {
  const formattedDate = weekOf.toLocaleDateString('en-CA', {
    month: 'long', day: 'numeric', year: 'numeric'
  });

  try {
    const result = await apnsService.notifyAllPremiumUsers(formattedDate);
    console.log(`[PUSH] Notifications: ${result.sent} sent, ${result.failed} failed`);
  } catch (error) {
    console.error('[PUSH] Failed to send push notifications:', error);
  }
}

module.exports = { generateWeeklyBriefs };
