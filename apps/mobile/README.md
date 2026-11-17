# Khalashi mobile (Flutter)

Phase 0–1 shell: splash, language (HI/EN), phone OTP stubs, home hub with Find / Offer stubs.

## Screens

1. Splash (brand) → language (first run) → phone → OTP → home
2. Home: **Find a ride** / **Offer a ride** stubs (later phases)
3. Session restore via `shared_preferences`

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

ARB sources live in `lib/l10n/`. Hand-written `AppLocalizations` classes ship for the shell; with Flutter installed you can also run `flutter gen-l10n`.
