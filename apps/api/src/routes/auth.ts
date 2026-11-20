import { Router } from "express";
import { z } from "zod";
import { env } from "../config/env";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { clientIp, rateLimit } from "../middleware/rateLimit";
import {
  getSession,
  logout,
  normalizePhone,
  requestOtp,
  updateEmergencyContact,
  verifyOtp,
} from "../services/authService";
import { getRatingSummary } from "../services/ratingService";
import { getUserVerificationStatus } from "../services/verificationService";
import { ErrorCodes, httpError } from "../utils/errors";
import { sendError } from "../utils/respond";

export const authRouter = Router();

const phoneBody = z.object({
  phone: z.string().min(10).max(15),
});

const verifyBody = z.object({
  phone: z.string().min(10).max(15),
  code: z.string().min(4).max(8),
});

const emergencyBody = z.object({
  emergencyContactName: z.string().max(120).nullable().optional(),
  emergencyContactPhone: z.string().max(15).nullable().optional(),
});

function bearer(req: { headers: { authorization?: string } }): string | undefined {
  const h = req.headers.authorization;
  if (!h?.startsWith("Bearer ")) return undefined;
  return h.slice(7);
}

function publicUser(
  user: {
    id: string;
    phone: string;
    displayName: string | null;
    language: "en" | "hi";
    emergencyContactName: string | null;
    emergencyContactPhone: string | null;
  },
  extras?: {
    verificationStatus?: string;
    ratingAvg?: number;
    ratingCount?: number;
  }
) {
  return {
    id: user.id,
    phone: user.phone,
    displayName: user.displayName,
    language: user.language,
    emergencyContactName: user.emergencyContactName,
    emergencyContactPhone: user.emergencyContactPhone,
    ...(extras?.verificationStatus
      ? { verificationStatus: extras.verificationStatus }
      : {}),
    ...(extras?.ratingAvg != null ? { ratingAvg: extras.ratingAvg } : {}),
    ...(extras?.ratingCount != null ? { ratingCount: extras.ratingCount } : {}),
  };
}

const otpPhoneLimit = rateLimit({
  name: "otp-phone",
  limit: env.RATE_LIMIT_OTP_PER_PHONE,
  windowMs: env.RATE_LIMIT_OTP_WINDOW_SEC * 1000,
  keyFn: (req) => {
    try {
      const phone = phoneBody.parse(req.body).phone;
      return normalizePhone(phone);
    } catch {
      return `bad:${clientIp(req)}`;
    }
  },
});

const otpIpLimit = rateLimit({
  name: "otp-ip",
  limit: env.RATE_LIMIT_OTP_PER_IP,
  windowMs: env.RATE_LIMIT_OTP_WINDOW_SEC * 1000,
  keyFn: (req) => clientIp(req),
});

authRouter.post("/auth/otp/request", otpIpLimit, otpPhoneLimit, async (req, res) => {
  try {
    const { phone } = phoneBody.parse(req.body);
    const result = await requestOtp(phone);
    res.json({ ok: true, ...result });
  } catch (err) {
    sendError(res, err);
  }
});

authRouter.post("/auth/otp/verify", otpIpLimit, async (req, res) => {
  try {
    const { phone, code } = verifyBody.parse(req.body);
    const result = await verifyOtp(phone, code);
    res.json({ ok: true, ...result });
  } catch (err) {
    sendError(res, err);
  }
});

authRouter.get("/auth/me", async (req, res) => {
  const auth = getSession(bearer(req));
  if (!auth) {
    sendError(res, httpError(401, "Unauthorized", ErrorCodes.UNAUTHORIZED));
    return;
  }
  try {
    const [verificationStatus, rating] = await Promise.all([
      getUserVerificationStatus(auth.user.id),
      getRatingSummary(auth.user.id),
    ]);
    res.json({
      ok: true,
      user: publicUser(auth.user, {
        verificationStatus,
        ratingAvg: rating.ratingAvg,
        ratingCount: rating.ratingCount,
      }),
    });
  } catch (err) {
    sendError(res, err);
  }
});

authRouter.put("/auth/emergency-contact", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const body = emergencyBody.parse(req.body ?? {});
    const updated = await updateEmergencyContact(user.id, {
      name: body.emergencyContactName ?? null,
      phone: body.emergencyContactPhone ?? null,
    });
    res.json({ ok: true, user: publicUser(updated) });
  } catch (err) {
    sendError(res, err);
  }
});

authRouter.post("/auth/logout", (req, res) => {
  logout(bearer(req));
  res.json({ ok: true });
});
