import { Router } from "express";
import { z } from "zod";
import { env } from "../config/env";
import { requireAdmin } from "../middleware/adminAuth";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { rateLimit } from "../middleware/rateLimit";
import {
  getMyVerification,
  getVerificationImage,
  listPendingVerifications,
  reviewVerification,
  submitVerification,
} from "../services/verificationService";
import { sendError } from "../utils/respond";

export const verificationRouter = Router();

const submitBody = z.object({
  idType: z.enum(["aadhaar", "dl", "voter"]),
  fullName: z.string().min(2).max(120),
  idNumber: z.string().min(4).max(64),
  imageBase64: z.string().min(32).max(Math.ceil((env.ID_IMAGE_MAX_BYTES * 4) / 3) + 128),
});

const reviewBody = z.object({
  reviewNote: z.string().max(500).optional().nullable(),
});

const submitLimit = rateLimit({
  name: "id-verify-submit",
  limit: 5,
  windowMs: 60 * 60 * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

verificationRouter.post(
  "/verification/submit",
  requireAuth,
  submitLimit,
  async (req, res) => {
    try {
      const body = submitBody.parse(req.body);
      const user = (req as AuthedRequest).user;
      const verification = await submitVerification({
        userId: user.id,
        idType: body.idType,
        fullName: body.fullName,
        idNumber: body.idNumber,
        imageBase64: body.imageBase64,
      });
      res.status(201).json({ ok: true, verification });
    } catch (err) {
      sendError(res, err);
    }
  }
);

verificationRouter.get("/verification/me", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const verification = await getMyVerification(user.id);
    res.json({ ok: true, verification });
  } catch (err) {
    sendError(res, err);
  }
});

verificationRouter.get(
  "/admin/verifications/pending",
  requireAdmin,
  async (req, res) => {
    try {
      const limit = Number(req.query.limit ?? 50);
      const items = await listPendingVerifications(Number.isFinite(limit) ? limit : 50);
      res.json({ ok: true, items });
    } catch (err) {
      sendError(res, err);
    }
  }
);

verificationRouter.get(
  "/admin/verifications/:id/image",
  requireAdmin,
  async (req, res) => {
    try {
      const { buffer, mime, filename } = await getVerificationImage(req.params.id);
      res.setHeader("Content-Type", mime);
      res.setHeader("Content-Disposition", `inline; filename="${filename}"`);
      res.send(buffer);
    } catch (err) {
      sendError(res, err);
    }
  }
);

verificationRouter.post(
  "/admin/verifications/:id/approve",
  requireAdmin,
  async (req, res) => {
    try {
      const body = reviewBody.parse(req.body ?? {});
      const item = await reviewVerification({
        verificationId: req.params.id,
        decision: "approve",
        reviewNote: body.reviewNote ?? undefined,
      });
      res.json({ ok: true, item });
    } catch (err) {
      sendError(res, err);
    }
  }
);

verificationRouter.post(
  "/admin/verifications/:id/reject",
  requireAdmin,
  async (req, res) => {
    try {
      const body = reviewBody.parse(req.body ?? {});
      const item = await reviewVerification({
        verificationId: req.params.id,
        decision: "reject",
        reviewNote: body.reviewNote ?? undefined,
      });
      res.json({ ok: true, item });
    } catch (err) {
      sendError(res, err);
    }
  }
);
