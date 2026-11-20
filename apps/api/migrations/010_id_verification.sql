-- Soft-launch gov ID verification (photo + manual review). No DigiLocker/UIDAI.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) NOT NULL DEFAULT 'unverified'
    CHECK (verification_status IN ('unverified', 'pending_review', 'verified', 'rejected'));

COMMENT ON COLUMN users.verification_status IS
  'Soft-launch ID review: unverified | pending_review | verified | rejected';

CREATE TABLE IF NOT EXISTS id_verifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  id_type         VARCHAR(20) NOT NULL
                    CHECK (id_type IN ('aadhaar', 'dl', 'voter')),
  full_name       VARCHAR(120) NOT NULL,
  id_number       VARCHAR(64) NOT NULL,
  status          VARCHAR(20) NOT NULL DEFAULT 'pending_review'
                    CHECK (status IN ('pending_review', 'verified', 'rejected')),
  -- Soft launch: store JPEG/PNG on API filesystem; path relative to UPLOAD_DIR.
  image_path      TEXT NOT NULL,
  image_mime      VARCHAR(40) NOT NULL DEFAULT 'image/jpeg',
  review_note     TEXT,
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One open/latest submission tracked per user (resubmit replaces row).
CREATE UNIQUE INDEX IF NOT EXISTS idx_id_verifications_user
  ON id_verifications (user_id);

CREATE INDEX IF NOT EXISTS idx_id_verifications_status_created
  ON id_verifications (status, created_at DESC);

COMMENT ON TABLE id_verifications IS
  'Gov ID front photo + fields for manual soft-launch review (no DigiLocker).';
