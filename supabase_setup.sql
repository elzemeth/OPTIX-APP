-- =====================================================
-- OPTIX Smart Glasses - Supabase Database Setup
-- =====================================================

-- 1. Create users table (main user management)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) UNIQUE, -- Each device can only be connected to one account
    device_name VARCHAR(255),
    device_mac_address VARCHAR(255),
    login_method VARCHAR(50) DEFAULT 'credentials',
    is_ble_registered BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    preferred_wifi_networks JSONB DEFAULT '[]',
    device_settings JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{"push": true, "email": true}'
);

-- 2. Create indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON public.users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- 3. RLS DEV MODE: tamamen kapalı (signup/login testleri için)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- RLS policies temizle
DROP POLICY IF EXISTS "Users can access their own data" ON public.users;
DROP POLICY IF EXISTS "Allow signup" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;

-- 5. Single shared results table (per-user data separated by RLS)
DROP TABLE IF EXISTS public.results CASCADE;
CREATE TABLE public.results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    file VARCHAR(255),
    ts DOUBLE PRECISION,
    text_index INTEGER,
    text_type VARCHAR(50),
    text TEXT,
    confidence DOUBLE PRECISION,
    box TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Indexes for results (per-user fetch, type filter, recent first)
CREATE INDEX IF NOT EXISTS idx_results_user_date ON public.results (created_by, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_results_user_type_date ON public.results (created_by, text_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_results_file ON public.results (file);

-- 6. Function to check if device is already connected to another account
CREATE OR REPLACE FUNCTION is_device_connected_to_another_account(
    device_id_param TEXT,
    current_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    device_owner_id UUID;
BEGIN
    SELECT id INTO device_owner_id 
    FROM public.users 
    WHERE device_id = device_id_param AND id != current_user_id;
    
    RETURN device_owner_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to get user by serial number hash
CREATE OR REPLACE FUNCTION get_user_by_serial_hash(serial_hash TEXT)
RETURNS TABLE(
    id UUID,
    username VARCHAR(50),
    email VARCHAR(255),
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    device_mac_address VARCHAR(255),
    login_method VARCHAR(50),
    is_ble_registered BOOLEAN,
    is_active BOOLEAN,
    is_verified BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    preferred_wifi_networks JSONB,
    device_settings JSONB,
    notification_settings JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.email,
        u.device_id,
        u.device_name,
        u.device_mac_address,
        u.login_method,
        u.is_ble_registered,
        u.is_active,
        u.is_verified,
        u.created_at,
        u.updated_at,
        u.last_login_at,
        u.full_name,
        u.avatar_url,
        u.preferred_wifi_networks,
        u.device_settings,
        u.notification_settings
    FROM public.users u
    WHERE u.device_id = serial_hash;
END;
$$ LANGUAGE plpgsql;

-- 8. Helper function to insert into shared results table
CREATE OR REPLACE FUNCTION insert_result(
    file_name VARCHAR(255),
    timestamp_val DOUBLE PRECISION,
    text_index_val INTEGER,
    text_type_val VARCHAR(50),
    text_content TEXT,
    confidence_val DOUBLE PRECISION,
    box_data TEXT,
    user_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.results (
        file, ts, text_index, text_type, text, confidence, box, created_by
    ) VALUES (
        file_name, timestamp_val, text_index_val, text_type_val, text_content, confidence_val, box_data, user_id
    );
END;
$$ LANGUAGE plpgsql;

-- 9. Helper function to get results for a user (optionally filter by text_type)
CREATE OR REPLACE FUNCTION get_results_for_user(
    user_id UUID,
    text_type_filter VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
    id UUID,
    file VARCHAR(255),
    ts DOUBLE PRECISION,
    text_index INTEGER,
    text_type VARCHAR(50),
    text TEXT,
    confidence DOUBLE PRECISION,
    box TEXT,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    IF text_type_filter IS NULL THEN
        RETURN QUERY
        SELECT * FROM public.results
        WHERE created_by = user_id
        ORDER BY created_at DESC;
    ELSE
        RETURN QUERY
        SELECT * FROM public.results
        WHERE created_by = user_id AND text_type = text_type_filter
        ORDER BY created_at DESC;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 10. RLS DEV MODE: sonuç tablosu için de kapalı
ALTER TABLE public.results DISABLE ROW LEVEL SECURITY;

-- Policy'leri temizle
DROP POLICY IF EXISTS "Users can access their own results" ON public.results;

-- 14. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- 15. Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 16. Apply trigger to users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 17. Apply trigger to general results table
CREATE TRIGGER update_results_updated_at 
    BEFORE UPDATE ON public.results 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
