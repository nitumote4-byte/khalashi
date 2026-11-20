import { Router } from "express";
import { z } from "zod";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { rateLimit } from "../middleware/rateLimit";
import {
  getBookingRatingState,
  submitRating,
} from "../services/ratingService";
import { sendError } from "../utils/respond";

export const ratingsRouter = Router();

const submitBody = z.object({
  bookingId: z.string().uuid(),
  stars: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional().nullable(),
});

const ratingLimit = rateLimit({
  name: "rating-submit",
  limit: 30,
  windowMs: 60 * 60 * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

ratingsRouter.get(
  "/ratings/booking/:bookingId",
  requireAuth,
  async (req, res) => {
    try {
      const user = (req as AuthedRequest).user;
      const state = await getBookingRatingState(req.params.bookingId, user.id);
      res.json({ ok: true, ...state });
    } catch (err) {
      sendError(res, err);
    }
  }
);

ratingsRouter.post("/ratings", requireAuth, ratingLimit, async (req, res) => {
  try {
    const body = submitBody.parse(req.body);
    const user = (req as AuthedRequest).user;
    const rating = await submitRating({
      bookingId: body.bookingId,
      raterId: user.id,
      stars: body.stars,
      comment: body.comment,
    });
    res.status(201).json({ ok: true, rating });
  } catch (err) {
    sendError(res, err);
  }
});
