import { Router } from "express";
import { z } from "zod";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import {
  cancelBooking,
  getBookingById,
  listMyBookings,
} from "../services/bookingService";
import { HttpError } from "../utils/errors";

export const bookingsRouter = Router();

function sendErr(res: import("express").Response, err: unknown) {
  if (err instanceof z.ZodError) {
    res.status(400).json({ ok: false, error: "Invalid payload", details: err.flatten() });
    return;
  }
  const e = err as { status?: number; message?: string; code?: string };
  if (err instanceof HttpError || e.status) {
    res.status(e.status ?? 500).json({
      ok: false,
      error: e.message ?? "Request failed",
      ...(e.code ? { code: e.code } : {}),
    });
    return;
  }
  console.error(err);
  res.status(500).json({ ok: false, error: "Internal server error" });
}

bookingsRouter.get("/bookings/mine", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const bookings = await listMyBookings(user.id);
    res.json({ ok: true, bookings });
  } catch (err) {
    sendErr(res, err);
  }
});

bookingsRouter.get("/bookings/:id", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const booking = await getBookingById(req.params.id, user.id);
    res.json({ ok: true, booking });
  } catch (err) {
    sendErr(res, err);
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
    sendErr(res, err);
  }
});
