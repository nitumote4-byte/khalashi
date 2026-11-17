import type { NextFunction, Request, Response } from "express";
import { getSession } from "../services/authService";
import { ErrorCodes } from "../utils/errors";

export type AuthedRequest = Request & {
  user: {
    id: string;
    phone: string;
    displayName: string | null;
    language: "en" | "hi";
  };
};

function bearer(req: Request): string | undefined {
  const h = req.headers.authorization;
  if (!h?.startsWith("Bearer ")) return undefined;
  return h.slice(7);
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const auth = getSession(bearer(req));
  if (!auth) {
    res.status(401).json({
      ok: false,
      error: "Unauthorized",
      code: ErrorCodes.UNAUTHORIZED,
    });
    return;
  }
  (req as AuthedRequest).user = auth.user;
  next();
}
