import type { Response } from "express";
import { ZodError } from "zod";
import { HttpError } from "./errors";

/**
 * Consistent JSON error shape: { ok: false, error, code? }
 */
export function sendError(res: Response, err: unknown): void {
  if (err instanceof ZodError) {
    res.status(400).json({
      ok: false,
      error: "Invalid payload",
      code: "VALIDATION_ERROR",
      details: err.flatten(),
    });
    return;
  }

  if (err instanceof HttpError) {
    res.status(err.status).json({
      ok: false,
      error: err.message,
      ...(err.code ? { code: err.code } : {}),
    });
    return;
  }

  const e = err as { status?: number; message?: string; code?: string };
  if (typeof e.status === "number" && e.message) {
    res.status(e.status).json({
      ok: false,
      error: e.message,
      ...(e.code ? { code: e.code } : {}),
    });
    return;
  }

  console.error(
    JSON.stringify({
      level: "error",
      msg: "unhandled",
      error: e?.message ?? String(err),
    })
  );
  res.status(500).json({ ok: false, error: "Internal server error", code: "INTERNAL" });
}
