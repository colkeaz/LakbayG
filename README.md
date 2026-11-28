# LakbayG: Citizen-Centered Government Document Assistant

Android-first Flutter student prototype: need-first service navigation, source-linked interactive roadmaps, local appointment tracking, and persistent preparation checklists in English and Filipino.

## Run

Toolchain used: Flutter 3.47.5 / Dart 3.13.4. Android SDK and JDK compatible with the installed Flutter are required. Dependencies are pinned in `pubspec.lock`.

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d <android-device-id>
flutter build apk --release
```

No network is required to read bundled guidance, track steps, or save checklists and appointment details. Official links open in an external browser. No accounts, credentials, document uploads, analytics, or server are implemented. Clearing app data or uninstalling removes local progress.

## Implementation

- `lib/domain.dart`: typed bilingual models, content validation, repository, deterministic questionnaire.
- `lib/storage.dart`: SQLite v2 repositories (`checklist`, `settings`, `step_progress`, `custom_items`, `tracker`) and a serialized `AppController`. UI state changes only after a successful write.
- `lib/theme.dart` and `lib/pip.dart` provide the cream and forest-green Material 3 theme and Pip’s offline illustrations for finding a service, following steps, and completing a packing checklist.
- `lib/screens/home_screen.dart`, `lib/screens/map_screen.dart`, `lib/screens/guide_screen.dart`, `lib/screens/navigator_screen.dart`: onboarding, keyword/category home, interactive OpenStreetMap office map & offline directory, interactive step/tracker/checklist guide, and comparison-enabled questionnaire.
- `lib/location_service.dart`: optional GPS helper (`geolocator`), distance calculation, and Google Maps turn-by-turn directions URI builder.
- `assets/catalog.json`: English/Filipino journeys (8 services, 9 sources, 9 questions, 8 referrals, 21 Batangas & Laguna offices). Stable requirement IDs preserve progress across updates.
- `lib/l10n/`: ARB UI translations and generated localization files.
- `test/`: branching, content integrity, SQLite v1→v2 migration & persistence, failures, localization, 360px @ 200% font-scale layout, and rendered screenshots.
- `integration_test/`: Android SQLite smoke test for execution on a connected device.

`Catalog.validate()` rejects duplicate identifiers, broken references, invalid categories, empty translations, cycles, unreachable outcomes, and unverified procedures with steps or requirements.

## Content release status

PNP, NBI, PSA Birth Certificate, DFA Passport, PhilSys National ID, SSS, and PhilHealth first-time procedures were checked against official online sources. Independent human accuracy and Filipino-language review remain pending. Taal's available charter is older (2019); the application intentionally marks it as `Official confirmation needed` and provides a referral without unconfirmed steps or requirements.

See `docs/SOURCE_REGISTER.md`, `docs/PROJECT_DOCUMENTATION.md`, `docs/VALIDATION.md`, and `docs/PRESENTATION.html`.

## Acknowledgments

Flutter/Dart and Flutter localization tooling (Google), sqflite and sqflite_common_ffi (tekartik), path and intl (Dart ecosystem), url_launcher (Flutter team), flutter_map, latlong2, geolocator, and OpenStreetMap contributors. Exact versions and transitive packages are in `pubspec.lock`; package licenses are accessible through Flutter's package ecosystem. Government references are credited in the app and source register. No other group's application was reused.
