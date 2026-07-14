-- FlowLedger Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor to set up the required tables
--
-- 3-TABLE ARCHITECTURE:
--   1. income_sources - Income entries (actual income transactions)
--   2. recurring_transactions - Templates for recurring income/expenses
--   3. expenses - Expense entries (actual expense transactions)
--
-- DEPRECATED: income_transactions table is no longer used
-- All income entries are stored in income_sources table

-- Enable RLS (Row Level Security) for all tables

-- =====================================================
-- PROFILES TABLE (User Information)
-- =====================================================
-- This stores user profile data linked to auth.users
-- The id is the same as auth.users.id (UUID)

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  birth_date DATE,
  currency TEXT DEFAULT 'INR',
  locale TEXT DEFAULT 'en_IN',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'deleted')),
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url, birth_date)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.raw_user_meta_data->>'avatar_url',
    (NEW.raw_user_meta_data->>'birth_date')::DATE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile when a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- SOFT DELETE FUNCTION
-- =====================================================
-- This function soft-deletes a user profile and all their data
-- The user can re-register with the same email after deletion

CREATE OR REPLACE FUNCTION public.soft_delete_user_profile()
RETURNS BOOLEAN AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  IF current_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Delete all user data from all tables (3-table architecture)
  DELETE FROM income_sources WHERE user_id = current_user_id;
  DELETE FROM expenses WHERE user_id = current_user_id;
  DELETE FROM recurring_transactions WHERE user_id = current_user_id;
  DELETE FROM bank_accounts WHERE user_id = current_user_id;
  DELETE FROM payment_methods WHERE user_id = current_user_id;
  DELETE FROM budgets WHERE user_id = current_user_id;
  DELETE FROM goals WHERE user_id = current_user_id;
  DELETE FROM custom_categories WHERE user_id = current_user_id;
  DELETE FROM merchants WHERE user_id = current_user_id;

  -- Mark profile as deleted (soft delete)
  UPDATE profiles
  SET
    status = 'deleted',
    deleted_at = NOW(),
    full_name = NULL,
    avatar_url = NULL
  WHERE id = current_user_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if email can be used for new signup
