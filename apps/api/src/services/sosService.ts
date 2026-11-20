import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";
import { getTripById } from "./tripService";

export type SosAction = "pressed" | "call_contact" | "share" | "call_112";

const ACTIONS = new Set<SosAction>(["pressed", "call_contact", "share", "call_112"]);

/**
 * Log an SOS action for a trip participant (driver or confirmed traveller).
 * Soft-launch audit only — no SMS gateway.
 */
export async function logSosEvent(input: {
  userId: string;
  tripId: string;
  bookingId?: string | null;
  action: SosAction;
}) {
  if (!ACTIONS.has(input.action)) {
    throw httpError(400, "Invalid SOS action", ErrorCodes.VALIDATION_ERROR);
  }

  const trip = await getTripById(input.tripId);

  let bookingId: string | null = input.bookingId ?? null;
  let allowed = trip.driverId === input.userId;

  if (!allowed) {
    const { rows } = await pool.query<{ id: string }>(
      `SELECT id FROM bookings
       WHERE trip_id = $1 AND traveller_id = $2 AND status = 'confirmed'
       ORDER BY created_at DESC
       LIMIT 1`,
      [input.tripId, input.userId]
    );
    if (rows[0]) {
      allowed = true;
      if (!bookingId) bookingId = rows[0].id;
    }
  }

  if (!allowed) {
    throw httpError(403, "Only trip participants can use SOS", ErrorCodes.FORBIDDEN);
  }

  if (bookingId) {
    const { rows: bookingRows } = await pool.query<{
      id: string;
      trip_id: string;
      traveller_id: string;
      status: string;
    }>("SELECT id, trip_id, traveller_id, status FROM bookings WHERE id = $1", [bookingId]);
    const booking = bookingRows[0];
    if (
      !booking ||
      booking.trip_id !== input.tripId ||
      (booking.traveller_id !== input.userId && trip.driverId !== input.userId)
    ) {
      throw httpError(400, "Booking does not match this trip", ErrorCodes.VALIDATION_ERROR);
    }
  }

  const { rows } = await pool.query<{
    id: string;
    user_id: string;
    trip_id: string;
    booking_id: string | null;
    action: SosAction;
    created_at: Date;
  }>(
    `INSERT INTO sos_events (user_id, trip_id, booking_id, action)
     VALUES ($1, $2, $3, $4)
     RETURNING id, user_id, trip_id, booking_id, action, created_at`,
    [input.userId, input.tripId, bookingId, input.action]
  );

  const row = rows[0];
  console.log(
    JSON.stringify({
      level: "info",
      msg: "sos_event",
      sosId: row.id,
      userId: input.userId,
      tripId: input.tripId,
      bookingId,
      action: input.action,
    })
  );

  return {
    id: row.id,
    userId: row.user_id,
    tripId: row.trip_id,
    bookingId: row.booking_id,
    action: row.action,
    createdAt: row.created_at.toISOString(),
  };
}
