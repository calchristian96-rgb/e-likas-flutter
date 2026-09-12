# Changelog — Quick Actions Functionality Pass

## 1. What was actually broken (confirmed by reading the code, not assumed)

**Refresh Data was incomplete.** The spec requires it to refresh alerts,
evacuation centers, *and* map data. The actual code only invalidated
the first two — `mapDataProvider` was never touched. This is a
real, confirmed bug, not a hypothesis.

**"View Alerts" led to a placeholder.** `/alerts` pointed at
`PlaceholderPage('Alerts')` — "coming in a later module" — left that
way deliberately when the Home Dashboard phase scoped the full Alerts
feature (list, details, caching, real-time) to a later phase. A
placeholder saying "not built yet" doesn't perform its intended
action, so this needed a real (if intentionally minimal) page.

## 2. On "alerts never finish loading" — what I could and couldn't confirm

I traced the entire chain by hand: `alertsSummaryProvider` →
`AlertsRemoteDatasource` → `ApiClient.get()` → Dio, with
`connectTimeout`/`receiveTimeout` both set to 10 seconds, and every
failure point already wrapped in try/catch that converts to
`AsyncValue.error`. Read carefully, this **should** resolve to an
error state within ~10 seconds if the backend is unreachable — not
hang forever. I could not find a specific line that would cause a true
infinite hang, and I want to be upfront that I can't run this myself to
either reproduce or rule it out with certainty.

Given that, I made a deliberate choice: rather than claim a root cause
I haven't verified, I added a genuine hardening fix that helps
regardless of the exact mechanism — see below. If "Checking for
alerts…" is still stuck well past ~12 seconds after this, that's a
real, different signal worth capturing directly (the actual on-screen
text, or `flutter run`'s console output) rather than me guessing
further from code alone.

## 3. How each thing was fixed

**`core/network/api_client.dart`** — added `.timeout(const Duration(seconds: 12))`
as an explicit outer bound on top of Dio's own configured timeouts.
This is a belt-and-suspenders safety net: every feature's data fetch
goes through this one shared client, so this guarantees none of them
can hang indefinitely regardless of how a specific device or network
condition interacts with Dio's own timeout handling — directly
addresses "no infinite loading indicators" without touching the
existing (already reasonable) 10-second Dio timeouts themselves.

**`home_page.dart`** — `Refresh Data` (both the quick-action button and
pull-to-refresh) now also invalidates `mapDataProvider`. Also wrapped
the pull-to-refresh's `Future.wait(...)` in try/catch: with three
sources now awaited together, any one of them failing would otherwise
throw an unhandled exception out of the refresh callback — each
section already shows its own error state independently, so this
callback's only job is to let the spinner finish, not propagate a
failure a second time.

**New: `alertsListProvider`** (added alongside the existing
`alertsSummary` in the same file) — reuses `AlertsRemoteDatasource`
directly rather than duplicating its fetch/parse logic; the only
addition is exposing the full list instead of just the newest item,
which "View Alerts" needs and the Home Dashboard's summary never did.

**New: `AlertsListPage`** + **`AlertListTile`** — a real, minimal Alerts
page: loading spinner, list of alerts, `EmptyState` when there are
none, `ErrorState` with retry when the fetch fails. Deliberately still
minimal — no details screen, no Isar caching, no real-time updates,
no notifications — those remain the next Alerts phase, unchanged from
the original scope agreement.

**Caught while implementing, not before**: my first pass named the new
page class `AlertsPage` — which collided with an *existing* `typedef
AlertsPage = ({...})` already in `alerts_remote_datasource.dart` (the
pagination-result record type). No file currently imports both into
the same scope, so this wouldn't have caused an immediate compile
error, but it's exactly the kind of latent landmine worth catching now
rather than leaving for later. Renamed to `AlertsListPage`, matching
the naming convention `EvacuationCentersListPage` already established.

**`app_router.dart`** — `/alerts` now points to `AlertsListPage`
instead of the placeholder. Also removed the `PlaceholderPage` class
itself, since every tab now has a real page and it was fully unused —
straightforward dead-code cleanup, not a functional change.

## 4. Verified already correct, no changes needed
- **Find Nearest Center**: navigation, loading state, and the specific
  permission-denied / service-disabled / permanently-denied messages
  (each with its own wording and a retry action) were all already
  correctly wired.
- **Open Hazard Map**, **View All Evacuation Centers**: loading/error/empty
  states are all present and intact — if these still appear "broken"
  after this pass, the most likely explanation (consistent with this
  whole project's history) is the backend still being unreachable,
  which correctly *should* show as an error state, not silently succeed.
- **Emergency Hotlines**: navigation, Copy Number (`Clipboard`), and the
  Call placeholder's SnackBar were all confirmed unchanged and working.

## Files modified
`core/network/api_client.dart`, `home/presentation/pages/home_page.dart`,
`alerts/presentation/providers/alerts_summary_provider.dart`,
`app/router/app_router.dart`

## Files created
`alerts/presentation/pages/alerts_page.dart` (class `AlertsListPage`),
`alerts/presentation/widgets/alert_list_tile.dart`

## Untouched
`pubspec.yaml`, Android configuration, `AppTheme`, every repository,
every datasource except the one new provider function added to an
*existing* file, Map/Evacuation Centers/Emergency Hotlines feature code.

## Manual verification
- [ ] Tap Refresh Data and confirm the Hazard Map's data also refreshes
      (previously it silently didn't).
- [ ] Tap View Alerts and confirm a real list (or empty/error state)
      appears instead of "coming in a later module."
- [ ] If "Checking for alerts…" is still stuck noticeably longer than
      ~12 seconds after this update, that's the concrete signal worth
      capturing directly — the exact wait time and whatever
      `flutter run`'s console shows at that moment.
- [ ] Confirm pull-to-refresh on Home still completes cleanly even with
      the backend unreachable (no red error screen / unhandled
      exception — it should just settle into each section's own error
      state).
