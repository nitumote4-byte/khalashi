import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";

export type RatingRow = {
  id: string;
  trip_id: string;
  booking_id: string;
  rater_id: string;
  ratee_id: string;
  stars: number;
  comment: string | null;
  created_at: Date;
};

function mapRating(row: RatingRow) {
  return {
    id: row.id,
    tripId: row.trip_id,
    bookingId: row.booking_id,
    raterId: row.rater_id,
    rateeId: row.ratee_id,
    stars: row.stars,
    comment: row.comment,
    createdAt: row.created_at.toISOString(),
  };
}

async function loadBookingContext(bookingId: string) {
  const { rows } = await pool.query<{
    id: string;
    trip_id: string;
    traveller_id: string;
    status: string;
    driver_id: string;
    trip_status: string;
    depart_at: Date;
    driver_display_name: string | null;
    traveller_display_name: string | null;
  }>(
    `SELECT b.id, b.trip_id, b.traveller_id, b.status,
            t.driver_id, t.status AS trip_status, t.depart_at,
            d.display_name AS driver_display_name,
            tr.display_name AS traveller_display_name
     FROM bookings b
     JOIN trips t ON t.id = b.trip_id
     JOIN users d ON d.id = t.driver_id
     JOIN users tr ON tr.id = b.traveller_id
     WHERE b.id = $1`,
    [bookingId]
  );
  if (!rows[0]) throw httpError(404, "Booking not found", ErrorCodes.NOT_FOUND);
  return rows[0];
}

function canRateNow(booking: {
  status: string;
  trip_status: string;
  depart_at: Date;
}): boolean {
  if (booking.status !== "confirmed") return false;
  if (booking.trip_status === "cancelled") return false;
  if (booking.trip_status === "completed") return true;
  return new Date(booking.depart_at).getTime() <= Date.now();
}

export async function getRatingSummary(userId: string) {
  const { rows } = await pool.query<{
    rating_avg: string | number;
    rating_count: number;
  }>("SELECT rating_avg, rating_count FROM users WHERE id = $1", [userId]);
  if (!rows[0]) {
    return { ratingAvg: 0, ratingCount: 0 };
  }
  return {
    ratingAvg: Number(rows[0].rating_avg) || 0,
    ratingCount: rows[0].rating_count || 0,
  };
}

export async function getBookingRatingState(bookingId: string, userId: string) {
  const booking = await loadBookingContext(bookingId);
  const isTraveller = booking.traveller_id === userId;
  const isDriver = booking.driver_id === userId;
  if (!isTraveller && !isDriver) {
    throw httpError(403, "Not allowed to view this booking", ErrorCodes.FORBIDDEN);
  }

  const rateeId = isTraveller ? booking.driver_id : booking.traveller_id;
  const rateeDisplayName = isTraveller
    ? booking.driver_display_name
    : booking.traveller_display_name;

  const { rows } = await pool.query<RatingRow>(
    `SELECT * FROM trip_ratings WHERE booking_id = $1 AND rater_id = $2`,
    [bookingId, userId]
  );
  const existing = rows[0] ? mapRating(rows[0]) : null;
  const eligible = canRateNow(booking) && !existing;

  return {
    bookingId,
    tripId: booking.trip_id,
    canRate: eligible,
    rateeId,
    rateeDisplayName: rateeDisplayName ?? null,
    myRating: existing,
  };
}

export async function submitRating(input: {
  bookingId: string;
  raterId: string;
  stars: number;
  comment?: string | null;
}) {
  if (!Number.isInteger(input.stars) || input.stars < 1 || input.stars > 5) {
    throw httpError(400, "Stars must be an integer from 1 to 5", ErrorCodes.VALIDATION_ERROR);
  }

  let comment: string | null = null;
  if (input.comment != null) {
    const trimmed = input.comment.trim();
    if (trimmed.length > 500) {
      throw httpError(400, "Comment must be at most 500 characters", ErrorCodes.VALIDATION_ERROR);
    }
    comment = trimmed.length === 0 ? null : trimmed;
  }

  const booking = await loadBookingContext(input.bookingId);
  const isTraveller = booking.traveller_id === input.raterId;
  const isDriver = booking.driver_id === input.raterId;
  if (!isTraveller && !isDriver) {
    throw httpError(403, "Not allowed to rate this booking", ErrorCodes.FORBIDDEN);
  }
  if (!canRateNow(booking)) {
    throw httpError(
      400,
      "Rating is only available after the trip has started or completed",
      ErrorCodes.RATING_NOT_ELIGIBLE
    );
  }

  const rateeId = isTraveller ? booking.driver_id : booking.traveller_id;

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const existing = await client.query<{ id: string }>(
      `SELECT id FROM trip_ratings WHERE booking_id = $1 AND rater_id = $2 FOR UPDATE`,
      [input.bookingId, input.raterId]
    );
    if (existing.rows[0]) {
      throw httpError(409, "You already rated this booking", ErrorCodes.RATING_ALREADY);
    }

    const insert = await client.query<RatingRow>(
      `INSERT INTO trip_ratings (trip_id, booking_id, rater_id, ratee_id, stars, comment)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [booking.trip_id, input.bookingId, input.raterId, rateeId, input.stars, comment]
    );

    // Recompute running average for the ratee.
    const agg = await client.query<{ avg: string; count: string }>(
      `SELECT COALESCE(AVG(stars), 0)::text AS avg, COUNT(*)::text AS count
       FROM trip_ratings WHERE ratee_id = $1`,
      [rateeId]
    );
    const avg = Number(agg.rows[0]?.avg ?? 0);
    const count = Number(agg.rows[0]?.count ?? 0);
    await client.query(
      `UPDATE users
       SET rating_avg = $2, rating_count = $3, updated_at = NOW()
       WHERE id = $1`,
      [rateeId, Math.round(avg * 100) / 100, count]
    );

    await client.query("COMMIT");

    console.log(
      JSON.stringify({
        level: "info",
        msg: "trip_rating_submitted",
        ratingId: insert.rows[0].id,
        bookingId: input.bookingId,
        raterId: input.raterId,
        rateeId,
        stars: input.stars,
      })
    );

    return mapRating(insert.rows[0]);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
