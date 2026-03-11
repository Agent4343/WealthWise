const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SYSTEM_PROMPT = `You are WealthWise, a Canadian financial education assistant. You provide educational guidance — not personalized financial advice. You are knowledgeable about Canadian tax rules, RRSP, TFSA, CPP, OAS, and investment fundamentals. You NEVER recommend specific securities, specific funds by name, or specific dollar amounts to invest. You use phrases like "you may want to consider", "historically, investors who...", "one option worth exploring is..." You always note that users should consult a licensed financial advisor (CFP) for personalized advice. You are warm, direct, judgment-free, and plain-spoken.

You must always respond with valid JSON matching this exact structure:
{
  "week_at_a_glance": "2-3 sentence snapshot relevant to this user this week",
  "canadian_economic_pulse": "Plain-English summary of Bank of Canada rates, inflation, TSX, CAD/USD",
  "accounts_this_week": "Personalized commentary on the user's RRSP and TFSA situation this week",
  "what_to_think_about": "2-3 educational concepts relevant to this user's profile and current market — always guidance framing",
  "monday_action_item": "One specific achievable action the user can take this week — never a buy/sell directive",
  "disclaimer": "WealthWise Weekly Brief is educational guidance only and does not constitute personalized financial, investment, or tax advice under OSC regulations. Past performance does not guarantee future results. Consult a Certified Financial Planner (CFP) for advice specific to your situation."
}`;

/**
 * Fetches current Canadian market context using Claude's web search tool.
 * @returns {Promise<string>} Plain-text market context summary
 */
async function fetchMarketContext() {
  try {
    const response = await client.messages.create({
      model: 'claude-sonnet-4-5',
      max_tokens: 1024,
      tools: [{ type: 'web_search_20250305', name: 'web_search' }],
      messages: [
        {
          role: 'user',
          content: 'Search for the current Bank of Canada overnight rate, latest Canadian inflation rate (CPI), TSX Composite Index performance this week, and CAD/USD exchange rate. Provide a concise factual summary of each in plain English suitable for a Canadian financial education app.',
        },
      ],
    });

    // Extract text from the response
    const textContent = response.content
      .filter(block => block.type === 'text')
      .map(block => block.text)
      .join('\n');

    return textContent || 'Current market data unavailable. Using general Canadian financial context.';
  } catch (err) {
    console.error('Market context fetch error:', err);
    return 'Current market data temporarily unavailable. General Canadian financial education context applies.';
  }
}

/**
 * Generates a personalized Weekly Brief for a single user.
 * @param {Object} profile - User's financial profile from Supabase
 * @param {string} marketContext - Current market context from web search
 * @returns {Promise<Object>} Structured 5-section Weekly Brief
 */
async function generateWeeklyBrief(profile, marketContext) {
  const userContext = buildUserContext(profile);

  const userPrompt = `Generate a personalized Monday Morning Weekly Brief for this WealthWise user.

CURRENT CANADIAN MARKET CONTEXT:
${marketContext}

USER FINANCIAL PROFILE:
${userContext}

Generate the Weekly Brief as a JSON object with the exact structure specified in the system prompt. Make it personal, specific to their situation, and actionable. Keep each section concise and readable in under 2 minutes.`;

  const response = await client.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 1500,
    system: SYSTEM_PROMPT,
    messages: [
      {
        role: 'user',
        content: userPrompt,
      },
    ],
  });

  const rawText = response.content
    .filter(block => block.type === 'text')
    .map(block => block.text)
    .join('');

  // Extract JSON from the response
  const jsonMatch = rawText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error('Claude did not return valid JSON in Weekly Brief response');
  }

  const brief = JSON.parse(jsonMatch[0]);

  // Validate required fields
  const requiredFields = [
    'week_at_a_glance',
    'canadian_economic_pulse',
    'accounts_this_week',
    'what_to_think_about',
    'monday_action_item',
    'disclaimer',
  ];

  for (const field of requiredFields) {
    if (!brief[field]) {
      throw new Error(`Missing required field in Weekly Brief: ${field}`);
    }
  }

  return {
    ...brief,
    usage: {
      input_tokens: response.usage.input_tokens,
      output_tokens: response.usage.output_tokens,
    },
  };
}

/**
 * Builds a plain-text user context string from a financial profile.
 * @param {Object} profile - Financial profile record from Supabase
 * @returns {string} Human-readable profile summary for the AI prompt
 */
function buildUserContext(profile) {
  if (!profile) {
    return 'New user — no financial profile set up yet. Provide general guidance for a Canadian starting their financial journey.';
  }

  const lines = [];

  if (profile.current_age) {
    const yearsToRetirement = (profile.target_retirement_age || 65) - profile.current_age;
    lines.push(`Age: ${profile.current_age} | Target retirement age: ${profile.target_retirement_age || 65} | Years to retirement: ${yearsToRetirement}`);
  }

  if (profile.province) {
    lines.push(`Province: ${profile.province}`);
  }

  if (profile.income_bracket) {
    lines.push(`Income bracket: ${profile.income_bracket}`);
  }

  if (profile.rrsp_room_available !== null && profile.rrsp_room_available !== undefined) {
    lines.push(`Available RRSP contribution room: $${profile.rrsp_room_available.toLocaleString()}`);
  }

  if (profile.tfsa_room_used !== null && profile.tfsa_room_used !== undefined) {
    lines.push(`TFSA contribution room used: $${profile.tfsa_room_used.toLocaleString()}`);
  }

  if (profile.current_rrsp_balance !== null && profile.current_rrsp_balance !== undefined) {
    lines.push(`Current RRSP balance: $${profile.current_rrsp_balance.toLocaleString()}`);
  }

  if (profile.current_tfsa_balance !== null && profile.current_tfsa_balance !== undefined) {
    lines.push(`Current TFSA balance: $${profile.current_tfsa_balance.toLocaleString()}`);
  }

  if (profile.current_savings_balance !== null && profile.current_savings_balance !== undefined) {
    lines.push(`Other savings/investments: $${profile.current_savings_balance.toLocaleString()}`);
  }

  if (profile.monthly_savings_amount !== null && profile.monthly_savings_amount !== undefined) {
    lines.push(`Monthly savings amount: $${profile.monthly_savings_amount.toLocaleString()}`);
  }

  if (profile.monthly_savings_target !== null && profile.monthly_savings_target !== undefined) {
    lines.push(`Monthly savings target: $${profile.monthly_savings_target.toLocaleString()}`);
  }

  if (profile.risk_tolerance) {
    lines.push(`Risk tolerance: ${profile.risk_tolerance}`);
  }

  return lines.length > 0 ? lines.join('\n') : 'Profile partially complete — provide general guidance.';
}

module.exports = { generateWeeklyBrief, fetchMarketContext, buildUserContext };
