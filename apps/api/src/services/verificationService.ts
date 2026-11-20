/**
 * Soft-launch gov ID verification — photo + manual review.
 * No DigiLocker / UIDAI. Images land on local/Railway disk under UPLOAD_DIR.
 */
import fs from "fs";
import path from "path";
import { randomUUID } from "crypto";
import { env } from "../config/env";
import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";

export type VerificationStatus = "unverified" | "pending_review" | "verified" | "rejected";
export type IdType = "aadhaar" | "dl" | "voter";

export type VerificationPublic = {
  status: VerificationStatus;
  idType: IdType | null;
  fullName: string | null;
  idNumberMasked: string | null;
  submittedAt: string | null;
  reviewedAt: string | null;
  reviewNote: string | null;
};

export type VerificationAdminRow = {
  id: string;
  userId: string;
  phone: string;
  idType: IdType;
  fullName: string;
  idNumber: string;
  status: "pending_review" | "verified" | "rejected";
  imagePath: string;
  imageMime: string;
  reviewNote: string | null;
  reviewedAt: string | null;
  createdAt: string;
  updatedAt: string;
};

function ensureUploadDir() {
  const dir = path.resolve(env.UPLOAD_DIR);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function maskIdNumber(raw: string): string {
  const cleaned = raw.replace(/\s+/g, "");
  if (cleaned.length <= 4) return "****";
  return `${"*".repeat(Math.max(0, cleaned.length - 4))}${cleaned.slice(-4)}`;
}

function decodeImageBase64(imageBase64: string): { buffer: Buffer; mime: string } {
  let raw = imageBase64.trim();
  let mime = "image/jpeg";
  const dataUrl = /^data:(image\/(?:jpeg|jpg|png|webp));base64,(.+)$/i.exec(raw);
  if (dataUrl) {
    mime = dataUrl[1].toLowerCase() === "image/jpg" ? "image/jpeg" : dataUrl[1].toLowerCase();
    raw = dataUrl[2];
  }
  const buffer = Buffer.from(raw, "base64");
  if (!buffer.length) {
    throw httpError(400, "Invalid image data", ErrorCodes.VALIDATION_ERROR);
  }
  if (buffer.length > env.ID_IMAGE_MAX_BYTES) {
    throw httpError(
      400,
      `Image too large (max ${Math.floor(env.ID_IMAGE_MAX_BYTES / 1024)} KiB)`,
      ErrorCodes.VALIDATION_ERROR
    );
  }
  // Soft sniff: JPEG / PNG / WEBP magic
  const isJpeg = buffer[0] === 0xff && buffer[1] === 0xd8;
  const isPng = buffer[0] === 0x89 && buffer[1] === 0x50;
  const isWebp =
    buffer.length > 12 &&
    buffer.toString("ascii", 0, 4) === "RIFF" &&
    buffer.toString("ascii", 8, 12) === "WEBP";
  if (!isJpeg && !isPng && !isWebp) {
    throw httpError(400, "Image must be JPEG, PNG, or WEBP", ErrorCodes.VALIDATION_ERROR);
  }
  if (isPng) mime = "image/png";
  else if (isWebp) mime = "image/webp";
  else mime = "image/jpeg";
  return { buffer, mime };
}

function extForMime(mime: string): string {
  if (mime === "image/png") return "png";
  if (mime === "image/webp") return "webp";
  return "jpg";
}

export async function getUserVerificationStatus(userId: string): Promise<VerificationStatus> {
  const { rows } = await pool.query<{ verification_status: VerificationStatus }>(
    "SELECT verification_status FROM users WHERE id = $1",
    [userId]
  );
  return rows[0]?.verification_status ?? "unverified";
}

/** Offer Ride soft-gate: require at least a submitted ID (pending or verified). */
export async function assertCanOfferRide(userId: string): Promise<void> {
  const status = await getUserVerificationStatus(userId);
  if (status === "pending_review" || status === "verified") return;
  throw httpError(
    403,
    status === "rejected"
      ? "ID verification was rejected. Resubmit a clearer gov ID photo to offer a ride."
      : "Submit a government ID for review before offering a ride.",
    ErrorCodes.VERIFICATION_REQUIRED
  );
}

export async function getMyVerification(userId: string): Promise<VerificationPublic> {
  const { rows } = await pool.query<{
    verification_status: VerificationStatus;
    id_type: IdType | null;
    full_name: string | null;
    id_number: string | null;
    review_note: string | null;
    reviewed_at: Date | null;
    created_at: Date | null;
  }>(
    `SELECT u.verification_status,
            v.id_type, v.full_name, v.id_number, v.review_note, v.reviewed_at, v.created_at
     FROM users u
     LEFT JOIN id_verifications v ON v.user_id = u.id
     WHERE u.id = $1`,
    [userId]
  );
  const row = rows[0];
  if (!row) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }
  return {
    status: row.verification_status,
    idType: row.id_type,
    fullName: row.full_name,
    idNumberMasked: row.id_number ? maskIdNumber(row.id_number) : null,
    submittedAt: row.created_at ? row.created_at.toISOString() : null,
    reviewedAt: row.reviewed_at ? row.reviewed_at.toISOString() : null,
    reviewNote: row.review_note,
  };
}

