# E-LIKAS mobile — setup notes

## Module 3: Map feature — GeoJSON parsing, flutter_map rendering

Full slice for `/public/gis/map-data`: domain (`HazardArea`, `MapData`
entities), data (`HazardAreaModel` — Isar-cacheable, applying every
Isar lesson from Module 2 from the start), presentation (provider,
the real Map tab page with `flutter_map`, tap-to-open-details on
markers, colored hazard polygons). Wired into the Map tab, replacing
its placeholder.

**Decisions worth flagging:**

- **`power_geojson` isn't used**, despite being in `pubspec.yaml` since
  Phase 1. It's built to parse GeoJSON directly into flutter_map's own
  `Marker`/`Polygon` widgets — but this feature needs to parse into
  *cacheable domain models* first, then render, not render directly.
  Manual parsing (iterate `features`, branch on `geometry.type`) is
  plain, verifiable JSON handling with no third-party API surface to
  get wrong — lower risk than adopting another package's exact API on
  top of everything else in this project. Left in `pubspec.yaml`
  un-removed, per "preserve dependencies."
- **Centers found in this GeoJSON feed are cached into the same Isar
  collection Module 2 already created** (`EvacuationCenterModel`),
  not a separate one — they're the same backend records reached
  through a different endpoint, so `fromGeoJsonFeature` was added as a
  new factory on the *existing* model file (Module 2's `fromJson` is
  untouched). This is the one place Module 3 touches an earlier
  module's file, and it's additive only.
- **Distinguishing centers from hazard areas by GeoJSON geometry type**
  (`Point` vs `Polygon`) rather than a properties field — this matches
  what the handoff document itself already confirms, so it's not an
  assumption the way property field names are.
- **Every Isar-specific choice in `HazardAreaModel` applies what Module
  2 had to learn the hard way**: backend's own `id` used directly as
  the Isar primary key (no `Isar.autoIncrement`, no nullable id field),
  no `@Index(replace:)`, polygon boundary stored as a flat
  `List<double>` rather than an `@embedded` type (an untested Isar
  surface not worth risking without a real need).

**Not yet verified against a real response — worth checking once the
backend is reachable:** the exact property names for hazard areas
(`name`, `hazard_type`, `severity_level`) are reasonable assumptions,
not confirmed. `EvacuationCenterModel.fromGeoJsonFeature` reuses the
already-confirmed flat field names from the documented
`/evacuation-centers` contract, so that side is on firmer ground.

