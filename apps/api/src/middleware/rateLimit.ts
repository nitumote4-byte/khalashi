import type { NextFunction, Request, Response } from "express";
import { httpError } from "../utils/errors";

type Bucket = { timestamps: number[] };

const buckets = new Map<string, Bucket>();

export type RateLimitOptions = {
  /** Unique name for this limiter (e.g. otp-request) */
  name: string;
  /** Max requests allowed in the window */
  limit: number;
  /** Window length in milliseconds */
  windowMs: number;
  /** Build a key from the request (phone, user id, IP, …) */
  keyFn: (req: Request) => string;
};

function prune(timestamps: number[], windowMs: number, now: number): number[] {
  return timestamps.filter((t) => now - t < windowMs);
}

/**
 * In-memory sliding-window rate limiter (single-process soft launch).
 * Returns 429 + code RATE_LIMITED when exceeded.
 */
export function rateLimit(opts: RateLimitOptions) {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      const now = Date.now();
      const identity = opts.keyFn(req);
      const mapKey = `${opts.name}:${identity}`;
      const bucket = buckets.get(mapKey) ?? { timestamps: [] };
      bucket.timestamps = prune(bucket.timestamps, opts.windowMs, now);

      if (bucket.timestamps.length >= opts.limit) {
        throw httpError(
          429,
          "Too many requests. Try again shortly.",
          "RATE_LIMITED"
        );
      }

      bucket.timestamps.push(now);
      buckets.set(mapKey, bucket);
      next();
    } catch (err) {
      next(err);
    }
  };
}

export function clientIp(req: Request): string {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0]?.trim() || req.ip || "unknown";
  }
  return req.ip || req.socket.remoteAddress || "unknown";
}

/** Test helper — clear all buckets between smoke runs if needed */
export function resetRateLimitsForTests() {
  buckets.clear();
}
