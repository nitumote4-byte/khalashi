-- Khalashi — map-pin meeting points (lat/lng alongside address labels).
-- pickup_point / dropoff_point remain as reverse-geocoded address labels.

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS dropoff_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS dropoff_lng DOUBLE PRECISION;

COMMENT ON COLUMN trips.pickup_lat IS
  'Optional WGS84 latitude of the boarding pin (paired with pickup_lng).';
COMMENT ON COLUMN trips.pickup_lng IS
  'Optional WGS84 longitude of the boarding pin (paired with pickup_lat).';
COMMENT ON COLUMN trips.dropoff_lat IS
  'Optional WGS84 latitude of the drop-off pin (paired with dropoff_lng).';
COMMENT ON COLUMN trips.dropoff_lng IS
  'Optional WGS84 longitude of the drop-off pin (paired with dropoff_lat).';

COMMENT ON COLUMN trips.pickup_point IS
  'Optional reverse-geocoded boarding address/label from the map pin.';
COMMENT ON COLUMN trips.dropoff_point IS
  'Optional reverse-geocoded drop-off address/label from the map pin.';
