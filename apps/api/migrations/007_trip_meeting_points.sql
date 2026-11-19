-- Khalashi — BlaBlaCar-style free-text meeting points on trips
-- Optional pickup / drop-off landmarks (not fixed RedBus-style catalogs).

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS pickup_point VARCHAR(200),
  ADD COLUMN IF NOT EXISTS dropoff_point VARCHAR(200);

COMMENT ON COLUMN trips.pickup_point IS
  'Optional free-text boarding landmark/area (e.g. Railway Station).';
COMMENT ON COLUMN trips.dropoff_point IS
  'Optional free-text drop-off landmark/area (e.g. Bus Stand).';
