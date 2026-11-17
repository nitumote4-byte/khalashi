import cors from "cors";
import express from "express";
import { env } from "./config/env";
import { requestLog } from "./middleware/requestLog";
import { authRouter } from "./routes/auth";
import { bookingsRouter } from "./routes/bookings";
import { healthRouter } from "./routes/health";
import { tripsRouter } from "./routes/trips";
import { HttpError } from "./utils/errors";
import { sendError } from "./utils/respond";

const app = express();

app.use(cors());
app.use(express.json({ limit: "64kb" }));
app.use(requestLog);

app.use(healthRouter);
app.use(authRouter);
app.use(tripsRouter);
app.use(bookingsRouter);

app.use((_req, res) => {
  res.status(404).json({ ok: false, error: "Not found", code: "NOT_FOUND" });
});

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  // Express error middleware (rateLimit next(err), etc.)
  if (err instanceof HttpError || (err as { status?: number }).status) {
    sendError(res, err);
    return;
  }
  sendError(res, err);
});

app.listen(env.PORT, () => {
  console.log(
    JSON.stringify({
      level: "info",
      msg: "api_listen",
      port: env.PORT,
      otp: env.OTP_PROVIDER,
      env: env.NODE_ENV,
    })
  );
});

export default app;
