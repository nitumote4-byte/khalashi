import { Router } from "express";
import { z } from "zod";
import { env } from "../config/env";
import { clientIp, rateLimit } from "../middleware/rateLimit";
import { getSession, logout, normalizePhone, requestOtp, verifyOtp } from "../services/authService";
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

function bearer(req: { headers: { authorization?: string } }): string | undefined {
  const h = req.headers.authorization;
  if (!h?.startsWith("Bearer ")) return undefined;
  return h.slice(7);
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

authRouter.get("/auth/me", (req, res) => {
  const auth = getSession(bearer(req));
  if (!auth) {
    sendError(res, httpError(401, "Unauthorized", ErrorCodes.UNAUTHORIZED));
    return;
  }
  res.json({
    ok: true,
    user: {
      id: auth.user.id,
      phone: auth.user.phone,
      displayName: auth.user.displayName,
      language: auth.user.language,
    },
  });
});

authRouter.post("/auth/logout", (req, res) => {
  logout(bearer(req));
  res.json({ ok: true });
});
