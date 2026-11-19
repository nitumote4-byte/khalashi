import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";
import { getTripById, lockTrip, mapTrip, type TripRow } from "./tripService";

export type SeatPreference = "front" | "window" | "any";

export type BookingRow = {
  id: string;
  trip_id: string;
  traveller_id: string;
  seats: number;
  seat_preference: SeatPreference;
  cash_total_inr: number;
  status: "confirmed" | "cancelled";
  cancelled_by: "traveller" | "driver" | "system" | null;
  cancel_reason: string | null;
  created_at: Date;
  updated_at: Date;
  traveller_phone?: string | null;
  traveller_display_name?: string | null;
};

function mapBooking(row: BookingRow, trip?: ReturnType<typeof mapTrip>) {
  return {
    id: row.id,
    tripId: row.trip_id,
    travellerId: row.traveller_id,
    seats: row.seats,
    seatPreference: row.seat_preference,
    cashTotalInr: row.cash_total_inr,
    status: row.status,
    cancelledBy: row.cancelled_by,
    cancelReason: row.cancel_reason,
    travellerPhone: row.traveller_phone ?? null,
    travellerDisplayName: row.traveller_display_name ?? null,
    bookingRef: row.id.replace(/-/g, "").slice(0, 8).toUpperCase(),
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
    trip: trip ?? undefined,
  };
}

