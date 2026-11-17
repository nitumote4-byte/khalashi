-- Khalashi Phase 0 — OTP challenges
-- Short-lived phone OTP state. Never store raw OTP long-term in plain text.

CREATE TABLE IF NOT EXISTS otp_challenges (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(15) NOT NULL,
  code_hash     VARCHAR(128) NOT NULL,
  expires_at    TIMESTAMPTZ NOT NULL,
  attempt_count INT NOT NULL DEFAULT 0,
  consumed_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_phone_created ON otp_challenges (phone, created_at DESC);

COMMENT ON TABLE otp_challenges IS 'Rate-limited OTP send/verify; hash only — raw codes stay out of logs.';
