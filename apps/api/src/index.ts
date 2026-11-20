import cors from "cors";
import express from "express";
import { env } from "./config/env";
import { requestLog } from "./middleware/requestLog";
import { authRouter } from "./routes/auth";
import { bookingsRouter } from "./routes/bookings";
import { healthRouter } from "./routes/health";
import { publicTripsRouter } from "./routes/publicTrips";
import { sosRouter } from "./routes/sos";
import { tripsRouter } from "./routes/trips";
import { verificationRouter } from "./routes/verification";
import { HttpError } from "./utils/errors";
import { sendError } from "./utils/respond";

const app = express();

app.use(cors());
// 3mb covers soft-launch base64 ID photos (max ~2 MiB decoded + JSON overhead).
app.use(express.json({ limit: "3mb" }));
app.use(requestLog);

app.use(healthRouter);
app.use(publicTripsRouter);
app.use(authRouter);
app.use(verificationRouter);
app.use(tripsRouter);
app.use(bookingsRouter);
app.use(sosRouter);

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

// Bind all interfaces so container hosts (Railway / Render / Fly) can reach the process.
app.listen(env.PORT, "0.0.0.0", () => {
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
