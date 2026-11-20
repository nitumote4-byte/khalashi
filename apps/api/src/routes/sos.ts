import { Router } from "express";
import { z } from "zod";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { logSosEvent, type SosAction } from "../services/sosService";
import { sendError } from "../utils/respond";

export const sosRouter = Router();

const logBody = z.object({
  tripId: z.string().uuid(),
  bookingId: z.string().uuid().optional().nullable(),
  action: z
    .enum(["pressed", "call_contact", "share", "call_112"])
    .default("pressed"),
});

sosRouter.post("/sos", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const body = logBody.parse(req.body ?? {});
    const event = await logSosEvent({
      userId: user.id,
      tripId: body.tripId,
      bookingId: body.bookingId ?? null,
      action: body.action as SosAction,
    });
    res.json({ ok: true, event });
  } catch (err) {
    sendError(res, err);
  }
});
