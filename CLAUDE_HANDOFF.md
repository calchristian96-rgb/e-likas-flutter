# E-LIKAS Flutter — Claude Handoff

This is an existing Flutter project. Do not recreate it or replace its architecture.

Current verified state:
- Flutter 3.44.8 / Dart 3.12.2
- Android emulator build works
- `flutter analyze` reports **No issues found**
- Riverpod, Dio, Isar Plus, Freezed, JSON serialization, routing, and Android core-library desugaring are configured
- Resident-facing, no login, read-only, offline-first

Before changing code:
1. Inspect the complete project structure and current implementations.
2. Preserve Clean Architecture and existing API contracts.
3. Do not edit generated `*.g.dart` or `*.freezed.dart` files manually.
4. Do not remove Android desugaring configuration.
5. Work one module at a time and run formatting/analyzer checks after changes.

Recommended first task: enhance the Home dashboard and bottom navigation without breaking the existing Hazard Map, Nearest Center, and Alerts modules.

## Status update

**Home Dashboard: done**, implemented as surgical edits against the
existing files rather than rewrites — see the assistant's response for
the exact diffs. Four-tab navigation (Home / Hazard Map / Nearest
Center / Alerts), minimal alerts summary slice (entity, remote
datasource, provider — no full Alerts feature yet, that's next), Home
page with header, emergency status card, quick actions, stats,
latest-alert card, safety tips. Map feature untouched. Evacuation
Centers feature: only its FAB removed (redundant once Nearest Center
became its own tab) and one AppBar action added to Nearest Center.

Next recommended task, per the approved plan: the full Alerts feature
(list UI, details, Isar caching, pull-to-refresh) — everything the
minimal Home slice deliberately deferred.

## Known issues (pre-existing, not yet fixed)

- **Settings → Connectivity row can stay on "Offline mode" while the app
  is actually online.** Seen 2026-09-27 on a physical device: the app's
  very first reachability probe failed (the backend link wasn't up yet),
  and the row kept saying "Offline mode" even after later probes
  succeeded and live data was loading. Probable cause, not yet
  confirmed: the row watches `connectivityStatusProvider`
  (`home_provider.dart`), i.e. `ConnectivityService.onConnectivityChanged`,
  which only re-probes when the device's network changes; data screens
  instead call `hasConnection()`, which re-probes on its own schedule.
  So an early failed probe is never corrected for the row until the
  network itself changes. Other widgets watching the same provider (the
  Home status pill, EC Board's offline-only UI, Quick Departure's
  offline notice) may be affected the same way. Deliberately left for
  its own session — not part of the navigation/EC Board work.
