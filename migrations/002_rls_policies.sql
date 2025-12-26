-- Fidelio Loyalty Platform - Row Level Security Policies
-- PostgreSQL/Supabase

-- Enable RLS on all tables
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE shadow_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- MERCHANTS POLICIES
-- =====================================================

-- Merchants can read their own data
CREATE POLICY "Merchants can view own data"
    ON merchants FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = merchants.id
    ));

-- Merchants can update their own data
CREATE POLICY "Merchants can update own data"
    ON merchants FOR UPDATE
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = merchants.id
    ));

-- =====================================================
-- CAMPAIGNS POLICIES
-- =====================================================

-- Merchants can manage their campaigns
CREATE POLICY "Merchants can manage campaigns"
    ON campaigns FOR ALL
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = campaigns.merchant_id
    ));

-- Public can read active campaigns (for display purposes)
CREATE POLICY "Public can view active campaigns"
    ON campaigns FOR SELECT
    USING (is_active = true AND (starts_at IS NULL OR starts_at <= CURRENT_TIMESTAMP));

-- =====================================================
-- WALLETS POLICIES
-- =====================================================

-- Users can view their own wallets
CREATE POLICY "Users can view own wallets"
    ON wallets FOR SELECT
    USING (auth.uid() = user_id);

-- Merchants can view wallets for their customers
CREATE POLICY "Merchants can view customer wallets"
    ON wallets FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = wallets.merchant_id
    ));

-- API Service Role can manage all wallets (for ingestion)
CREATE POLICY "Service role can manage wallets"
    ON wallets FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- =====================================================
-- SHADOW BALANCES POLICIES
-- =====================================================

-- Only service role can access shadow balances
CREATE POLICY "Service role can manage shadow balances"
    ON shadow_balances FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- Merchants can view shadow stats
CREATE POLICY "Merchants can view shadow stats"
    ON shadow_balances FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = shadow_balances.merchant_id
    ));

-- =====================================================
-- TRANSACTIONS POLICIES
-- =====================================================

-- Users can view their own transactions
CREATE POLICY "Users can view own transactions"
    ON transactions FOR SELECT
    USING (wallet_id IN (
        SELECT id FROM wallets WHERE user_id = auth.uid()
    ));

-- Merchants can view all transactions for their business
CREATE POLICY "Merchants can view transactions"
    ON transactions FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM merchant_users WHERE merchant_id = transactions.merchant_id
    ));

-- Only service role can insert transactions (immutable ledger)
CREATE POLICY "Service role can insert transactions"
    ON transactions FOR INSERT
    WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- =====================================================
-- MERCHANT USERS TABLE (for RLS)
-- =====================================================

-- Table to link Supabase Auth users to merchants
CREATE TABLE merchant_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- Supabase Auth user
    role TEXT DEFAULT 'owner',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(merchant_id, user_id)
);

CREATE INDEX idx_merchant_users_user ON merchant_users(user_id);
CREATE INDEX idx_merchant_users_merchant ON merchant_users(merchant_id);

ALTER TABLE merchant_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own merchant access"
    ON merchant_users FOR SELECT
    USING (auth.uid() = user_id);
