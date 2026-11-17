-- Khalashi — vehicle details on trip post (required for travellers)
-- car model, number plate, color — shown on search / detail / booking.

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS car_model VARCHAR(80),
  ADD COLUMN IF NOT EXISTS number_plate VARCHAR(32),
  ADD COLUMN IF NOT EXISTS car_color VARCHAR(40);

-- Backfill any pre-migration rows so NOT NULL can apply
UPDATE trips
SET
  car_model = COALESCE(NULLIF(TRIM(car_model), ''), 'Unknown'),
  number_plate = COALESCE(NULLIF(TRIM(number_plate), ''), 'N/A'),
  car_color = COALESCE(NULLIF(TRIM(car_color), ''), 'Unknown')
WHERE car_model IS NULL
   OR number_plate IS NULL
   OR car_color IS NULL
   OR TRIM(car_model) = ''
   OR TRIM(number_plate) = ''
   OR TRIM(car_color) = '';

ALTER TABLE trips
  ALTER COLUMN car_model SET NOT NULL,
  ALTER COLUMN number_plate SET NOT NULL,
  ALTER COLUMN car_color SET NOT NULL;

COMMENT ON COLUMN trips.car_model IS 'Driver-entered car model shown to travellers.';
COMMENT ON COLUMN trips.number_plate IS 'Driver-entered number plate shown to travellers.';
COMMENT ON COLUMN trips.car_color IS 'Driver-entered car color shown to travellers.';
