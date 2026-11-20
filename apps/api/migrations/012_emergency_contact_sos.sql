-- Emergency contact on profile + SOS press audit (soft launch, no SMS gateway).

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(120),
  ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(15);

COMMENT ON COLUMN users.emergency_contact_name IS
  'Optional trusted contact name for SOS call/share.';
COMMENT ON COLUMN users.emergency_contact_phone IS
  'Optional trusted contact phone (E.164 preferred, e.g. +9198XXXXXXXX).';

CREATE TABLE IF NOT EXISTS sos_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  trip_id     UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  booking_id  UUID REFERENCES bookings (id) ON DELETE SET NULL,
  action      VARCHAR(40) NOT NULL DEFAULT 'pressed'
                CHECK (action IN ('pressed', 'call_contact', 'share', 'call_112')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sos_events_user_created
  ON sos_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_events_trip_created
  ON sos_events (trip_id, created_at DESC);

COMMENT ON TABLE sos_events IS
  'Audit log when a user opens SOS or uses a soft-launch SOS action on a trip.';
