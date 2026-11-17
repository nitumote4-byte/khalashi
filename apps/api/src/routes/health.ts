import { Router } from "express";
import { env } from "../config/env";

export const healthRouter = Router();

healthRouter.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "khalashi-api",
    phase: "0-1",
    env: env.NODE_ENV,
    otpProvider: env.OTP_PROVIDER,
  });
});
