import type { NextFunction, Request, Response } from "express";
import { env } from "../config/env";
import { ErrorCodes } from "../utils/errors";

/**
 * Soft-launch admin gate: shared secret via X-Admin-Secret or Bearer.
 * Set ADMIN_SECRET on the API service (Railway). Not a full RBAC system.
 */
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const secret = env.ADMIN_SECRET?.trim();
  if (!secret) {
    res.status(503).json({
      ok: false,
      error: "Admin review is not configured (set ADMIN_SECRET)",
      code: ErrorCodes.INTERNAL,
    });
    return;
  }

  const headerSecret = req.headers["x-admin-secret"];
  const fromHeader = typeof headerSecret === "string" ? headerSecret : undefined;
  const auth = req.headers.authorization;
  const fromBearer =
    auth?.startsWith("Bearer ") ? auth.slice(7) : undefined;

  if (fromHeader !== secret && fromBearer !== secret) {
    res.status(401).json({
      ok: false,
      error: "Unauthorized",
      code: ErrorCodes.UNAUTHORIZED,
    });
    return;
  }
  next();
}
