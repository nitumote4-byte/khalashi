# Khalashi

BlaBlaCar-style India carpool for **Nitin Mote Tours & Travel**.

**v1 locked:** trip post + seat book · cash on trip · phone OTP · Hindi + English · driver-set fare · seat preference as request · free cancel until trip start · all India cities.

Stack: **Flutter** mobile · **Node (Express)** API · **PostgreSQL**.

This repo includes **Phase 0–2** (auth + trips/book/cancel) and **Phase 3 soft-launch harden** (rate limits, spam guards, Help/safety, ops checklist). Still **no** UPI / KYC / maps / chat / ratings / deep admin.

## Monorepo layout

```
apps/
  api/       Express + TypeScript API
  mobile/    Flutter app (HI/EN)
apps/api/migrations/   Postgres schema
```

## Quick start — API

```bash
cd apps/api
cp .env.example .env
npm install
# Start Postgres, then:
npm run migrate
npm run dev
```

### Auth (mock OTP)

- `POST /auth/otp/request` `{ "phone": "9876543210" }` — returns `debugCode` when `OTP_PROVIDER=mock`
- `POST /auth/otp/verify` `{ "phone": "9876543210", "code": "123456" }` → Bearer token
- Users are upserted into Postgres on verify (required for trips/bookings)
- Soft-launch: OTP / search / book / trip-post are rate-limited (`RATE_LIMIT_*` in `.env`)

### Trips & bookings (Bearer required)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/trips` | Offer a ride (origin, destination, departAt, seatsTotal, fareInr) |
| GET | `/trips/mine` | Driver’s trips |
| GET | `/trips/search?origin=&destination=&date=YYYY-MM-DD` | Search (normalized city text, IST day) |
| GET | `/trips/:id` | Trip detail |
| POST | `/trips/:id/cancel` | Cancel trip before start (cascades bookings) |
| GET | `/trips/:id/bookings` | Driver: bookings on trip |
| POST | `/trips/:id/bookings` | Book seats `{ seats, seatPreference }` |
| GET | `/bookings/mine` | Traveller bookings |
| GET | `/bookings/:id` | Booking detail |
| POST | `/bookings/:id/cancel` | Cancel booking before start (restores seats) |

Errors return `{ ok: false, error, code }` (e.g. `RATE_LIMITED`, `SEATS_FULL`, `SPAM_TRIP_LIMIT`, `OTP_EXPIRED`).

Seat booking uses `SELECT … FOR UPDATE` so concurrent books cannot oversell.

**Not in v1 API:** UPI, KYC, maps, chat, ratings.

## Quick start — Mobile

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Flows: language → phone OTP → home → **Find a ride** / **Offer a ride** → search/book or post → my bookings / my trips → **Profile** (HI/EN toggle, Help & safety, support stubs) → free cancel until departure. Cash-on-trip + safety disclaimers; HI + EN.

Replace stub WhatsApp/phone in `apps/mobile/lib/config/support_contacts.dart` before soft launch.

## Postgres migrations

| File | Purpose |
|------|---------|
| `000_extensions.sql` | `pgcrypto` |
| `001_users.sql` | users |
| `002_trips.sql` | driver trips |
| `003_bookings.sql` | seat bookings |
| `004_otp_challenges.sql` | OTP rows (future) |
| `005_phase2_indexes.sql` | list/search indexes |

## Soft-launch checklist (ops)

Use this before inviting real drivers/travellers (practical soft launch — full Play publish optional).

1. **Postgres**
   - Provision managed Postgres (Neon / RDS / Supabase / etc.).
   - Set `DATABASE_URL` in production `.env`.
   - Run `cd apps/api && npm run migrate` against that database.
2. **Mock vs real OTP**
   - Dev / smoke: `OTP_PROVIDER=mock` (console + `debugCode`; optional `OTP_MOCK_CODE`).
   - Production: set `OTP_PROVIDER=msg91` or `2factor` and fill provider keys in `.env` (see `apps/api/.env.example`).
   - Keep `SESSION_SECRET` long and random in production.
3. **India DLT (SMS)**
   - Register entity + **OTP template** on DLT (TRAI) **before** flipping off mock.
   - Template wording must match MSG91 / 2Factor template IDs.
   - DLT approval is external calendar time — start early.
4. **Rate limits / spam**
   - Confirm `RATE_LIMIT_*`, `MAX_TRIPS_PER_DRIVER_PER_DAY`, `MIN_DEPART_AHEAD_MINUTES` fit your soft-launch traffic.
   - Limits are in-memory per API process (fine for single instance soft launch).
5. **Mobile / support**
   - Point `API_BASE_URL` at the hosted API.
   - Replace support stubs (WhatsApp + phone) in `support_contacts.dart`.
   - Spot-check Help & safety copy (cash, not KYC-verified, 112 for emergencies).
6. **Smoke**
   - `./scripts/smoke-phase2.sh` — book + seat race + cancel.
   - `./scripts/smoke-phase3.sh` — OTP rate limit + spam trip guards + error codes.
7. **Play Store (optional this phase)**
   - Listing copy lives in project Context (`docs/play-store-listing.md`).
   - Need privacy URL, account deletion path, and real support contacts before publish.

## Product docs

Product outline, feature list, wireframes, dispute/safety, and tech build plan live in the project Context (`docs/`), not this git tree.

## Phases

| Phase | Focus | Status |
|------:|-------|--------|
| 0–1 | Foundations + OTP auth shell | Done |
| 2 | Trip post + search/book + free cancel | Done |
| 3 | Soft-launch harden (limits, Help/safety, ops) | This branch |
| Later | Real SMS wiring polish, Play build, crash reporting | Next |
