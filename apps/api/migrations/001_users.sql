-- Khalashi Phase 0 — users
-- Phone OTP auth; dual-role (driver + traveller) from one account.

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(15) NOT NULL UNIQUE,
  display_name  VARCHAR(120),
  language      VARCHAR(5) NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'hi')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone);

COMMENT ON TABLE users IS 'Phone-authenticated accounts; same user can Find or Offer rides.';
COMMENT ON COLUMN users.phone IS 'E.164 preferred, e.g. +9198XXXXXXXX';
COMMENT ON COLUMN users.language IS 'UI preference: en | hi';
