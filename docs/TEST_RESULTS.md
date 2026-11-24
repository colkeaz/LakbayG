# LakbayG (Lakbay Gobyerno) validation results — 24 November 2026

Environment: Flutter 3.47.5 stable, Dart 3.13.4, Windows, Android SDK, JDK supplied by Android Studio.

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues |
| `flutter test --reporter expanded` | PASS — 17 tests |
| Questionnaire coverage | Every reachable branch terminates in the expected journey or referral; BackButton history verified |
| SQLite persistence | PASS — desktop SQLite file closed/reopened; selections and language restored |
| Storage failure | PASS — failed write leaves prepared state unchanged and displays error SnackBar |
| Bilingual UI | PASS — onboarding, segmented/menu switching, and in-flow language switching preserve state |
| Navigation & fallbacks | PASS — bottom tabs, empty-state visibility, unverified Taal routing, reset cancel/confirm, and offline link dialog verified |
| Small-screen layout | PASS — 360px width, 200% text, Filipino home |
| Rendered screenshots | English home, Filipino home, PNP roadmap captured under `docs/screenshots/` |
| Android APK | PASS — ARM64 debug build produced successfully (4 November 2026 baseline) |
| Team content & Filipino review | PASS — accuracy (Hans) and Filipino wording (Lordy) recorded in `docs/SOURCE_REGISTER.md` |
| Connected Android integration test | PENDING DEVICE — scheduled in `docs/HANDOFF.md` |
| Student usability and presentation rehearsal | PENDING PARTICIPANTS — scheduled in `docs/HANDOFF.md` |

## Android tooling observations

The required NDK 28.2.13676358 was installed. A temporary Android 35 ATD emulator image was installed for device testing, but startup required more free space than available. The temporary emulator and its image were removed with Android's own tools. A multi-architecture debug build ran out of disk space; an ARM64-only debug build was then attempted. No unrelated user files were deleted.

## Test evidence boundaries

Desktop SQLite tests exercise a real SQLite database using `sqflite_common_ffi`. They do not substitute for the included Android integration test (`integration_test/app_test.dart`) on an installed app. Screenshots are from Flutter widget rendering, not an Android phone. Manual TalkBack, real external-browser behavior, force-stop/relaunch and airplane-mode checks remain part of connected-device validation (see `docs/HANDOFF.md`).

Taal's exact current requirements and office directions are intentionally withheld as a verification-pending referral until a current municipal charter is published.

## Final build record

Command: `flutter build apk --debug --target-platform android-arm64`

Artifact: `build/app/outputs/flutter-apk/app-debug.apk`

Size: 82980731 bytes

SHA-256: `86b231841de52393b862f16426908498ff22bd93a3b713f6d94db01f8fe494f6`

This build was not installed on a device in this session.
