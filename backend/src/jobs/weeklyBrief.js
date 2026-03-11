const cron = require('node-cron');
const { v4: uuidv4 } = require('uuid');
const supabase = require('../config/supabase');
const { generateWeeklyBrief, fetchMarketContext } = require('../services/aiEngine');
const { sendWeeklyBriefEmail } = require('../services/emailService');
const { sendWeeklyBriefNotification } = require('../services/pushNotifications');

/**
 * Railway cron job that generates and delivers the Weekly Brief to all Premium subscribers.
 * Schedule: 04:00 UTC = 23:00 EST (UTC-5) in winter / 00:00 EDT (UTC-4) in summer.
 * Both windows fall on Sunday night / early Monday morning, ensuring delivery before 07:00 Monday EST.
 *
 * Processing pipeline:
 * 1. Fetch all Premium subscribers from Supabase
 * 2. Fetch current Canadian market context via Claude web search
 * 3. For each user: generate personalized brief, store in DB, send email + push notification
 */
const weeklyBriefJob = cron.schedule(
  '0 4 * * 1', // 04:00 UTC Monday: 23:00 EST (winter) / 00:00 EDT (summer)
  runWeeklyBriefGeneration,
  {
    scheduled: false,
    timezone: 'UTC',
  },
);

/**
 * Main execution function for the weekly brief pipeline.
 * Can be called directly for testing/manual triggers.
 */
async function runWeeklyBriefGeneration() {
  const runId = uuidv4();
  const startTime = Date.now();
  const weekStartDate = getMondayDate();

  console.log(`[WeeklyBrief ${runId}] Starting generation run for week of ${weekStartDate}`);

  try {
    // Step 1: Fetch all Premium subscribers
    const { data: premiumUsers, error: fetchError } = await supabase
      .from('app_users')
      .select(`
        id,
        email,
        subscription_tier,
        subscription_expires_at,
        apns_device_tokens,
        financial_profiles (*)
      `)
      .eq('subscription_tier', 'premium')
      .or(`subscription_expires_at.is.null,subscription_expires_at.gt.${new Date().toISOString()}`);

    if (fetchError) {
      throw new Error(`Failed to fetch Premium subscribers: ${fetchError.message}`);
    }

    if (!premiumUsers || premiumUsers.length === 0) {
      console.log(`[WeeklyBrief ${runId}] No Premium subscribers found. Exiting.`);
      return { processed: 0, errors: 0, durationMs: Date.now() - startTime };
    }

    console.log(`[WeeklyBrief ${runId}] Found ${premiumUsers.length} Premium subscribers`);

    // Step 2: Fetch market context once (shared across all users to reduce API calls)
    console.log(`[WeeklyBrief ${runId}] Fetching current Canadian market context...`);
    const marketContext = await fetchMarketContext();
    console.log(`[WeeklyBrief ${runId}] Market context fetched (${marketContext.length} chars)`);

    // Step 3: Process each subscriber
    let processed = 0;
    let errors = 0;

    for (const user of premiumUsers) {
      try {
        await processUserBrief(user, marketContext, weekStartDate, runId);
        processed++;
        // Small delay between users to avoid overwhelming downstream APIs
        await sleep(500);
      } catch (userErr) {
        errors++;
        console.error(`[WeeklyBrief ${runId}] Error processing user ${user.id}:`, userErr.message);
      }
    }

    const durationMs = Date.now() - startTime;
    console.log(`[WeeklyBrief ${runId}] Completed: ${processed} processed, ${errors} errors, ${durationMs}ms total`);

    return { processed, errors, durationMs };
  } catch (err) {
    const durationMs = Date.now() - startTime;
    console.error(`[WeeklyBrief ${runId}] Fatal error after ${durationMs}ms:`, err);
    throw err;
  }
}

/**
 * Processes a single user's Weekly Brief: generate → store → notify.
 */
async function processUserBrief(user, marketContext, weekStartDate, runId) {
  const profile = user.financial_profiles?.[0] || null;

  console.log(`[WeeklyBrief ${runId}] Generating brief for user ${user.id}`);

  // Generate the AI brief
  const brief = await generateWeeklyBrief(profile, marketContext);

  // Store in Supabase
  const { data: reportRecord, error: insertError } = await supabase
    .from('user_reports')
    .insert({
      user_id: user.id,
      week_start_date: weekStartDate,
      generated_at: new Date().toISOString(),
      title: `Your Monday Brief — ${formatDisplayDate(weekStartDate)}`,
      summary_snippet: brief.week_at_a_glance.substring(0, 150),
      week_at_a_glance: brief.week_at_a_glance,
      canadian_economic_pulse: brief.canadian_economic_pulse,
      accounts_this_week: brief.accounts_this_week,
      what_to_think_about: brief.what_to_think_about,
      monday_action_item: brief.monday_action_item,
      disclaimer: brief.disclaimer,
      ai_tokens_used: (brief.usage?.input_tokens || 0) + (brief.usage?.output_tokens || 0),
    })
    .select('id')
    .single();

  if (insertError) {
    throw new Error(`DB insert failed for user ${user.id}: ${insertError.message}`);
  }

  console.log(`[WeeklyBrief ${runId}] Stored report ${reportRecord.id} for user ${user.id}`);

  // Send email notification
  if (user.email) {
    try {
      await sendWeeklyBriefEmail(user.email, brief, weekStartDate);
      console.log(`[WeeklyBrief ${runId}] Email sent to ${user.email}`);
    } catch (emailErr) {
      // Email failures should not block push notification
      console.error(`[WeeklyBrief ${runId}] Email failed for ${user.email}:`, emailErr.message);
    }
  }

  // Send push notification
  if (user.apns_device_tokens && user.apns_device_tokens.length > 0) {
    try {
      await sendWeeklyBriefNotification(user.apns_device_tokens, formatDisplayDate(weekStartDate));
      console.log(`[WeeklyBrief ${runId}] Push sent to ${user.apns_device_tokens.length} device(s) for user ${user.id}`);
    } catch (pushErr) {
      console.error(`[WeeklyBrief ${runId}] Push failed for user ${user.id}:`, pushErr.message);
    }
  }
}

/**
 * Returns the ISO date string for the upcoming Monday (week start).
 */
function getMondayDate() {
  const now = new Date();
  const dayOfWeek = now.getUTCDay();
  const daysUntilMonday = dayOfWeek === 1 ? 0 : (8 - dayOfWeek) % 7 || 7;
  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() + daysUntilMonday);
  monday.setUTCHours(0, 0, 0, 0);
  return monday.toISOString().split('T')[0];
}

/**
 * Formats a date string for display (e.g. "Monday, March 9, 2026").
 */
function formatDisplayDate(dateStr) {
  return new Date(dateStr + 'T12:00:00Z').toLocaleDateString('en-CA', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

/**
 * Simple sleep helper for rate limiting.
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = weeklyBriefJob;
module.exports.runWeeklyBriefGeneration = runWeeklyBriefGeneration;
module.exports.getMondayDate = getMondayDate;