export async function submitVerification(input: {
  userId: string;
  idType: IdType;
  fullName: string;
  idNumber: string;
  imageBase64: string;
}): Promise<VerificationPublic> {
  const fullName = input.fullName.trim();
  const idNumber = input.idNumber.trim().replace(/\s+/g, " ");
  if (fullName.length < 2) {
    throw httpError(400, "Full name is required", ErrorCodes.VALIDATION_ERROR);
  }
  if (idNumber.length < 4) {
    throw httpError(400, "ID number is required", ErrorCodes.VALIDATION_ERROR);
  }

  const current = await getUserVerificationStatus(input.userId);
  if (current === "pending_review") {
    throw httpError(
      409,
      "Verification already pending review",
      ErrorCodes.VERIFICATION_PENDING
    );
  }
  if (current === "verified") {
    throw httpError(409, "Already verified", ErrorCodes.VERIFICATION_ALREADY);
  }

  const { buffer, mime } = decodeImageBase64(input.imageBase64);
  const uploadDir = ensureUploadDir();
  const filename = `${input.userId}-${Date.now()}.${extForMime(mime)}`;
  const absPath = path.join(uploadDir, filename);
  fs.writeFileSync(absPath, buffer);

  // Relative path stored so UPLOAD_DIR can move later.
  const imagePath = filename;

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // Remove previous file if resubmitting after reject.
    const prev = await client.query<{ image_path: string }>(
      "SELECT image_path FROM id_verifications WHERE user_id = $1",
      [input.userId]
    );
    if (prev.rows[0]?.image_path) {
      const oldAbs = path.join(uploadDir, prev.rows[0].image_path);
      try {
        fs.unlinkSync(oldAbs);
      } catch {
        /* ignore missing */
      }
    }

    await client.query(
      `INSERT INTO id_verifications
         (id, user_id, id_type, full_name, id_number, status, image_path, image_mime, review_note, reviewed_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, 'pending_review', $6, $7, NULL, NULL, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         id_type = EXCLUDED.id_type,
         full_name = EXCLUDED.full_name,
         id_number = EXCLUDED.id_number,
         status = 'pending_review',
         image_path = EXCLUDED.image_path,
         image_mime = EXCLUDED.image_mime,
         review_note = NULL,
         reviewed_at = NULL,
         updated_at = NOW()`,
      [randomUUID(), input.userId, input.idType, fullName, idNumber, imagePath, mime]
    );

    await client.query(
      `UPDATE users SET verification_status = 'pending_review', updated_at = NOW() WHERE id = $1`,
      [input.userId]
    );

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    try {
      fs.unlinkSync(absPath);
    } catch {
      /* ignore */
    }
    throw err;
  } finally {
    client.release();
  }

  console.log(
    JSON.stringify({
      level: "info",
      msg: "id_verification_submitted",
      userId: input.userId,
      idType: input.idType,
    })
  );

  return getMyVerification(input.userId);
}

