-- Migration: create_user_profiles
-- App-specific user data, separate from Supabase auth.users.
-- One row per user, auto-created on signup via trigger.

CREATE TABLE user_profiles (
  id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_language   TEXT NOT NULL DEFAULT 'fr' CHECK (preferred_language IN ('fr', 'en', 'es', 'ar')),
  subscription_tier    TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'lifetime')),
  target_exam_level    TEXT CHECK (target_exam_level IN ('CSP', 'CR', 'NAT')),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Auto-create a profile row when a new auth user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Now that user_profiles exists, add the premium questions RLS policy
-- (could not be defined in migration 000003 as user_profiles didn't exist yet)
CREATE POLICY "Premium questions require active subscription"
  ON questions FOR SELECT
  TO authenticated
  USING (
    exam_type IN ('CR', 'NAT')
    AND EXISTS (
      SELECT 1
      FROM user_profiles
      WHERE id = auth.uid()
        AND subscription_tier IN ('premium', 'lifetime')
    )
  );

-- RLS: users can read and update only their own profile
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
