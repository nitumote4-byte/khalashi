# Khalashi

BlaBlaCar-style India carpool for **Nitin Mote Tours & Travel**.

**v1 locked:** trip post + seat book · cash on trip · phone OTP · Hindi + English · driver-set fare · seat preference as request · free cancel until trip start · all India cities.

Stack: **Flutter** mobile · **Node (Express)** API · **PostgreSQL**.

This repo includes **Phase 0–2** (auth + trips/book/cancel), **Phase 3 soft-launch harden**, and **soft-launch gov ID verification** (ID photo + selfie + manual review — no DigiLocker/UIDAI / paid face-match). Still **no** UPI / paid KYC APIs / chat / ratings / deep admin UI.

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

### Auth (OTP)

- `POST /auth/otp/request` `{ "phone": "9876543210" }` — returns `debugCode` when `OTP_PROVIDER=mock`
- `POST /auth/otp/verify` `{ "phone": "9876543210", "code": "123456" }` → Bearer token
- Default provider is **mock** (local/dev). Production: `OTP_PROVIDER=msg91` after India DLT template approval.
- MSG91 **sends** SMS; **verify** is always against the server challenge hash (same as mock).
- Users are upserted into Postgres on verify (required for trips/bookings)
- Soft-launch: OTP / search / book / trip-post are rate-limited (`RATE_LIMIT_*` in `.env`)

#### MSG91 secrets (never commit real keys)

Set these only in local `.env` (gitignored), **Cursor Dashboard → Cloud Agents → Environments → Secrets**, or **GitHub → Settings → Secrets and variables → Actions** (same names):

| Secret name | Purpose |
|-------------|---------|
| `OTP_PROVIDER` | `mock` (default) or `msg91` |
| `MSG91_AUTH_KEY` | MSG91 auth key |
| `MSG91_TEMPLATE_ID` | MSG91 OTP template id (must match DLT copy) |
| `MSG91_SENDER_ID` | DLT-approved sender header |
| `SESSION_SECRET` | Session hashing / tokens |
| `DATABASE_URL` | Postgres |

India **DLT (TRAI):** register entity + OTP SMS template first; MSG91 template wording/sender must match. Missing MSG91 vars with `OTP_PROVIDER=msg91` → `503` / `OTP_PROVIDER_MISCONFIGURED`. Do not paste keys into chat.

### Trips & bookings (Bearer required)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/trips` | Offer a ride (origin, destination, optional map pickup/drop labels + lat/lng, departAt, seatsTotal, fareInr, vehicle) |
| GET | `/trips/mine` | Driver’s trips |
| GET | `/trips/search?origin=&destination=&date=YYYY-MM-DD` | Search by From/To cities + IST day |
| GET | `/trips/:id` | Trip detail |
| POST | `/trips/:id/cancel` | Cancel trip before start (cascades bookings) |
| GET | `/trips/:id/bookings` | Driver: bookings on trip |
| POST | `/trips/:id/bookings` | Book seats `{ seats, seatPreference }` |
| GET | `/bookings/mine` | Traveller bookings |
| GET | `/bookings/:id` | Booking detail |
| POST | `/bookings/:id/cancel` | Cancel booking before start (restores seats) |

Errors return `{ ok: false, error, code }` (e.g. `RATE_LIMITED`, `SEATS_FULL`, `SPAM_TRIP_LIMIT`, `OTP_EXPIRED`).

Seat booking uses `SELECT … FOR UPDATE` so concurrent books cannot oversell.

### Soft-launch ID verification (ID photo + selfie + manual review)

