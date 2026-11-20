import { pool } from "../db/pool";
import { ErrorCodes, httpError } from "../utils/errors";

export type BlockRow = {
  blocker_id: string;
  blocked_id: string;
  created_at: Date;
  blocked_display_name?: string | null;
  blocked_phone?: string | null;
};

function mapBlock(row: BlockRow) {
  return {
    blockedUserId: row.blocked_id,
    displayName: row.blocked_display_name ?? null,
    phone: row.blocked_phone ?? null,
    createdAt: row.created_at.toISOString(),
  };
}

/** True if either user has blocked the other (soft-launch mutual hide). */
export async function isPairBlocked(userA: string, userB: string): Promise<boolean> {
  if (userA === userB) return false;
  const { rows } = await pool.query<{ exists: boolean }>(
    `SELECT EXISTS (
       SELECT 1 FROM user_blocks
       WHERE (blocker_id = $1 AND blocked_id = $2)
          OR (blocker_id = $2 AND blocked_id = $1)
     ) AS exists`,
    [userA, userB]
  );
  return Boolean(rows[0]?.exists);
}

export async function assertNotBlocked(userA: string, userB: string) {
  if (await isPairBlocked(userA, userB)) {
    throw httpError(
      403,
      "You cannot interact with this user",
      ErrorCodes.USER_BLOCKED
    );
  }
}

export async function blockUser(blockerId: string, blockedId: string) {
  if (blockerId === blockedId) {
    throw httpError(400, "Cannot block yourself", ErrorCodes.VALIDATION_ERROR);
  }

  const userCheck = await pool.query<{ id: string }>(
    "SELECT id FROM users WHERE id = $1",
    [blockedId]
  );
  if (!userCheck.rows[0]) {
    throw httpError(404, "User not found", ErrorCodes.NOT_FOUND);
  }

  await pool.query(
    `INSERT INTO user_blocks (blocker_id, blocked_id)
     VALUES ($1, $2)
     ON CONFLICT (blocker_id, blocked_id) DO NOTHING`,
    [blockerId, blockedId]
  );

  console.log(
    JSON.stringify({
      level: "info",
      msg: "user_blocked",
      blockerId,
      blockedId,
    })
  );

  return { ok: true as const, blockedUserId: blockedId };
}

export async function unblockUser(blockerId: string, blockedId: string) {
  const result = await pool.query(
    `DELETE FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2`,
    [blockerId, blockedId]
  );
  if ((result.rowCount ?? 0) === 0) {
    throw httpError(404, "Block not found", ErrorCodes.NOT_FOUND);
  }
  return { ok: true as const, blockedUserId: blockedId };
}

export async function listMyBlocks(blockerId: string) {
  const { rows } = await pool.query<BlockRow>(
    `SELECT b.blocker_id, b.blocked_id, b.created_at,
            u.display_name AS blocked_display_name, u.phone AS blocked_phone
     FROM user_blocks b
     JOIN users u ON u.id = b.blocked_id
     WHERE b.blocker_id = $1
     ORDER BY b.created_at DESC`,
    [blockerId]
  );
  return rows.map(mapBlock);
}
