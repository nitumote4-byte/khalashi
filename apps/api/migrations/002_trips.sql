-- Khalashi Phase 0 — trips
-- Driver-posted A→B rides with seats and fare. Booking logic in later phases.

CREATE TABLE IF NOT EXISTS trips (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id         UUID NOT NULL REFERENCES users (id),
  origin            VARCHAR(120) NOT NULL,
  destination       VARCHAR(120) NOT NULL,
  origin_normalized VARCHAR(120) NOT NULL,
  destination_normalized VARCHAR(120) NOT NULL,
  depart_at         TIMESTAMPTZ NOT NULL,
  seats_total       INT NOT NULL CHECK (seats_total >= 1),
  seats_left        INT NOT NULL CHECK (seats_left >= 0),
  fare_inr          INT NOT NULL CHECK (fare_inr >= 0),
  status            VARCHAR(20) NOT NULL DEFAULT 'open'
                      CHECK (status IN ('open', 'cancelled', 'completed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT trips_seats_left_lte_total CHECK (seats_left <= seats_total)
);

CREATE INDEX IF NOT EXISTS idx_trips_driver ON trips (driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_search
  ON trips (depart_at, origin_normalized, destination_normalized)
  WHERE status = 'open';

COMMENT ON TABLE trips IS 'Driver-posted trips; seats_left decremented atomically on book (Phase 3).';
COMMENT ON COLUMN trips.fare_inr IS 'Driver-set fare per seat in whole rupees; cash on trip only.';
