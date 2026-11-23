# E-LIKAS mobile (elikas_mobile)

The Ligao City evacuation app for Android: a resident app (no sign-in,
works offline) and Staff Mode for barangay officials and CSWD. Package
name `com.example.elikas_mobile`. Current version **0.4.0+9**.

## Run and test

```sh
flutter pub get
flutter gen-l10n          # pub get removes the generated l10n files
dart run build_runner build --delete-conflicting-outputs   # *.g.dart
flutter analyze
flutter test
flutter test test_screenshots --update-goldens   # PNGs in test_screenshots/goldens/
```

Release builds go through `tool/release.ps1` (see RELEASING.md). The
next release after 0.4.0+9 needs build 10 or higher.

## Backend

The API contract the app follows is in `docs/backend/`; the newest files
win: `apps-api-2026-11-23.md` (accounts, device headers, Report a
problem, system notices, push), `apps-api-2026-11-22.md` (locks, families
to evacuate, facility requests, relief, alerts, volcanic events) and
`push-notifications.md`.

## Push notifications (Firebase)

- Firebase project `e-likas-40a9e`. Put the project's
  `google-services.json` in `android/app/`. It is in `.gitignore`: never
  commit it.
- The app listens to `elikas-city` and to the resident's barangay topic
  exactly as `GET /public/gis/barangay-status` names it (`push_topic`);
  it never builds topic names. Settings > tap Version seven times shows
  "Receive test notifications" (`elikas-test`).
- Channel `elikas_alerts` ("Emergency alerts and evacuation orders",
  high importance) is created at start and is FCM's default channel.

## Content to review before release

- `assets/data/preparedness.json`: the go-bag and preparedness lists and
  "what to do" steps. Each list names the agency whose public guidance
  it follows (NDRRMC, DSWD, PHIVOLCS); the team checks the wording
  against that agency's current materials and edits this file (no code
  change). The app shows "for team review" until then.
- `lib/l10n/app_bcl.arb`: every Bikol string written for 0.4.0 carries
  `"description": "NEEDS NATIVE BIKOL REVIEW"`. Most staff screens are
  still in English in Bikol.

## What stays on the phone

- The family emergency plan and the checklist ticks: SharedPreferences
  only, never sent.
- The device id sent as `X-Device-Id` is a random UUID made at install;
  with it go the app version and the sync counts (counts only).

## Hand tests

`docs/phone-test-checklist.md` lists what to try on a real phone for
0.4.0, part by part.
