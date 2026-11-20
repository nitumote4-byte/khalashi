-- Soft-launch selfie for manual face match against gov ID photo.
-- No paid face-match API — ops compare ID + selfie visually.

ALTER TABLE id_verifications
  ADD COLUMN IF NOT EXISTS selfie_path TEXT,
  ADD COLUMN IF NOT EXISTS selfie_mime VARCHAR(40);

COMMENT ON COLUMN id_verifications.selfie_path IS
  'Front-camera selfie relative to UPLOAD_DIR; required on new submits for manual match';

COMMENT ON COLUMN id_verifications.selfie_mime IS
  'MIME of selfie image (image/jpeg|png|webp)';

COMMENT ON TABLE id_verifications IS
  'Gov ID front photo + selfie + fields for manual soft-launch review (no DigiLocker / paid face-match).';