export async function createBooking(input: {
  tripId: string;
  travellerId: string;
  seats: number;
  seatPreference: SeatPreference;
}) {
  if (!Number.isInteger(input.seats) || input.seats < 1) {
    throw httpError(400, "Seats must be at least 1", ErrorCodes.VALIDATION_ERROR);
  }
  if (!["front", "window", "any"].includes(input.seatPreference)) {
    throw httpError(
      400,
      "Seat preference must be front, window, or any",
      ErrorCodes.VALIDATION_ERROR
    );
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const trip = await lockTrip(client, input.tripId);

    if (trip.driver_id === input.travellerId) {
      throw httpError(400, "Drivers cannot book their own trip", ErrorCodes.VALIDATION_ERROR);
    }
    if (trip.status !== "open") {
      throw httpError(400, "Trip is not open for booking", ErrorCodes.TRIP_NOT_OPEN);
    }
    if (new Date(trip.depart_at).getTime() <= Date.now()) {
      throw httpError(400, "Trip has already started", ErrorCodes.TRIP_STARTED);
    }
    if (trip.seats_left < input.seats) {
      throw httpError(409, "Seats just filled", ErrorCodes.SEATS_FULL);
    }

    const cashTotal = trip.fare_inr * input.seats;
    const bookingResult = await client.query<BookingRow>(
      `INSERT INTO bookings (
         trip_id, traveller_id, seats, seat_preference, cash_total_inr, status
       ) VALUES ($1, $2, $3, $4, $5, 'confirmed')
       RETURNING *`,
      [input.tripId, input.travellerId, input.seats, input.seatPreference, cashTotal]
    );

    const updatedTrip = await client.query<TripRow>(
      `UPDATE trips
       SET seats_left = seats_left - $2, updated_at = NOW()
       WHERE id = $1 AND seats_left >= $2
       RETURNING *`,
      [input.tripId, input.seats]
    );
    if (!updatedTrip.rows[0]) {
      throw httpError(409, "Seats just filled", ErrorCodes.SEATS_FULL);
    }

    await client.query("COMMIT");
    console.log(
      JSON.stringify({
        level: "info",
        msg: "booking_created",
        bookingId: bookingResult.rows[0].id,
        tripId: input.tripId,
        travellerId: input.travellerId,
        seats: input.seats,
      })
    );
    return mapBooking(bookingResult.rows[0], mapTrip(updatedTrip.rows[0]));
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

type BookingWithTrip = BookingRow & {
  t_id: string;
  t_driver_id: string;
  t_origin: string;
  t_destination: string;
  t_origin_normalized: string;
  t_destination_normalized: string;
  t_pickup_point: string | null;
  t_dropoff_point: string | null;
  t_depart_at: Date;
  t_seats_total: number;
  t_seats_left: number;
  t_fare_inr: number;
  t_car_model: string;
  t_number_plate: string;
  t_car_color: string;
  t_status: TripRow["status"];
  t_created_at: Date;
  t_updated_at: Date;
};

function tripFromJoined(row: BookingWithTrip): TripRow {
  return {
    id: row.t_id,
    driver_id: row.t_driver_id,
    origin: row.t_origin,
    destination: row.t_destination,
    origin_normalized: row.t_origin_normalized,
    destination_normalized: row.t_destination_normalized,
    pickup_point: row.t_pickup_point,
    dropoff_point: row.t_dropoff_point,
    depart_at: row.t_depart_at,
    seats_total: row.t_seats_total,
    seats_left: row.t_seats_left,
    fare_inr: row.t_fare_inr,
    car_model: row.t_car_model,
    number_plate: row.t_number_plate,
    car_color: row.t_car_color,
    status: row.t_status,
    created_at: row.t_created_at,
    updated_at: row.t_updated_at,
  };
}

const BOOKING_TRIP_SELECT = `
  b.id, b.trip_id, b.traveller_id, b.seats, b.seat_preference, b.cash_total_inr,
  b.status, b.cancelled_by, b.cancel_reason, b.created_at, b.updated_at,
  u.phone AS traveller_phone, u.display_name AS traveller_display_name,
  t.id AS t_id, t.driver_id AS t_driver_id, t.origin AS t_origin,
  t.destination AS t_destination, t.origin_normalized AS t_origin_normalized,
  t.destination_normalized AS t_destination_normalized,
  t.pickup_point AS t_pickup_point, t.dropoff_point AS t_dropoff_point,
  t.depart_at AS t_depart_at,
  t.seats_total AS t_seats_total, t.seats_left AS t_seats_left, t.fare_inr AS t_fare_inr,
  t.car_model AS t_car_model, t.number_plate AS t_number_plate, t.car_color AS t_car_color,
  t.status AS t_status, t.created_at AS t_created_at, t.updated_at AS t_updated_at
`;

export async function listMyBookings(travellerId: string) {
  const { rows } = await pool.query<BookingWithTrip>(
    `SELECT ${BOOKING_TRIP_SELECT}
     FROM bookings b
     JOIN trips t ON t.id = b.trip_id
     JOIN users u ON u.id = b.traveller_id
     WHERE b.traveller_id = $1
     ORDER BY t.depart_at DESC`,
    [travellerId]
  );
  return rows.map((row) => mapBooking(row, mapTrip(tripFromJoined(row))));
}

export async function listBookingsForTrip(tripId: string, driverId: string) {
  const trip = await getTripById(tripId);
  if (trip.driverId !== driverId) {
    throw httpError(403, "Only the driver can view trip bookings", ErrorCodes.FORBIDDEN);
  }

  const { rows } = await pool.query<BookingRow>(
    `SELECT b.*, u.phone AS traveller_phone, u.display_name AS traveller_display_name
     FROM bookings b
     JOIN users u ON u.id = b.traveller_id
     WHERE b.trip_id = $1
     ORDER BY b.created_at ASC`,
    [tripId]
  );
  return {
    trip,
    bookings: rows.map((r) => mapBooking(r)),
  };
}

export async function getBookingById(bookingId: string, userId: string) {
  const { rows } = await pool.query<BookingWithTrip>(
    `SELECT ${BOOKING_TRIP_SELECT}
     FROM bookings b
     JOIN trips t ON t.id = b.trip_id
     JOIN users u ON u.id = b.traveller_id
     WHERE b.id = $1`,
    [bookingId]
  );
  if (!rows[0]) throw httpError(404, "Booking not found", ErrorCodes.NOT_FOUND);
  const row = rows[0];
  if (row.traveller_id !== userId && row.t_driver_id !== userId) {
    throw httpError(403, "Not allowed to view this booking", ErrorCodes.FORBIDDEN);
  }
  return mapBooking(row, mapTrip(tripFromJoined(row)));
}

export async function cancelBooking(input: {
  bookingId: string;
  userId: string;
  asRole?: "traveller" | "driver";
}) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const { rows } = await client.query<BookingRow>(
      `SELECT * FROM bookings WHERE id = $1 FOR UPDATE`,
      [input.bookingId]
    );
    if (!rows[0]) throw httpError(404, "Booking not found", ErrorCodes.NOT_FOUND);
    const booking = rows[0];

    if (booking.status !== "confirmed") {
      throw httpError(400, "Booking is already cancelled", ErrorCodes.VALIDATION_ERROR);
    }

    const trip = await lockTrip(client, booking.trip_id);
    const isTraveller = booking.traveller_id === input.userId;
    const isDriver = trip.driver_id === input.userId;
    if (!isTraveller && !isDriver) {
      throw httpError(403, "Not allowed to cancel this booking", ErrorCodes.FORBIDDEN);
    }

    if (new Date(trip.depart_at).getTime() <= Date.now()) {
      throw httpError(400, "Cannot cancel after trip start", ErrorCodes.TRIP_STARTED);
    }

    if (input.asRole === "driver" && !isDriver) {
      throw httpError(403, "Only the driver can cancel as driver", ErrorCodes.FORBIDDEN);
    }
    if (input.asRole === "traveller" && !isTraveller) {
      throw httpError(403, "Only the traveller can cancel as traveller", ErrorCodes.FORBIDDEN);
    }

    const by: "traveller" | "driver" =
      input.asRole ?? (isTraveller ? "traveller" : "driver");

    await client.query(
      `UPDATE bookings
       SET status = 'cancelled',
           cancelled_by = $2,
           cancel_reason = $3,
           updated_at = NOW()
       WHERE id = $1`,
      [
        input.bookingId,
        by,
        by === "traveller" ? "Cancelled by traveller" : "Cancelled by driver",
      ]
    );

    if (trip.status === "open") {
      await client.query(
        `UPDATE trips
         SET seats_left = LEAST(seats_total, seats_left + $2),
             updated_at = NOW()
         WHERE id = $1`,
        [trip.id, booking.seats]
      );
    }

    await client.query("COMMIT");
    return getBookingById(input.bookingId, input.userId);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
