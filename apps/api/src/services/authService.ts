/**
 * In-memory OTP + session store for Phase 1 shell.
 * Swap to Postgres otp_challenges + real sessions when DB is wired in CI/prod.
 */
import { randomBytes } from "crypto";
import { env } from "../config/env";
import { generateOtpCode, hashOtp, sendOtp, verifyOtpHash } from "./otpProvider";

type Challenge = {
  phone: string;
  codeHash: string;
  expiresAt: number;
  attemptCount: number;
};

type Session = {
  token: string;
  userId: string;
  phone: string;
  expiresAt: number;
};

type User = {
  id: string;
  phone: string;
  displayName: string | null;
  language: "en" | "hi";
};

const challenges = new Map<string, Challenge>();
const sessions = new Map<string, Session>();
const usersByPhone = new Map<string, User>();

const RATE_WINDOW_MS = 60_000;
const sendTimestamps = new Map<string, number[]>();

function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, "");
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 12 && digits.startsWith("91")) return `+${digits}`;
  if (raw.startsWith("+91") && digits.length === 12) return `+${digits}`;
  throw Object.assign(new Error("Invalid Indian mobile number"), { status: 400 });
}

function assertRateLimit(phone: string) {
  const now = Date.now();
  const recent = (sendTimestamps.get(phone) ?? []).filter((t) => now - t < RATE_WINDOW_MS);
  if (recent.length >= 3) {
    throw Object.assign(new Error("Too many OTP requests. Try again shortly."), {
      status: 429,
    });
  }
  recent.push(now);
  sendTimestamps.set(phone, recent);
}

function ensureUser(phone: string): User {
  let user = usersByPhone.get(phone);
  if (!user) {
    user = {
      id: randomBytes(16).toString("hex"),
      phone,
      displayName: null,
      language: "en",
    };
    usersByPhone.set(phone, user);
  }
  return user;
}

export async function requestOtp(phoneRaw: string) {
  const phone = normalizePhone(phoneRaw);
  assertRateLimit(phone);

  const code = generateOtpCode();
  const codeHash = hashOtp(code);
  const expiresAt = Date.now() + env.OTP_EXPIRY_SECONDS * 1000;

  challenges.set(phone, { phone, codeHash, expiresAt, attemptCount: 0 });
  const sendResult = await sendOtp(phone, code);

  return {
    phone,
    expiresInSeconds: env.OTP_EXPIRY_SECONDS,
    provider: sendResult.provider,
    ...(sendResult.debugCode ? { debugCode: sendResult.debugCode } : {}),
  };
}

export async function verifyOtp(phoneRaw: string, code: string) {
  const phone = normalizePhone(phoneRaw);
  const challenge = challenges.get(phone);

  if (!challenge) {
    throw Object.assign(new Error("No OTP pending for this number. Request a new code."), {
      status: 400,
    });
  }
  if (Date.now() > challenge.expiresAt) {
    challenges.delete(phone);
    throw Object.assign(new Error("OTP expired. Request a new code."), { status: 400 });
  }
  if (challenge.attemptCount >= 5) {
    challenges.delete(phone);
    throw Object.assign(new Error("Too many attempts. Request a new code."), { status: 429 });
  }

  challenge.attemptCount += 1;
  if (!verifyOtpHash(code.trim(), challenge.codeHash)) {
    throw Object.assign(new Error("Incorrect OTP."), { status: 401 });
  }

  challenges.delete(phone);
  const user = ensureUser(phone);
  const token = randomBytes(32).toString("hex");
  const expiresAt = Date.now() + env.SESSION_TTL_SECONDS * 1000;
  sessions.set(token, { token, userId: user.id, phone: user.phone, expiresAt });

  return {
    token,
    expiresInSeconds: env.SESSION_TTL_SECONDS,
    user: {
      id: user.id,
      phone: user.phone,
      displayName: user.displayName,
      language: user.language,
    },
  };
}

export function getSession(token: string | undefined) {
  if (!token) return null;
  const session = sessions.get(token);
  if (!session) return null;
  if (Date.now() > session.expiresAt) {
    sessions.delete(token);
    return null;
  }
  const user = usersByPhone.get(session.phone);
  if (!user) return null;
  return { session, user };
}

export function logout(token: string | undefined) {
  if (token) sessions.delete(token);
}