Same verification sequence as every module — no backend needed for
this part, same reasoning as before (a correctly-formed, correctly-
addressed request timing out because nothing's listening proves the
pipe is built right; it doesn't need to succeed to prove that):

```
flutter pub get
dart run build_runner build
flutter analyze
```

## Module 2: Evacuation Centers — needs build_runner, then analyze

Full data → domain → presentation slice for `/public/evacuation-centers`
and `/nearest`, wired into the Centers tab (with a "Nearest to me" FAB
routing to `/centers/nearest`). Static checks (brace/paren balance,
every import resolves, every cross-file symbol is declared) all pass,
same as Phase 1 — but this module is the first to actually need code
generation, so the steps are different this time:

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

`build_runner` needs to run **before** `analyze` this time, because six
files now have a `part '*.g.dart';` directive with nothing behind it
yet: `evacuation_center_model.dart` (Isar's `@collection` schema),
`evacuation_centers_provider.dart`, and four core services
(`api_client.dart`, `isar_service.dart`, `location_service.dart`,
`connectivity_service.dart`) now expose their singletons as `@riverpod`
providers for DI, each needing its own generated file.

### One deliberate architecture change from the original plan

`EvacuationCenterModel` is **plain Dart, not Freezed** — a change from
what the architecture notes said data models would generally use.
Isar's code generator expects a specific field shape (its own mutable
`Id id` field, direct field access) that doesn't mix cleanly with
Freezed's fully-immutable, copyWith-based generated classes. Freezed
stays available for any future model that doesn't also need to double
as an Isar collection row.

### Things I couldn't verify without a real compiler — check these first if `build_runner` or `analyze` complain

- **Isar's generated collection accessor name.** `isar.evacuationCenterModels`
  in the local datasource assumes Isar's codegen pluralizes
  `EvacuationCenterModel` by lowercasing the first letter and adding
  an `s` — the same pattern as the `User`/`isar.users` example in
  Isar's own docs. If the generator produces a different name,
  `build_runner`'s output will show the actual generated collection
  name to swap in.
- **The `@riverpod` family-provider syntax** in
  `nearestEvacuationCenters(Ref ref, {required double latitude, required double longitude})`
  — modern `riverpod_generator` is supposed to support named parameters
  directly on the annotated function, but this hasn't been confirmed
  against your exact installed version. If generation fails here,
  falling back to a positional-record parameter is the likely fix.
- **`@Index(unique: true, replace: true)`** on `serverId` in the model
  — a standard pattern from the original Isar project that isar_plus
  is described as staying compatible with, but not independently
  re-confirmed for this specific isar_plus version.

None of these would show up in a plain `flutter analyze` before
`build_runner` runs — they're all about what the generator actually
produces, which is exactly the kind of thing this sandbox can't test
and your machine can.

## Phase 1 fix history (six issues, all resolved)

1. **`osrm ^1.0.0`** doesn't exist past 0.0.8, a pre-1.0 package
   self-described as "under development." Replaced with
   `routing_client_dart: ^1.0.7`.
2. **`isar_plus`/`isar_plus_flutter_libs` `^4.0.0`** was a prerelease
   stalled 10 months; real current stable was the 1.x line.
3. **`flutter_local_notifications ^18.0.0`**, **`riverpod_generator
   ^3.0.0`**, **`flutter_lints ^5.0.0`** were stale floors, bumped to
   confirmed current versions.
4. **`isar_plus` `meta` conflict**: versions ≥1.2.7 need `meta ^1.18.0`,
   which no current stable Flutter ships (confirmed against 3.44.8).
   Constrained to `>=1.2.0 <1.2.7`.
5. **`freezed_annotation ^2.4.4`** conflicted with what
   `riverpod_generator`'s own chain now needs (`^3.0.0`); freezed
   bumped to match.
6. **`latlong2 ^0.10.0`** (my own earlier bump) conflicted with
   `power_geojson`, which pins it to `^0.9.1`. Reverted.

Full detail on each, in the order they were found, is below.

## Third round: a real SDK/package conflict, not a version typo

`flutter pub get` got past the version-solving issues above, then hit:

```
Because every version of flutter_test from sdk depends on meta 1.17.0 and
isar_plus >=1.2.7 depends on meta ^1.18.0, flutter_test from sdk is
incompatible with isar_plus >=1.2.7.
```

This looked at first like an outdated Flutter SDK, but the person
running this was on Flutter 3.44.8 — the current stable release, only
2 days old. So there's no newer Flutter to upgrade to; `isar_plus`
>=1.2.7 is asking for a `meta` version that isn't in any current stable
Flutter yet. Fixed by constraining below that boundary:

```yaml
isar_plus: ">=1.2.0 <1.2.7"
isar_plus_flutter_libs: ">=1.2.0 <1.2.7"
```

This is inferred from the error message's own precision (it names
1.2.7 as the exact threshold) rather than independently verified
against isar_plus 1.2.6's own dependency manifest — if `pub get` still
complains about `meta` after this change, **`isar_community`**
(isar-community.dev, a separate actively-maintained fork with its own
non-conflicting 3.x version line) is the next thing to try in place of
`isar_plus` — it would mean changing the import in
`core/cache/isar_service.dart` from `package:isar_plus/isar_plus.dart`
to `package:isar_community/isar_community.dart` and the two pubspec
lines accordingly.

## Fourth round: freezed's major version had moved too

Next conflict: `riverpod_generator`'s own dependency chain (via
`riverpod_analyzer_utils`) now requires `freezed_annotation ^3.0.0`,
but this pubspec still had `^2.4.4`. Freezed itself has moved to a 3.x
line in step with its annotation package. Fixed:

```yaml
freezed_annotation: ^3.0.0   # was ^2.4.4
freezed: ^3.0.0              # was ^2.5.0 (dev dependency)
```

Worth knowing for Module 2, when the first Freezed models actually get
written: freezed 3.x's migration guide shows model classes declared as
`abstract class Person with _$Person` rather than plain `class Person
with _$Person` — a syntax change from the 2.x examples still floating
around in older tutorials.

**Why this keeps happening, and why it's not a sign of a bad plan:**
`isar_plus`, `freezed`, `riverpod_generator`, and `json_serializable`
are all code generators that share foundational packages underneath
(`analyzer`, `meta`, `build`, `source_gen`) — each one evolves
independently, so keeping all of them mutually compatible is
genuinely fiddly in the Dart ecosystem generally, not specific to this
project. `flutter pub get`'s own solver finds these faster and more
completely than checking each package's dependency tree by hand can —
each run is surfacing the next real constraint, not a new mistake.
Worth just re-running it after each fix and reporting back whatever
it says next.

