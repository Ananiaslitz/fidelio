-- Fidelio Loyalty Platform - Initial Schema Migration
-- PostgreSQL/Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- MERCHANTS TABLE
-- =====================================================
CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    api_key TEXT NOT NULL UNIQUE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchants_api_key ON merchants(api_key);

-- =====================================================
-- CAMPAIGNS TABLE
-- =====================================================
CREATE TYPE campaign_type AS ENUM ('PUNCH_CARD', 'CASHBACK', 'PROGRESSIVE');

CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type campaign_type NOT NULL,
    config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_campaigns_merchant ON campaigns(merchant_id);
CREATE INDEX idx_campaigns_active ON campaigns(merchant_id, is_active) WHERE is_active = true;

-- =====================================================
-- WALLETS TABLE
-- =====================================================
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- References Supabase Auth users
    phone_hash TEXT NOT NULL,
    balance DECIMAL(12, 2) DEFAULT 0.00,
    state JSONB DEFAULT '{}', -- Campaign-specific state (punch count, tier, etc.)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(merchant_id, user_id)
);

CREATE INDEX idx_wallets_merchant_user ON wallets(merchant_id, user_id);
CREATE INDEX idx_wallets_phone_hash ON wallets(phone_hash);

-- =====================================================
-- SHADOW BALANCES TABLE
-- =====================================================
CREATE TABLE shadow_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    phone_hash TEXT NOT NULL,
    amount DECIMAL(12, 2) DEFAULT 0.00,
    state JSONB DEFAULT '{}',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    converted_at TIMESTAMP WITH TIME ZONE, -- NULL if not converted yet
    UNIQUE(merchant_id, phone_hash)
);

CREATE INDEX idx_shadow_merchant_phone ON shadow_balances(merchant_id, phone_hash);
CREATE INDEX idx_shadow_expires ON shadow_balances(expires_at) WHERE converted_at IS NULL;

-- =====================================================
-- TRANSACTIONS TABLE (Immutable Ledger)
-- =====================================================
CREATE TYPE transaction_type AS ENUM ('EARN', 'REDEEM', 'EXPIRE', 'CONVERT');

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id) ON DELETE SET NULL,
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    shadow_balance_id UUID REFERENCES shadow_balances(id) ON DELETE SET NULL,
    transaction_type transaction_type NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_merchant ON transactions(merchant_id);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_transactions_shadow ON transactions(shadow_balance_id);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON merchants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- HELPER FUNCTION: Generate Phone Hash
-- =====================================================
CREATE OR REPLACE FUNCTION hash_phone(phone TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(digest(phone, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
