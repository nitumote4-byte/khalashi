import { Router } from "express";
import { z } from "zod";
import { requireAdmin } from "../middleware/adminAuth";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { rateLimit } from "../middleware/rateLimit";
import { createReport, listReports } from "../services/reportService";
import { sendError } from "../utils/respond";

export const reportsRouter = Router();

const createBody = z.object({
  reportedUserId: z.string().uuid(),
  reason: z.enum([
    "harassment",
    "unsafe_driving",
    "no_show",
    "spam",
    "fraud",
    "other",
  ]),
  details: z.string().max(1000).optional().nullable(),
  tripId: z.string().uuid().optional().nullable(),
  bookingId: z.string().uuid().optional().nullable(),
});

const reportLimit = rateLimit({
  name: "report-submit",
  limit: 10,
  windowMs: 60 * 60 * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

reportsRouter.post("/reports", requireAuth, reportLimit, async (req, res) => {
  try {
    const body = createBody.parse(req.body);
    const user = (req as AuthedRequest).user;
    const report = await createReport({
      reporterId: user.id,
      reportedUserId: body.reportedUserId,
      reason: body.reason,
      details: body.details,
      tripId: body.tripId,
      bookingId: body.bookingId,
    });
    res.status(201).json({ ok: true, report });
  } catch (err) {
    sendError(res, err);
  }
});

/** Admin: curl -H "X-Admin-Secret: $ADMIN_SECRET" "$API/admin/reports?status=open" */
reportsRouter.get("/admin/reports", requireAdmin, async (req, res) => {
  try {
    const status =
      typeof req.query.status === "string" ? req.query.status : "open";
    const limit = Number(req.query.limit ?? 50);
    const items = await listReports({
      status,
      limit: Number.isFinite(limit) ? limit : 50,
    });
    res.json({ ok: true, items });
  } catch (err) {
    sendError(res, err);
  }
});
