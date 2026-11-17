import { Router } from "express";
import { z } from "zod";
import { env } from "../config/env";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { rateLimit } from "../middleware/rateLimit";
import {
  cancelBooking,
  createBooking,
  listBookingsForTrip,
} from "../services/bookingService";
import {
  cancelTrip,
  createTrip,
  getTripById,
  listMyTrips,
  searchTrips,
} from "../services/tripService";
import { sendError } from "../utils/respond";

export const tripsRouter = Router();

const createBody = z.object({
  origin: z.string().min(1).max(120),
  destination: z.string().min(1).max(120),
  departAt: z.string().min(1),
  seatsTotal: z.number().int(),
  fareInr: z.number().int(),
});

const searchQuery = z.object({
  origin: z.string().min(1),
  destination: z.string().min(1),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

const bookBody = z.object({
  seats: z.number().int().min(1),
  seatPreference: z.enum(["front", "window", "any"]).default("any"),
});

const tripPostLimit = rateLimit({
  name: "trip-post",
  limit: env.RATE_LIMIT_TRIP_POST_PER_USER,
  windowMs: env.RATE_LIMIT_ACTION_WINDOW_SEC * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

const searchLimit = rateLimit({
  name: "search",
  limit: env.RATE_LIMIT_SEARCH_PER_USER,
  windowMs: env.RATE_LIMIT_ACTION_WINDOW_SEC * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

const bookLimit = rateLimit({
  name: "book",
  limit: env.RATE_LIMIT_BOOK_PER_USER,
  windowMs: env.RATE_LIMIT_ACTION_WINDOW_SEC * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

tripsRouter.post("/trips", requireAuth, tripPostLimit, async (req, res) => {
  try {
    const body = createBody.parse(req.body);
    const user = (req as AuthedRequest).user;
    const trip = await createTrip({
      driverId: user.id,
      origin: body.origin,
      destination: body.destination,
      departAt: body.departAt,
      seatsTotal: body.seatsTotal,
      fareInr: body.fareInr,
    });
    res.status(201).json({ ok: true, trip });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.get("/trips/mine", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const trips = await listMyTrips(user.id);
    res.json({ ok: true, trips });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.get("/trips/search", requireAuth, searchLimit, async (req, res) => {
  try {
    const q = searchQuery.parse(req.query);
    const trips = await searchTrips(q);
    res.json({ ok: true, trips });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.get("/trips/:id", requireAuth, async (req, res) => {
  try {
    const trip = await getTripById(req.params.id);
    res.json({ ok: true, trip });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.post("/trips/:id/cancel", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const trip = await cancelTrip(req.params.id, user.id);
    res.json({ ok: true, trip });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.get("/trips/:id/bookings", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const result = await listBookingsForTrip(req.params.id, user.id);
    res.json({ ok: true, ...result });
  } catch (err) {
    sendError(res, err);
  }
});

tripsRouter.post("/trips/:id/bookings", requireAuth, bookLimit, async (req, res) => {
  try {
    const body = bookBody.parse(req.body);
    const user = (req as AuthedRequest).user;
    const booking = await createBooking({
      tripId: req.params.id,
      travellerId: user.id,
      seats: body.seats,
      seatPreference: body.seatPreference,
    });
    res.status(201).json({ ok: true, booking });
  } catch (err) {
    sendError(res, err);
  }
});

// Convenience: cancel booking nested under trip (driver or traveller)
tripsRouter.post("/trips/:tripId/bookings/:bookingId/cancel", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const booking = await cancelBooking({
      bookingId: req.params.bookingId,
      userId: user.id,
    });
    res.json({ ok: true, booking });
  } catch (err) {
    sendError(res, err);
  }
});
