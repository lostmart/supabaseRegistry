-- Migration: create_user_subscriptions
-- Stripe payment tracking for premium access.

CREATE TYPE subscription_tier_enum   AS ENUM ('premium', 'lifetime');
CREATE TYPE subscription_status_enum AS ENUM ('active', 'cancelled', 'expired');

CREATE TABLE user_subscriptions (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_subscription_id   TEXT,              -- Nullable for one-time (lifetime) payments
  stripe_payment_intent_id TEXT,
  tier                     subscription_tier_enum   NOT NULL,
  status                   subscription_status_enum NOT NULL,
  started_at               TIMESTAMPTZ NOT NULL,
  expires_at               TIMESTAMPTZ,       -- NULL for lifetime
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions (user_id);
CREATE INDEX idx_user_subscriptions_status  ON user_subscriptions (user_id, status);

CREATE TRIGGER trg_user_subscriptions_updated_at
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- RLS: users can only read their own subscription records
-- Writes are handled exclusively by the backend using the service key (Stripe webhooks)
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscriptions"
  ON user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