## findAll → build().findAll() — down to the last error

Both `findAllAsync()` and plain `findAll()` were confirmed wrong on
`QueryBuilder` in isar_plus 1.2.6. Checked Isar's actual API docs
directly (mainline `isar` package, since isar_plus doesn't publish
version-specific docs going back that far): `findAll`/`findAllSync`
are declared on the `Query<T>` class itself, reached via `.build()`.
The version callable directly on `QueryBuilder` (what most tutorials
show) is a separate convenience extension that isar_plus 1.2.6 may not
carry. Changed to:

```dart
isar.evacuationCenterModels.where().build().findAll()
```

This is a well-reasoned bet backed by real documentation of how Isar
structures this internally, not a directly-confirmed fact for 1.2.6
specifically. If this is *still* wrong, the fastest way to get a
definitive answer without another guess: type
`isar.evacuationCenterModels.where().build().` in VS Code and read
what autocomplete actually offers — that reads the real installed
package on your machine, which is more reliable than anything I can
find by searching.

## Real build_runner output — the Id nullability question, finally settled

Genuinely useful this round: the error came from `isar_plus:isar_generator`
itself, not just `flutter analyze` — **"Id properties must not be
nullable."** on the `int? id;` field. That rules out the nullable
approach directly, and combined with the earlier confirmed fact that
`Isar.autoIncrement` doesn't exist in 1.2.6 either, both documented
paths to a non-nullable auto-increment id are closed off in this
specific version.

Rather than guess a third sentinel value, redesigned around the
problem instead: merged the separate Isar-internal id with the
backend's own `id` field, using it directly as Isar's primary key.
The backend's id is already guaranteed unique, so there's no real need
for a second, separately-managed one — and `put`/`putAll` now upsert
naturally on a matching id, which also let the local datasource's
manual match-and-copy logic (built a few rounds back specifically to
work around the missing `@Index(replace: true)`) be removed entirely.
Simpler on both counts, not just a workaround.

**Also confirmed by this same build_runner run**: `riverpod_generator`
reported "5 output" this time — strong evidence the missing-`.g.dart`
files from two rounds ago (the `Success`/`Failed` import fix, the
positional-parameter family provider change) are actually resolved.
The only remaining generator failure was this one Isar issue.

One warning in the build_runner output — `SDK language version 3.12.0
is newer than analyzer language version 3.11.0` — is informational
only, not blocking; safe to ignore unless something specific traces
back to it.

## Riverpod cluster exact-pinned after re-resolution reintroduced the analyzer conflict

After a clean `pubspec.lock` delete + `flutter clean`, the exact same
configuration that previously succeeded (`flutter_riverpod ^3.3.2`,
`riverpod_annotation ^4.0.2`, `riverpod_generator ^4.0.3`) failed again
on the same `analyzer` conflict as before. Most likely explanation:
pub.dev is a live registry, and something in this cluster likely
shipped a new patch between the original success and this run — a
caret range would happily float up to it. Exact-pinned all three
(`flutter_riverpod: 3.3.1`, `riverpod_annotation: 4.0.2`,
`riverpod_generator: 4.0.3`, no carets) to stop that drift, per pub's
own suggested downgrade. Only `pubspec.yaml` changed this round — no
source files touched.

If this specific conflict resurfaces a third time despite exact pins,
that would be a strong signal this isn't really fixable by chasing
version numbers further — the isar_plus/riverpod_generator combination
may be at a fundamentally narrow or shifting compatibility point, and
the honest next step would be reconsidering one side of that pairing
rather than continuing to re-pin.

## Real analyzer output, real fixes (this round)

First actual `flutter analyze` output after `build_runner` ran. Confirmed
several isar_plus 1.2.6 API differences from what's documented for the
current 1.3.7 release, plus one genuine bug of my own:

