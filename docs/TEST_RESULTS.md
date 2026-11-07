# TuDok validation results â€” 4 November 2026

Environment: Flutter 3.47.5 stable, Dart 3.13.4, Windows, Android SDK, JDK supplied by Android Studio.

| Check | Result |
|---|---|
| `flutter analyze` | PASS â€” no issues |
| `flutter test --reporter expanded` | PASS â€” 13 tests |
| Questionnaire coverage | Every reachable branch terminates in the expected journey or referral |
| SQLite persistence | PASS â€” desktop SQLite file closed/reopened; selections and language restored |
| Storage failure | PASS â€” failed write does not mark requirement prepared |
| Bilingual UI | PASS â€” onboarding and in-flow language switching preserve state |
| Small-screen layout | PASS â€” 360px width, 200% text, Filipino home |
| Rendered screenshots | English home, Filipino home, PNP roadmap captured under screenshots/ |
| Android APK | PASS — ARM64 debug build produced successfully |
| Connected Android integration test | NOT RUN â€” no physical device; test emulator could not start due disk capacity |
| Human content and Filipino review | NOT RUN â€” requires independent team review |
| Student usability and presentation rehearsal | NOT RUN â€” requires participants and team |

## Android tooling observations

The required NDK 28.2.13676358 was installed. A temporary Android 35 ATD emulator image was installed for device testing, but startup required more free space than available. The temporary emulator and its image were removed with Android's own tools. A multi-architecture debug build ran out of disk space; an ARM64-only debug build was then attempted. No unrelated user files were deleted.

## Test evidence boundaries

Desktop SQLite tests exercise a real SQLite database using sqflite_common_ffi. They do not substitute for the included Android integration test on an installed app. Screenshots are from Flutter widget rendering, not an Android phone. Manual TalkBack, real external-browser behavior, force-stop/relaunch and airplane-mode checks remain part of connected-device validation.

Taal's exact current requirements and office directions are intentionally withheld. This prototype must not be presented as a completed three-verified-journey release until those details and the independent reviews are completed.

## Final build record

Command: `flutter build apk --debug --target-platform android-arm64`

Artifact: `build/app/outputs/flutter-apk/app-debug.apk`

Size: 82980731 bytes

SHA-256: `86b231841de52393b862f16426908498ff22bd93a3b713f6d94db01f8fe494f6`

This build was not installed on a device in this session.
