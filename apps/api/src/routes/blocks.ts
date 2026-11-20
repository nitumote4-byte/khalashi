import { Router } from "express";
import { z } from "zod";
import { requireAuth, type AuthedRequest } from "../middleware/auth";
import { rateLimit } from "../middleware/rateLimit";
import {
  blockUser,
  listMyBlocks,
  unblockUser,
} from "../services/blockService";
import { sendError } from "../utils/respond";

export const blocksRouter = Router();

const blockBody = z.object({
  userId: z.string().uuid(),
});

const blockLimit = rateLimit({
  name: "block-submit",
  limit: 30,
  windowMs: 60 * 60 * 1000,
  keyFn: (req) => (req as AuthedRequest).user?.id ?? "anon",
});

blocksRouter.get("/blocks/mine", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const blocks = await listMyBlocks(user.id);
    res.json({ ok: true, blocks });
  } catch (err) {
    sendError(res, err);
  }
});

blocksRouter.post("/blocks", requireAuth, blockLimit, async (req, res) => {
  try {
    const body = blockBody.parse(req.body);
    const user = (req as AuthedRequest).user;
    const result = await blockUser(user.id, body.userId);
    res.status(201).json(result);
  } catch (err) {
    sendError(res, err);
  }
});

blocksRouter.delete("/blocks/:userId", requireAuth, async (req, res) => {
  try {
    const user = (req as AuthedRequest).user;
    const result = await unblockUser(user.id, req.params.userId);
    res.json(result);
  } catch (err) {
    sendError(res, err);
  }
});
