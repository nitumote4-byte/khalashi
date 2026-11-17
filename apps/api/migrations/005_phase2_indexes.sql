-- Khalashi Phase 2 — listing indexes for my trips / my bookings
CREATE INDEX IF NOT EXISTS idx_trips_driver_depart
  ON trips (driver_id, depart_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_traveller_created
  ON bookings (traveller_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_trip_status
  ON bookings (trip_id, status);
