# TuDok — Team Handoff & Final Defense Guide

## 1. Current Repository & Verification Status

The Flutter/Dart application, bilingual content, and academic deliverables are updated and verified on desktop:

- **Static analysis**: `flutter analyze` passes with 0 issues.
- **Automated unit & widget tests**: All 17 tests in `test/tudok_test.dart` pass, covering:
  - Dataset integrity, cycle detection, and translation validation (`Catalog.validate()`)
  - Exhaustive questionnaire branching, answer invalidation, and referral routing
  - SQLite (`sqflite`) close/reopen persistence, per-service isolation, and write-failure rollback
  - Language onboarding, segmented & menu switching, and mid-questionnaire locale preservation
  - Bottom navigation tabs, empty-state visibility, unverified Taal routing, reset cancel/confirm, error `SnackBar`, offline URL fallback dialog, and questionnaire `BackButton` history
  - Small-screen (360px) layout at 200% text scale and rendered screenshot generation (`docs/screenshots/`)
- **Content & localization reviews**: Accuracy review (`Hans`) and Filipino translation review (`Lordy`) for PNP and NBI standard first-time procedures are recorded in `docs/SOURCE_REGISTER.md`. Taal remains an intentional verification-pending referral because the only available online charter dates from 2019.

---

## 2. Remaining Hardware & Human Tasks by Owner

### Luke (Team Leader & Technical Lead)
1. **Physical Android Device Validation**:
   - Connect an Android phone with USB debugging enabled and confirm detection via `flutter devices`.
   - Run the on-device integration test:
     ```powershell
     flutter test integration_test/app_test.dart -d <device-id>
     ```
   - Build and install the ARM64 debug APK:
     ```powershell
     flutter build apk --debug --target-platform android-arm64
     flutter install -d <device-id>
     ```
   - Manually verify airplane-mode offline guidance, external browser launch (`url_launcher`), Android system Back navigation, and force-stop/relaunch SQLite persistence.
2. **Live Demonstration**:
   - Rehearse the 6-step live demo script in `docs/VALIDATION.md` on the demonstration phone.

### Lordy (UI/UX & Localization Lead)
1. **On-Device Accessibility & Layout Check**:
   - Enable Android TalkBack and 200% system font size on the test phone and verify all three tabs (`Home`, `My Checklists`, `About & Settings`) and `NavigatorScreen` / `RoadmapScreen` / `ChecklistScreen` have no clipped text or broken focus order.
2. **Presentation & Visuals**:
   - Review `docs/PRESENTATION.html` (Slides 3, 4, and 7) and optionally replace `docs/screenshots/*.png` with real Android device captures if preferred.

### Hans (QA, Content & Research Lead)
1. **Formative Usability Study (3–5 Student Participants)**:
   - Run the 4 usability tasks in `docs/VALIDATION.md` (`Find Correct Service`, `Review Official Source Link`, `Check 2 Items & Restart App`, `Switch Language to Filipino`) with 3–5 consenting classmates using anonymous codes (`P1`–`P5`).
   - Record pass/fail results and observations in `docs/VALIDATION.md` and `docs/TEST_RESULTS.md`.
2. **Defense Preparation**:
   - Finalize talking points for problem background, RA 11032 / Citizen's Charter methodology, Taal referral rationale, and usability results (Slide 8).

---

## 3. Final Submission & Defense Checklist (BatStateU IT 331)

- [x] Source code clean (`flutter analyze` = 0 issues, 17/17 automated tests passing)
- [x] `README.md`, `pubspec.yaml`, `docs/PROJECT_DOCUMENTATION.md`, `docs/SOURCE_REGISTER.md`, and `docs/PRESENTATION.html` updated with team roster and review status
- [ ] Connected Android integration test executed (`flutter test integration_test/app_test.dart -d <device-id>`)
- [ ] ARM64 APK installed and verified offline on physical Android device
- [ ] 3–5 student usability sessions recorded in `docs/VALIDATION.md` and `docs/TEST_RESULTS.md`
- [ ] Team presentation (`docs/PRESENTATION.html`) rehearsed twice before class defense
