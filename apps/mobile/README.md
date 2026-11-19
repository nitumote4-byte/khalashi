# Khalashi mobile (Flutter)

Phase 2: auth shell + Find/Offer rides, search/book with seat preference, my trips/bookings, free cancel until start. Cash-on-trip copy; Hindi + English.

## Screens

1. Splash → language → phone OTP → home
2. Find a ride → results → trip detail → book (preference chips) → success
3. Offer a ride → map pin pickup/drop (optional) → publish → trip manage
4. Find a ride → From/To cities + date only (no pickup/drop filters)
5. My bookings / My trips + booking/trip cancel

## Setup

Requires Flutter 3.24+ (SDK not bundled in this repo).

```bash
cd apps/mobile
flutter pub get
flutter run
```

Default `API_BASE_URL` is the live Railway API
(`https://khalashi-api-production.up.railway.app`, no trailing slash).
Plain `flutter run` on a physical phone hits production HTTPS.

To use a local API instead:

```bash
# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

### Map tiles (Offer Ride pin picker)

Uses **flutter_map** with free **Esri World Street Map** tiles by default
(OpenStreetMap.org as HTTP fallback). No Google / MapTiler key is required.

```bash
flutter run
```

Optional: point at another raster template you already have credentials for
via `--dart-define=MAP_TILE_URL_TEMPLATE=…` (see `lib/config/map_tiles.dart`).
Do not paste a placeholder `key=YOUR_KEY` — those CDNs return error tiles.

## i18n

ARB sources in `lib/l10n/` plus hand-maintained `AppLocalizations` (EN/HI). With Flutter installed you can run `flutter gen-l10n`.
