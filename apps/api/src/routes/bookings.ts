import { Router } from "express";
import { z } from "zod";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import {
  cancelBooking,
  getBookingById,
  listMyBookings,
} from "../services/bookingService";
import { sendError } from "../utils/respond";

export const bookingsRouter = Router();

bookingsRouter.get("/bookings/mine", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const bookings = await listMyBookings(user.id);
    res.json({ ok: true, bookings });
  } catch (err) {
    sendError(res, err);
  }
});

bookingsRouter.get("/bookings/:id", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const booking = await getBookingById(req.params.id, user.id);
    res.json({ ok: true, booking });
  } catch (err) {
    sendError(res, err);
  }
});

bookingsRouter.post("/bookings/:id/cancel", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const asRole = z
      .object({ asRole: z.enum(["traveller", "driver"]).optional() })
      .parse(req.body ?? {}).asRole;
    const booking = await cancelBooking({
      bookingId: req.params.id,
      userId: user.id,
      asRole,
    });
    res.json({ ok: true, booking });
  } catch (err) {
    sendError(res, err);
  }
});