function mapAdminRow(row: {
  id: string;
  user_id: string;
  phone: string;
  id_type: IdType;
  full_name: string;
  id_number: string;
  status: "pending_review" | "verified" | "rejected";
  image_path: string;
  image_mime: string;
  review_note: string | null;
  reviewed_at: Date | null;
  created_at: Date;
  updated_at: Date;
}): VerificationAdminRow {
  return {
    id: row.id,
    userId: row.user_id,
    phone: row.phone,
    idType: row.id_type,
    fullName: row.full_name,
    idNumber: row.id_number,
    status: row.status,
    imagePath: row.image_path,
    imageMime: row.image_mime,
    reviewNote: row.review_note,
    reviewedAt: row.reviewed_at ? row.reviewed_at.toISOString() : null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

export async function listPendingVerifications(limit = 50): Promise<VerificationAdminRow[]> {
  const { rows } = await pool.query<{
    id: string;
    user_id: string;
    phone: string;
    id_type: IdType;
    full_name: string;
    id_number: string;
    status: "pending_review" | "verified" | "rejected";
    image_path: string;
    image_mime: string;
    review_note: string | null;
    reviewed_at: Date | null;
    created_at: Date;
    updated_at: Date;
  }>(
    `SELECT v.id, v.user_id, u.phone, v.id_type, v.full_name, v.id_number, v.status,
            v.image_path, v.image_mime, v.review_note, v.reviewed_at, v.created_at, v.updated_at
     FROM id_verifications v
     JOIN users u ON u.id = v.user_id
     WHERE v.status = 'pending_review'
     ORDER BY v.created_at ASC
     LIMIT $1`,
    [Math.min(Math.max(limit, 1), 200)]
  );
  return rows.map(mapAdminRow);
}

export async function getVerificationImage(
  verificationId: string
): Promise<{ buffer: Buffer; mime: string; filename: string }> {
  const { rows } = await pool.query<{ image_path: string; image_mime: string }>(
    "SELECT image_path, image_mime FROM id_verifications WHERE id = $1",
    [verificationId]
  );
  const row = rows[0];
  if (!row) {
    throw httpError(404, "Verification not found", ErrorCodes.NOT_FOUND);
  }
  const abs = path.join(path.resolve(env.UPLOAD_DIR), row.image_path);
  if (!fs.existsSync(abs)) {
    throw httpError(404, "Image file missing on disk", ErrorCodes.NOT_FOUND);
  }
  return {
    buffer: fs.readFileSync(abs),
    mime: row.image_mime,
    filename: row.image_path,
  };
}

export async function reviewVerification(input: {
  verificationId: string;
  decision: "approve" | "reject";
  reviewNote?: string;
}): Promise<VerificationAdminRow> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { rows } = await client.query<{
      id: string;
      user_id: string;
      phone: string;
      id_type: IdType;
      full_name: string;
      id_number: string;
      status: "pending_review" | "verified" | "rejected";
      image_path: string;
      image_mime: string;
      review_note: string | null;
      reviewed_at: Date | null;
      created_at: Date;
      updated_at: Date;
    }>(
      `SELECT v.id, v.user_id, u.phone, v.id_type, v.full_name, v.id_number, v.status,
              v.image_path, v.image_mime, v.review_note, v.reviewed_at, v.created_at, v.updated_at
       FROM id_verifications v
       JOIN users u ON u.id = v.user_id
       WHERE v.id = $1
       FOR UPDATE OF v`,
      [input.verificationId]
    );
    const row = rows[0];
    if (!row) {
      throw httpError(404, "Verification not found", ErrorCodes.NOT_FOUND);
    }
    if (row.status !== "pending_review") {
      throw httpError(409, "Verification is not pending review", ErrorCodes.VERIFICATION_PENDING);
    }

    const nextStatus = input.decision === "approve" ? "verified" : "rejected";
    const note = input.reviewNote?.trim() || null;

    const updated = await client.query<{
      id: string;
      user_id: string;
      phone: string;
      id_type: IdType;
      full_name: string;
      id_number: string;
      status: "pending_review" | "verified" | "rejected";
      image_path: string;
      image_mime: string;
      review_note: string | null;
      reviewed_at: Date | null;
      created_at: Date;
      updated_at: Date;
    }>(
      `UPDATE id_verifications v
       SET status = $2, review_note = $3, reviewed_at = NOW(), updated_at = NOW()
       FROM users u
       WHERE v.id = $1 AND u.id = v.user_id
       RETURNING v.id, v.user_id, u.phone, v.id_type, v.full_name, v.id_number, v.status,
                 v.image_path, v.image_mime, v.review_note, v.reviewed_at, v.created_at, v.updated_at`,
      [input.verificationId, nextStatus, note]
    );

    await client.query(
      `UPDATE users SET verification_status = $2, updated_at = NOW() WHERE id = $1`,
      [row.user_id, nextStatus]
    );

    await client.query("COMMIT");

    console.log(
      JSON.stringify({
        level: "info",
        msg: "id_verification_reviewed",
        verificationId: input.verificationId,
        userId: row.user_id,
        decision: input.decision,
      })
    );

    return mapAdminRow(updated.rows[0]);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
