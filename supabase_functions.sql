-- Shared results (single table) + helper functions

-- Users table (kept for reference)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(255),
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
    device_settings JSONB DEFAULT '{}'
);

-- Users indexes + RLS
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON public.users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can access their own data" ON public.users;
CREATE POLICY "Users can access their own data" ON public.users
    FOR ALL USING (auth.uid()::text = id::text);

-- Results table (single shared)
CREATE TABLE IF NOT EXISTS public.results (
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

CREATE INDEX IF NOT EXISTS idx_results_user_date ON public.results (created_by, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_results_user_type_date ON public.results (created_by, text_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_results_file ON public.results (file);

ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can access their own results" ON public.results;
CREATE POLICY "Users can access their own results" ON public.results
    FOR ALL USING (created_by = auth.uid());

-- Helper insert
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

-- Helper select
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