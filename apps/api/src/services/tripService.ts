import type { PoolClient } from "pg";
import { env } from "../config/env";
import { pool } from "../db/pool";
import { displayCity, normalizeCity } from "../utils/cities";
import { ErrorCodes, httpError } from "../utils/errors";

export type TripRow = {
  id: string;
  driver_id: string;
  origin: string;
  destination: string;
  origin_normalized: string;
  destination_normalized: string;
  pickup_point: string | null;
  dropoff_point: string | null;
  pickup_lat: number | string | null;
  pickup_lng: number | string | null;
  dropoff_lat: number | string | null;
  dropoff_lng: number | string | null;
  distance_meters: number | string | null;
  duration_seconds: number | string | null;
  depart_at: Date;
  seats_total: number;
  seats_left: number;
  fare_inr: number;
  car_model: string;
  number_plate: string;
  car_color: string;
  status: "open" | "cancelled" | "completed";
  created_at: Date;
  updated_at: Date;
  driver_display_name?: string | null;
  driver_phone?: string | null;
};

const MAX_SEATS = 8;
const MAX_FARE_INR = 50_000;
const MAX_DEPART_DAYS = 90;
const MAX_CAR_MODEL = 80;
const MAX_NUMBER_PLATE = 32;
const MAX_CAR_COLOR = 40;
const MAX_MEETING_POINT = 200;