1. **`Isar.autoIncrement` doesn't exist** on `Isar` in 1.2.6 (confirmed
   by the analyzer, not a guess). Switched the `id` field to nullable,
   non-final `int? id;` with no initializer — Isar's own documented v3
   behavior ("if the id field is null and not final, Isar assigns an
   auto-increment id") doesn't depend on that specific getter existing.
2. **`@Index(replace: true)` isn't a valid parameter** in 1.2.6. Kept
   `@Index(unique: true)` for the database-level guarantee, and moved
   the actual upsert logic into `EvacuationCentersLocalDatasource`
   explicitly: read what's cached, match by `serverId`, carry over the
   existing Isar `id` before writing, so `put` updates instead of
   colliding with the unique index.
3. **`findAllAsync()` isn't defined for `QueryBuilder`** — switched to
   `findAll()` (still `await`ed, which is harmless whether or not the
   method itself is actually async).
4. **A genuine missing import**, unrelated to any version issue:
   `evacuation_centers_provider.dart` uses `Success`/`Failed` but never
   imported `core/error/result.dart` directly — it only had them
   transitively through other imports, which Dart doesn't resolve on
   its own. Added the direct import.
5. **Simplified the `nearestEvacuationCenters` family provider** from
   named parameters to plain positional ones (`Ref ref, double
   latitude, double longitude`) — a more conservatively-supported
   riverpod_generator pattern, since this was the likely single point
   where an unfriendly syntax could silently block that file's whole
   `.g.dart` from being written. Updated the one call site
   (`nearest_center_page.dart`) to match.

**On the 5 missing `.g.dart` files specifically:** all 5 are very
likely one root cause, not five — a `part` directive pointing at a
file that doesn't exist is a hard error for that whole library, and
`location_service.dart`'s missing part file is a plausible direct
explanation for `nearest_center_page.dart`'s own "non-exhaustive switch
on dynamic" error (if `LocationService`'s members can't resolve, code
that calls them loses its type information downstream). The Isar model
file's three confirmed errors are the most likely thing that was
blocking the whole `dart run build_runner build` pass from writing any
output at all. This is a reasoned inference from the evidence, not
something independently confirmed — the real test is whether all 5
generate successfully on the next run.

## Reverted back to isar_plus — and found the actual root cause

After the `analyzer` conflict between `isar_plus` and `riverpod_generator`
surfaced, the fallback suggested was switching to `isar_community`. On
request, reverted back to `isar_plus` — and on closer look, the real
fix wasn't a fallback at all:

**`riverpod_generator: ^4.0.4` was never a stable release.** Checked
against pub.dev's own version history: `4.0.3` is the actual latest
stable; `4.0.4` only exists as a `4.0.4-dev.x` prerelease. That
prerelease is specifically where "Support analyzer 12" was introduced.
My original `^4.0.4` constraint (from a docs snippet that likely
included a prerelease as "latest") forced pub to reach into that exact
dev track to satisfy it — which is what pulled in the `analyzer
^12.0.0` requirement that `isar_plus` can't satisfy.

```yaml
isar_plus: ">=1.2.0 <1.2.7"              # back from isar_community
isar_plus_flutter_libs: ">=1.2.0 <1.2.7" # back from isar_community
riverpod_generator: ^4.0.3                # was ^4.0.4 — the actual mistake
```

If this resolves cleanly, both preferences (isar_plus, and Riverpod's
codegen convenience) are satisfied — no trade-off needed. If `pub get`
still shows an `analyzer` conflict, that would mean 4.0.3 has *some*
`analyzer` requirement above what isar_plus's 1.2.x line supports too,
and the isar_community swap (or dropping codegen) genuinely is the
remaining option — but this is worth trying first since it may need
neither.

## Fifth round: my own earlier "fix" collided with a different package

Bumping `latlong2` to `^0.10.0` a few rounds back was correct in
isolation (0.10.1 genuinely is latlong2's current release) but didn't
account for `power_geojson`, which pins `latlong2` to `^0.9.1` across
its entire 3.41.x line. Reverted:

```yaml
latlong2: ^0.9.1   # was ^0.10.0
```

`flutter_map` itself wasn't named in the conflict, so it's already
compatible with `latlong2 ^0.9.1` — no further change needed there.
Worth naming honestly: "upgrade to the package's own current version"
isn't always the right call when something else you depend on pins it
lower — the right version is whatever the whole graph agrees on, which
`pub get` sees and a one-package-at-a-time check doesn't.

## Why you need to compile this yourself

The environment these files were written in can reach GitHub but not
pub.dev or Flutter's SDK distribution host, so `flutter pub get` /
`flutter analyze` / `flutter build` could not be run here to prove
compilation. Every file was written and reviewed against each
package's documented API, and a basic brace/paren balance check was
run on all of them — but that's static analysis, not a compiler.

**Update after the first real `flutter pub get` attempt:** it failed —
`osrm ^1.0.0` doesn't exist (real current version: 0.0.8, and its own
README calls it "under development" with Flutter integration marked
incomplete). That prompted a full re-verification of every version
constraint directly against pub.dev, which caught several more that
were wrong or stale:

