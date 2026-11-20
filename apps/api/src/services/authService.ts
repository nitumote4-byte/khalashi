/**
 * OTP + session store for Phase 1–3.
 * Provider: OTP_PROVIDER=mock|msg91|2factor (default mock).
 * Send goes through otpProvider; verify is always against the in-memory challenge hash.
 * Users are upserted into Postgres so trips/bookings can FK to users.id.
 * OTP challenges and sessions stay in-memory (swap later for production).
 */
import { randomBytes } from "crypto";
import { env } from "../config/env";
import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";
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
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
};

type UserRow = {
  id: string;
  phone: string;
  display_name: string | null;
  language: "en" | "hi";
  emergency_contact_name: string | null;
  emergency_contact_phone: string | null;
};

const USER_SELECT =
  "id, phone, display_name, language, emergency_contact_name, emergency_contact_phone";

function mapUserRow(row: UserRow): AuthUser {
  return {
    id: row.id,
    phone: row.phone,
    displayName: row.display_name,
    language: row.language,
    emergencyContactName: row.emergency_contact_name,
    emergencyContactPhone: row.emergency_contact_phone,
  };
}

const challenges = new Map<string, Challenge>();
const sessions = new Map<string, Session>();
const usersById = new Map<string, AuthUser>();
const usersByPhone = new Map<string, AuthUser>();

export function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, "");
  if (digits.length === 10) return `+91${digits}`;
  if (digits.length === 12 && digits.startsWith("91")) return `+${digits}`;
  if (raw.startsWith("+91") && digits.length === 12) return `+${digits}`;
  throw httpError(400, "Invalid Indian mobile number", ErrorCodes.OTP_INVALID_PHONE);
}

function cacheUser(user: AuthUser) {
  usersById.set(user.id, user);
  usersByPhone.set(user.phone, user);
}

async function ensureUser(phone: string): Promise<AuthUser> {
  const cached = usersByPhone.get(phone);
  if (cached) return cached;

  const existing = await pool.query<UserRow>(
    `SELECT ${USER_SELECT} FROM users WHERE phone = $1`,
    [phone]
  );

  if (existing.rows[0]) {
    const user = mapUserRow(existing.rows[0]);
    cacheUser(user);
    return user;
  }

  const inserted = await pool.query<UserRow>(
    `INSERT INTO users (phone, language)
     VALUES ($1, 'en')
     ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone
     RETURNING ${USER_SELECT}`,
    [phone]
  );
  const user = mapUserRow(inserted.rows[0]);
  cacheUser(user);
  return user;
}

export async function requestOtp(phoneRaw: string) {
  const phone = normalizePhone(phoneRaw);

  const code = generateOtpCode();
  const codeHash = hashOtp(code);
  const expiresAt = Date.now() + env.OTP_EXPIRY_SECONDS * 1000;

  challenges.set(phone, { phone, codeHash, expiresAt, attemptCount: 0 });
  const sendResult = await sendOtp(phone, code);

  console.log(
    JSON.stringify({
      level: "info",
      msg: "otp_requested",
      phone,
      provider: sendResult.provider,
    })
  );

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
    throw httpError(
      400,
      "No OTP pending for this number. Request a new code.",
      ErrorCodes.OTP_NONE_PENDING
    );
  }
  if (Date.now() > challenge.expiresAt) {
    challenges.delete(phone);
    throw httpError(400, "OTP expired. Request a new code.", ErrorCodes.OTP_EXPIRED);
  }
  if (challenge.attemptCount >= 5) {
    challenges.delete(phone);
    throw httpError(
      429,
      "Too many attempts. Request a new code.",
      ErrorCodes.OTP_TOO_MANY_ATTEMPTS
    );
  }

  challenge.attemptCount += 1;
  if (!verifyOtpHash(code.trim(), challenge.codeHash)) {
    throw httpError(401, "Incorrect OTP.", ErrorCodes.OTP_INCORRECT);
  }

  challenges.delete(phone);
  const user = await ensureUser(phone);
  const token = randomBytes(32).toString("hex");
  const expiresAt = Date.now() + env.SESSION_TTL_SECONDS * 1000;
  sessions.set(token, { token, userId: user.id, phone: user.phone, expiresAt });

  console.log(
    JSON.stringify({
      level: "info",
      msg: "otp_verified",
      phone,
      userId: user.id,
    })
  );

  return {
    token,
    expiresInSeconds: env.SESSION_TTL_SECONDS,
    user: {
      id: user.id,
      phone: user.phone,
      displayName: user.displayName,
      language: user.language,
      emergencyContactName: user.emergencyContactName,
      emergencyContactPhone: user.emergencyContactPhone,
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
  const { rows } = await pool.query<UserRow>(
    `UPDATE users
     SET display_name = $2, updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_SELECT}`,
    [userId, displayName]
  );
  if (!rows[0]) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }
  const user = mapUserRow(rows[0]);
  cacheUser(user);
  return user;
}

export async function updateLanguage(userId: string, language: "en" | "hi") {
  const { rows } = await pool.query<UserRow>(
    `UPDATE users
     SET language = $2, updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_SELECT}`,
    [userId, language]
  );
  if (!rows[0]) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }
  const user = mapUserRow(rows[0]);
  cacheUser(user);
  return user;
}

/** Save or clear emergency contact. Empty name+phone clears both. */
export async function updateEmergencyContact(
  userId: string,
  input: { name: string | null; phone: string | null }
) {
  const nameRaw = input.name?.trim() ?? "";
  const phoneRaw = input.phone?.trim() ?? "";

  let name: string | null = null;
  let phone: string | null = null;

  if (nameRaw || phoneRaw) {
    if (!nameRaw) {
      throw httpError(400, "Emergency contact name is required", ErrorCodes.VALIDATION_ERROR);
    }
    if (nameRaw.length > 120) {
      throw httpError(
        400,
        "Emergency contact name must be at most 120 characters",
        ErrorCodes.VALIDATION_ERROR
      );
    }
    if (!phoneRaw) {
      throw httpError(400, "Emergency contact phone is required", ErrorCodes.VALIDATION_ERROR);
    }
    name = nameRaw;
    phone = normalizePhone(phoneRaw);
  }

  const { rows } = await pool.query<UserRow>(
    `UPDATE users
     SET emergency_contact_name = $2,
         emergency_contact_phone = $3,
         updated_at = NOW()
     WHERE id = $1
     RETURNING ${USER_SELECT}`,
    [userId, name, phone]
  );
  if (!rows[0]) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }
  const user = mapUserRow(rows[0]);
  cacheUser(user);
  return user;
}

export async function getUserById(userId: string): Promise<AuthUser | null> {
  const cached = usersById.get(userId);
  if (cached) return cached;
  const { rows } = await pool.query<UserRow>(
    `SELECT ${USER_SELECT} FROM users WHERE id = $1`,
    [userId]
  );
  if (!rows[0]) return null;
  const user = mapUserRow(rows[0]);
  cacheUser(user);
  return user;
}
