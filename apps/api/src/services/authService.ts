/**
 * Mock OTP + session store for Phase 1–2.
 * Users are upserted into Postgres so trips/bookings can FK to users.id.
 * OTP challenges and sessions stay in-memory (swap later for production).
 */
import { randomBytes } from "crypto";
import { env } from "../config/env";
import { pool } from "../db/pool";
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

export type AuthUser = {
  id: string;
  phone: string;
  displayName: string | null;
  language: "en" | "hi";
};

const challenges = new Map<string, Challenge>();
const sessions = new Map<string, Session>();
const usersById = new Map<string, AuthUser>();
const usersByPhone = new Map<string, AuthUser>();

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

function cacheUser(user: AuthUser) {
  usersById.set(user.id, user);
  usersByPhone.set(user.phone, user);
}

async function ensureUser(phone: string): Promise<AuthUser> {
  const cached = usersByPhone.get(phone);
  if (cached) return cached;

  const existing = await pool.query<{
    id: string;
    phone: string;
    display_name: string | null;
    language: "en" | "hi";
  }>("SELECT id, phone, display_name, language FROM users WHERE phone = $1", [phone]);

  if (existing.rows[0]) {
    const row = existing.rows[0];
    const user: AuthUser = {
      id: row.id,
      phone: row.phone,
      displayName: row.display_name,
      language: row.language,
    };
    cacheUser(user);
    return user;
  }

  const inserted = await pool.query<{
    id: string;
    phone: string;
    display_name: string | null;
    language: "en" | "hi";
  }>(
    `INSERT INTO users (phone, language)
     VALUES ($1, 'en')
     ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone
     RETURNING id, phone, display_name, language`,
    [phone]
  );
  const row = inserted.rows[0];
  const user: AuthUser = {
    id: row.id,
    phone: row.phone,
    displayName: row.display_name,
    language: row.language,
  };
  cacheUser(user);
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
  const user = await ensureUser(phone);
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
  const user = usersById.get(session.userId) ?? usersByPhone.get(session.phone);
  if (!user) return null;
  return { session, user };
}

export function logout(token: string | undefined) {
  if (token) sessions.delete(token);
}

export async function updateDisplayName(userId: string, displayName: string | null) {
  const { rows } = await pool.query<{
    id: string;
    phone: string;
    display_name: string | null;
    language: "en" | "hi";
  }>(
    `UPDATE users
     SET display_name = $2, updated_at = NOW()
     WHERE id = $1
     RETURNING id, phone, display_name, language`,
    [userId, displayName]
  );
  if (!rows[0]) {
    throw Object.assign(new Error("User not found"), { status: 404 });
  }
  const user: AuthUser = {
    id: rows[0].id,
    phone: rows[0].phone,
    displayName: rows[0].display_name,
    language: rows[0].language,
  };
  cacheUser(user);
  return user;
}

export async function updateLanguage(userId: string, language: "en" | "hi") {
  const { rows } = await pool.query<{
    id: string;
    phone: string;
    display_name: string | null;
    language: "en" | "hi";
  }>(
    `UPDATE users
     SET language = $2, updated_at = NOW()
     WHERE id = $1
     RETURNING id, phone, display_name, language`,
    [userId, language]
  );
  if (!rows[0]) {
    throw Object.assign(new Error("User not found"), { status: 404 });
  }
  const user: AuthUser = {
    id: rows[0].id,
    phone: rows[0].phone,
    displayName: rows[0].display_name,
    language: rows[0].language,
  };
  cacheUser(user);
  return user;
}