| Package | Was | Now | Why |
|---|---|---|---|
| `osrm` | `^1.0.0` | *(removed)* | Never published past 0.0.8; replaced with `routing_client_dart` below |
| `routing_client_dart` | *(new)* | `^1.0.7` | More mature alternative — supports OSRM + Valhalla, includes `nextInstruction()`/`isOnPath()` helpers that fit turn-by-turn guidance directly |
| `isar_plus` | `^4.0.0` | `^1.3.7` | 4.0.0 is a prerelease stalled for 10 months; 1.x is the actively-released real stable line |
| `isar_plus_flutter_libs` | `^4.0.0` | `^1.3.7` | Same as above |
| `flutter_local_notifications` | `^18.0.0` | `^21.0.0` | Would have resolved, just to a 3-major-version-old release |
| `latlong2` | `^0.9.0` | `^0.10.0` | Dart's caret locks the *minor* version for 0.x packages, so `^0.9.0` would silently pin a 2-year-old release instead of failing |
| `riverpod_generator` | `^3.0.0` | `^4.0.4` | Confirmed against Riverpod's own current official docs — the generator's version numbering doesn't track the main package's |
| `flutter_lints` | `^5.0.0` | `^6.0.0` | Would have resolved, just outdated |

`core/cache/isar_service.dart` also had a real API mismatch, caught by
reading Isar Plus's own current quickstart docs directly: `Isar.open`
takes a **named** `schemas:` parameter and is **not awaited** (it
returns `Isar` synchronously, not `Future<Isar>`) — the file used a
positional list argument and an unnecessary `await`. Fixed.

Everything else in `pubspec.yaml` (Riverpod, Dio, go_router,
flutter_map, geolocator, connectivity_plus, freezed, json_serializable,
mocktail, web_socket_channel, path_provider, build_runner) was checked
directly against pub.dev during this pass and is either an exact
confirmed version or a floor with real headroom below the current
release, so `pub get` has room to resolve upward rather than fail.

**Still worth double-checking if `pub get` fails again:** `geolocator`,
`connectivity_plus`, `mocktail`, and `intl` weren't pinned down to an
exact current version number the way the table above was — they're
conservative floors with no contradicting evidence found, not
triple-confirmed like `isar_plus` now is. `intl` in particular is
another 0.x package, so the same minor-version-locking caveat as
`latlong2` applies if it's moved past 0.19.x.

## Steps

1. In an empty parent folder: `flutter create --org com.cswdo elikas_mobile`
   This generates a correct `android/` and `ios/` for whatever Flutter
   version you have installed — deliberately not hand-written here,
   since those are toolchain-generated and version-specific.
2. Copy `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `lib/`,
   `test/`, and `assets/` from this archive into the generated project,
   overwriting the defaults.
3. `flutter pub get`
4. `flutter analyze`
5. `flutter run` — should launch to the bottom-nav shell with three
   placeholder tabs.

If `pub get` still fails on something, the error names the exact
package and constraint — paste it back and it's a fast, targeted fix
rather than another guess.

## Permissions you'll need to add once android/ and ios/ exist

- **Location** (for the nearest-center feature, Module 2):
  `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` in
  `AndroidManifest.xml`; `NSLocationWhenInUseUsageDescription` in
  `Info.plist`.
- **Notifications** (Module 5): Android 13+ needs the
  `POST_NOTIFICATIONS` runtime permission; iOS needs the usual
  `flutter_local_notifications` setup in `AppDelegate`.
- **Internet**: Android needs `INTERNET` in `AndroidManifest.xml`
  (usually present by default in generated projects, worth confirming).

None of this is written into XML here, since the exact generated
manifest structure depends on your installed Flutter version's
template — better to add these to the real generated files than have
me guess at a structure I can't see.

## What's intentionally not here yet

- `lib/features/*` folders are placeholders (`.gitkeep` only) — real
  code starts at Module 2 (Evacuation Centers).
- No tests yet — Module 7.
- `ReverbClient` exists but is unused — Module 6, and only after
  confirming the backend broadcasts "sent" alerts on a public channel.
