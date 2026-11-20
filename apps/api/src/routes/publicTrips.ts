import { Router } from "express";
import { getTripById } from "../services/tripService";
import { sendError } from "../utils/respond";

export const publicTripsRouter = Router();

/**
 * Unauthenticated read-only trip status for share links.
 * Omits driver phone / PII beyond cities and schedule.
 */
publicTripsRouter.get("/public/trips/:id", async (req, res) => {
  try {
    const trip = await getTripById(req.params.id);
    const wantsHtml =
      (req.headers.accept ?? "").includes("text/html") ||
      req.query.format === "html";

    const payload = {
      id: trip.id,
      origin: trip.origin,
      destination: trip.destination,
      pickupPoint: trip.pickupPoint,
      dropoffPoint: trip.dropoffPoint,
      departAt: trip.departAt,
      status: trip.status,
      seatsLeft: trip.seatsLeft,
      seatsTotal: trip.seatsTotal,
      vehicle: `${trip.carColor} ${trip.carModel}`.trim(),
      numberPlate: trip.numberPlate,
      driverDisplayName: trip.driverDisplayName,
    };

    if (!wantsHtml) {
      res.json({ ok: true, trip: payload });
      return;
    }

    const depart = new Date(trip.departAt).toLocaleString("en-IN", {
      timeZone: "Asia/Kolkata",
      dateStyle: "medium",
      timeStyle: "short",
    });
    const pickup = trip.pickupPoint
      ? `<p><strong>Pickup:</strong> ${escapeHtml(trip.pickupPoint)}</p>`
      : "";
    const dropoff = trip.dropoffPoint
      ? `<p><strong>Drop-off:</strong> ${escapeHtml(trip.dropoffPoint)}</p>`
      : "";

    res.type("html").send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Khalashi trip · ${escapeHtml(trip.origin)} → ${escapeHtml(trip.destination)}</title>
  <style>
    body{font-family:system-ui,sans-serif;max-width:32rem;margin:2rem auto;padding:0 1rem;color:#1a2b2b;background:#f3e8d8}
    h1{font-size:1.35rem;color:#0f3d3e}
    .card{background:#fff;border-radius:12px;padding:1.25rem;box-shadow:0 1px 3px rgba(0,0,0,.08)}
    .muted{color:#5a6b6b;font-size:.9rem}
  </style>
</head>
<body>
  <p class="muted">Khalashi · shared trip status</p>
  <div class="card">
    <h1>${escapeHtml(trip.origin)} → ${escapeHtml(trip.destination)}</h1>
    <p><strong>When:</strong> ${escapeHtml(depart)} (IST)</p>
    ${pickup}${dropoff}
    <p><strong>Status:</strong> ${escapeHtml(trip.status)}</p>
    <p><strong>Vehicle:</strong> ${escapeHtml(payload.vehicle)} · ${escapeHtml(trip.numberPlate)}</p>
    ${
      trip.driverDisplayName
        ? `<p><strong>Driver:</strong> ${escapeHtml(trip.driverDisplayName)}</p>`
        : ""
    }
    <p class="muted">Read-only summary. Open the Khalashi app for booking details. In danger, call 112.</p>
  </div>
</body>
</html>`);
  } catch (err) {
    sendError(res, err);
  }
});

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
