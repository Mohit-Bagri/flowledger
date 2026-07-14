-- FlowLedger: Multi-Currency Support Migration
-- Run this in Supabase SQL Editor after the main migration

-- Add currency_code column to expenses table
ALTER TABLE expenses
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR';

-- Add currency_code column to income_sources table
ALTER TABLE income_sources
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR';

-- Add currency_code column to recurring_transactions table
ALTER TABLE recurring_transactions
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR';

-- Add currency_code column to budgets table
ALTER TABLE budgets
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR';

-- Add currency_code column to goals table
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR';

-- Create index for currency filtering (optional, for performance)
CREATE INDEX IF NOT EXISTS idx_expenses_currency ON expenses(currency_code);
CREATE INDEX IF NOT EXISTS idx_income_sources_currency ON income_sources(currency_code);
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_currency ON recurring_transactions(currency_code);

-- Update existing records to use INR as default (if NULL)
UPDATE expenses SET currency_code = 'INR' WHERE currency_code IS NULL;
UPDATE income_sources SET currency_code = 'INR' WHERE currency_code IS NULL;
UPDATE recurring_transactions SET currency_code = 'INR' WHERE currency_code IS NULL;
UPDATE budgets SET currency_code = 'INR' WHERE currency_code IS NULL;
UPDATE goals SET currency_code = 'INR' WHERE currency_code IS NULL;

-- Grant permissions (if using RLS)
-- These are already handled by the main migration's RLS policies

-- Verify the changes
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name = 'currency_code'
ORDER BY table_name;
