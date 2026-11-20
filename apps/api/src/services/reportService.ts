import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";

export type ReportReason =
  | "harassment"
  | "unsafe_driving"
  | "no_show"
  | "spam"
  | "fraud"
  | "other";

export type ReportRow = {
  id: string;
  reporter_id: string;
  reported_user_id: string;
  reason: ReportReason;
  details: string | null;
  trip_id: string | null;
  booking_id: string | null;
  status: "open" | "reviewed" | "dismissed";
  created_at: Date;
  reporter_phone?: string | null;
  reported_phone?: string | null;
  reporter_display_name?: string | null;
  reported_display_name?: string | null;
};

function mapReport(row: ReportRow) {
  return {
    id: row.id,
    reporterId: row.reporter_id,
    reportedUserId: row.reported_user_id,
    reason: row.reason,
    details: row.details,
    tripId: row.trip_id,
    bookingId: row.booking_id,
    status: row.status,
    createdAt: row.created_at.toISOString(),
    reporterPhone: row.reporter_phone ?? null,
    reportedPhone: row.reported_phone ?? null,
    reporterDisplayName: row.reporter_display_name ?? null,
    reportedDisplayName: row.reported_display_name ?? null,
  };
}

const REASONS: ReportReason[] = [
  "harassment",
  "unsafe_driving",
  "no_show",
  "spam",
  "fraud",
  "other",
];

export async function createReport(input: {
  reporterId: string;
  reportedUserId: string;
  reason: string;
  details?: string | null;
  tripId?: string | null;
  bookingId?: string | null;
}) {
  if (input.reporterId === input.reportedUserId) {
    throw httpError(400, "Cannot report yourself", ErrorCodes.VALIDATION_ERROR);
  }
  if (!REASONS.includes(input.reason as ReportReason)) {
    throw httpError(400, "Invalid report reason", ErrorCodes.VALIDATION_ERROR);
  }

  let details: string | null = null;
  if (input.details != null) {
    const trimmed = input.details.trim();
    if (trimmed.length > 1000) {
      throw httpError(400, "Details must be at most 1000 characters", ErrorCodes.VALIDATION_ERROR);
    }
    details = trimmed.length === 0 ? null : trimmed;
  }

  const userCheck = await pool.query<{ id: string }>(
    "SELECT id FROM users WHERE id = $1",
    [input.reportedUserId]
  );
  if (!userCheck.rows[0]) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }

  // Soft spam guard: max 10 reports / reporter / day
  const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const countResult = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM user_reports
     WHERE reporter_id = $1 AND created_at >= $2`,
    [input.reporterId, dayAgo]
  );
  if (Number(countResult.rows[0]?.count ?? 0) >= 10) {
    throw httpError(
      429,
      "Report limit reached for today. Try again tomorrow.",
      ErrorCodes.RATE_LIMITED
    );
  }

  const { rows } = await pool.query<ReportRow>(
    `INSERT INTO user_reports (
       reporter_id, reported_user_id, reason, details, trip_id, booking_id
     ) VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      input.reporterId,
      input.reportedUserId,
      input.reason,
      details,
      input.tripId ?? null,
      input.bookingId ?? null,
    ]
  );

  console.log(
    JSON.stringify({
      level: "info",
      msg: "user_report_created",
      reportId: rows[0].id,
      reporterId: input.reporterId,
      reportedUserId: input.reportedUserId,
      reason: input.reason,
    })
  );

  return mapReport(rows[0]);
}

export async function listReports(input: {
  status?: string;
  limit?: number;
}) {
  const limit = Math.min(Math.max(input.limit ?? 50, 1), 200);
  const status = input.status?.trim() || "open";
  const statuses = ["open", "reviewed", "dismissed", "all"];
  if (!statuses.includes(status)) {
    throw httpError(400, "Invalid status filter", ErrorCodes.VALIDATION_ERROR);
  }

  const params: unknown[] = [limit];
  let where = "";
  if (status !== "all") {
    where = "WHERE r.status = $2";
    params.push(status);
  }

  const { rows } = await pool.query<ReportRow>(
    `SELECT r.*,
            reporter.phone AS reporter_phone,
            reporter.display_name AS reporter_display_name,
            reported.phone AS reported_phone,
            reported.display_name AS reported_display_name
     FROM user_reports r
     JOIN users reporter ON reporter.id = r.reporter_id
     JOIN users reported ON reported.id = r.reported_user_id
     ${where}
     ORDER BY r.created_at DESC
     LIMIT $1`,
    params
  );
  return rows.map(mapReport);
}
