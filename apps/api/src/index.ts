import cors from "cors";
import express from "express";
import { env } from "./config/env";
import { authRouter } from "./routes/auth";
import { bookingsRouter } from "./routes/bookings";
import { healthRouter } from "./routes/health";
import { tripsRouter } from "./routes/trips";

const app = express();

app.use(cors());
app.use(express.json());

app.use(healthRouter);
app.use(authRouter);
app.use(tripsRouter);
app.use(bookingsRouter);

app.use((_req, res) => {
  res.status(404).json({ ok: false, error: "Not found" });
});

app.listen(env.PORT, () => {
  console.log(
    `Khalashi API listening on :${env.PORT} (otp=${env.OTP_PROVIDER}, env=${env.NODE_ENV})`
  );
});

export default app;
