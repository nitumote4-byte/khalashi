# Khalashi mobile (Flutter)

Phase 2: auth shell + Find/Offer rides, search/book with seat preference, my trips/bookings, free cancel until start. Cash-on-trip copy; Hindi + English.

## Screens

1. Splash → language → phone OTP → home
2. Find a ride → results → trip detail → book (preference chips) → success
3. Offer a ride → publish → trip manage (cancel trip / view bookings)
4. My bookings / My trips + booking/trip cancel

## Setup

Requires Flutter 3.24+ (SDK not bundled in this repo).

```bash
cd apps/mobile
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator → host
```

iOS simulator can use `http://localhost:3000`.

## i18n

ARB sources in `lib/l10n/` plus hand-maintained `AppLocalizations` (EN/HI). With Flutter installed you can run `flutter gen-l10n`.
