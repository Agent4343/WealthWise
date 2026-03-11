-- WealthWise Supabase Database Schema
-- Run this in the Supabase SQL editor to initialize the database.
-- All tables use Row Level Security (RLS) with Supabase Auth integration.

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: app_users
-- Mirrors Supabase auth.users with app-specific metadata.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.app_users (
  id                           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                        TEXT NOT NULL,
  subscription_tier            TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium')),
  subscription_expires_at      TIMESTAMPTZ,
  apple_original_transaction_id TEXT,
  apple_account_token          UUID,                      -- appAccountToken from StoreKit 2
  apns_device_tokens           TEXT[] DEFAULT '{}',       -- Array of APNs device tokens
  created_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for StoreKit 2 webhook lookups
CREATE INDEX IF NOT EXISTS idx_app_users_apple_account_token ON public.app_users(apple_account_token);

-- RLS
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own record"
  ON public.app_users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own record"
  ON public.app_users FOR UPDATE
  USING (auth.uid() = id);

-- Service role can do everything (used by backend)
CREATE POLICY "Service role full access to app_users"
  ON public.app_users
  USING (auth.role() = 'service_role');

-- ============================================================
-- TABLE: financial_profiles
-- One profile per user. Stores all financial data for AI engine.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.financial_profiles (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL UNIQUE REFERENCES public.app_users(id) ON DELETE CASCADE,
  current_age             INTEGER CHECK (current_age BETWEEN 18 AND 100),
  target_retirement_age   INTEGER CHECK (target_retirement_age BETWEEN 45 AND 80),
  province                TEXT CHECK (province IN ('AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT')),
  income_bracket          TEXT,                           -- e.g. "$50,000–$75,000"
  tfsa_room_used          DECIMAL(12,2),
  rrsp_room_available     DECIMAL(12,2),
  current_savings_balance DECIMAL(12,2),
  current_rrsp_balance    DECIMAL(12,2),
  current_tfsa_balance    DECIMAL(12,2),
  monthly_savings_amount  DECIMAL(10,2),
  monthly_savings_target  DECIMAL(10,2),
  risk_tolerance          TEXT CHECK (risk_tolerance IN ('conservative', 'balanced', 'growth')),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE public.financial_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own profile"
  ON public.financial_profiles
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to financial_profiles"
  ON public.financial_profiles
  USING (auth.role() = 'service_role');

-- ============================================================
-- TABLE: user_reports
-- Stores generated Weekly Brief reports for Premium subscribers.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_reports (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                 UUID NOT NULL REFERENCES public.app_users(id) ON DELETE CASCADE,
  week_start_date         DATE NOT NULL,
  generated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  title                   TEXT NOT NULL,
  summary_snippet         TEXT,                           -- First 150 chars for list view
  week_at_a_glance        TEXT NOT NULL,
  canadian_economic_pulse TEXT NOT NULL,
  accounts_this_week      TEXT NOT NULL,
  what_to_think_about     TEXT NOT NULL,
  monday_action_item      TEXT NOT NULL,
  disclaimer              TEXT NOT NULL,
  ai_tokens_used          INTEGER,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_start_date)                       -- One report per user per week
);

-- Index for efficient paginated queries
CREATE INDEX IF NOT EXISTS idx_user_reports_user_generated
  ON public.user_reports(user_id, generated_at DESC);

-- RLS
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own reports"
  ON public.user_reports FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to user_reports"
  ON public.user_reports
  USING (auth.role() = 'service_role');

-- ============================================================
-- TABLE: calculator_saves
-- Saves calculator results for Basic/Premium users.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.calculator_saves (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.app_users(id) ON DELETE CASCADE,
  calculator_type TEXT NOT NULL CHECK (calculator_type IN ('retirement', 'tfsa', 'rrsp', 'fee_drag', 'fire')),
  inputs          JSONB NOT NULL,
  outputs         JSONB NOT NULL,
  label           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calculator_saves_user
  ON public.calculator_saves(user_id, calculator_type, created_at DESC);

-- RLS
ALTER TABLE public.calculator_saves ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own calculator saves"
  ON public.calculator_saves
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to calculator_saves"
  ON public.calculator_saves
  USING (auth.role() = 'service_role');

-- ============================================================
-- FUNCTION: update updated_at timestamp automatically
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_app_users_updated_at
  BEFORE UPDATE ON public.app_users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trigger_financial_profiles_updated_at
  BEFORE UPDATE ON public.financial_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