No DigiLocker / UIDAI / paid face-match API. User submits gov ID front photo + front-camera selfie + name/number → `pending_review`. Ops open ID + selfie side-by-side and approve/reject via admin secret.

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/verification/me` | Bearer | Current status + masked fields |
| POST | `/verification/submit` | Bearer | `{ idType, fullName, idNumber, imageBase64, selfieBase64 }` → pending |
| GET | `/admin/verifications/pending` | `X-Admin-Secret` | List pending (includes `imageUrl` + `selfieUrl`) |
| GET | `/admin/verifications/:id/image` | admin | Gov ID JPEG/PNG/WEBP bytes |
| GET | `/admin/verifications/:id/selfie` | admin | Selfie JPEG/PNG/WEBP bytes |
| POST | `/admin/verifications/:id/approve` | admin | Mark verified |
| POST | `/admin/verifications/:id/reject` | admin | `{ reviewNote? }` → rejected |

`idType`: `aadhaar` \| `dl` \| `voter`. ID + selfie stored under `UPLOAD_DIR` (default `/app/uploads` in Docker). Mount a Railway volume there so photos survive redeploys.

**Offer Ride gate:** `POST /trips` requires `pending_review` or `verified`. Find Ride / book stays open without ID. Client shows the same gate with a prompt to verify.

Admin curl example (open ID + selfie in two tabs for manual match):

```bash
export API=https://khalashi-api-production.up.railway.app
export ADMIN_SECRET=…   # set on Railway service
curl -s -H "X-Admin-Secret: $ADMIN_SECRET" "$API/admin/verifications/pending"
# Side-by-side manual match — no paid face API:
curl -s -H "X-Admin-Secret: $ADMIN_SECRET" -o id.jpg "$API/admin/verifications/<id>/image"
curl -s -H "X-Admin-Secret: $ADMIN_SECRET" -o selfie.jpg "$API/admin/verifications/<id>/selfie"
curl -s -X POST -H "X-Admin-Secret: $ADMIN_SECRET" -H "Content-Type: application/json" \
  -d '{}' "$API/admin/verifications/<id>/approve"
```

**Not in v1 API:** UPI, DigiLocker, paid face-match, chat, ratings, SOS. Offer Ride uses an in-app map pin
picker (flutter_map + free Esri/OSM tiles) for optional pickup/drop meeting points.

## Quick start — Mobile

```bash
cd apps/mobile
flutter pub get
flutter run
```

Defaults to the live Railway API. For a local API:
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android emulator).

Flows: language → phone OTP → home → **Find a ride** / **Offer a ride** (ID submit required) → search/book or post → my bookings / my trips → **Profile** (verification badge, HI/EN, Help & safety) → free cancel until departure. Soft-launch ID: rear-camera ID photo + optional ML Kit OCR autofill + front-camera selfie + manual review. Cash-on-trip + safety disclaimers; HI + EN.

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
| `006_trip_vehicle.sql` | car model / plate / color |
| `007_trip_meeting_points.sql` | pickup/drop address labels |
| `008_trip_meeting_coords.sql` | pickup/drop lat/lng pins |
| `009_trip_route_stats.sql` | route distance / duration |
| `010_id_verification.sql` | users.verification_status + id_verifications |
| `011_id_verification_selfie.sql` | id_verifications.selfie_path + selfie_mime |

## Deploy (hosted API + Postgres)

Deploy configs live in-repo (no secrets committed):

| File | Host |
|------|------|
| `apps/api/Dockerfile` + `docker-entrypoint.sh` | Any container host — runs `migrate` then `start` |
| `render.yaml` | Render Blueprint (API + Postgres) |
| `apps/api/railway.toml` | Railway (Dockerfile build; attach Postgres) |
| `apps/api/fly.toml` | Fly.io (attach Fly Postgres) |

**Live URL:** `https://khalashi-api-production.up.railway.app`

### Production env checklist (host secrets — never commit)

| Name | Required | Soft-launch value |
|------|----------|-------------------|
| `DATABASE_URL` | yes | From host Postgres plugin / Blueprint |
| `SESSION_SECRET` | yes | Long random (Render `generateValue` / `openssl rand -hex 32`) |
| `OTP_PROVIDER` | yes | **`mock`** until India DLT + MSG91 |
| `OTP_MOCK_CODE` | optional | `123456` for QA |
| `NODE_ENV` | yes | `production` |
| `PORT` | usually set by host | Host default is fine |
| `MSG91_*` | no for soft launch | Leave unset while `OTP_PROVIDER=mock` |
| `ADMIN_SECRET` | yes for ID review | Shared secret for `/admin/verifications/*` |
| `UPLOAD_DIR` | optional | Default `/app/uploads` in Docker — mount a volume for persistence |
| `ID_IMAGE_MAX_BYTES` | optional | Default `2097152` (2 MiB) |

