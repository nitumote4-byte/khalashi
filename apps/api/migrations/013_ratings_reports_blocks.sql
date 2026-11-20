-- Soft-launch trip ratings, user reports (admin review), and mutual soft blocks.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS rating_avg NUMERIC(3, 2) NOT NULL DEFAULT 0
    CHECK (rating_avg >= 0 AND rating_avg <= 5),
  ADD COLUMN IF NOT EXISTS rating_count INT NOT NULL DEFAULT 0
    CHECK (rating_count >= 0);

COMMENT ON COLUMN users.rating_avg IS
  'Running average of stars received (0 when rating_count = 0).';
COMMENT ON COLUMN users.rating_count IS
  'Number of ratings received from other users.';

CREATE TABLE IF NOT EXISTS trip_ratings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id      UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  booking_id   UUID NOT NULL REFERENCES bookings (id) ON DELETE CASCADE,
  rater_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  ratee_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  stars        INT NOT NULL CHECK (stars >= 1 AND stars <= 5),
  comment      VARCHAR(500),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT trip_ratings_rater_ne_ratee CHECK (rater_id <> ratee_id),
  CONSTRAINT trip_ratings_one_per_rater_booking UNIQUE (booking_id, rater_id)
);

CREATE INDEX IF NOT EXISTS idx_trip_ratings_ratee
  ON trip_ratings (ratee_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trip_ratings_trip
  ON trip_ratings (trip_id);

COMMENT ON TABLE trip_ratings IS
  '1–5 star rating + optional comment after a confirmed booking once the trip has started/ended.';

CREATE TABLE IF NOT EXISTS user_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  reported_user_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  reason            VARCHAR(40) NOT NULL
                      CHECK (reason IN (
                        'harassment',
                        'unsafe_driving',
                        'no_show',
                        'spam',
                        'fraud',
                        'other'
                      )),
  details           VARCHAR(1000),
  trip_id           UUID REFERENCES trips (id) ON DELETE SET NULL,
  booking_id        UUID REFERENCES bookings (id) ON DELETE SET NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'open'
                      CHECK (status IN ('open', 'reviewed', 'dismissed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_reports_reporter_ne_reported CHECK (reporter_id <> reported_user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_reports_status_created
  ON user_reports (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported
  ON user_reports (reported_user_id, created_at DESC);

COMMENT ON TABLE user_reports IS
  'Soft-launch misconduct reports for ADMIN_SECRET review (no deep admin UI).';

CREATE TABLE IF NOT EXISTS user_blocks (
  blocker_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  blocked_id  UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT user_blocks_ne CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked
  ON user_blocks (blocked_id);

COMMENT ON TABLE user_blocks IS
  'Pairwise soft block: blocked pairs cannot book each other or see each other in search.';
