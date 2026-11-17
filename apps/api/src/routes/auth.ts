import { Router } from "express";
import { z } from "zod";
import { getSession, logout, requestOtp, verifyOtp } from "../services/authService";

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

authRouter.post("/auth/otp/request", async (req, res) => {
  try {
    const { phone } = phoneBody.parse(req.body);
    const result = await requestOtp(phone);
    res.json({ ok: true, ...result });
  } catch (err) {
    const e = err as { status?: number; message?: string; errors?: unknown };
    if (e instanceof z.ZodError) {
      res.status(400).json({ ok: false, error: "Invalid phone payload" });
      return;
    }
    res.status(e.status ?? 500).json({ ok: false, error: e.message ?? "Request failed" });
  }
});

authRouter.post("/auth/otp/verify", async (req, res) => {
  try {
    const { phone, code } = verifyBody.parse(req.body);
    const result = await verifyOtp(phone, code);
    res.json({ ok: true, ...result });
  } catch (err) {
    const e = err as { status?: number; message?: string };
    if (e instanceof z.ZodError) {
      res.status(400).json({ ok: false, error: "Invalid verify payload" });
      return;
    }
    res.status(e.status ?? 500).json({ ok: false, error: e.message ?? "Verify failed" });
  }
});

authRouter.get("/auth/me", (req, res) => {
  const auth = getSession(bearer(req));
  if (!auth) {
    res.status(401).json({ ok: false, error: "Unauthorized" });
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
