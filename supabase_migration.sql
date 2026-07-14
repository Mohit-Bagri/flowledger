-- FlowLedger Supabase Migration Script
-- Run this in your Supabase SQL Editor to migrate to the 3-table architecture
--
-- 3-TABLE ARCHITECTURE:
--   1. income_sources - Income entries (actual income transactions)
--   2. recurring_transactions - Templates for recurring income/expenses
--   3. expenses - Expense entries (actual expense transactions)
--
-- DEPRECATED: income_transactions table is no longer used
-- All income entries are stored in income_sources table

-- ============================================
-- STEP 1: DROP THE DEPRECATED income_transactions TABLE
-- ============================================
-- WARNING: This will permanently delete all data in income_transactions
-- Make sure you have backed up any needed data before running this!

-- First, drop the trigger if it exists
DROP TRIGGER IF EXISTS update_income_transactions_updated_at ON income_transactions;

-- Drop the RLS policies
DROP POLICY IF EXISTS "Users can only access their own income transactions" ON income_transactions;
DROP POLICY IF EXISTS "Users can manage their own income_transactions" ON income_transactions;

-- Drop the indexes
DROP INDEX IF EXISTS idx_income_transactions_user_id;
DROP INDEX IF EXISTS idx_income_transactions_date;
DROP INDEX IF EXISTS idx_income_transactions_user;

-- Finally, drop the table
DROP TABLE IF EXISTS income_transactions;

-- ============================================
-- STEP 2: UPDATE income_sources TABLE
-- ============================================
-- Add new columns to support the full income entry model
ALTER TABLE income_sources
ADD COLUMN IF NOT EXISTS source_name TEXT,
ADD COLUMN IF NOT EXISTS category_id TEXT DEFAULT 'other',
ADD COLUMN IF NOT EXISTS amount DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS date TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS payment_method_id TEXT,
ADD COLUMN IF NOT EXISTS bank_account_id TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS payer_name TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS recurring_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS recurring_frequency INTEGER,
ADD COLUMN IF NOT EXISTS recurring_day_of_month INTEGER,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_income_sources_date ON income_sources(date);
CREATE INDEX IF NOT EXISTS idx_income_sources_recurring ON income_sources(recurring_transaction_id);

-- ============================================
-- STEP 3: UPDATE expenses TABLE
-- ============================================
ALTER TABLE expenses
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS amount DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS category_id TEXT DEFAULT 'other',
ADD COLUMN IF NOT EXISTS date TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS payment_method_id TEXT DEFAULT 'cash',
ADD COLUMN IF NOT EXISTS bank_account_id TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS merchant_name TEXT,
ADD COLUMN IF NOT EXISTS receipt_id TEXT,
ADD COLUMN IF NOT EXISTS receipt_image_path TEXT,
ADD COLUMN IF NOT EXISTS receipt_items_json TEXT,
ADD COLUMN IF NOT EXISTS has_receipt BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS recurring_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS recurring_frequency INTEGER,
ADD COLUMN IF NOT EXISTS recurring_day_of_month INTEGER,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_recurring ON expenses(recurring_transaction_id);

-- ============================================
-- STEP 4: UPDATE recurring_transactions TABLE
-- ============================================
ALTER TABLE recurring_transactions
ADD COLUMN IF NOT EXISTS type INTEGER,
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS amount DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS category_id TEXT DEFAULT 'other',
ADD COLUMN IF NOT EXISTS payment_method_id TEXT,
ADD COLUMN IF NOT EXISTS bank_account_id TEXT,
ADD COLUMN IF NOT EXISTS merchant_name TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS frequency INTEGER,
ADD COLUMN IF NOT EXISTS next_due_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_processed_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_recurring_transactions_type ON recurring_transactions(type);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_next_due ON recurring_transactions(next_due_date);

-- ============================================
-- STEP 5: UPDATE bank_accounts TABLE
-- ============================================
ALTER TABLE bank_accounts
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS account_name TEXT,
ADD COLUMN IF NOT EXISTS account_number TEXT,
ADD COLUMN IF NOT EXISTS ifsc_code TEXT,
ADD COLUMN IF NOT EXISTS account_type INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS custom_account_type_label TEXT,
ADD COLUMN IF NOT EXISTS color INTEGER,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- STEP 6: UPDATE payment_methods TABLE
-- ============================================
ALTER TABLE payment_methods
ADD COLUMN IF NOT EXISTS type INTEGER,
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS bank_account_id TEXT,
ADD COLUMN IF NOT EXISTS last_four_digits TEXT,
ADD COLUMN IF NOT EXISTS upi_id TEXT,
ADD COLUMN IF NOT EXISTS color INTEGER,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- STEP 7: UPDATE budgets TABLE
-- ============================================
ALTER TABLE budgets
ADD COLUMN IF NOT EXISTS category_id TEXT,
ADD COLUMN IF NOT EXISTS amount DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS month INTEGER,
ADD COLUMN IF NOT EXISTS year INTEGER,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_budgets_month_year ON budgets(month, year);

-- ============================================
-- STEP 8: UPDATE goals TABLE
-- ============================================
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS target_amount DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS current_amount DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS target_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS icon_code INTEGER,
ADD COLUMN IF NOT EXISTS color INTEGER,
ADD COLUMN IF NOT EXISTS milestones_reached TEXT,
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- STEP 9: UPDATE custom_categories TABLE
-- ============================================
ALTER TABLE custom_categories
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS icon_code INTEGER,
ADD COLUMN IF NOT EXISTS color INTEGER,
ADD COLUMN IF NOT EXISTS budget_limit DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 100,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- STEP 10: UPDATE soft_delete_user_profile FUNCTION
-- ============================================
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

-- ============================================
-- STEP 11: ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 12: CREATE/UPDATE RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can manage their own income_sources" ON income_sources;
DROP POLICY IF EXISTS "Users can manage their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can manage their own recurring_transactions" ON recurring_transactions;
DROP POLICY IF EXISTS "Users can manage their own bank_accounts" ON bank_accounts;
DROP POLICY IF EXISTS "Users can manage their own payment_methods" ON payment_methods;
DROP POLICY IF EXISTS "Users can manage their own budgets" ON budgets;
DROP POLICY IF EXISTS "Users can manage their own goals" ON goals;
DROP POLICY IF EXISTS "Users can manage their own custom_categories" ON custom_categories;
DROP POLICY IF EXISTS "Users can manage their own merchants" ON merchants;

CREATE POLICY "Users can manage their own income_sources"
ON income_sources FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own expenses"
ON expenses FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own recurring_transactions"
ON recurring_transactions FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own bank_accounts"
ON bank_accounts FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own payment_methods"
ON payment_methods FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own budgets"
ON budgets FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own goals"
ON goals FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own custom_categories"
ON custom_categories FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own merchants"
ON merchants FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'Migration completed successfully!' AS status,
       'income_transactions table has been removed' AS note1,
       'All tables updated to 3-table architecture' AS note2;
