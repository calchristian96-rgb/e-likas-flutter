# Changelog — Home Dashboard Phase

## UI Polish Phase (this update) — presentation layer only

Scoped strictly to presentation-layer files, per instruction — no
networking, Dio, Isar, repositories, Android config, or pubspec
touched. Two categories of change: concrete bugs found and fixed, and
broader consistency/polish applied across every screen (not just Home).

### Real overflow bugs found and fixed
1. **`evacuation_center_card.dart`** — the occupancy+distance row had
   no `Expanded`/`Flexible` at all; with both pieces of text present
   on a narrow screen, this was a genuine overflow risk, not a
   theoretical one. Rebuilt using `Wrap` so the two icon+text pairs
   reflow onto a second line when they don't both fit, instead of
   overflowing. Center name and address also given `maxLines`, and the
   status pill given a max width + ellipsis (status vocabulary isn't
   confirmed, so this is a safety net, not a fix for something known
   to be too long today).
2. **`quick_action_card.dart` + the Home quick-actions grid** — the
   grid used a fixed `childAspectRatio`, which makes cell *height*
   depend on screen *width* — backwards for fitting text, since "View
   All Evacuation Centers" (28 characters) most needs vertical room
   exactly when the screen is narrow and the aspect-ratio cell is
   shortest. Switched to `SliverGridDelegateWithFixedCrossAxisCount`
   with a fixed `mainAxisExtent`, and added `maxLines: 2` +
   `TextOverflow.ellipsis` to the label as a second line of defense.
3. **`home_stats_section.dart`** — the value text (e.g. "Unavailable")
   had no overflow protection in a narrow third-of-screen tile. Now
   wrapped in `FittedBox(fit: BoxFit.scaleDown)`, which shrinks to fit
   rather than wrapping awkwardly or risking overflow.

### A real correctness gap, not just polish
4. **`EmergencyStatusCard`** showed "No Active Public Alert" during
   the *loading* state too (`.value` is null before the first fetch
   resolves) — a false negative, not just missing polish. It now takes
   an explicit `isLoading` and shows a distinct neutral "Checking for
   alerts…" state instead.

### Consistency: every screen now shares the same empty/error language
Migrated `evacuation_centers_list_page.dart`, `nearest_center_page.dart`,
and `evacuation_map_page.dart` to use the same `core/widgets/EmptyState`
/`ErrorState` the Home phase introduced, rather than each hand-rolling
its own — this also fixed a real gap where `nearest_center_page.dart`'s
error state had **no retry action at all**. Added an optional `icon`
override to `ErrorState` (matching the pattern `EmptyState` already
had) so screens needing a more specific icon (e.g., "location off")
don't lose that specificity for the sake of consistency. The Map page
also gained a genuine empty state (previously: if there was no data at
all, the map just rendered blank with no message) and a small legend
distinguishing center markers from hazard polygons — neither existed
before.

### Loading skeletons (new: `core/widgets/loading_skeleton.dart`)
A simple pulsing placeholder using Flutter's own `AnimationController`
— no new package, since `pubspec.yaml` is off-limits this phase.
Applied to the Home stats tiles and the latest-alert card, replacing a
bare spinner with a shape that previews the real layout.

### Subtle animation (item 15)
The skeleton pulse itself, plus an `AnimatedSwitcher` cross-fade on the
Emergency Status Card when it transitions between loading/no-alert/an
alert — restrained, not decorative.

