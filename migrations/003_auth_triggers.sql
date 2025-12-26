-- Fidelio Loyalty Platform - Auth Triggers and Webhooks
-- PostgreSQL/Supabase

-- =====================================================
-- FUNCTION: Notify Backend on User Sign-Up
-- =====================================================

-- This function will be called by a Supabase webhook or trigger
-- when a new user signs up with a phone number.
-- It notifies the Fidelio backend to convert any shadow wallets.

CREATE OR REPLACE FUNCTION notify_shadow_conversion()
RETURNS TRIGGER AS $$
DECLARE
    phone_raw TEXT;
    phone_normalized TEXT;
BEGIN
    -- Extract phone from new user
    phone_raw := NEW.phone;
    
    -- Normalize phone (remove spaces, dashes, etc)
    phone_normalized := regexp_replace(phone_raw, '[^0-9+]', '', 'g');
    
    -- Log the conversion attempt
    RAISE NOTICE 'New user signed up: % with phone: %', NEW.id, phone_normalized;
    
    -- Option 1: Direct conversion (if backend is in same network)
    -- This would require a stored procedure to call the conversion service
    -- For now, we'll rely on webhook approach
    
    -- Option 2: Insert into a queue table for processing
    INSERT INTO shadow_conversion_queue (user_id, phone, created_at)
    VALUES (NEW.id, phone_normalized, NOW());
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- SHADOW CONVERSION QUEUE TABLE
-- =====================================================

-- Queue table to track pending shadow wallet conversions
CREATE TABLE IF NOT EXISTS shadow_conversion_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    phone TEXT NOT NULL,
    processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_conversion_queue_pending ON shadow_conversion_queue(processed) WHERE processed = false;

-- =====================================================
-- TRIGGER: On Auth User Creation
-- =====================================================

-- Note: This trigger should be created on the auth.users table
-- In Supabase, you may need to use a webhook instead since
-- direct triggers on auth.users might not be allowed.

-- If using PostgreSQL trigger (for self-hosted):
-- CREATE TRIGGER on_auth_user_created
--     AFTER INSERT ON auth.users
--     FOR EACH ROW
--     EXECUTE FUNCTION notify_shadow_conversion();

-- =====================================================
-- ALTERNATIVE: Webhook Endpoint Handler
-- =====================================================

-- For Supabase, configure a webhook in the dashboard:
-- 1. Go to Database > Webhooks
-- 2. Create new webhook
-- 3. Table: auth.users
-- 4. Event: INSERT
-- 5. HTTP request: POST to https://your-api.com/v1/webhook/user-created
-- 6. HTTP headers: X-Webhook-Secret: your-secret-key

-- The backend will handle the webhook and call ConversionService

-- =====================================================
-- FUNCTION: Process Conversion Queue (for polling)
-- =====================================================

-- This function can be called periodically by the backend
-- to process any pending conversions
CREATE OR REPLACE FUNCTION get_pending_conversions(batch_size INT DEFAULT 10)
RETURNS TABLE (
    queue_id UUID,
    user_id UUID,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        q.id,
        q.user_id,
        q.phone,
        q.created_at
    FROM shadow_conversion_queue q
    WHERE q.processed = false
    ORDER BY q.created_at ASC
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION: Mark Conversion as Processed
-- =====================================================

CREATE OR REPLACE FUNCTION mark_conversion_processed(queue_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE shadow_conversion_queue
    SET processed = true,
        processed_at = NOW()
    WHERE id = queue_id_param;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EXAMPLE: Manual Conversion Trigger
-- =====================================================

-- For testing purposes, you can manually trigger a conversion:
-- SELECT notify_shadow_conversion() with a test user

-- Example usage:
-- INSERT INTO shadow_conversion_queue (user_id, phone)
-- VALUES ('00000000-0000-0000-0000-000000000001', '+5511999999999');

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions to service role
-- GRANT EXECUTE ON FUNCTION notify_shadow_conversion() TO service_role;
-- GRANT EXECUTE ON FUNCTION get_pending_conversions(INT) TO service_role;
-- GRANT EXECUTE ON FUNCTION mark_conversion_processed(UUID) TO service_role;

-- Grant table access
ALTER TABLE shadow_conversion_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage conversion queue"
    ON shadow_conversion_queue FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');
