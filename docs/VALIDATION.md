# Validation and classroom demonstration

## Automated checks

Run `flutter analyze` and `flutter test --reporter expanded`. Tests exercise every questionnaire path, edited-answer invalidation, uncertain referrals, malformed content, database close/reopen persistence, per-service isolation, save failure, language onboarding and switching, reset confirmation, and a 360px screen with 200% text. The screenshot test regenerates `docs/screenshots/`.

## Connected Android checks

Connect an Android phone with USB debugging enabled, or start a configured Android emulator. Run:

```powershell
flutter devices
flutter test integration_test/app_test.dart -d <device-id>
flutter run -d <device-id>
```

Manually exercise all supported journeys in airplane mode; change languages mid-questionnaire; use Android Back; save and uncheck items; force-stop and relaunch; confirm progress; cancel then confirm reset. Test TalkBack labels, large system text, browser opening, and unavailable-network external links. Do not delete application data between persistence checks.

## Formative usability study — not yet conducted

Recruit approximately five consenting students. Use anonymous participant codes; collect no government document images or identity details. Ask each to identify a specified service, find its official reference, prepare a checklist, close and reopen the app, and switch language. Record success, confusion and suggested improvements. Do not claim measured reduction in government-office delays.

| Participant | Correct service | Found reference | Checklist resumed | Language task | Confusion / feedback |
|---|---|---|---|---|---|
| P1 | Pending | Pending | Pending | Pending | |
| P2 | Pending | Pending | Pending | Pending | |
| P3 | Pending | Pending | Pending | Pending | |
| P4 | Pending | Pending | Pending | Pending | |
| P5 | Pending | Pending | Pending | Pending | |

## Live demonstration script

1. Introduce the group, problem and target users.
2. Select PNP through the guided questionnaire; show source and last check date.
3. Save two checklist items and restart the application to demonstrate persistence.
4. Switch to Filipino and demonstrate an uncertain clearance referral.
5. Show the distinction between local birth copy and PSA certificate, including the Taal verification limitation.
6. Explain the code structure, source review process, challenges and each member's actual contribution.

## Execution results

See TEST_RESULTS.md for results from this implementation session. Human reviews, usability sessions and rehearsal must be recorded by the team when actually performed.
