-- Khalashi — optional route distance / duration from Offer Ride preview (OSRM or estimate).

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS distance_meters INT,
  ADD COLUMN IF NOT EXISTS duration_seconds INT;

COMMENT ON COLUMN trips.distance_meters IS
  'Optional road (or estimated) distance in meters between meeting pins at publish time.';
COMMENT ON COLUMN trips.duration_seconds IS
  'Optional road (or estimated) travel duration in seconds between meeting pins at publish time.';
