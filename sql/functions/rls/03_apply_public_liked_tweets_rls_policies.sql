
-- Function to apply RLS policies for entity tables
CREATE OR REPLACE FUNCTION public.apply_public_liked_tweets_rls_policies(schema_name TEXT, table_name TEXT) RETURNS void
set search_path TO ''
 AS $$
DECLARE
    policy_name TEXT;
    full_table_name TEXT;
BEGIN
    full_table_name := schema_name || '.' || table_name;

    -- Enable RLS on the table
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', schema_name, table_name);

    -- Drop existing policies
    FOR policy_name IN (
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = schema_name AND tablename = table_name
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', policy_name, schema_name, table_name);
    END LOOP;

    EXECUTE format('CREATE POLICY "Entities are publicly visible" ON %I.%I to anon, authenticated FOR SELECT USING (true)', schema_name, table_name);
    EXECUTE format('CREATE POLICY "Entities are modifiable by their users" ON %I.%I to authenticated  USING (EXISTS (SELECT 1 FROM public.account dt WHERE dt.account_id = (select auth.jwt()) -> ''app_metadata'' ->> ''provider_id'')) WITH CHECK (EXISTS (SELECT 1 FROM public.account dt WHERE dt.account_id = (select auth.jwt()) -> ''app_metadata'' ->> ''provider_id''))', schema_name, table_name, schema_name, table_name, schema_name, table_name);
END;
$$ LANGUAGE plpgsql;