import type { PoolClient } from "pg";
import { pool } from "../db/pool";
import { displayCity, normalizeCity } from "../utils/cities";
import { httpError } from "../utils/errors";

export type TripRow = {
  id: string;
  driver_id: string;
  origin: string;
  destination: string;
  origin_normalized: string;
  destination_normalized: string;
  depart_at: Date;
  seats_total: number;
  seats_left: number;
  fare_inr: number;
  status: "open" | "cancelled" | "completed";
  created_at: Date;
  updated_at: Date;
  driver_display_name?: string | null;
  driver_phone?: string | null;
};

const MAX_SEATS = 8;
const MAX_FARE_INR = 50_000;
const MAX_DEPART_DAYS = 90;

export function mapTrip(row: TripRow) {
  return {
    id: row.id,
    driverId: row.driver_id,
    origin: row.origin,
    destination: row.destination,
    departAt: row.depart_at.toISOString(),
    seatsTotal: row.seats_total,
    seatsLeft: row.seats_left,
    fareInr: row.fare_inr,
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
  departAt: string;
  seatsTotal: number;
  fareInr: number;
}) {
  const origin = displayCity(input.origin);
  const destination = displayCity(input.destination);
  if (!origin || !destination) {
    throw httpError(400, "Origin and destination are required");
  }
  if (normalizeCity(origin) === normalizeCity(destination)) {
    throw httpError(400, "Origin and destination must be different cities");
  }

  const departAt = new Date(input.departAt);
  if (Number.isNaN(departAt.getTime())) {
    throw httpError(400, "Invalid departure time");
  }
  const now = Date.now();
  if (departAt.getTime() <= now) {
    throw httpError(400, "Departure must be in the future");
  }
  const maxDepart = now + MAX_DEPART_DAYS * 24 * 60 * 60 * 1000;
  if (departAt.getTime() > maxDepart) {
    throw httpError(400, `Departure must be within ${MAX_DEPART_DAYS} days`);
  }

  if (!Number.isInteger(input.seatsTotal) || input.seatsTotal < 1 || input.seatsTotal > MAX_SEATS) {
    throw httpError(400, `Seats must be between 1 and ${MAX_SEATS}`);
  }
  if (!Number.isInteger(input.fareInr) || input.fareInr < 0 || input.fareInr > MAX_FARE_INR) {
    throw httpError(400, `Fare must be between ₹0 and ₹${MAX_FARE_INR}`);
  }

  const { rows } = await pool.query<TripRow>(
    `INSERT INTO trips (
       driver_id, origin, destination, origin_normalized, destination_normalized,
       depart_at, seats_total, seats_left, fare_inr, status
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $7, $8, 'open')
     RETURNING *`,
    [
      input.driverId,
      origin,
      destination,
      normalizeCity(origin),
      normalizeCity(destination),
      departAt.toISOString(),
      input.seatsTotal,
      input.fareInr,
    ]
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
  if (!rows[0]) throw httpError(404, "Trip not found");
  return mapTrip(rows[0]);
}

export async function searchTrips(input: {
  origin: string;
  destination: string;
  date: string; // YYYY-MM-DD (IST calendar day interpreted as UTC date window for MVP)
}) {
  const originNorm = normalizeCity(input.origin);
  const destNorm = normalizeCity(input.destination);
  if (!originNorm || !destNorm) {
    throw httpError(400, "Origin and destination are required");
  }

  // Treat date as India calendar day in +05:30.
  const day = input.date.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) {
    throw httpError(400, "Date must be YYYY-MM-DD");
  }
  const start = new Date(`${day}T00:00:00+05:30`);
  const end = new Date(`${day}T24:00:00+05:30`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    throw httpError(400, "Invalid date");
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
      throw httpError(403, "Only the driver can cancel this trip");
    }
    if (trip.status !== "open") {
      throw httpError(400, "Trip is not open");
    }
    if (new Date(trip.depart_at).getTime() <= Date.now()) {
      throw httpError(400, "Cannot cancel after trip start", "TRIP_STARTED");
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
  if (!rows[0]) throw httpError(404, "Trip not found");
  return rows[0];
}