function normalizeVehicleField(value: string, label: string, maxLen: number): string {
  const trimmed = value.trim().replace(/\s+/g, " ");
  if (!trimmed) {
    throw httpError(400, `${label} is required`, ErrorCodes.VALIDATION_ERROR);
  }
  if (trimmed.length > maxLen) {
    throw httpError(
      400,
      `${label} must be at most ${maxLen} characters`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  return trimmed;
}

/** Optional address/label for a map pin; empty → null. */
export function normalizeMeetingPoint(
  value: string | null | undefined,
  label: string
): string | null {
  if (value == null) return null;
  const trimmed = value.trim().replace(/\s+/g, " ");
  if (!trimmed) return null;
  if (trimmed.length > MAX_MEETING_POINT) {
    throw httpError(
      400,
      `${label} must be at most ${MAX_MEETING_POINT} characters`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  return trimmed;
}

function asFiniteNumber(value: number | string | null | undefined): number | null {
  if (value == null || value === "") return null;
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : null;
}

function asOptionalInt(value: number | string | null | undefined): number | null {
  const n = asFiniteNumber(value);
  return n == null ? null : Math.round(n);
}

/** Optional WGS84 coordinate pair. Both null, or both valid numbers. */
export function normalizeMeetingCoords(
  lat: number | null | undefined,
  lng: number | null | undefined,
  label: string
): { lat: number | null; lng: number | null } {
  const hasLat = lat != null && !(typeof lat === "number" && Number.isNaN(lat));
  const hasLng = lng != null && !(typeof lng === "number" && Number.isNaN(lng));
  if (!hasLat && !hasLng) return { lat: null, lng: null };
  if (!hasLat || !hasLng) {
    throw httpError(
      400,
      `${label} latitude and longitude must both be provided`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw httpError(400, `${label} coordinates are invalid`, ErrorCodes.VALIDATION_ERROR);
  }
  if (lat! < -90 || lat! > 90 || lng! < -180 || lng! > 180) {
    throw httpError(400, `${label} coordinates are out of range`, ErrorCodes.VALIDATION_ERROR);
  }
  return { lat: lat!, lng: lng! };
}

/** Optional non-negative integer; null/undefined → null. */
function normalizeOptionalInt(
  value: number | null | undefined,
  label: string,
  min: number,
  max: number
): number | null {
  if (value == null || (typeof value === "number" && Number.isNaN(value))) {
    return null;
  }
  if (!Number.isFinite(value) || !Number.isInteger(value)) {
    throw httpError(400, `${label} must be an integer`, ErrorCodes.VALIDATION_ERROR);
  }
  if (value < min || value > max) {
    throw httpError(
      400,
      `${label} must be between ${min} and ${max}`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  return value;
}

export function mapTrip(row: TripRow) {
  return {
    id: row.id,
    driverId: row.driver_id,
    origin: row.origin,
    destination: row.destination,
    pickupPoint: row.pickup_point ?? null,
    dropoffPoint: row.dropoff_point ?? null,
    pickupLat: asFiniteNumber(row.pickup_lat),
    pickupLng: asFiniteNumber(row.pickup_lng),
    dropoffLat: asFiniteNumber(row.dropoff_lat),
    dropoffLng: asFiniteNumber(row.dropoff_lng),
    distanceMeters: asOptionalInt(row.distance_meters),
    durationSeconds: asOptionalInt(row.duration_seconds),
    departAt: row.depart_at.toISOString(),
    seatsTotal: row.seats_total,
    seatsLeft: row.seats_left,
    fareInr: row.fare_inr,
    carModel: row.car_model,
    numberPlate: row.number_plate,
    carColor: row.car_color,
    status: row.status,
    driverDisplayName: row.driver_display_name ?? null,
    driverPhone: row.driver_phone ?? null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

export async function createTrip(input: {
  driverId: string;
  origin: string;
  destination: string;
  pickupPoint?: string | null;
  dropoffPoint?: string | null;
  pickupLat?: number | null;
  pickupLng?: number | null;
  dropoffLat?: number | null;
  dropoffLng?: number | null;
  distanceMeters?: number | null;
  durationSeconds?: number | null;
  departAt: string;
  seatsTotal: number;
  fareInr: number;
  carModel: string;
  numberPlate: string;
  carColor: string;
}) {
  const origin = displayCity(input.origin);
  const destination = displayCity(input.destination);
  if (!origin || !destination) {
    throw httpError(400, "Origin and destination are required", ErrorCodes.VALIDATION_ERROR);
  }
  if (normalizeCity(origin) === normalizeCity(destination)) {
    throw httpError(
      400,
      "Origin and destination must be different cities",
      ErrorCodes.VALIDATION_ERROR
    );
  }
  const pickupPoint = normalizeMeetingPoint(input.pickupPoint, "Pickup point");
  const dropoffPoint = normalizeMeetingPoint(input.dropoffPoint, "Drop-off point");
  const pickupCoords = normalizeMeetingCoords(
    input.pickupLat,
    input.pickupLng,
    "Pickup"
  );
  const dropoffCoords = normalizeMeetingCoords(
    input.dropoffLat,
    input.dropoffLng,
    "Drop-off"
  );
  const distanceMeters = normalizeOptionalInt(
    input.distanceMeters,
    "Distance",
    0,
    20_000_000
  );
  const durationSeconds = normalizeOptionalInt(
    input.durationSeconds,
    "Duration",
    0,
    7 * 24 * 3600
  );

  const departAt = new Date(input.departAt);
  if (Number.isNaN(departAt.getTime())) {
    throw httpError(400, "Invalid departure time", ErrorCodes.VALIDATION_ERROR);
  }
  const now = Date.now();
  if (departAt.getTime() <= now) {
    throw httpError(400, "Departure must be in the future", ErrorCodes.VALIDATION_ERROR);
  }
  const minAheadMs = env.MIN_DEPART_AHEAD_MINUTES * 60 * 1000;
  if (departAt.getTime() < now + minAheadMs) {
    throw httpError(
      400,
      `Departure must be at least ${env.MIN_DEPART_AHEAD_MINUTES} minutes from now`,
      ErrorCodes.DEPART_TOO_SOON
    );
  }
  const maxDepart = now + MAX_DEPART_DAYS * 24 * 60 * 60 * 1000;
  if (departAt.getTime() > maxDepart) {
    throw httpError(
      400,
      `Departure must be within ${MAX_DEPART_DAYS} days`,
      ErrorCodes.VALIDATION_ERROR
    );
  }

  if (!Number.isInteger(input.seatsTotal) || input.seatsTotal < 1 || input.seatsTotal > MAX_SEATS) {
    throw httpError(
      400,
      `Seats must be between 1 and ${MAX_SEATS}`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  if (!Number.isInteger(input.fareInr) || input.fareInr < 0 || input.fareInr > MAX_FARE_INR) {
    throw httpError(
      400,
      `Fare must be between ₹0 and ₹${MAX_FARE_INR}`,
      ErrorCodes.VALIDATION_ERROR
    );
  }

  const carModel = normalizeVehicleField(input.carModel, "Car model", MAX_CAR_MODEL);
  const numberPlate = normalizeVehicleField(
    input.numberPlate,
    "Number plate",
    MAX_NUMBER_PLATE
  ).toUpperCase();
  const carColor = normalizeVehicleField(input.carColor, "Car color", MAX_CAR_COLOR);

  // Spam guard: cap open trips created by this driver in the last 24h
  const dayAgo = new Date(now - 24 * 60 * 60 * 1000).toISOString();
  const countResult = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM trips
     WHERE driver_id = $1 AND created_at >= $2`,
    [input.driverId, dayAgo]
  );
  const tripsToday = Number(countResult.rows[0]?.count ?? 0);
  if (tripsToday >= env.MAX_TRIPS_PER_DRIVER_PER_DAY) {
    throw httpError(
      429,
      `Trip post limit reached (${env.MAX_TRIPS_PER_DRIVER_PER_DAY}/day). Try again tomorrow.`,
      ErrorCodes.SPAM_TRIP_LIMIT
    );
  }

  const originNorm = normalizeCity(origin);
  const destNorm = normalizeCity(destination);

  // Spam guard: block near-duplicate open trip (same route + same IST calendar day)
  const dup = await pool.query<{ id: string }>(
    `SELECT id FROM trips
     WHERE driver_id = $1
       AND status = 'open'
       AND origin_normalized = $2
       AND destination_normalized = $3
       AND (depart_at AT TIME ZONE 'Asia/Kolkata')::date
           = ($4::timestamptz AT TIME ZONE 'Asia/Kolkata')::date
     LIMIT 1`,
    [input.driverId, originNorm, destNorm, departAt.toISOString()]
  );
  if (dup.rows[0]) {
    throw httpError(
      409,
      "You already have an open trip on this route for that day",
      ErrorCodes.SPAM_DUPLICATE_TRIP
    );
  }

  const { rows } = await pool.query<TripRow>(
    `INSERT INTO trips (
       driver_id, origin, destination, origin_normalized, destination_normalized,
       pickup_point, dropoff_point, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
       distance_meters, duration_seconds,
       depart_at, seats_total, seats_left, fare_inr,
       car_model, number_plate, car_color, status
     ) VALUES (
       $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
       $12, $13, $14, $15, $15, $16, $17, $18, $19, 'open'
     )
     RETURNING *`,
    [
      input.driverId,
      origin,
      destination,
      originNorm,
      destNorm,
      pickupPoint,
      dropoffPoint,
      pickupCoords.lat,
      pickupCoords.lng,
      dropoffCoords.lat,
      dropoffCoords.lng,
      distanceMeters,
      durationSeconds,
      departAt.toISOString(),
      input.seatsTotal,
      input.fareInr,
      carModel,
      numberPlate,
      carColor,
    ]
  );

  console.log(
    JSON.stringify({
      level: "info",
      msg: "trip_created",
      tripId: rows[0].id,
      driverId: input.driverId,
      origin: originNorm,
      destination: destNorm,
    })
  );

  return mapTrip(rows[0]);
}

export async function listMyTrips(driverId: string) {
  const { rows } = await pool.query<TripRow>(
    `SELECT * FROM trips
     WHERE driver_id = $1
     ORDER BY depart_at DESC`,
    [driverId]
  );
  return rows.map(mapTrip);
}

export async function getTripById(tripId: string) {
  const { rows } = await pool.query<TripRow>(
    `SELECT t.*, u.display_name AS driver_display_name, u.phone AS driver_phone
     FROM trips t
     JOIN users u ON u.id = t.driver_id
     WHERE t.id = $1`,
    [tripId]
  );
  if (!rows[0]) throw httpError(404, "Trip not found", ErrorCodes.NOT_FOUND);
  return mapTrip(rows[0]);
}

export async function searchTrips(input: {
  origin: string;
  destination: string;
  date: string; // YYYY-MM-DD (IST calendar day)
}) {
  const originNorm = normalizeCity(input.origin);
  const destNorm = normalizeCity(input.destination);
  if (!originNorm || !destNorm) {
    throw httpError(400, "Origin and destination are required", ErrorCodes.VALIDATION_ERROR);
  }

  // Treat date as India calendar day in +05:30.
  const day = input.date.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw httpError(400, "Date must be YYYY-MM-DD", ErrorCodes.VALIDATION_ERROR);
  }
  const start = new Date(`${day}T00:00:00+05:30`);
  const end = new Date(`${day}T24:00:00+05:30`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    throw httpError(400, "Invalid date", ErrorCodes.VALIDATION_ERROR);
  }

  const { rows } = await pool.query<TripRow>(
    `SELECT t.*, u.display_name AS driver_display_name, u.phone AS driver_phone
     FROM trips t
     JOIN users u ON u.id = t.driver_id
     WHERE t.status = 'open'
       AND t.origin_normalized = $1
       AND t.destination_normalized = $2
       AND t.depart_at >= $3
       AND t.depart_at < $4
     ORDER BY t.depart_at ASC, t.fare_inr ASC`,
    [originNorm, destNorm, start.toISOString(), end.toISOString()]
  );
  return rows.map(mapTrip);
}

export async function cancelTrip(tripId: string, driverId: string) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const trip = await lockTrip(client, tripId);
    if (trip.driver_id !== driverId) {
      throw httpError(403, "Only the driver can cancel this trip", ErrorCodes.FORBIDDEN);
    }
    if (trip.status !== "open") {
      throw httpError(400, "Trip is not open", ErrorCodes.TRIP_NOT_OPEN);
    }
    if (new Date(trip.depart_at).getTime() <= Date.now()) {
      throw httpError(400, "Cannot cancel after trip start", ErrorCodes.TRIP_STARTED);
    }

    await client.query(
      `UPDATE trips
       SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1`,
      [tripId]
    );

    await client.query(
      `UPDATE bookings
       SET status = 'cancelled',
           cancelled_by = 'driver',
           cancel_reason = 'Trip cancelled by driver',
           updated_at = NOW()
       WHERE trip_id = $1 AND status = 'confirmed'`,
      [tripId]
    );

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
  return getTripById(tripId);
}

export async function lockTrip(client: PoolClient, tripId: string): Promise<TripRow> {
  const { rows } = await client.query<TripRow>(
    `SELECT * FROM trips WHERE id = $1 FOR UPDATE`,
    [tripId]
  );
  if (!rows[0]) throw httpError(404, "Trip not found", ErrorCodes.NOT_FOUND);
  return rows[0];
}