### Accessibility (item 16)
Added an explicit `Semantics` label to the header's connectivity icon
(previously icon + tiny text with no semantic label); confirmed
existing tooltips (Nearest Center's "view all" button) were already in
place.

### Files touched this round
**New:** `lib/core/widgets/loading_skeleton.dart`
**Modified:** `evacuation_center_card.dart`, `quick_action_card.dart`,
`home_page.dart`, `home_stats_section.dart`, `latest_alert_card.dart`,
`emergency_status_card.dart`, `error_state.dart` (added optional icon
param), `evacuation_centers_list_page.dart`, `nearest_center_page.dart`,
`evacuation_map_page.dart`
**Untouched:** everything outside `lib/features/*/presentation` and
`lib/core/widgets` — no repositories, datasources, providers' logic,
Dio, Isar, routing structure, Android config, or `pubspec.yaml`.

### Manual verification specific to this round
- [ ] On a small device/emulator (or DevTools' device-size override at
      ~360dp width), confirm the evacuation center cards and quick
      action tiles no longer show the yellow/black overflow stripes —
      this is the one thing genuinely worth checking on an actual
      narrow screen rather than trusting the reasoning alone.
- [ ] Confirm the Emergency Status Card shows "Checking for alerts…"
      briefly on first load rather than flashing "No Active Public
      Alert" before the real alert (if any) appears.
- [ ] Confirm pull-to-refresh still works on the centers list and Home
      screen (the empty/error state rework kept the scrollable-wrapper
      needed for `RefreshIndicator`, but worth confirming directly).

## Integration audit round

A full audit against 10 preservation criteria found 3 genuine issues,
all fixed — see "Integration Audit Report" below for the complete
findings, including the 7 points that were already compliant.

Four-tab navigation (Home / Hazard Map / Nearest Center / Alerts) and
a minimal alerts summary slice, implemented as surgical edits against
the existing codebase. Map feature untouched; Evacuation Centers
feature only had its now-redundant FAB removed and one link added.

## Files created (15)

### `lib/core/widgets/` — shared UI building blocks
| File | Purpose |
|---|---|
| `offline_banner.dart` | Slim banner shown when offline; renders nothing when online |
| `empty_state.dart` | Reusable "nothing here yet" block |
| `error_state.dart` | Reusable error block with a retry action |
| `last_updated_label.dart` | "Updated 5m ago" / "Not yet updated" relative-time label |

### `lib/features/alerts/` — minimal summary slice only
| File | Purpose |
|---|---|
| `domain/entities/alert.dart` | Minimal `Alert` entity — only the fields Home displays (title, message, alert_type, status, date). Deliberately not the full entity the later Alerts phase will need. |
| `data/datasources/alerts_remote_datasource.dart` | Fetches `GET /public/alerts` via the existing `ApiResponse<T>` wrapper for the outer envelope; parses the inner pagination shape defensively (Laravel-nested or flat — not confirmed which yet) |
| `presentation/providers/alerts_summary_provider.dart` | `@riverpod` provider exposing `{latest, count}`. No repository layer. Failures are caught and re-thrown as the existing `NetworkFailure` type, not a raw exception |

### `lib/features/home/` — the dashboard itself
| File | Purpose |
|---|---|
| `domain/dashboard_summary.dart` | `DataFreshness` enum (live/cached/offline/unavailable) and its derivation reasoning |
| `presentation/providers/home_provider.dart` | Live connectivity stream (wraps the existing `ConnectivityService`) + the pure `deriveFreshness()` helper |
| `presentation/pages/home_page.dart` | The Home screen itself — composes existing `allEvacuationCentersProvider` + new `alertsSummaryProvider`, nothing fetched independently |
| `presentation/widgets/emergency_status_card.dart` | Status card — derives label strictly from real `alert_type`, neutral fallback for anything unrecognized |
| `presentation/widgets/quick_action_card.dart` | One reusable tile, used 5 times (Nearest Center, Hazard Map, Alerts, All Centers, Refresh) |
| `presentation/widgets/home_stats_section.dart` | Total centers / alert count / data-freshness tiles — no fabricated numbers |
| `presentation/widgets/latest_alert_card.dart` | Own loading/empty/error states |
| `presentation/widgets/safety_tips_section.dart` | Static local list, no data source |

## Files modified (4)

### `lib/app/router/app_router.dart`
6 targeted edits, not a rewrite — Map and Alerts branches have zero
diff lines touching them:
1. Added the `HomePage` import.
2. Updated one doc comment ("three" → "four" destinations).
3. Inserted a `Home` `NavigationDestination`; repurposed the old
   `Centers` destination into `Nearest Center` (icon + label only).
4. Changed `initialLocation` from `/map` to `/home`.
5. Inserted a new `Home` branch first; changed the old `Centers`
   branch's route from `/centers` (with a nested `nearest` route) to a
   direct `/nearest-center` route.
6. Added `/centers` as a plain route *outside* the shell, so the
   all-centers list is still reachable (pushed on top of any tab) but
   isn't a tab itself.

**Why**: this is the one file that has to change for a 4-tab
navigation restructure — GoRouter's `StatefulShellBranch`es are
independent stacks, so promoting Nearest Center out of nesting under
`/centers` structurally requires its own top-level path.

### `lib/features/evacuation_centers/presentation/pages/evacuation_centers_list_page.dart`
Removed the FAB (`FloatingActionButton.extended`, "Nearest to me") and
its now-unused `go_router` import. Nothing else in this file changed.

**Why**: the FAB pushed to `/centers/nearest`, a route that no longer
exists post-restructure. Rather than repoint it, it was removed
outright — Nearest Center is now a permanent bottom-nav tab, so a FAB
doing the identical navigation from this screen would be redundant UI,
not a loss of functionality.

### `lib/app/theme/app_theme.dart`
Added one new class, `AppSemanticColors` (a `ThemeExtension`), and wired
it into `_themeFrom()` via the `extensions:` parameter. Nothing else in
the file changed — the existing `AppTheme.light`/`.dark` getters,
`ColorScheme.fromSeed` call, and app bar/nav bar theming are untouched.

**Why**: found during the integration audit below — `EmergencyStatusCard`
originally used hardcoded `Colors.deepOrange`/`Colors.amber`/`Colors.green`
for alert severity, since Material 3's `ColorScheme` has no built-in
"warning" or "success" role. A `ThemeExtension` is the standard Flutter
way to add semantic colors that still respect theming and dark mode,
rather than either hardcoding or dropping the severity distinction.

## Integration Audit Report

A full audit against 10 preservation criteria, requested before final
acceptance. 7 were already compliant; 3 genuine issues were found and
fixed.

| # | Area | Finding | Action |
|---|---|---|---|
| 1 | API client | No new `Dio()` instance anywhere — `alertsSummaryProvider` reuses `apiClientProvider` | Compliant, no change |
| 2 | Repositories | No existing repository touches `/public/alerts`; nothing to extend | Compliant, no change |
| 3 | Response wrapper | **Issue**: `alerts_remote_datasource.dart` read `response.data['data']` directly, bypassing the existing `ApiResponse<T>` | **Fixed** — now uses `ApiResponse<AlertsPage>.fromJson()` for the outer envelope, same as the other two datasources |
| 4 | Error handling | **Issue**: caught nothing, let raw exceptions reach `AsyncValue.error` instead of the app's own `Failure` type | **Fixed** — `alertsSummaryProvider` now catches and throws `NetworkFailure`; `home_page.dart` extracts `.message` the same way `NearestCenterPage` already does |
| 5 | Riverpod style | All new providers use plain `@riverpod` functions, matching every existing provider (no `AsyncNotifier` classes anywhere in the project) | Compliant, no change |
| 6 | Theme / colors | **Issue**: `EmergencyStatusCard` used hardcoded `Colors.*` for warning/success states (roles `ColorScheme` doesn't define) | **Fixed** — added `AppSemanticColors` `ThemeExtension` to `app_theme.dart`; card now reads `theme.extension<AppSemanticColors>()` |
| 7 | Widget duplication | Compared against the existing private `_StatusPill` in `evacuation_center_card.dart` — different visual pattern (hero card vs. small pill), not a duplicate. No new Loading/Empty/Error/Card/Banner widget duplicates an existing one | Compliant, no change |
| 8 | Routing | Every `context.go/push` target matches a declared route; 0 routes removed; `StatefulShellRoute.indexedStack`'s stock back-button behavior untouched (no custom `PopScope`/back overrides added) | Compliant — back navigation should work via GoRouter's own defaults, but this specifically needs a real device to confirm (see below) |
| 9 | Isar cache | `Alert` is plain Dart, no `@collection`; no new Isar collection created | Compliant, no change |
| 10 | Code quality | No TODOs, no dead code, no duplicate constants/helpers found in the 15 new files | Compliant, no change |

### Assumptions still depending on the Laravel backend
- Alerts pagination envelope shape (Laravel-nested vs. flat) — handled defensively, not confirmed.
- `alert_type` vocabulary — matched by substring against plausible values, neutral fallback for anything unrecognized.
- "Available centers" count intentionally omitted — `status` field vocabulary not confirmed reliably enough.

### Manual verification still needed after `flutter pub get` / `build_runner` / `analyze` / `run`
- [ ] Confirm exactly 2 new generated files (`home_provider.g.dart`, `alerts_summary_provider.g.dart`) — nothing else should regenerate.
- [ ] Confirm `analyze` is clean on the 15 new + 4 modified files specifically.
- [ ] Tap through all five Quick Action cards — each should land on the tab/screen its label promises.
- [ ] Confirm the bottom nav shows 4 tabs in order (Home / Hazard Map / Nearest Center / Alerts) and that switching tabs preserves each tab's own scroll/navigation state.
- [ ] **Back navigation** (Android system back): tab-to-tab, and drilling into `/centers` then backing out. Stock GoRouter behavior, untouched by this change, but worth confirming directly on a device.
- [ ] With the backend reachable: confirm Home's alert count/latest-alert reflect real data, and that the status card's colors now pull from `AppSemanticColors` (visually distinct warning/success, respecting light/dark mode) rather than a fixed hardcoded shade.
- [ ] Confirm "View All Evacuation Centers" and the icon button on Nearest Center both open the same `EvacuationCentersListPage` with a working back button.
