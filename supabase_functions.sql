-- Create user-specific results table function
CREATE OR REPLACE FUNCTION create_user_table(table_name TEXT)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id SERIAL PRIMARY KEY,
            file VARCHAR(255),
            ts DOUBLE PRECISION,
            text_index INTEGER,
            text_type VARCHAR(50),
            text TEXT,
            confidence DOUBLE PRECISION,
            box TEXT,
            created_by UUID,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Create index for better performance
        CREATE INDEX IF NOT EXISTS idx_%I_created_by ON public.%I(created_by);
        CREATE INDEX IF NOT EXISTS idx_%I_text_type ON public.%I(text_type);
        CREATE INDEX IF NOT EXISTS idx_%I_created_at ON public.%I(created_at);
    ', table_name, table_name, table_name, table_name, table_name, table_name);
END;
$$ LANGUAGE plpgsql;

-- Create users table if not exists
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

-- Create indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON public.users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access only their own data
CREATE POLICY "Users can access their own data" ON public.users
    FOR ALL USING (auth.uid()::text = id::text);