-- Returns true if email doesn't exist or existing account is deleted
CREATE OR REPLACE FUNCTION public.can_register_email(check_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if there's an active profile with this email
  IF EXISTS (
    SELECT 1 FROM profiles
    WHERE email = check_email
    AND status = 'active'
  ) THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reactivate a deleted profile (for re-registration)
CREATE OR REPLACE FUNCTION public.reactivate_profile()
RETURNS BOOLEAN AS $$
DECLARE
  current_user_id UUID;
  user_email TEXT;
BEGIN
  current_user_id := auth.uid();

  IF current_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Get email from auth.users
  SELECT email INTO user_email FROM auth.users WHERE id = current_user_id;

  -- Check if there's a deleted profile with this email
  IF EXISTS (
    SELECT 1 FROM profiles
    WHERE email = user_email
    AND status = 'deleted'
  ) THEN
    -- Reactivate the profile
    UPDATE profiles
    SET
      id = current_user_id,
      status = 'active',
      deleted_at = NULL,
      updated_at = NOW()
    WHERE email = user_email AND status = 'deleted';

    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DATA TABLES
-- =====================================================

-- =====================================================
-- INCOME SOURCES TABLE (Primary Income Entry Table)
-- =====================================================
-- Stores actual income transactions (like expenses table)
-- Has full parity with expenses table for comprehensive tracking
CREATE TABLE IF NOT EXISTS income_sources (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  source_name TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  category_id TEXT DEFAULT 'other',
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Payment details
  payment_method_id TEXT,
  bank_account_id TEXT,
  -- Description fields
  description TEXT,
  payer_name TEXT,
  notes TEXT,
  -- Recurring transaction fields
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_transaction_id TEXT,
  recurring_frequency INTEGER,
  recurring_day_of_month INTEGER,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own income sources"
  ON income_sources FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_income_sources_user_id ON income_sources(user_id);
CREATE INDEX idx_income_sources_date ON income_sources(date);
CREATE INDEX idx_income_sources_recurring ON income_sources(recurring_transaction_id);

-- =====================================================
-- EXPENSES TABLE
-- =====================================================
-- Stores actual expense transactions
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  name TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  category_id TEXT DEFAULT 'other',
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Payment details
  payment_method_id TEXT DEFAULT 'cash',
  bank_account_id TEXT,
  -- Description fields
  description TEXT,
  merchant_name TEXT,
  -- Receipt fields
  receipt_id TEXT,
  receipt_image_path TEXT,
  receipt_items_json TEXT,
  has_receipt BOOLEAN DEFAULT FALSE,
  -- Recurring transaction fields
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_transaction_id TEXT,
  recurring_frequency INTEGER,
  recurring_day_of_month INTEGER,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own expenses"
  ON expenses FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_recurring ON expenses(recurring_transaction_id);

-- =====================================================
-- RECURRING TRANSACTIONS TABLE
-- =====================================================
-- Templates for recurring income AND expenses
-- type: 0 = income, 1 = expense
CREATE TABLE IF NOT EXISTS recurring_transactions (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  type INTEGER NOT NULL CHECK (type IN (0, 1)), -- 0=income, 1=expense
  name TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  category_id TEXT DEFAULT 'other',
  -- Payment details
  payment_method_id TEXT,
  bank_account_id TEXT,
  -- Description fields
  merchant_name TEXT,
  description TEXT,
  -- Recurring schedule
  frequency INTEGER NOT NULL, -- 0=daily, 1=weekly, 2=biweekly, 3=monthly, 4=quarterly, 5=yearly
  next_due_date TIMESTAMPTZ NOT NULL,
  last_processed_date TIMESTAMPTZ,
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own recurring transactions"
  ON recurring_transactions FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_recurring_transactions_user_id ON recurring_transactions(user_id);
CREATE INDEX idx_recurring_transactions_type ON recurring_transactions(type);
CREATE INDEX idx_recurring_transactions_next_due ON recurring_transactions(next_due_date);

-- =====================================================
-- BANK ACCOUNTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS bank_accounts (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  bank_name TEXT NOT NULL,
  account_name TEXT NOT NULL,
  account_number TEXT,
  ifsc_code TEXT,
  account_type INTEGER DEFAULT 0, -- 0=savings, 1=current, 2=salary, 3=fd, 4=nri, 5=other
  custom_account_type_label TEXT,
  -- Display
  color INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own bank accounts"
  ON bank_accounts FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_bank_accounts_user_id ON bank_accounts(user_id);

-- =====================================================
-- PAYMENT METHODS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  type INTEGER NOT NULL, -- 0=cash, 1=bankTransfer, 2=upi, 3=debitCard, 4=creditCard, 5=wallet, 6=cheque, 7=other
  name TEXT NOT NULL,
  bank_account_id TEXT,
  -- Card/UPI details
  last_four_digits TEXT,
  upi_id TEXT,
  -- Display
  color INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own payment methods"
  ON payment_methods FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);

-- =====================================================
-- BUDGETS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS budgets (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  category_id TEXT NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own budgets"
  ON budgets FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_month_year ON budgets(month, year);

-- =====================================================
-- GOALS TABLE (Savings Goals)
-- =====================================================
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  name TEXT NOT NULL,
  target_amount DOUBLE PRECISION NOT NULL,
  current_amount DOUBLE PRECISION DEFAULT 0,
  target_date TIMESTAMPTZ,
  -- Display
  icon_code INTEGER,
  color INTEGER,
  -- Progress
  milestones_reached TEXT, -- JSON array as text
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own goals"
  ON goals FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_goals_user_id ON goals(user_id);

-- =====================================================
-- CUSTOM CATEGORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS custom_categories (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Core fields
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  name TEXT NOT NULL,
  icon_code INTEGER,
  color INTEGER,
  -- Budget (for expense categories)
  budget_limit DOUBLE PRECISION,
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 100,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Legacy JSON data column for backward compatibility
  data JSONB
);

ALTER TABLE custom_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own custom categories"
  ON custom_categories FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_custom_categories_user_id ON custom_categories(user_id);
CREATE INDEX idx_custom_categories_type ON custom_categories(type);

-- =====================================================
-- MERCHANTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS merchants (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id, user_id)
);

ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own merchants"
  ON merchants FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_merchants_user_id ON merchants(user_id);

-- =====================================================
-- FUNCTION: Update updated_at timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_income_sources_updated_at BEFORE UPDATE ON income_sources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recurring_transactions_updated_at BEFORE UPDATE ON recurring_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON payment_methods FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_custom_categories_updated_at BEFORE UPDATE ON custom_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON merchants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
