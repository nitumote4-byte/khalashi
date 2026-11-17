import type { NextFunction, Request, Response } from "express";
import { randomBytes } from "crypto";

/**
 * Lightweight request logger. Never logs bodies (OTP codes live there).
 */
export function requestLog(req: Request, res: Response, next: NextFunction) {
  const started = Date.now();
  const requestId =
    (typeof req.headers["x-request-id"] === "string" && req.headers["x-request-id"]) ||
    randomBytes(6).toString("hex");
  res.setHeader("x-request-id", requestId);

  res.on("finish", () => {
    const ms = Date.now() - started;
    const userId = (req as Request & { user?: { id?: string } }).user?.id;
    console.log(
      JSON.stringify({
        level: "info",
        msg: "http",
        requestId,
        method: req.method,
        path: req.originalUrl?.split("?")[0] ?? req.path,
        status: res.statusCode,
        ms,
        ...(userId ? { userId } : {}),
        ip: req.ip || req.socket.remoteAddress,
      })
    );
  });

  next();
}
