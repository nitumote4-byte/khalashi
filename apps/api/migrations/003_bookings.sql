-- Khalashi Phase 0 — bookings
-- Traveller seat holds. Preference is request-only (not a seat map).

CREATE TABLE IF NOT EXISTS bookings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id          UUID NOT NULL REFERENCES trips (id),
  traveller_id     UUID NOT NULL REFERENCES users (id),
  seats            INT NOT NULL CHECK (seats >= 1),
  seat_preference  VARCHAR(20) NOT NULL DEFAULT 'any'
                     CHECK (seat_preference IN ('front', 'window', 'any')),
  cash_total_inr   INT NOT NULL CHECK (cash_total_inr >= 0),
  status           VARCHAR(20) NOT NULL DEFAULT 'confirmed'
                     CHECK (status IN ('confirmed', 'cancelled')),
  cancelled_by     VARCHAR(20) CHECK (cancelled_by IS NULL OR cancelled_by IN ('traveller', 'driver', 'system')),
  cancel_reason    VARCHAR(255),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_trip ON bookings (trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_traveller ON bookings (traveller_id);
CREATE INDEX IF NOT EXISTS idx_bookings_traveller_status ON bookings (traveller_id, status);

COMMENT ON TABLE bookings IS 'Confirmed/cancelled seat bookings; free cancel until trip start (Phase 4).';
COMMENT ON COLUMN bookings.seat_preference IS 'Request only: front | window | any — not guaranteed assignment.';
COMMENT ON COLUMN bookings.cash_total_inr IS 'seats × fare; paid cash to driver offline — no payment state machine.';
