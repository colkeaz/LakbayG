# LakbayG: An assistant to hlep process your Goverment documents

Android-first Flutter student prototype: need-first service navigation, source-linked roadmaps, and persistent preparation checklists in English and Filipino.

## Run

Toolchain used: Flutter 3.47.5 / Dart 3.13.4. Android SDK and JDK compatible with the installed Flutter are required. Dependencies are pinned in `pubspec.lock`.

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d <android-device-id>
flutter build apk --debug --target-platform android-arm64
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. This is an ARM64 debug-signed classroom demonstration build for modern Android phones, not a store release. For a distribution build, configure your own signing key before `flutter build apk --release`.

No network is required to read bundled guidance or save checklists. Official links open in an external browser. No accounts, credentials, document uploads, analytics, or server are implemented. Clearing app data or uninstalling removes local progress.

## Implementation

- `lib/domain.dart`: typed bilingual models, content validation, repository, deterministic questionnaire.
- `lib/storage.dart`: SQLite repositories and a ChangeNotifier controller. UI state changes only after a successful write.
- `lib/main.dart`: onboarding, three main destinations, questionnaire, roadmaps and checklists.
- `assets/catalog.json`: English/Filipino journeys, sources and rules. Stable requirement IDs preserve progress across translations. Give a requirement a new ID when its meaning changes.
- `lib/l10n/`: ARB UI translations and generated localization files.
- `test/`: branching, content integrity, SQLite persistence, failures, localization, small-screen layout and rendered screenshots.
- `integration_test/`: Android SQLite smoke test for execution on a connected device.

`Catalog.validate()` rejects duplicate identifiers, broken references, empty translations, cycles, unreachable outcomes and unpublished procedures marked as confirmed. Adding a journey means adding bilingual content, source references and a reachable questionnaire outcome. No public API exists.

## Content release status

PNP and NBI standard first-time appearance procedures were checked against official online sources on 4 November 2026. Independent human accuracy and Filipino-language review remain pending. Taal's available charter is older; the application intentionally provides a referral, without unconfirmed requirements or office directions. **The promised three fully verified journeys are not release-complete until Taal is confirmed.**

See `docs/SOURCE_REGISTER.md`, `docs/PROJECT_DOCUMENTATION.md`, `docs/VALIDATION.md`, and `docs/PRESENTATION.html`. The original project documents are preserved unchanged.

## Acknowledgments

Flutter/Dart and Flutter localization tooling (Google), sqflite and sqflite_common_ffi (tekartik), path and intl (Dart ecosystem), url_launcher (Flutter team). Exact versions and transitive packages are in `pubspec.lock`; package licenses are accessible through Flutter's package ecosystem. Government references are credited in the app and source register. No other group's application was reused.
