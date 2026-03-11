-- WealthWise Database Schema
-- Supabase (PostgreSQL)
-- Migration 001: Initial Schema

-- ============================================
-- Table: app_users
-- ============================================
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    province TEXT CHECK (province IN ('AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Table: financial_profiles
-- ============================================
CREATE TABLE IF NOT EXISTS financial_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    age SMALLINT CHECK (age >= 18 AND age <= 100),
    retirement_age SMALLINT CHECK (retirement_age >= 45 AND retirement_age <= 100),
    income_bracket TEXT,
    rrsp_room_used NUMERIC(12,2) DEFAULT 0,
    tfsa_room_used NUMERIC(12,2) DEFAULT 0,
    current_savings NUMERIC(12,2) DEFAULT 0,
    monthly_contribution NUMERIC(10,2) DEFAULT 0,
    risk_tolerance TEXT CHECK (risk_tolerance IN ('conservative', 'balanced', 'growth')) DEFAULT 'balanced',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- Table: subscriptions
-- ============================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('free', 'basic', 'premium')) DEFAULT 'free',
    apple_original_transaction_id TEXT,
    apple_product_id TEXT,
    status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled', 'grace_period')) DEFAULT 'active',
    expires_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- Table: weekly_briefs
-- ============================================
CREATE TABLE IF NOT EXISTS weekly_briefs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    week_of DATE NOT NULL,
    section_1_snapshot TEXT NOT NULL,
    section_2_market TEXT NOT NULL,
    section_3_accounts TEXT NOT NULL,
    section_4_learn TEXT NOT NULL,
    section_5_action TEXT NOT NULL,
    tokens_used INTEGER,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    UNIQUE(user_id, week_of)
);

-- ============================================
-- Indexes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_financial_profiles_user_id ON financial_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_weekly_briefs_user_id ON weekly_briefs(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_briefs_week_of ON weekly_briefs(week_of DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_briefs_user_week ON weekly_briefs(user_id, week_of DESC);

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_briefs ENABLE ROW LEVEL SECURITY;

-- app_users: Users can only read/update their own record
CREATE POLICY "Users can view own profile"
    ON app_users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON app_users FOR UPDATE
    USING (auth.uid() = id);

-- financial_profiles: Users can only access their own profile
CREATE POLICY "Users can view own financial profile"
    ON financial_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own financial profile"
    ON financial_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own financial profile"
    ON financial_profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- subscriptions: Users can only read their own subscription
CREATE POLICY "Users can view own subscription"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- weekly_briefs: Users can only read their own briefs
CREATE POLICY "Users can view own briefs"
    ON weekly_briefs FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================
-- Service role bypass (for backend operations)
-- The SUPABASE_SERVICE_KEY bypasses RLS automatically
-- ============================================