Migrations run automatically on container start (`docker-entrypoint.sh` → `node dist/db/migrate.js`). After merging selfie verification, **redeploy the API** so migration `011_id_verification_selfie.sql` applies (and `010` if not yet applied) and set `ADMIN_SECRET`.

### Point Flutter at the hosted API

The mobile app defaults to `https://khalashi-api-production.up.railway.app`
(no trailing slash). Plain `flutter run` is enough for a physical device.

```bash
cd apps/mobile
flutter run
# optional local override:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Unblock agent deploy (Nitin)

Cloud Agents have **no** Railway / Render / Fly login today. Pick **one** and add a Cursor Environment secret, then re-run deploy:

1. **Railway (recommended):** [railway.app](https://railway.app) → Account → Tokens → create token → Cursor Dashboard → Cloud Agents → Environments → Secrets → `RAILWAY_TOKEN`
2. **Render:** [dashboard.render.com](https://dashboard.render.com) → Account Settings → API Keys → `RENDER_API_KEY`
3. **Fly.io:** `fly auth token` after `fly auth login` → secret `FLY_API_TOKEN`

Or deploy from the dashboard: Render → New → Blueprint → this repo; or Railway → New Project → Deploy from GitHub → root `apps/api` + Postgres plugin. Keep `OTP_PROVIDER=mock`.

## Soft-launch checklist (ops)

Use this before inviting real drivers/travellers (practical soft launch — full Play publish optional).

1. **Postgres**
   - Provision managed Postgres via host plugin (Render/Railway/Fly) or Neon / RDS / Supabase.
   - Set `DATABASE_URL` in host secrets (not git).
   - Confirm deploy entrypoint ran migrations (or `npm run migrate:prod` against that DB).
2. **Mock vs real OTP**
   - Soft launch / smoke: `OTP_PROVIDER=mock` (default; console + `debugCode`; optional `OTP_MOCK_CODE`).
   - Production SMS: `OTP_PROVIDER=msg91` plus `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_SENDER_ID` via host secrets (never commit). See `apps/api/.env.example`.
   - Smoke misconfig: `OTP_PROVIDER=msg91` with empty MSG91_* → clear `OTP_PROVIDER_MISCONFIGURED` (`apps/api/scripts/smoke-otp.sh`).
   - Keep `SESSION_SECRET` long and random in production.
3. **India DLT (SMS)**
   - Register entity + **OTP template** on DLT (TRAI) **before** flipping off mock.
   - Template wording + sender must match MSG91 OTP template id / `MSG91_SENDER_ID`.
   - DLT approval is external calendar time — start early.
4. **Rate limits / spam**
   - Confirm `RATE_LIMIT_*`, `MAX_TRIPS_PER_DRIVER_PER_DAY`, `MIN_DEPART_AHEAD_MINUTES` fit your soft-launch traffic.
   - Limits are in-memory per API process (fine for single instance soft launch).
5. **Mobile / support**
   - Point `API_BASE_URL` at the hosted API (see Deploy above).
   - Replace support stubs (WhatsApp + phone) in `support_contacts.dart`.
   - Spot-check Help & safety copy (cash, not KYC-verified, 112 for emergencies).
6. **Smoke**
   - `curl -sS https://YOUR-HOSTED-API/health` → `ok: true`, `otpProvider: "mock"`.
   - `./scripts/smoke-otp.sh` — mock OTP request/verify + msg91-without-keys misconfig.
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
| 3 | Soft-launch harden (limits, Help/safety, ops) | Done |
| — | Real MSG91 OTP send (verify via stored challenge) | This branch |
| Later | Play build, crash reporting, 2Factor option | Next |
