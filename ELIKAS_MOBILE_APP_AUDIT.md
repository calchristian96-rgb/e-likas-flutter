# E-LIKAS Flutter Mobile Application — Implementation Audit

**Audit date:** 9 October 2026 (Asia/Manila)  
**Project:** `C:\projects\e-likas-flutter`  
**Source revision:** `399906aaf5067ddde987f0d8775171da8b032dd0`  
**Declared application version:** `0.1.0+1`  
**Method:** read-only source and configuration inspection; this report is the only requested new file.

## 1. Executive findings and evidence boundaries

The application implements public resident access and an authenticated staff workspace in one Flutter application. Residents can use Home, Alerts, Map, Hotlines, Settings, evacuation-center listings and details, and nearest-center discovery without an account. Staff can sign in, register complete families, record rapid individual arrivals through an EC Information Board, review family records, check evacuees out, and create or edit evacuation centers.

The application uses Riverpod, GoRouter, Dio, and Drift/SQLite. It has two databases: an unencrypted resident cache and a staff database opened through SQLCipher with a key obtained from secure storage. Most cached reads are **network-first with local fallback**, despite historical descriptions calling the entire application “offline-first.” Family registrations and EC Board intake have manually synchronized offline queues. Center editing and evacuee checkout require a connection.

Important limits for capstone claims:

- Alerts are fetched through REST and polled every 60 seconds while the application shell is in the foreground. A changed latest-alert ID can trigger an in-app banner. Device push notifications, background notification delivery, and SMS sending or receiving are not connected workflows.
- The Settings “Push Notifications” switch persists a preference, but neither alert polling nor the in-app banner consults it.
- The map renders evacuation centers and hazard polygons. “Get Directions” opens an external map location; the application does not compute a road route, turn-by-turn instructions, or a hazard-avoiding evacuation path.
- The EC Board displays server-returned totals and separate unsynchronized contributions. It has no current manual quick-count editor or Quick Departure action.
- Evacuation events are selected and read from the API. There is no mobile event creation, editing, activation, or closure workflow.
- The mobile client’s expected Laravel contracts are inspectable. The Laravel application, route definitions, policies, migrations, OpenAPI specification, and live response samples are absent from this project. Actual backend compatibility and server authorization remain **UNVERIFIED**.
- Staff access checks, cache separation, failure recovery, and synchronization have material gaps described in Section 9. “Implemented” does not mean these paths have passed runtime acceptance testing.

### 1.1 Classification rules

| Classification | Meaning in this report |
|---|---|
| **VERIFIED IMPLEMENTED** | Reachable or directly wired mobile source implements the stated behavior. Verification is static unless explicitly stated otherwise. |
| **PARTIALLY IMPLEMENTED** | A meaningful portion exists, but the broader workflow is incomplete, disconnected, or has a material limitation. |
| **NOT IMPLEMENTED** | No executable mobile workflow was found after reviewing routes, feature modules, network calls, storage, dependencies, and platform configuration. A package, comment, or translation string alone is insufficient. |
| **UNVERIFIED** | Establishing the claim requires the backend, a device, runtime execution, external service evidence, or an unavailable specification. |

### 1.2 Scope and method

The inspection covered the application entry point and router; all 12 feature modules; shared networking, connectivity, location, storage, database, security, localization, and widget infrastructure; Android manifests and build configuration; dependency declarations and lockfile; localization catalogs; project documentation; and the 11 existing test files. The inventory contains 212 first-party Dart files under `lib`, excluding generated provider/database files and generated localization classes. All referenced Dart `part` files were present in this working copy when checked.

Generated files and existing build artifacts were treated as supporting artifacts, not as independent proof of working features. Installed Dio and `flutter_map` source was read to resolve URL-composition and default tile-cache behavior. No application, emulator, dependency installation, code generation, migration, database opening, API request, login, upload, or synchronization was executed. Tests and analyzer/build commands were not run so the audit would not generate or change project artifacts. Historical statements that builds or tests passed were not reused as current results.

Evidence identifiers such as **[E01]** refer to the file-and-symbol index in Section 13. All endpoint descriptions below mean **what this client calls or expects**, not an independently verified Laravel implementation.

## 2. Architecture and state management

### 2.1 Structure

```text
main()
  -> WidgetsFlutterBinding.ensureInitialized()
  -> await BackendOverrideService.initialize()
  -> ProviderScope
     -> ElikasApp / MaterialApp.router
        -> SplashPage -> /home
        -> GoRouter StatefulShellRoute.indexedStack
           -> resident tabs and nested staff pages

Presentation page / widget
  -> Riverpod provider or notifier
     -> domain use case (where present) / repository interface
        -> repository implementation
           -> Dio remote datasource -> expected Laravel REST API
           -> Drift local datasource -> resident or staff SQLite database

Supporting paths:
  preferences -> SharedPreferences
  token, cached identity, staff DB key -> FlutterSecureStorage
  GPS -> Geolocator
  tiles -> OpenStreetMap / Esri through flutter_map
  calls/maps/sharing -> operating-system applications
```

The feature directories generally separate `presentation`, `domain`, and `data`. This is a feature-organized, layered architecture rather than a uniform use-case layer for every action. Resident centers, alerts, and maps have small use-case classes; several staff providers call repositories directly. The static hotline module does not need a remote datasource. [E01–E07, E16, E18, E24]

Riverpod provides dependency construction, asynchronous reads, session state, preferences, and invalidation after changes. Generated `@riverpod` providers coexist with `@Riverpod(keepAlive: true)` services such as databases and connectivity. `ConsumerWidget` and `ConsumerStatefulWidget` consume `AsyncValue` loading/data/error states. Forms, filters, selected events, search terms, busy flags, and map visibility also use widget-local state and `setState`. The source does not implement a Bloc or Redux state architecture. Most domain objects and JSON parsers are handwritten Dart; Freezed/JSON-generator dependencies do not establish their use in these workflows.

### 2.2 Dependencies actually relevant to execution

| Responsibility | Library / locked version where relevant | Observed use |
|---|---|---|
| State and dependency injection | `flutter_riverpod` 3.3.1; Riverpod code generation | Providers, notifiers, provider families, invalidation |
| Navigation | `go_router` 16.3.0 | Five persistent shell branches and nested/top-level routes |
| HTTP | `dio` 5.10.0 | Public GETs, authenticated staff reads/writes, multipart photo uploads |
| Structured local data | `drift` 2.31.0 | Three resident tables and seven staff tables |
| Native encryption library | `sqlcipher_flutter_libs` 0.6.8 | Keyed staff DB and unkeyed resident DB connections |
| Secret storage | `flutter_secure_storage` 11.0.0 | Token, cached session JSON, encryption key |
| Map rendering | `flutter_map` 8.3.1; `latlong2` | Tile layers, markers, polygons, map controls |
| Device integration | `geolocator`, `connectivity_plus`, `image_picker`, `url_launcher`, `share_plus` | GPS, network interfaces, center photo selection, dialer/maps/share sheet |
| Preferences | `shared_preferences` | Locale, theme, notification preference, hotline favorites, timestamps, developer URL override |
| Present but not connected to a product workflow | `flutter_local_notifications`, `routing_client_dart`, `power_geojson`; `web_socket_channel` used only by an unreferenced `ReverbClient` | Do not claim notifications, route computation, or a live Reverb subscription from dependency presence |

`pubspec.yaml` declares Dart `>=3.12.0 <4.0.0`, Flutter localization generation, Public Sans fonts, and image/icon assets. Android is the only platform host present in the audited project; iOS, web, and desktop deployment are **UNVERIFIED**. The Android application ID is `com.example.elikas_mobile`, while the map tile user-agent string is `com.cswdo.elikas_mobile`. This is a configuration inconsistency, not proof of a map failure. [E40]

## 3. Actors, navigation, and access boundaries

### 3.1 Actors

| Actor | Implemented access |
|---|---|
| Resident / visitor without login | Public information, maps, nearest centers, hotlines, preferences, resident cache management |
| Authenticated staff member | Staff workspace, family registration and records, EC Board, center management, manual queue synchronization |
| Staff with `role == 'barangay_official'` | Same workspace; own-barangay defaults or filters in selected screens; center editing allowed by the client only when `createdBy == session.id` |
| Other authenticated role strings | No distinct administrator dashboard or explicit role allowlist; `canEditCenter` returns true for non-`barangay_official` roles |
| Laravel backend | Expected authentication, validation, authorization, storage, aggregate counts, and restricted response shaping; server implementation unverified |
| Device / external applications | GPS, secure storage, local database, dialer, map application/browser, native share sheet |

### 3.2 Actual route map

| Route | Page / entry behavior |
|---|---|
| `/splash` | `SplashPage`; replaced by `/home` after initialization |
| `/home` | `HomePage` — bottom tab 1 |
| `/alerts` and `/alerts/:id` | `AlertsListPage`, `AlertDetailsPage` — bottom tab 2; details stay in the branch |
| `/map` | `EvacuationMapPage` — bottom tab 3 |
| `/emergency-hotlines` | `EmergencyHotlinesPage` — bottom tab 4 |
| `/settings` | `SettingsPage` — bottom tab 5 |
| `/settings/offline-data` | `OfflineDataManagementPage` |
| `/settings/dev` | `DevSettingsPage`; hidden tap entry and release-mode refusal |
| `/settings/staff` | `StaffWorkspacePage`, wrapped by `StaffAuthGuard` |
| `/settings/staff/login` | `StaffLoginPage`; also rendered directly by the guard |
| `/settings/staff/register-family` | `FamilyRegistrationFormPage` |
| `/settings/staff/pending-registrations` and `/:localId` | Pending family list and detail |
| `/settings/staff/all-evacuees` | `RegisteredFamiliesPage`; UI label is Evacuees |
| `/settings/staff/registered-families` | `RegisteredFamiliesOverviewPage`; pending/synced sections and full family registration entry |
| `/settings/staff/evacuation-centers`, `/add`, `/:id` | Staff center list, add form, authenticated center detail |
| `/settings/staff/ec-board` and `/:id` | Board center selector and `EcBoardPage` |
| `/centers` and `/centers/:id` | Public center list/detail outside the bottom-navigation shell |
| `/nearest-center` | `NearestCenterPage` outside the shell |

Center edit, location picker, EC Board Add Evacuee, pending EC entry detail/edit, and family detail sheets use `Navigator.push` or modal sheets with objects already available in memory. They are not separate named GoRouter routes. Invalid public center/alert IDs show an invalid-link page. The EC Board route converts an invalid ID to `0` instead. There is no global router authentication redirect. [E02, E19]

**Access limitation:** `StaffAuthGuard` checks for a non-null session, not an allowed role. Most staff entry pages use it, but `EcBoardPage` and `AddEvacueeFormPage` do not wrap their own content with this guard. `PendingEcEntryDetailPage` does use the guard. Guarded parent routes do not constitute an explicit guard in the child implementation. Direct navigation/session-change behavior needs runtime reproduction; this finding does not establish that unauthenticated server writes succeed. [E19, E25–E27]

## 4. Feature classification matrix

| Feature | Classification | Actual scope / limitation |
|---|---|---|
| Layered Flutter architecture and Riverpod state | VERIFIED IMPLEMENTED | Feature modules, repositories, providers, local/remote datasources |
| Resident access without login | VERIFIED IMPLEMENTED | Default startup enters public Home |
| Five resident navigation tabs | VERIFIED IMPLEMENTED | Home, Alerts, Map, Hotlines, Settings |
| Home dashboard | VERIFIED IMPLEMENTED | Alert status, center/alert counts, nearest preview, clock, safety tips, refresh |
| Staff email/password login and logout | VERIFIED IMPLEMENTED | REST token flow and local session clearing |
| Cached staff-session restoration | VERIFIED IMPLEMENTED | Stored token plus cached identity used after non-401 restoration failure |
| Complete role-based navigation/security | PARTIALLY IMPLEMENTED | Session guard plus limited role checks; no role allowlist; EC Board guard gaps |
| Public center list, search, status filters, sorting | VERIFIED IMPLEMENTED | Name/occupancy/capacity sorting over loaded data |
| Capacity and available-slot presentation | VERIFIED IMPLEMENTED | Server occupancy; available slots clamped to zero; missing occupancy omitted |
| Guaranteed current availability | UNVERIFIED | Depends on server correctness, freshness, and cache provenance |
| Center detail and facilities checklist | VERIFIED IMPLEMENTED | Detail from center list; facilities fetched independently |
| Offline facilities checklist | NOT IMPLEMENTED | No facilities table/cache |
| Center photo display and offline reuse | VERIFIED IMPLEMENTED | Files cached after a successful photo download |
| Nearest centers | VERIFIED IMPLEMENTED | GPS, server query, local straight-line fallback |
| Map markers, hazard polygons, layer controls | VERIFIED IMPLEMENTED | OSM/Esri base layers; status/hazard filters; location and fit controls |
| General-purpose GeoJSON support | PARTIALLY IMPLEMENTED | Hazard parser assumes a Polygon exterior ring; holes/MultiPolygon unsupported |
| External map handoff | VERIFIED IMPLEMENTED | `geo:` or Google Maps search URL |
| In-app routing / turn-by-turn / safest route | NOT IMPLEMENTED | No route calculation or hazard-routing integration |
| Public alerts list/details/search/filter/share | VERIFIED IMPLEMENTED | Limited recent feed and cache; native share sheet |
| Foreground alert updates | VERIFIED IMPLEMENTED | 60-second polling and latest-ID banner |
| Push-notification setting | PARTIALLY IMPLEMENTED | Preference saved; delivery behavior not connected |
| OS/background push or local alert delivery | NOT IMPLEMENTED | No plugin initialization, permission flow, FCM token flow, or show call |
| Live Reverb alert subscription | PARTIALLY IMPLEMENTED | Low-level client exists but has no application call site |
| SMS sending, receiving, subscriptions, OTP, gateway | NOT IMPLEMENTED | Contact numbers and alert metadata are not SMS integration |
| SMS delivery by the intended backend | UNVERIFIED | No backend/gateway source or execution evidence |
| Emergency hotline directory/copy/favorites/dialer | VERIFIED IMPLEMENTED | 12 bundled entries; dialing is a device handoff |
| Current accuracy of hotline numbers | UNVERIFIED | No external validation performed; one duplicated number noted in Section 9 |
| EC Board live/saved counts | VERIFIED IMPLEMENTED | Center/event snapshot, age/sex, sectoral groups, separate pending figures |
| Rapid Add Evacuee | VERIFIED IMPLEMENTED | New/existing household, sex, age group, sectoral/head answers |
| Full named-family registration | VERIFIED IMPLEMENTED | Event/barangay/displacement, named members, contact validation |
| Local duplicate-name warning | VERIFIED IMPLEMENTED | Cached-name warning only; no uniqueness enforcement |
| Pending queue review/edit/delete/manual sync | VERIFIED IMPLEMENTED | Owner-scoped queues and status/error metadata |
| Crash-safe/exactly-once queue synchronization | PARTIALLY IMPLEMENTED | Ambiguous-response branch exists; timeout/recovery/dependency gaps remain |
| Registered family/evacuee browsing | VERIFIED IMPLEMENTED | Server list, owner-scoped summary cache, live member records |
| Individual checkout and Mark Family Departed | VERIFIED IMPLEMENTED | Online per-person POSTs; batch can partially succeed |
| Offline checkout / transfer destination registration | NOT IMPLEMENTED | A checkout reason does not register a destination stay |
| Center create/edit/status/location/photo | VERIFIED IMPLEMENTED | Online authenticated form; creator-based edit visibility for officials |
| Center deletion / facilities editing | NOT IMPLEMENTED | No mobile delete or facility-write workflow |
| Event lookup/selection/closed-event board handling | VERIFIED IMPLEMENTED | Existing events only |
| Event create/update/activate/close management | NOT IMPLEMENTED | No event write datasource or page |
| Resident cache viewing and refresh/clear controls | VERIFIED IMPLEMENTED | Resident rows and timestamps; limits described below |
| Fully offline maps and all center/staff details | PARTIALLY IMPLEMENTED | Cached geometry/photos/summaries; tiles and several detail operations conditional |
| Automatic background upload on reconnect | NOT IMPLEMENTED | Reconnect refreshes reads; staff writes remain manual |
| Laravel REST client integration | VERIFIED IMPLEMENTED | Concrete endpoints, bearer token, multipart forms, result/error mapping |
| End-to-end compatibility with deployed Laravel | UNVERIFIED | Server source and live verification unavailable |
| Secure token/key storage and SQLCipher wiring | VERIFIED IMPLEMENTED | Configured in source; operational at-rest encryption unverified |
| Comprehensive local data protection | PARTIALLY IMPLEMENTED | Shared/private-field cache and recovery-backup issues |
| Loading, empty, retry, offline states | VERIFIED IMPLEMENTED | Used broadly; not complete coverage of every thrown exception |
| English/Filipino/Bikol locale selection and theme | VERIFIED IMPLEMENTED | Preferences and app-wide rebuilds |
| Complete Bikol translation | PARTIALLY IMPLEMENTED | 575 of 583 message values equal English; review markers present |
| Live weather | NOT IMPLEMENTED | Explicit weather-unavailable widget |

## 5. Detailed text-based workflows A–I

### A. Resident Main Navigation

**Classification:** VERIFIED IMPLEMENTED.  
**Actor:** Resident or any visitor; staff can also use the resident surface.  
**Starting action:** Open the application.  
**Inputs:** Saved locale/theme/notification preferences; selected tab/action; network state; optionally location permission.

```text
START: launch application
  -> initialize Flutter bindings
  -> load developer backend override in non-release builds
  -> create ProviderScope and MaterialApp.router
  -> show /splash
  -> in parallel: load preferences and wait minimum 1.8 seconds
       preference failure -> retain defaults and continue
  -> replace splash with /home
  -> load center list, alert summary, connectivity, nearest preview
       each section branches independently: loading / data / empty / error
  -> select Home | Alerts | Map | Hotlines | Settings
       GoRouter changes branch; each branch keeps its navigation stack
  -> optional top-level center list or nearest-center page
       return with Back, or navigate to a selected tab
END: resident remains on selected information screen
```

Home combines center count and alert count; it does not perform its own backend dashboard aggregation. The clock uses Philippine-time utilities. Emergency status derives from the latest fetched alert/severity and distinguishes loading and unavailable states. Safety tips and the weather-unavailable notice are local content. Home’s nearest preview requests GPS when initialized; declining GPS does not require login or block the other public features.

Home’s current quick actions are View All Evacuation Centers and Refresh Data. Nearest Center is also reachable through its preview. Alerts, map, hotlines, and settings are permanent tabs rather than the older six-action Home layout described in changelogs.

**Branches and interactions:** Refresh calls `OfflineDataOverview.syncAll()`; tab navigation itself does not authenticate. Settings can persist locale/theme, toggle the disconnected notification preference, open offline-data management, or enter staff access. Resident REST requests use the public client without the staff token. The shell listens for connectivity restoration and invalidates resident datasets and EC Board count reads; it does not upload staff queues.

**Output:** Selected resident screen, asynchronously loaded information, contextual loading/error/cached presentation.  
**Ending state:** Active tab and its navigation stack retained while switching tabs; no resident account/session created.  
**Relevant source:** `main`, `ElikasApp.build`, `SplashPage._bootstrap/_initializeApp`, `appRouter`, `AppShell._handleConnectivityChange`, `HomePage._handleQuickRefresh/build`, `NearestCenterPreview._requestPosition`, preference notifiers. [E01–E04, E09, E15, E16]

### B. Resident Evacuation Center Viewing

**Classification:** VERIFIED IMPLEMENTED for list/details/nearest; offline detail is limited.  
**Actor:** Resident without login.  
**Starting action:** Tap Home’s center action, an alert’s View Evacuation Centers button, a nearest result, or a map center.  
**Inputs:** Optional search text, status, sort order, center ID; GPS latitude/longitude for nearest results.

```text
START: open /centers
  -> allEvacuationCentersProvider
  -> allEvacuationCentersSnapshotProvider -> GetAllEvacuationCenters
  -> repository checks backend reachability
       reachable -> GET public/evacuation-centers
         parse list -> merge/upsert resident cache -> record sync time
         success -> return current response with isFromCache=false
         exception -> attempt cache
       unreachable -> attempt cache
       cache has rows -> return saved list with isFromCache=true
       cache empty -> failure / Retry screen
  -> locally search name/address/barangay
  -> optionally filter status and sort
       zero matches -> no-results state
  -> select center -> /centers/:id
       invalid numeric link -> invalid-link screen
       center absent from loaded list -> not-found state
       center present -> overview, photo, location, facilities
END: center details displayed or an actionable failure state
```

Status filters are All, `active`, `full`, `on_standby`, and `closed`. Sorts are name ascending, occupancy percentage descending with missing values last, and capacity descending. Status is supplied by the server. Color additionally uses occupancy thresholds of 75% and 95%; with no occupancy data or a closed status, the presentation is neutral. These colors are not an independently validated emergency-capacity rule.

Details resolve the core center object through `centerById()` from the full-list provider. A public detail GET separately reads facilities and can backfill a missing photo URL. Capacity defaults to zero when absent in supported parsers; nullable occupancy is not treated as zero. Available slots are `max(capacityPersons - currentOccupancy, 0)` when occupancy exists. There is no reservation, bed allocation, or admission guarantee.

Facilities render a fixed 19-type checklist, quantities/availability, and recorded concerns/needs. A missing facility record is shown as not recorded; an empty facilities response is an empty state. Facilities have independent loading/error handling and are not persisted. Photos download to app-document files when online, fall back to a matching saved file, and otherwise show a placeholder.

**Nearest-center branch:**

```text
Open nearest preview or /nearest-center
  -> LocationService.getCurrentPosition()
       services off / denied / permanently denied / GPS failure -> message
       permanently denied -> option to open app settings on nearest page
       position available -> GET public/evacuation-centers/nearest
                              ?latitude=...&longitude=...&limit=10
         success -> display server ordering, first result emphasized
         unavailable -> rank cached centers with coordinates by local distance
  -> choose a result -> center details
  -> Get Directions -> external map handoff
END: nearby list/detail, external application, or location/data error
```

The local fallback computes geographic straight-line distance and does not filter out full/closed centers or avoid hazards. It is not driving distance. `View on Map` navigates to `/map` without passing the selected center ID or destination coordinates; it does not guarantee that center is focused.

**API/local interactions:** Public list, nearest, and detail GETs; resident center table; photo files; sync timestamp preferences.  
**Output:** Center list/details, conditional capacity/occupancy, nearest ranking, or external map.  
**Ending state:** Information remains viewable to the extent it was cached; facilities/current availability may require reconnection.  
**Relevant source:** `EvacuationCentersListPage._visibleCenters/build`, `EvacuationCenterDetailsPage.build`, `NearestCenterPage._requestPosition`, `EvacuationCentersRepositoryImpl.getAllCenters/getNearestCenters/getCenterFacilities/refreshCenterPhotoIfMissing`, `EvacuationCenter.availableSlots`, `centerById`, `CenterPhotoCacheService`, `openDirections`. [E05–E10]

### C. Resident GIS/Hazard Map Access

**Classification:** VERIFIED IMPLEMENTED for rendering and controls; PARTIALLY IMPLEMENTED for general GeoJSON/offline map coverage.  
**Actor:** Resident without login.  
**Starting action:** Select Map tab or View on Map.  
**Inputs:** Map pan/zoom, search text, base-layer choice, center-status/hazard-type visibility, optional current-location request.

```text
START: open /map
  -> mapDataProvider -> GetMapData -> MapRepositoryImpl.getMapData()
  -> reachable?
       yes -> GET public/gis/map-data
              read data.evacuation_centers.features
              read data.hazard_areas.features
              parse -> cache centers and hazard boundaries -> sync timestamp
              failure -> cache fallback
       no -> cache fallback
  -> neither centers nor hazards available?
       no saved data after failure -> error with Retry
       successful empty response -> empty map-data message
       data present -> FlutterMap
  -> start at first center having coordinates, otherwise Ligao fallback
  -> render street/satellite tiles + hazard polygons + center markers
  -> optional controls:
       toggle centers/hazards/my-location; filter statuses/hazard types
       search visible centers -> select -> focus if coordinates exist
       tap marker -> center information sheet
       locate me -> permission/GPS branches -> marker and recenter
       fit visible -> fit centers, polygon vertices, optional location
  -> center sheet: details or external Get Directions
END: selected map view, center sheet/detail, or external map application
```

Base layers are OpenStreetMap street tiles and Esri World Imagery. Hazard colors recognize flood, landslide, lahar, storm surge, and volcanic danger zone; unrecognized types use gray. Polygons carry their area-name label. The layer sheet offers the recognized types/statuses present in the data. There is no hazard editing, geofenced alerting, risk prediction, or navigation algorithm.

GeoJSON coordinates are converted from longitude/latitude to `LatLng(latitude, longitude)`. Hazard parsing takes only the first polygon ring. It does not branch on geometry type, render interior holes, or flatten a MultiPolygon. The map datasource casts geometry to a non-null map, so missing/null geometry can fail the entire fetch even though center model coordinates themselves are nullable.

**Offline distinction:** Hazard geometry and center rows are persisted by the application. `TileLayer` uses its default network provider. The locked `flutter_map` 8.3.1 dependency has built-in native tile caching; previously visited fresh tiles can be reused. This is incidental package behavior, not a user-selected offline region, guaranteed tile archive, or part of E-LIKAS cache-management statistics. Device tile availability was not tested.

**API/local interactions:** Public GIS GET; resident tables; OSM/Esri tile services; Geolocator; `geo:`/Google Maps search handoff.  
**Output:** Interactive geographic view and conditional saved overlays/tiles.  
**Ending state:** Current layer/filter/search state remains in the map widget while retained; no route is calculated or stored.  
**Relevant source:** `EvacuationMapPage`, `_MapViewState._locateMe/_selectCenter/_fitToVisible/_showLayersSheet`, `MapRemoteDatasource.getMapData`, `MapRepositoryImpl.getMapData`, `HazardAreaModel.fromGeoJsonFeature`, `buildHazardPolygons`, `mapBaseTileLayer`, `openDirections`. [E09–E12, E42]

### D. Resident Alert Viewing

**Classification:** VERIFIED IMPLEMENTED for REST viewing, local cache, sharing, and foreground banner; notification delivery limitations apply.  
**Actor:** Resident without login.  
**Starting action:** Select Alerts, tap a Home alert, or tap View on a new-alert banner.  
**Inputs:** Search text, severity filter, sort order, alert ID, refresh/share action.

```text
START: open Alerts
  -> alertsListProvider -> GetAlerts(limit=20)
  -> repository checks connection
       online -> GET public/alerts?per_page=20
                 parse feed -> upsert cache -> record sync time
       request/cache-write failure or offline -> use cached alerts
       no cached alerts after failure -> error with Retry
  -> show list / successful-empty state
  -> locally search title/message/type; filter severity; sort
  -> tap alert -> alertByIdProvider -> GetAlertById
       cached ID found -> return cached item immediately
       not cached and online -> fetch first recent page with per_page=50
           ID found -> show it
           absent -> “no longer in recent feed” failure
       not cached/offline -> not-available-offline failure
  -> show title, message, severity/type, date, optional event/sender/recipients
  -> optional Share -> native share sheet with text
  -> optional View Evacuation Centers -> /centers
END: alert details, share handoff, center list, or error state
```

Severity filters are `mandatory`, `advisory`, `info`, and `all_clear`. Sorting supports newest, oldest, and severity; date sorting groups by Today/Yesterday/date. The parser accepts `date_sent` or `created_at`, nested/flat event and sender names, and recipient summary/count metadata. Dates are converted to device local time; this is distinct from Home’s explicit Philippine-time clock.

The Home summary separately requests five alerts and uses the response total when available. The alert list does not paginate past its first 20 requested items. Detail retrieval does not call a dedicated alert-detail endpoint. “Latest” assumes the first server item is latest; the mobile client does not filter `status == sent`, active periods, expiry, audience, or barangay. The expected public endpoint must enforce its public-alert contract.

**Foreground update branch:** `AppShell` starts one 60-second timer, invalidates summary/list, and seeds its known latest ID from the first resolved summary. Subsequent different latest IDs show a MaterialBanner with Dismiss and View. Background/inactive lifecycle states stop the timer; resume refreshes reachability/alerts and restarts it. The remembered ID is session memory, not a durable read/unread record. The code compares “different ID,” not strictly “newer alert”; changes in which item is first can also produce a banner.

**API/local interactions:** Public alert feed GETs; resident alerts table; sync timestamps; native share sheet. No SMS, FCM, or local-notification delivery occurs.  
**Output:** Recent public alert content and optional in-app announcement.  
**Ending state:** User remains on alert content or a linked screen; notification setting does not alter this workflow.  
**Relevant source:** `AlertsListPage._visibleAlerts/_handleRefresh`, `AlertDetailsPage._shareAlert`, `AlertsRemoteDatasource.getAlerts/_parseAlertsPage`, `AlertsRepositoryImpl.getAlerts/getAlertById`, `AppShell._startPolling/_handleAlertsSummaryChange/_showNewAlertBanner`, `NotificationPreferenceNotifier`. [E02, E13–E15]

### E. Staff Login and Dashboard

**Classification:** VERIFIED IMPLEMENTED login/session/workspace; PARTIALLY IMPLEMENTED role enforcement.  
**Actor:** Staff member with a backend account.  
**Starting action:** Settings -> Staff Access / Staff Dashboard.  
**Inputs:** Email and password for first login; saved token and session for restoration.

```text
START: open /settings/staff
  -> StaffAuthGuard watches StaffAuth
  -> restoreSession()
       no stored token -> no session -> show login
       token exists -> GET auth/me with Bearer token
          valid response -> parse/cache identity -> authenticated content
          HTTP 401 -> delete token and cached identity -> login
          another failure -> cached identity available?
              yes -> cached staff session / offline-session notice
              no -> no session -> login
  -> on login: require nonempty email/password
  -> check connectivity
       offline -> error; cannot perform first login
       online -> POST auth/login {email, password}
          success -> read data.token + data.user
                     secure-store token and identity; update StaffAuth
          failure -> show returned/mapped error
  -> normal submit calls Navigator.maybePop()
  -> Settings reflects signed-in identity; Staff Dashboard opens workspace
END: authenticated workspace or login/error state
```

The login form trims email, obscures password with a visibility toggle, and blocks the normal submit button while submitting. There is no resident login, account creation, password reset, OTP, biometric unlock, or role chooser. Successful authentication is accepted regardless of the returned role string. When login is rendered in-place by the guard, its `maybePop()` can return to Settings; documentation should not promise an unconditional redirect to the workspace.

Workspace displays staff identity, role display name, barangay, and a cached-session notice when applicable. Actions are EC Board, Add Evacuation Center, Manage Evacuation Centers, Evacuees, Registered Families, and Logout. Full family registration is reached from Registered Families rather than a separate current dashboard action. The workspace is a navigation hub, not a statistics dashboard.

**Logout branch:** Confirmation -> best-effort `POST auth/logout` -> delete local token and cached identity even if the network call fails -> set session null -> navigate to Settings. The encryption key, cached staff records, and queues remain. Server-side token revocation after an offline/failed logout is unverified.

**API/local interactions:** Auth login/me/logout; secure storage; Riverpod session state. Session restoration does not enforce a local expiry age on the cached identity.  
**Output:** Staff session and workspace actions or a sign-in error.  
**Ending state:** Staff can enter authorized UI paths, subject to backend authorization; logout removes local credentials but preserves data.  
**Relevant source:** `StaffLoginPage._submit`, `StaffAuth.build/login/logout`, `StaffAuthRepositoryImpl.login/restoreSession/_cachedSessionOr/logout`, `StaffSession.fromJson/isBarangayOfficial`, `StaffAuthGuard.build`, `StaffWorkspacePage`, `_StaffWorkspaceBody._confirmLogout`. [E17–E19]

### F. Staff Evacuee Registration — full family workflow

**Classification:** VERIFIED IMPLEMENTED; synchronization resilience is partial.  
**Actor:** Signed-in staff, including a staff member with a restored cached session.  
**Starting action:** Workspace -> Registered Families -> Register Family, or edit a pending family registration.  
**Inputs:** Event; home barangay; optional home address; inside/outside-center displacement; center when inside; family 4Ps flag; one or more members.

Each member captures first/middle/last name, suffix, sex, date of birth, civil status, contact number, PWD and PWD type, pregnancy, lactation, solo-parent, indigenous-person and 4Ps flags, and head-of-family selection. The date picker ranges from 1900 to today. The first added member defaults to head; staff can select another head. [E20, E21]

```text
START: open guarded family form
  -> load barangays, events, centers through staff lookup repositories
       online -> staff GET lists -> replace cached lookup tables
       unavailable -> cached lookups, or lookup-unavailable fields
  -> default official's home barangay for a new form, still editable
  -> choose event whose status != closed
  -> select inside_center / outside_center
       inside -> require a center
       outside -> clear center selection
  -> add/edit/remove members; designate exactly one head
  -> optional cached duplicate-name warning after 400 ms debounce
       warning -> staff may inspect match and still continue
  -> submit -> validate head, every contact number, required draft fields
       invalid -> inline contact/server errors or validation message; remain
  -> check connectivity
       offline -> enqueue UUID draft or update existing local draft
                  status=pending; ownerStaffId=current staff
                  show Saved Offline and leave form
       online -> POST families/register with draft JSON
          success -> expect data.id; delete edited pending item if any
                     invalidate pending/family views; success; leave
          422 -> inline field errors; retain form
                 if editing queued item, persist it as needsAttention
          ambiguous receive timeout -> save needsAttention record
                                      show review warning; leave
          other mapped failure -> message; remain on form
END: server-confirmed registration, queued draft, review-needed item,
     or an unsaved form awaiting correction
```

Client submission validation requires an event, barangay, displacement type, center for inside-center registration, at least one member, exactly one head, nonblank first/last names, date of birth, and a PWD type for members marked PWD. The form additionally requires **every member’s contact number** to match `09` plus nine digits or `+639` plus nine digits. Copy From Head can reuse the head’s number. The validity helper is called on trimmed input, while serialization preserves the stored member string; backend trimming behavior should be checked.

The center dropdown iterates all returned lookup centers; its `barangayId` input does not filter that list. Duplicate checks compare normalized names against cached registered-family member names, using exact full-name or first-and-last-token matches. They neither query a server duplicate endpoint nor prevent duplicates, and they do not cover uncached people or every pending registration.

**Pending review branch:** Registered Families presents Not Synced and Synced sections. A pending detail shows payload summary, members, timestamps, status, attempts, error category, and field errors. Staff can edit or confirm deletion unless the item is marked syncing. Discard confirmation protects unsaved form changes; it is not continuous draft autosave. Local deletion does not undo a record that the server may already have accepted.

**API/local interactions:** Authenticated lookups; `POST families/register`; encrypted `PendingFamilyRegistrations`; owner-scoped `CachedFamilies` for duplicate warnings; manual sync service described in H.  
**Output:** A full household payload and named-member records expected to be created by Laravel, or a persistent local queue item.  
**Ending state:** Success is server-confirmed only when an expected response arrives; “Saved Offline” means pending, not registered remotely.  
**Relevant source:** `_FamilyRegistrationFormBodyState._submit/_contactNumberErrors/_scheduleDuplicateCheck/_setHeadOfFamily`, `FamilyRegistrationDraft.isSubmittable/toJson`, `FamilyMemberDraft.toJson`, `FamilyMemberCard`, `isValidPhMobileNumber`, `PendingQueueRepositoryImpl`, `FamilyRegistrationRepositoryImpl.submit`, pending detail edit/delete. [E20–E24]

### G. Staff EC Board Operations

**Classification:** VERIFIED IMPLEMENTED board/intake/pending operations; access and synchronization limitations apply.  
**Actor:** Staff entering through the guarded board center selector.  
**Starting action:** Workspace -> EC Board -> choose a center.  
**Inputs:** Center ID; evacuation event; intake answers; optional household search; Sync Now; pending-record edit/delete.

```text
START: open EC Board center selector
  -> load public center list; search name/barangay
  -> group own barangay first, followed by other barangays
  -> choose center -> /settings/staff/ec-board/:id
  -> read event lookup; default first non-closed event, else first event
  -> GET evacuation-centers/{id}/quick-count?evacuation_event_id=...
       success -> cache center/event snapshot and fetch time
       Dio failure -> cached snapshot if present, otherwise error/dashes
  -> display official/server counts and separate pending contribution
  -> choose event or pull to refresh reads
       closed event -> show closed-event explanation; no Add Evacuee action
       open event -> Add Evacuee available
  -> review local entries / add person / manually sync
END: current or last-known board plus this device's unsynced entries
```

The board header shows barangay, center, event, As of, cumulative/current families, cumulative/current persons, and 4Ps beneficiary families. Age/sex rows are infant, toddler, preschooler, school age, teenage, adult, senior citizen, unclassified, and the server’s total row. Unclassified total can include unknown sex through `total_count`. Sectoral rows are PWD, child-headed family, single-headed family, solo parent, pregnant women, lactating mothers, 4Ps beneficiary, and indigenous peoples. Sectoral groups overlap, so no summed sectoral total is displayed. The mobile client consumes these server totals; their backend calculation is not verified here.

Tables are stacked on a phone and placed side by side at widths of at least 720 logical pixels. Before a snapshot exists, unknown values render as dashes; a cached snapshot retains its saved As of timestamp. Pending age/sex and sectoral contributions appear as `+N` in a separate section and are not added to confirmed totals. The pending breakdown follows the selected event; the entry-management list includes all events for that center, including needs-attention records.

**Rapid intake subworkflow:**

```text
Tap Add Evacuee
  -> select male/female and age bracket
  -> choose Existing household or New household
       Existing:
         GET center/{id}/families for selected event
         show families currently here; honor generic/redacted family rows
         network failure -> offer locally saved non-legacy families
         also offer pending full-family and pending new-household entries
         select remote family ID or local household reference
         optionally identify arriving head when no head is linked
       New:
         enter household/head name; choose home barangay explicitly
         optionally use center's barangay shortcut
         answer whether this person is head, single-headed household,
         or another head's sex/minor status as applicable
  -> optional per-person sectoral flags
       pregnant/lactating choices restricted to female UI selection
  -> show “will be recorded” summary
  -> validate event, sex, age, and household fields
  -> offline OR household has only local ID?
       yes -> enqueue/update pending EC entry and return
       no -> POST evacuation-centers/{centerId}/evacuees
          success -> expect top-level evacuee_id and data.id (family ID)
                     remove edited local record; refresh views; return
          mapped failure -> persist needsAttention with category/message
                            show message and return
END: one server-confirmed arrival, a queued person, or a review-needed entry
```

This intake is intentionally lighter than full family registration: it does not collect the arriving person’s full identity, birth date, or phone number. New-household name/head answers and demographic flags are not a completed named-member record. Placeholder members are recognized in later family-detail screens.

New-household home barangay has no automatic initial selection. An official working at another barangay’s center sees an explanatory note. The “families here” response can identify another barangay’s family generically; `FamilyHere.fromJson` hides names when `is_generic` is true. In offline fallback, the picker uses owner-cached family summaries, which are not filtered to prove an open stay at this particular center/event. Pending full-family options are likewise not center/event-filtered by `_filteredPending`.

Closed events with pending entries remain selectable for review; if no open event exists, past boards can still be viewed. An already selected event is retained. The board disables new intake for a closed selected event, but queued records can still be edited and synchronization relies on server rejection if an event has since closed. There is no current quick-count PUT call, manual totals editor, or board Quick Departure action.

**API/local interactions:** Public centers; staff event lookups; quick-count and families-here GETs; intake POST; encrypted quick-count cache and pending EC entries; shared manual sync service.  
**Output:** Server/saved board, separate local contributions, intake result, pending review, or sync result count.  
**Ending state:** Confirmed counts change when refreshed from the server; local additions alone do not alter them.  
**Relevant source:** `EcBoardCentersListPage._visibleCenters`, `EcBoardPage._ensureEventSelected/_runSync`, `_EcBoardBody.build/_openAddEvacuee`, `_PendingSection.build`, `AddEvacueeFormPage._submit/_pickExistingHousehold`, `EcBoardEntryDraft.isSubmittable/isReadyToSync/toJson`, `EcBoardRepositoryImpl`, `countPendingSectoral`. [E25–E28]

### H. Offline Features and Synchronization

**Classification:** VERIFIED IMPLEMENTED for specified cached reads and manual queues; PARTIALLY IMPLEMENTED as an application-wide offline guarantee.  
**Actor:** Resident or previously signed-in staff.  
**Starting action:** Use a screen without backend reachability; save a staff form offline; open Offline Data Management; tap Sync Now.  
**Inputs:** Existing caches/token/identity/lookups; new form data; connectivity; queue owner; manual sync choice.

```text
Resident offline read
  -> attempt ordinary repository read
  -> backend unavailable -> query local resident tables
       saved rows exist -> display cached information
       no rows -> offline-data-unavailable state
  -> bundled hotlines/preferences remain usable independently

Staff offline use
  -> stored token + cached session -> guarded staff content can restore
  -> use saved lookup lists/family summaries/board snapshots
  -> valid family or EC intake -> save encrypted pending record
  -> retain record across app restarts and logout

Manual staff synchronization
  -> user taps Sync Now
  -> check connection; if unavailable, stop with offline message
  -> suppress overlapping runs on the same StaffSyncService instance
  -> load current owner's pending full-family entries, oldest first
  -> each: check connection -> mark syncing -> submit
       success -> delete local item -> promote dependent household IDs
       401 -> restore pending with error; stop run for reauthentication
       422/403/ambiguous -> needsAttention; continue other items
       rate-limit/network/server failure -> pending for a later manual run
  -> then process owner's pending EC entries, oldest first
       unresolved local household dependency -> skip
       success for new household -> promote its local ID for dependents
       same status/error branches
  -> invalidate pending/board/family providers; show processed count
END: successful items removed; failures/review/dependencies remain local
```

Three sync entry points exist: all queues, full-family queue only, and EC queue only. The Registered Families overview uses family-only sync; the board AppBar uses all-queue sync; the board pending section uses EC-only sync. **EC-only sync processes the current staff member’s whole EC queue, not just the displayed center/event.** Reconnect, app startup, and background execution do not automatically submit these writes.

Local UUIDs are used for queue identity and household dependencies. They are not sent as backend idempotency keys. `processed` counts confirmed successful submissions, not attempts or a guarantee that all queued records synchronized. A queue item requiring attention must be reviewed; saving an edit changes it back to pending in repository logic. Needs-attention and syncing entries are excluded from normal pending queue selection.

**Resident cache-management subworkflow:** Settings -> Offline Data Management -> display resident record counts, estimated storage, and sync dates. Update All invalidates centers, alert summary/list, and map providers, then waits for centers, summary, and map. Clear Cached Data asks for confirmation, deletes resident center/alert/hazard rows and resident sync timestamps, and invalidates their providers. It does not clear staff records/queues/session/key, center photo files, or map-package tiles. Active providers can repopulate resident rows online after invalidation. [E33]

**Limits:** A fresh install has no remote-data cache. Offline first login is unavailable. Facilities, live family-member/stay detail, checkout, and center create/edit are not durable offline workflows. Validated forms save only on submit, not continuously. A resident refresh that returns cache can still report success. Interrupted `syncing` entries have no identified automatic reset/reconciliation path. See Section 9 before claiming crash-safe or exactly-once sync.

**Output:** Saved information, persistent pending items, freshness labels, or explicit unavailable/failure states.  
**Ending state:** Successful manual uploads are removed; unsent/review-needed data remains for the owner; server totals remain separate.  
**Relevant source:** Resident repositories/local datasources, `OfflineDataOverview.syncAll/clearCachedData`, `StaffSyncService.run/_runFamilyQueue/_runEcBoardQueue`, queue repository status methods, `StaffAuthRepositoryImpl.restoreSession`, `CenterPhotoCacheService`. [E06, E12–E14, E18, E22–E24, E27, E33–E37]

### I. API Communication and Error Handling

**Classification:** VERIFIED IMPLEMENTED for HTTP integration and mapped errors; PARTIALLY IMPLEMENTED for exhaustive exception/retry handling.  
**Actor:** Mobile screen/provider acting for resident or staff.  
**Starting action:** Data load, refresh, login, submit, checkout, or manual sync.  
**Inputs:** Configured base URL, relative path, query/body, optional photo, and stored staff token.

```text
START: page/provider requests data or a mutation
  -> choose public ApiClient or authenticated StaffApiClient
  -> compose base URL and endpoint
  -> for staff: read secure token and attach Authorization: Bearer ...
  -> issue Dio request with connection/receive limits and outer timeout
  -> response received?
       valid expected JSON -> parse model -> Result.Success / provider data
       HTTP/Dio error -> repository-specific handling
           resident reads -> cache fallback or failure
           staff writes -> mapStaffDioError -> typed Failure
           selected staff reads -> cache fallback (including some auth errors)
       other exception -> only caught where a broader catch exists
  -> presentation chooses data/loading/empty/error, inline validation,
     snackbar, cached snapshot, pending, or needsAttention
END: screen resolves OR an uncovered exception path requires recovery
```

The compiled default is `https://e-likasligao.online/api/v1/`, overrideable with `API_BASE_URL`. Non-release builds can persist a developer URL after seven About taps within the implemented tap-reset timing. Saving the override requests a full app restart; it does not rebuild already-created clients. The developer form saves trimmed text without URL validation. No override is read/applied in release mode. The configured production host was not contacted during this audit. [E03]

Public client has GET only. Staff client exposes GET, POST, PATCH, and PUT; current features do not use PUT. Normal Dio connection/receive timeouts are 10 seconds. GET has an outer 12-second timeout; staff writes normally have 15 seconds; center multipart uploads request a 45-second outer timeout but still retain Dio’s default connection/receive limits. No shared `Accept: application/json`, explicit send timeout, general retry/backoff, token-refresh flow, or global 401 logout interceptor is configured. [E04]

| Condition in `mapStaffDioError` | Result and typical treatment |
|---|---|
| HTTP 401 | `AuthFailure`; session restore clears credentials; queue run stops for reauthentication |
| HTTP 403 | `ForbiddenFailure`; show message or queue needsAttention |
| HTTP 404 | `ServerFailure` |
| HTTP 422 | `ValidationFailure` with normalized field-error map |
| HTTP 429 | `RateLimitFailure`; queued item returns to pending |
| HTTP 5xx | Generic `ServerFailure`; queued item returns to pending |
| Dio receive timeout | `AmbiguousWriteFailure`; queued write requires review |
| Connection/send/transform timeout | `NetworkFailure` |
| Connection/certificate/cancel/other Dio error | Mapped network/error message |
| Outer `Future.timeout` / malformed response / local DB exception | Not a `DioException`; several staff paths do not catch or normalize it |

The mapper is reused for reads, so a receive timeout during a GET can be labeled as an ambiguous write. The outer `.timeout()` does not pass a Dio cancellation token: expiration of the awaited Future is not proof the server did not receive or complete a request.

Resident `ApiResponse` parses `success`, `message`, and `data`, but remote datasources consume `data` without checking `success`. Many staff datasources cast straight to the expected envelope. A 200 response with `success: false`, HTML, malformed JSON shape, or wrong types is not uniformly handled. These contracts should be validated against Laravel fixtures rather than inferred from successful HTTP status alone.

**Output:** Parsed domain data or typed failure where covered.  
**Ending state:** Repository/provider/widget result; for queued writes, one of the states in H.  
**Relevant source:** `buildDio`, `ApiClient.get`, `StaffApiClient._authInterceptor/get/post/patch/put`, `LoggingInterceptor`, `ApiResponse.fromJson`, `mapStaffDioError`, individual repository try/catch blocks. [E03, E04, E41]

## 6. Additional implemented workflows

### 6.1 Staff evacuation-center management

**Classification:** VERIFIED IMPLEMENTED for online create/edit.  
**Actor:** Signed-in staff; creator restriction on edit visibility for barangay officials.  
**Starting action:** Workspace -> Add Evacuation Center, or Manage Evacuation Centers -> center -> Edit.  
**Inputs:** Barangay, name, type, address, status, optional latitude/longitude, capacities for families/persons, camp manager name/contact, optional camera/gallery photo.

```text
START: open management list
  -> read public all-center snapshot
  -> session has barangay name?
       yes -> show only centers with exactly that barangay name
       no -> show all centers
  -> search displayed centers by name/address/localized type
  -> open center -> authenticated GET evacuation-centers/{id}
       offline -> connection-required error (no detail fallback)
  -> determine Edit visibility
       barangay_official -> center.createdBy must equal session.id
       other role -> Edit shown
  -> edit or add form
       official -> own barangay prefilled/locked
       other staff -> barangay selector
       validate required name/type/address/barangay/status
       choose optional location/photo
  -> online?
       no -> show connection required; no queued center write
       yes -> create or update request
          success -> cache returned center, invalidate list/detail, return
          validation -> field errors; remain
          other mapped failure -> error; remain
END: server-confirmed center change, or unsaved form
```

Center types are school, covered court, church, barangay hall, gymnasium, and other. Status defaults to `on_standby`; active/full/on-standby/closed are selectable. Capacity/manager fields are optional in the mobile draft; the server is expected to validate detailed numeric and other constraints.

Location selection supports a map tap, current GPS, pasting a comma-separated latitude/longitude pair, clearing the point, and canceling without changing the form. The parser checks numeric conversion and coordinate ranges. There is no address geocoding. The picker can switch street/satellite layers. Photo selection requests a maximum 1920-by-1920 image at quality 85; image-picker exceptions do not have a dedicated catch in `_pickPhoto`.

Creation uses multipart POST, even without a photo. Editing without a new photo uses JSON PATCH. Editing with a photo uses multipart POST with `_method: PATCH`. Clearing existing coordinates while uploading a photo first sends a JSON PATCH to clear coordinates, then uploads the other changes. These are separate requests; the second failing does not roll back the first.

**API/local interactions:** Staff center GET/POST/PATCH; public center snapshot; lookup barangays; resident center cache; camera/gallery temporary image; GPS and tiles.  
**Output/ending state:** Saved center metadata/photo, or a form awaiting correction/reconnection. No center-delete API or facilities-management UI exists.  
**Relevant source:** `StaffEvacuationCentersListPage._visibleCenters/_refresh`, `StaffEvacuationCenterDetailPage`, `canEditCenter`, `_EvacuationCenterFormBodyState._submit/_chooseLocation/_pickPhoto`, `CenterLocationPickerPage`, `parseCoordinates`, `EvacuationCenterDraft`, staff center repository and remote datasource. [E31, E32]

### 6.2 Registered families, individual checkout, and family departure

**Classification:** VERIFIED IMPLEMENTED for browsing and online checkout.  
**Actor:** Signed-in staff.  
**Starting action:** Workspace -> Evacuees or Registered Families -> family card.  
**Inputs:** Family ID; one or more checked-in member IDs; checkout reason; confirmation.

```text
START: open family list
  -> GET families, page size 100, following data.meta.last_page
       success -> replace current owner's cached summaries
       Dio failure/offline -> owner's cached summaries if any
  -> Evacuees: group by barangay, then sort named families
  -> Registered Families: separate pending and synced sections
  -> tap family -> detail sheet
       show cached/list summary immediately
       GET families/{id} for members and open evacuation records
          failure/offline -> show connection/error notice and saved names
          success -> identify each member's latest record with date_out=null
  -> individual Check out OR Mark Family Departed
       no open stay -> checkout action not offered
       individual -> choose reason -> confirm -> POST member check-out
       family -> select checked-in members (initially all) and one reason
                 confirm -> sequential POST for each selected member
  -> refresh family record and family list
       all success -> success message
       batch failures -> successful count and per-member failure list
END: confirmed departures for successful requests; other members unchanged
```

Checkout reasons are `returned_home`, `transferred`, and `other`. No free-text “other” note, transfer destination, arrival at another center, or offline checkout queue is submitted. “Mark Family Departed” is a client-side series of individual requests, not a transactional family-wide endpoint. The loop continues after mapped per-member failures. Uncaught exceptions can still interrupt it.

Cached family summaries include names and descriptive information, not the full current evacuation-record list. Member placeholder and legacy-bulk markers are handled in the live detail UI. Checkout invalidates family record/list providers, but does not directly invalidate the EC Board quick-count or resident center snapshot, so those views may need their own refresh.

**API/local interactions:** Staff families list/detail; `POST evacuees/{id}/check-out` with `{status: reason}`; owner-scoped family summary cache and timestamp.  
**Output/ending state:** Updated member-stay presentation and partial/all-success feedback. Backend authority still determines the real stay state.  
**Relevant source:** `RegisteredFamiliesRemoteDataSource.fetchAll/fetchOne/checkOut`, `RegisteredFamiliesRepositoryImpl.getAll/getRecord/checkOut/_toRecordMember`, `registeredFamiliesGrouped`, `showRegisteredFamilyDetailSheet`, `_MemberRow._checkOut`, `_RegisteredFamilyDetailSheet._markFamilyDeparted`, `_MarkFamilyDepartedConfirmDialogState._run`. [E29, E30]

### 6.3 Emergency hotlines

**Classification:** VERIFIED IMPLEMENTED; number accuracy UNVERIFIED.  
**Actor:** Resident or staff.  
**Starting action:** Select Hotlines tab.  
**Inputs:** Hotline choice; Call, Copy, or favorite toggle.

```text
START -> load 12 compiled hotline entries and saved favorite names
      -> display national-emergency priority card, favorites, categories
      -> favorite: update Riverpod state and SharedPreferences
      -> copy: Clipboard.setData -> confirmation snackbar
      -> call: launch tel: URI with whitespace-free number
           launch returns false -> could-not-open-dialer snackbar
           launch succeeds -> device dialer takes over
END: number/favorite available, clipboard populated, or dialer opened
```

The directory can be viewed without internet. Completing a call depends on the dialer and telephone service; the Flutter application does not directly place or verify a call. No SMS URI, SMS composer, emergency-message transmission, location sending, or SOS dispatch is implemented. Sharing an alert through the general share sheet does not establish an E-LIKAS SMS delivery feature.

**API/local interactions:** No Laravel API; static Dart data; preferences; clipboard; device dialer.  
**Relevant source:** `EmergencyHotlinesPage.build`, `emergencyHotlines`, `Hotline.dialableNumber`, `HotlineFavorites.build/toggle`, `HotlineCard._handleCall/_handleCopy`, `PriorityHotlineCard`. [E38]

### 6.4 Preferences and developer configuration

**Classification:** VERIFIED IMPLEMENTED for locale/theme/favorites; notification behavior partial.  
**Actor:** Resident/staff; developer for hidden non-release configuration.  
**Starting action:** Settings -> Language/Appearance/Push Notifications; or non-release About tap sequence.  
**Inputs:** Supported locale, system/light/dark theme, boolean preference, optional backend URL.

Processing updates provider state and writes the preference. `ElikasApp` watches locale/theme and rebuilds `MaterialApp.router` without replacing the router. Bikol app strings are supplied by `app_bcl.arb`; unsupported Flutter framework localization falls back to English. Locale options being present does not mean the Bikol catalog is translated: most values are English with pending-review annotations. Dates and raw backend message content are not automatically translated. Developer URL changes persist and take effect for newly constructed clients after restart; release mode refuses the screen/override.

**Output/ending state:** Saved preferences and updated UI; notification preference has no delivery effect.  
**Relevant source:** `SettingsPage`, language/theme selector sheets, `AppLocale`, `AppThemeModeNotifier`, `NotificationPreferenceNotifier`, `DevSettingsPage._save/_clear`, `BackendOverrideService`. [E03, E15, E16, E19]

## 7. Laravel REST API contract inventory

### 7.1 Request paths and expected responses

Paths below are relative to the configured `/api/v1/` base. Authenticated datasource strings commonly begin with `/`; public constants do not. **This is not by itself a lost-API-prefix bug:** installed Dio 5.10.0 `RequestOptions.uri` concatenates `baseUrl + path` and normalizes duplicate slashes. A malformed developer base URL can still be a problem. [E04, E42]

| Method and relative endpoint | Caller / input | Expected response and use |
|---|---|---|
| GET `public/evacuation-centers` | Public center list | Envelope `data` is a list of flat center objects |
| GET `public/evacuation-centers/nearest` | `latitude`, `longitude`, `limit=10` | Same list parser; optional distance/occupancy fields |
| GET `public/evacuation-centers/{id}` | Facilities and missing-photo backfill | `data.facilities` list and/or `data.photo_url`; can be separate requests |
| GET `public/gis/map-data` | Map repository | `data.evacuation_centers.features` and `data.hazard_areas.features` GeoJSON collections |
| GET `public/alerts` | `per_page=1` probe; 5 summary; 20 list; 50 detail search | `data` array or nested paginator with `data` list and `total`/`meta.total` |
| POST `auth/login` | `{email, password}` | `data.token` and `data.user` |
| GET `auth/me` | Bearer token | `data` is user with id/name/email/role, optional display name and nested barangay |
| POST `auth/logout` | Bearer token | Body not needed; local session cleared despite request failure |
| GET `barangays` | Staff lookup | `data` list, id/name |
| GET `evacuation-events` | Staff lookup | `data` list, id/name/status/start_date/end_date |
| GET `evacuation-centers` | Staff registration lookup | `data` list; center id/name, nested barangay, status |
| POST `families/register` | Full draft described below | `data.id` must be integer family ID |
| GET `families` | `per_page=100`, `page=1..50` | `data.data` list and `data.meta.last_page` |
| GET `families/{id}` | Live family-member detail | `data` with members, head, flags, each member’s evacuation_records |
| POST `evacuees/{id}/check-out` | `{status: returned_home|transferred|other}` | Successful request sufficient; body ignored |
| GET `evacuation-centers/{id}` | Staff center detail | `data` center with nested barangay, creator ID, capacities, manager info/photo |
| POST `evacuation-centers` | Multipart center fields and optional `photo` | `data` staff center model |
| PATCH `evacuation-centers/{id}` | JSON fields; nullable values can clear fields | `data` staff center model except dedicated clear-location call ignores body |
| POST `evacuation-centers/{id}` with `_method=PATCH` | Multipart edited fields plus photo | `data` staff center model |
| GET `evacuation-centers/{id}/quick-count` | `evacuation_event_id` | `data` totals, age_groups, age_groups_total, sectoral_groups, optional update metadata |
| GET `evacuation-centers/{id}/families` | `evacuation_event_id` | `data` list of family IDs, generic/name/head indicators and counts |
| POST `evacuation-centers/{id}/evacuees` | Rapid-intake draft | Integer **top-level** `evacuee_id` plus **`data.id`** family ID |

No mobile endpoint call was found for SMS, notifications/device tokens, alert creation, event writes, center deletion, facilities writes, route calculation, or quick-count updates. `StaffApiClient.put` being defined does not imply such a workflow. [E04–E15, E18, E20–E32]

### 7.2 Payload details that matter for backend alignment

**Full family registration:** `evacuation_event_id`, `barangay_id`, `home_address` (trimmed, blank -> null), `displacement_type`, optional `evacuation_center_id`, family `is_4ps_beneficiary`, and `members[]`. Each member serializes `first_name`, `middle_name`, `last_name`, `suffix`, `sex`, `date_of_birth`, `civil_status`, `contact_number`, `is_pwd`, `pwd_type`, `is_pregnant`, `is_lactating`, `is_solo_parent`, `is_indigenous_person`, `is_4ps_beneficiary`, and `is_head_of_family`.

**Rapid EC intake:** `evacuation_event_id`, `sex`, `age_bracket`, and `household_mode`. Existing household sends `family_id` and optionally `head_is_self: true`. New household sends `family_name`, `barangay_id`, `head_is_self`, nullable `is_single_headed`, and, when someone else is head, `head_sex`/`head_is_minor`. Only selected per-person sectoral flags are emitted as true. Local household UUID references are deliberately not serialized as `family_id` until promoted to a remote integer ID.

**Center fields:** `barangay_id`, `name`, `type`, `address`, `latitude`, `longitude`, `capacity_families`, `capacity_persons`, `camp_manager_name`, `camp_manager_contact`, `status`, plus multipart `photo` as applicable. JSON edit includes nulls; multipart fields omit null/blank optional values. A server that treats an omitted multipart field as “retain existing” will not clear capacity/manager fields during a simultaneous photo edit.

**Quick-count response:** The client expects `families_cumulative`, `families_now`, `persons_cumulative`, `persons_now`, `beneficiaries_4ps`; age groups keyed by the wire values in Section G; `age_groups_total.male_count/female_count/total_persons`; and sectoral groups keyed by `sectoral_group`. Missing numeric fields default to zero, so an incompatible response can display convincing zeros instead of a contract error.

### 7.3 Backend verification boundary

Comments name Laravel controllers/resources/request classes and several historical backend copies. Those comments help identify intended contracts but are not the current PHP implementation. In particular, claims about Sanctum configuration, exact policy scope, public visibility, idempotency support, event closure rules, cumulative-count calculations, SMS broadcasting, and transaction semantics cannot be certified from this Flutter repository. The concrete incompatibility risks and mobile-internal contradictions below are evidence-backed; whether a particular deployed Laravel version triggers them remains unverified.

## 8. Local storage, offline coverage, and security

### 8.1 Data stores

| Store | Contents / ownership | Lifecycle and security observations |
|---|---|---|
| `elikas_resident.sqlite`, schema 1 | `EvacuationCenters`, `Alerts`, `HazardAreas` | Unkeyed SQLite; centers/alerts/hazards upsert by server ID; not an authoritative replacement snapshot |
| `elikas_staff.sqlite`, schema 6 | Lookup barangays/events/centers; cached families; pending families; pending EC entries; cached quick counts | SQLCipher key supplied by secure storage; shared DB file for the device |
| Staff lookup tables | Names/IDs/statuses/dates | Replaced per successful lookup load; not scoped to a staff owner |
| `CachedFamilies` | Family ID + owner staff ID composite key; home address, head name, member names/count, barangay/center labels, 4Ps, head/legacy flags | Replaced per owner; retained on logout |
| `PendingFamilyRegistrations` | UUID, owner, JSON payload, summary, timestamps, attempts, status, category/message, field errors | Retained until manual deletion or confirmed sync |
| `PendingEcBoardEntries` | UUID, owner, center/event, sex/age, household references/name/barangay, flags/head answers, error/status metadata | Retained until deletion/confirmed sync; dependency references promoted after queued household success |
| `CachedQuickCounts` | Center ID + event ID composite key; count JSON and cached time | No staff owner in key; cache fallback available after any caught Dio error |
| Secure storage | `elikas.staff.sanctum_token`, `elikas.staff.cached_session`, `elikas.staff.drift_encryption_key` | Token/identity cleared on logout; DB key retained |
| Preferences | `elikas.locale`, `elikas.themeMode`, `elikas.notificationsEnabled`, `elikas.hotlines.favorites`, resident/staff sync timestamps, migration flags, developer URL | Small metadata, not encrypted staff registration payloads |
| `evacuation_center_photos` in app documents | Downloaded center images named by center ID and URL hash | Unencrypted public-photo files; superseded files for that center evicted after new download |
| `flutter_map` native tile cache | Package-managed tile files/metadata in platform cache | Default incidental cache; not listed/cleared by the E-LIKAS offline page |
| Recovery backups | `elikas_staff.pre_recovery.<timestamp>.sqlite`, unreadable backups, temporary recovery file | Original file preserved; a plaintext source backup remains plaintext |

`SecureTokenStorage` creates 32 cryptographically random bytes represented as 64 hex characters for the staff database key. `openSqlCipherDatabase` applies `PRAGMA key` before normal staff access and installs the SQLCipher Android native library override. This verifies implementation wiring, not the bytes of an actual installed database. No database was opened or examined in this audit. [E34–E37]

### 8.2 Offline coverage matrix

| Operation | First use with no connection | After prior successful use/cache |
|---|---|---|
| Open app, tabs, preferences, safety tips | Available | Available |
| Hotline directory/copy | Available from bundled data | Available; call depends on telephone service |
| Center list and basic details | No remote data yet | Cached records available; resident screens have limited freshness labeling |
| Center facilities | Unavailable | No persistent facilities cache; an already alive provider may retain memory temporarily |
| Center photos | No downloaded photo | Matching local file available if previously downloaded |
| Nearest centers | Requires GPS and center data | GPS plus cached coordinates permit straight-line ranking |
| Hazard polygons and center markers | No geometry/center cache | Stored geometry/centers available |
| Map base tiles | No guaranteed coverage | Conditional package cache; unvisited/stale/evicted tiles may need network |
| Alert list/details | No feed cache | Previously cached items available; details can be stale |
| First staff login | Unavailable | Cached session can restore if token/identity still stored |
| Full family registration | No first-login/lookups | Can queue after prior staff sign-in and usable lookup cache |
| Rapid EC intake | No first-login/events | Can queue using saved events and household options |
| EC Board confirmed totals | No saved snapshot | Last successful center/event snapshot with saved As of |
| Registered family summaries | No saved family data | Current owner’s cached summaries/names |
| Live member stays / checkout | Unavailable | Still requires a current connection; no durable checkout queue |
| Add/edit center and staff center detail | Unavailable | Remains online-only |
| Manual staff sync | Unavailable | Waits for a connection and user action |

### 8.3 Implemented protections and their limits

Implemented protections include separate public/staff HTTP clients, bearer-token storage outside ordinary preferences, a keyed staff DB, owner filtering for family caches and queues, masked login password, no stored password, and debug-only request logging that avoids deliberately logging Authorization headers or full request payloads. Staff logout retains queues so unsent records are not deliberately discarded.

These do not amount to complete data isolation. Rich staff center responses, including camp manager name/contact and creator ID, are cached in the **unencrypted resident database**. Staff quick counts and lookups are not owner-scoped. Local legacy family-queue rows with no owner are claimed by the first current staff repository that accesses them. No local biometric/PIN gate, session maximum offline age, encrypted photo cache, custom backup-exclusion configuration, certificate pinning, or app-owned immutable audit log was found. Debug logging still prints server-provided error messages/exceptions and diagnostic exception details, whose sensitivity is not guaranteed by the logger. These are observed limits, not a claim that credentials are currently exposed. [E04, E18, E22, E27, E32, E34–E37, E40]

## 9. Inconsistencies, defects, and backend-alignment risks

“Confirmed” below means the source condition is present. Impact described as a risk or possible outcome was not reproduced on a device. Priorities indicate what most affects documentation accuracy, access control, and reliable registration.

### 9.1 High-priority source findings

1. **Notification UI promises more than the implementation.** `SettingsPage` labels a switch as Push Notifications; `NotificationPreferenceNotifier` only persists a boolean. `AppShell` never reads it, `flutter_local_notifications` is not imported/initialized, and `ReverbClient` has no consumer. Describe foreground REST polling and in-app banners. Do not claim enabled/disabled OS notification delivery. **Confirmed.** [E02, E15, E19]

2. **Staff guard coverage and role checks are incomplete.** `StaffAuthGuard` accepts any non-null session. `EcBoardPage` and `AddEvacueeFormPage` lack their own guard, although the selector and pending detail are guarded. `canEditCenter` allows every other role string, not a named staff-role allowlist. Restore-cache behavior has no maximum age. Audit direct navigation and expired/changed-role sessions against server policies. **Confirmed client conditions; runtime access exposure and server enforcement UNVERIFIED.** [E17–E19, E25–E27, E32]

3. **Private center fields cross into the unencrypted resident cache.** Staff center GET/create/update calls `_cacheAuthoritative`, which writes manager name/contact and creator ID through `EvacuationCentersLocalDatasource` to `ResidentDatabase`. Public center UI does not normally display these manager fields, but storage separation is still incomplete. Keep public and restricted storage projections distinct in a future change. **Confirmed.** [E07, E32, E34]

4. **Outer timeout and parse failures can bypass staff write handling.** `StaffApiClient` wraps Futures with `.timeout`; registration/EC/center/check-out repositories generally catch only `DioException`. A `TimeoutException`, cast failure after an accepted write, file error, or DB error can escape; submit/sync UI often has no `finally` reset. An item marked `syncing` may remain there. Catching receive timeouts in the mapper does not cover these paths. **Confirmed exception-coverage gap; failure outcome inferred from control flow.** [E04, E20, E24, E27, E29, E32, E41]

5. **No queue recovery for interrupted `syncing` state.** Queue selection includes only `pending`; review edit/delete is disabled for `syncing`. No startup reconciliation/reset of that state was found. Process termination or an uncaught submit exception can leave an entry unavailable to normal sync/review. Blindly retrying would also be unsafe without checking the server. **Confirmed missing recovery path; interruption scenario not executed.** [E22–E24, E26, E27]

6. **Dependency promotion is not consistent across all submission paths.** `StaffSyncService` promotes local household references after queued family/new-household success. Submitting an edited pending family or new-household EC entry directly online deletes its local row without calling promotion or consuming the returned family ID for dependents. Dependent EC entries can then retain an unresolved local ID and be skipped indefinitely. Deleting a referenced pending household has no identified dependent-entry check. In the sync service itself, deletion precedes promotion without a shared transaction, leaving an interruption window. **Confirmed control-flow gaps.** [E20, E22, E24, E26, E27]

7. **Cache fallback can hide authorization failure.** Session restoration uses cached identity for non-401 errors, including 403. Registered-family listing catches any Dio exception and can return the owner cache. Board quick counts fall back after any Dio exception, including 401/403, and their key has no owner. Document saved data as saved data and verify which cached content is permitted after revocation/account changes. **Confirmed client behavior; actual authorization policy UNVERIFIED.** [E18, E27, E29, E35]

8. **Staff DB recovery is incomplete for the current schema.** Plaintext recovery copies lookups, cached families, and pending family registrations, but does not copy pending EC entries or cached quick counts. It renames the original plaintext file to a retained backup. Unreadable-file recovery backs up the file and allows a new database rather than recovering its content. Migration flags alone are not proof that unsynced records become accessible again; no active Isar bridge was found in the current application. **Confirmed code; actual device recovery not exercised.** [E35–E37]

### 9.2 API and data-consistency risks

9. **Strict and inconsistent response-shape assumptions.** Public centers require flat `barangay`; staff centers require nested `barangay`. Public `address` is cast as non-null String despite the domain field being nullable. Coordinates are numeric casts, not numeric-string conversion. GIS properties require occupancy values and geometry maps. Families require `data.data` and `data.meta.last_page`; ordinary paginator `last_page` at another level is not followed. Rapid intake requires top-level `evacuee_id`. These are precise backend contract checks, not proof the deployed API violates them. **Confirmed expectations; deployment match UNVERIFIED.** [E06, E07, E12, E27, E29]

10. **No uniform success-envelope validation.** A parsed `success` flag is ignored by public remote callers; staff callers directly cast `data`. Missing quick-count fields become zero, and missing GIS collections become empty lists. An incompatible HTTP-200 response can look like empty/zero data or become a parsing error. Add contract fixtures before asserting server compatibility. **Confirmed.** [E04, E12, E14, E27, E41]

11. **Pagination limits can hide records.** Alerts load 20 items, Home five, and uncached detail searches only the first 50 recent items. Registered families stop after 50 pages of 100 requested records, without indicating truncation. Missing `data.meta.last_page` ends family retrieval at the current page. Cached replacement then contains only the fetched subset. **Confirmed.** [E14, E29]

12. **Public-data caches retain deleted/withdrawn records.** Centers, alerts, and hazard areas are upserted without removing IDs absent from later successful responses. An empty live alert feed does not purge older cached alerts. A later offline read may show withdrawn alerts, removed centers, or outdated hazards. Lookup and owner-family caches do use replacement, so the issue is not universal. **Confirmed.** [E06, E12, E14, E22, E29, E34]

13. **Different center response shapes can overwrite or conceal data.** Nearest responses can omit occupancy, and center merging copies incoming occupancy nulls over existing values. The public parser ignores staff fields, while merging retains certain old optional fields. GIS caching treats photo URL as authoritative, so an omitted/null GIS photo can erase a cached URL. Public list and GIS loads can touch the same rows without producing one coherent snapshot. **Confirmed merge rules; depends on received response shapes.** [E06, E07, E12]

14. **Freshness and refresh success are not consistently factual.** Home sets its last-updated time when the center provider yields data, including cache fallback, rather than using the server-fetch timestamp. Alerts/Map banners receive `lastUpdated: null`; public center list/detail/nearest do not surface snapshot provenance. `OfflineDataOverview.syncAll` considers a successful cache fallback to be success and waits for the five-alert summary rather than explicitly awaiting a complete alerts-list fetch. Do not describe every success banner or Home timestamp as proof of a new server synchronization. **Confirmed.** [E05, E11, E13, E16, E33]

15. **Resident center refresh targets a derived provider.** The center list refreshes `allEvacuationCentersProvider`; its actual network/cache fetch lives in `allEvacuationCentersSnapshotProvider`. Recomputing a derived provider does not itself invalidate an already retained upstream snapshot. Center-detail Retry similarly invalidates `centerById`. The staff center list correctly invalidates the snapshot. A retained snapshot may prevent the resident gesture from making a fresh GET; verify runtime behavior. **Confirmed dependency/invalidation mismatch; observed network outcome UNVERIFIED.** [E05–E07, E31]

16. **“Online” measures one backend route, not all internet services.** Reachability probes `public/alerts?per_page=1`. Dio’s default rejected statuses throw before the code’s `statusCode > 0` branch, so a responding server with 401/404/429/500 may still be treated as offline. An alert-endpoint problem can prevent login/center writes guarded by connectivity, while tiles or other endpoints might be reachable. Passive checks use a five-second result cache and two-failure threshold; a stream badge and immediate operation check can briefly differ. **Confirmed.** [E09]

17. **Photo edits have different null semantics and a partial-update window.** JSON edits send null optional fields; multipart photo edits omit them. Only cleared coordinates get a separate null-clearing PATCH. Clearing a capacity/manager field while choosing a photo may retain the old backend value. Clearing coordinates plus upload is not atomic. **Confirmed payload difference; backend omitted-field behavior UNVERIFIED.** [E31, E32]

18. **Event eligibility and family selection are loosely coupled.** `isOpen` means anything other than the exact string `closed`, so unknown statuses count as open. Full-registration edits can retain an event ID no longer in the open-event dropdown. EC offline family fallback and pending-full-family choices are not restricted to the selected center/event. Server validation must resolve stale, closed, or mismatched cases. **Confirmed; exact Laravel acceptance rules UNVERIFIED.** [E20–E22, E26, E28]

19. **Manual sync scope is broader than the visible board.** EC-only sync has no center/event argument; it processes all current-owner pending EC entries. A board-level action can therefore upload records from another center or event. The local pending UI is narrower than the synchronization scope. **Confirmed.** [E24–E27]

20. **Checkout does not immediately refresh occupancy consumers.** Successful checkout refreshes family record/list providers but not center snapshots or board quick-count providers. Counts can remain unchanged until their next explicit/reconnect refresh. There is no live occupancy subscription. **Confirmed.** [E02, E29, E30]

21. **No client-side idempotency protocol.** Queue UUIDs are local-only; no idempotency header/key is sent. Ambiguous receive-timeout handling reduces one retry risk but cannot guarantee exactly-once submission. Server 5xx/network errors are eligible for a later manual retry even when server commit status may be uncertain. Source comments assert the backend lacks idempotency; this audit can verify only the absence of a client protocol. **Client absence confirmed; backend protection UNVERIFIED.** [E04, E21, E24, E28]

### 9.3 Other documentation and configuration discrepancies

22. **Storage reporting is an estimate, not measured disk usage.** `OfflineCacheService._rowSizeBytes` returns `row.toString().length`; it is neither UTF-8 byte length nor SQLite file/page size. Photos, staff DB, and tile cache are omitted. “Clear Cached Data” only clears resident rows/timestamps and may trigger online repopulation. **Confirmed.** [E33]

23. **Bikol localization is mostly an English fallback.** All three ARB catalogs have 583 message keys. 575 Bikol values exactly match English; pending-review annotations explain the intention. Claim locale selection with partial Bikol content, not complete local-language translation. **Confirmed catalog comparison; translation quality not independently assessed.** [E16]

24. **Two hotline entries share a number.** The PNP–Ligao and LCWD entries both contain `0998 598 5928` in the bundled list. This is a data-consistency flag, not a finding about which service owns the number. Verify the directory with its owner before calling it an externally verified official list. **Duplicate confirmed; correctness UNVERIFIED.** [E38]

25. **Backend changes do not isolate cached data or credentials by environment.** Developer override changes the base URL, while token, cached session, DB names, queue owners/IDs, and cache keys remain the same. Switching environments can mix identically numbered records or reuse an existing token with the new configured backend. The form has no scheme/path validation. Release override is disabled, but compile-time URLs can also vary. **Confirmed configuration/storage design; cross-environment scenario not executed.** [E03, E04, E34–E36]

26. **Platform/release readiness is not established by source presence.** Only Android host files are present. Main manifest declares internet, foreground location, and optional camera; no explicit POST_NOTIFICATIONS or SMS permission is declared there. Release signing falls back to the debug signing configuration if `key.properties` is absent. That fallback is source behavior, not a determination of how an existing APK was signed. Device encryption, production signing, installability, and OS integrations remain UNVERIFIED. [E40]

## 10. Implemented versus historical, disconnected, and absent features

| Historical/intended claim | Current evidence | Documentation treatment |
|---|---|---|
| “Resident-only, no auth surface” in pubspec/app comments/handoff | Staff auth, writes, queues, management and checkout exist | Replace with public resident mode plus staff workspace |
| Four tabs or placeholder feature folders in older notes | Five real shell tabs and 12 feature modules | Use current router for navigation diagrams |
| Isar/Isar Plus as current persistence | Current repositories use Drift and SQLCipher/SQLite; no current Isar dependency | Describe Drift; treat Isar remarks as historical |
| Alerts lack details/caching | Both implemented now | Document feed limits and cache-first details |
| Hotline Call is a placeholder; seven entries | `tel:` launch is wired; 12 entries present | Describe dialer handoff and current bundled directory |
| Known connectivity row permanently stale | Current service broadcasts passive corrections, replays latest value, and refreshes on resume; test source covers related cases | Do not present the old handoff issue as an observed current bug |
| Push notification toggle | Boolean preference only | PARTIALLY IMPLEMENTED setting; delivery NOT IMPLEMENTED |
| Reverb real-time alerts | Unreferenced `ReverbClient` scaffold | PARTIALLY IMPLEMENTED scaffold, no live app subscription |
| Route guidance dependency / route wording | No routing-client calls or in-app route rendering | NOT IMPLEMENTED; external map handoff is the implemented behavior |
| Full offline maps | Geometry cache and default package tile cache; no region download | PARTIALLY IMPLEMENTED offline map access |
| Editable quick counts / Quick Departure | Current board is read-only server totals plus Add Evacuee/pending operations; old quick-count-edit table deleted in schema upgrade | Do not include removed operations in an as-built diagram |
| Complete event management | GET lookup and selection only | Event creation/closure NOT IMPLEMENTED in mobile |
| SMS-related alert delivery | No SMS integration call sites | NOT IMPLEMENTED in mobile; backend SMS UNVERIFIED |
| Live weather | `WeatherUnavailablePlaceholder` | NOT IMPLEMENTED |

The README is still the generic Flutter starter text. `SETUP.md`, `CLAUDE_HANDOFF.md`, and the three changelogs describe different historical stages. Comments claiming verification against particular Laravel copies do not replace an available backend contract. Features absent here should be described as outside the current mobile implementation; do not assert that each is a committed future plan without a separate approved specification.

## 11. Recommended Chapter 3 diagrams and page layouts

Use separate figures with one question per page. The specifications below are recommendations for documenting this implementation, not extra application features. Keep resident and staff write workflows separate so readers can follow the offline branches.

### 11.1 Page rules

- Use A4 portrait with approximately 25 mm margins for activity/state/navigation diagrams: usable area about 160 × 247 mm. Use landscape for a sequence/component diagram only when needed: about 247 × 160 mm.
- Target 10.5–12 pt diagram labels and 9–10 pt figure notes; use the capstone’s required caption style. Avoid reducing an oversized diagram until labels become unreadable.
- Limit a main activity figure to about 8–12 process nodes and two or three decisions. Move error details into a separate error/queue-state figure. Use numbered off-page references when a workflow spans figures.
- Use top-to-bottom flow, short verb phrases, labeled Yes/No arrows, and at most three swimlanes on a portrait page. Include a small legend for server-confirmed data versus locally pending data.
- Show the backend as an external expected API boundary. Mark unverified backend internals explicitly. Do not draw an SMS gateway, push delivery, route engine, background sync worker, or event-management write as implemented components.

### 11.2 Diagram set

| Figure | Purpose / content | Readable layout |
|---|---|---|
| 3.1 System context | Resident, staff, E-LIKAS mobile, expected Laravel API, GPS/OS apps, tile providers | Portrait; app centered, actors left, external services right; 7–9 nodes |
| 3.2 Mobile component architecture | Presentation, Riverpod, domain/repositories, Dio, two databases, preferences/secure storage | Landscape; three columns for UI/state, repositories/services, API/storage |
| 3.3 Resident navigation | Splash -> Home; five tabs; centers/nearest/details as secondary destinations | Portrait; five tabs in a compact grid; Settings -> staff as one off-page connector |
| 3.4 Resident data-viewing activity | Select list/map/alerts -> remote read -> cache fallback -> display/error | Portrait; common read flow; annotate dataset differences outside nodes |
| 3.5 Staff authentication activity | Stored token? -> me -> valid/cache/401; login; workspace/logout | Portrait; Device UI, Auth repository, API/secure storage swimlanes |
| 3.6 Full family registration activity | Lookup -> household/member input -> validation -> online submit/offline enqueue | Portrait; 10–12 nodes; exception branches refer to Figure 3.9 |
| 3.7 EC Board/intake activity | Center/event -> board snapshot -> closed? -> existing/new household -> intake/queue | Portrait; split board-read and intake into 3.7a/3.7b if more than 12 nodes |
| 3.8 Manual synchronization sequence | User -> UI/provider -> StaffSyncService -> local queue -> REST API | Landscape; five lifelines; family-first loop then EC loop and dependency promotion |
| 3.9 Queue state diagram | Pending, Syncing, Needs Attention, Deleted after success; failure labels | Portrait; 4 states plus start; explicitly annotate missing crash recovery |
| 3.10 Local storage/data model | Resident tables and staff tables, owner keys, local/remote household references | Landscape; two boxes for the two databases; only important columns |
| 3.11 Checkout activity | Load live stays -> select member(s)/reason -> confirm -> individual POST loop -> partial result | Portrait; one sequential loop; no fictitious atomic family checkout |
| 3.12 Deployment/network diagram | Android app, Laravel base URL, tile services, local stores, dialer/map handoff | Portrait; one phone boundary, separate remote-services boundary |

A shorter Chapter 3 can use Figures 3.1–3.3, 3.5–3.9, with checkout and storage in appendices. A use-case diagram can substitute for Figure 3.1, but split resident and staff use cases into two pages if their labels become crowded.

### 11.3 Text layouts ready to convert into figures

**Resident read activity:**

```text
Start
  |
Choose information screen
  |
Check backend reachability
  | Yes                   | No
GET dataset               |
  | success               |
Parse + save cache        |
  |                       |
Display live data         |
                          v
GET failure ----------> Read cache
                          | rows exist      | empty
                       Display saved     Show unavailable
                          \                 /
                              End
```

Use a note beside the diagram: alert details are cache-first; board totals try the remote call directly; facilities and live member stays do not follow this common durable-cache flow.

**Manual queue state:**

```text
Save offline / save reviewed draft
              |
           PENDING <-------- retry-later network/429/5xx or auth stop
              |                                      ^
      user taps Sync Now                             |
              v                                      |
           SYNCING ----------------------------------+
              | success                 | 422 / 403 / ambiguous
              v                         v
    Delete local row              NEEDS ATTENTION
    + promote dependents                 |
                                  staff reviews/edits
                                        |
                                      PENDING
```

Add two callouts: “Unresolved local household reference: remain pending and skip” and “Interruption during syncing: no automatic recovery path identified.” Do not add an automatic reconnect arrow or an exactly-once guarantee.

**EC Board data separation:**

```text
GET center + event quick count ---> Confirmed / Last-known board
                    |               As of = successful fetch time
                    v
             Saved count snapshot

Local pending EC entries --------> Separate +N contribution section
                    |
             Manual Sync Now
                    |
            successful server write
                    |
              refresh board GET
```

For the storage diagram, label references as application-level ID relationships. The Drift tables do not declare relational foreign-key constraints for these links. Do not present the mobile cache schema as the Laravel database ERD.

## 12. Verification performed and remaining acceptance evidence

### 12.1 Performed in this audit

- Inventoried all first-party feature modules, routes, API call sites, data stores, and Android integration declarations.
- Traced the nine requested workflows from UI through providers/repositories to remote/local operations, plus center management, checkout, hotlines, and settings.
- Inspected implementation and historical documentation separately; checked absence of SMS/notification/routing call sites rather than inferring features from dependencies.
- Checked localization key/value coverage, current declared/locked dependencies, presence of generated `part` targets, and installed Dio/map dependency behavior where needed.
- Reviewed test declarations and relevant fixtures/expectations as intended behavior evidence. No test was executed, and no passing result is claimed.
- Compared SHA-256 hashes of all 297 tracked files before and after the audit: no changed or missing tracked file. Git reports only this new report; staged and unstaged tracked diffs are empty. This audit did not open an application database or execute its recovery/migration code.

### 12.2 Existing test coverage

The 11 test files cover connectivity-state corrections/order/replay; staff “My Evacuation Centers” filtering and cache labels; EC Board layout, last-known time, pending-data separation, closed events, new-household home barangay, other-barangay notices, generic families, head answers, and per-person sectoral flags; and individual/family checkout selection, confirmation, and partial failure. Some tests exercise Drift through in-memory executors. Their presence supports design intent, not proof that the full app or a real Laravel server passes today. [E39]

No dedicated integration-test directory, current live API contract suite, or device evidence was found for the complete login/registration/offline-sync lifecycle, native encryption, camera/gallery permission behavior, map handoff, hotline calls, full resident alert flows, or release installation. Existing build artifacts and handoff claims were not treated as substitutes.

### 12.3 Evidence to obtain before stronger capstone claims

1. Match every Section 7 endpoint and response envelope against current Laravel routes/resources/requests and sanitized fixtures. Confirm status/severity/age/sectoral wire values and pagination metadata.
2. Verify staff role restrictions, creator policies, generic-family redaction, revoked tokens, direct routes, and cached access after role/account changes.
3. Exercise a first offline launch, cached offline launch, login restoration, form save, reconnect without upload, manual sync, needs-attention review, and cross-center sync scope.
4. Test timeout-after-server-commit, raw outer timeout, malformed successful response, killed app during syncing, parent/dependent household edits, and deletion of a referenced household.
5. Inspect encryption and backups on a test device with synthetic records, including legacy plaintext recovery and current EC pending rows. Do not use real resident records as test fixtures.
6. Verify capacity/photo/null-coordinate behavior and stale counts after registration/checkout; test hazard Polygon/MultiPolygon/missing geometry and withdrawn alerts/centers.
7. Validate actual hotline data with its owner and obtain local review of Bikol translations. Verify narrow-screen/font-scale layouts and native handoffs on the intended Android devices.

These are recommended future validation activities, not work performed or project changes made during this read-only audit.

## 13. Source evidence index

Paths are relative to the project root unless explicitly marked as installed dependency sources. Methods listed against a page may reside in that page's private `State`/body class; the workflow references identify those classes where useful. Generated `.g.dart` files provide Riverpod/Drift wiring and are not a separate feature implementation.

### 13.1 Bootstrap, resident features, and shared services

- **[E01] Application startup:** [main.dart](lib/main.dart), [app.dart](lib/app/app.dart), [splash_page.dart](lib/app/splash/splash_page.dart). `main`, `ElikasApp.build`, `_SplashPageState._bootstrap/_initializeApp`; initialization, preferences, splash delay, and public entry.
- **[E02] Navigation and foreground alerts:** [app_router.dart](lib/app/router/app_router.dart). `appRouter`, `AppShell`, `_AppShellState`, `_InvalidLinkPage`; route definitions, shell branches, lifecycle handling, `_startPolling`, `_handleConnectivityChange`, `_handleAlertsSummaryChange`, `_showNewAlertBanner`.
- **[E03] Backend configuration:** [env.dart](lib/core/env/env.dart), [backend_override_service.dart](lib/core/env/backend_override_service.dart), [dev_settings_page.dart](lib/features/settings/presentation/pages/dev_settings_page.dart), [api_endpoints.dart](lib/core/constants/api_endpoints.dart). `Env`, `BackendOverrideService`, `DevSettingsPage`, `ApiEndpoints`; base URL selection, initialization/save/clear, release checks, public endpoint strings.
- **[E04] HTTP infrastructure:** [api_client.dart](lib/core/network/api_client.dart), [staff_api_client.dart](lib/core/network/staff_api_client.dart), [dio_factory.dart](lib/core/network/dio_factory.dart), [network_interceptors.dart](lib/core/network/network_interceptors.dart), [api_response.dart](lib/core/network/api_response.dart). `ApiClient.get`, `StaffApiClient.get/post/patch/put/_authInterceptor`, `buildDio`, `LoggingInterceptor`, `ApiResponse.fromJson`; headers, timeouts, logging, response envelope.
- **[E05] Resident center pages:** [evacuation_centers_list_page.dart](lib/features/evacuation_centers/presentation/pages/evacuation_centers_list_page.dart), [evacuation_center_details_page.dart](lib/features/evacuation_centers/presentation/pages/evacuation_center_details_page.dart), [nearest_center_page.dart](lib/features/evacuation_centers/presentation/pages/nearest_center_page.dart), [evacuation_center_card.dart](lib/features/evacuation_centers/presentation/widgets/evacuation_center_card.dart). `EvacuationCentersListPage`, `_visibleCenters`, `EvacuationCenterDetailsPage.build`, `NearestCenterPage`, `_requestPosition`; filters, sorting, detail actions, nearest results, refresh behavior.
- **[E06] Center read/cache processing:** [evacuation_centers_repository_impl.dart](lib/features/evacuation_centers/data/repositories/evacuation_centers_repository_impl.dart), [evacuation_centers_remote_datasource.dart](lib/features/evacuation_centers/data/datasources/evacuation_centers_remote_datasource.dart), [evacuation_centers_local_datasource.dart](lib/features/evacuation_centers/data/datasources/evacuation_centers_local_datasource.dart), [get_all_evacuation_centers.dart](lib/features/evacuation_centers/domain/usecases/get_all_evacuation_centers.dart), [get_nearest_evacuation_centers.dart](lib/features/evacuation_centers/domain/usecases/get_nearest_evacuation_centers.dart). `EvacuationCentersRepositoryImpl.getAllCenters/getNearestCenters/getCenterFacilities/refreshCenterPhotoIfMissing`; remote list/nearest/detail, local merge/upsert, fallback and distance ordering.
- **[E07] Center state and representations:** [evacuation_centers_provider.dart](lib/features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart), [evacuation_center_model.dart](lib/features/evacuation_centers/data/models/evacuation_center_model.dart), [evacuation_center.dart](lib/features/evacuation_centers/domain/entities/evacuation_center.dart), [evacuation_centers_snapshot.dart](lib/features/evacuation_centers/domain/entities/evacuation_centers_snapshot.dart). `allEvacuationCentersSnapshot`, `allEvacuationCenters`, `centerById`, `nearestEvacuationCenters`, `centerFacilities`, `centerPhotoRefresh`; JSON/GeoJSON conversion, `EvacuationCenter.availableSlots`, occupancy and freshness fields.
- **[E08] Center photos, facilities, and labels:** [center_photo_cache_service.dart](lib/features/evacuation_centers/data/services/center_photo_cache_service.dart), [center_photo_provider.dart](lib/features/evacuation_centers/presentation/providers/center_photo_provider.dart), [center_photo_card.dart](lib/features/evacuation_centers/presentation/widgets/center_photo_card.dart), [center_facilities_section.dart](lib/features/evacuation_centers/presentation/widgets/center_facilities_section.dart), [center_facility_model.dart](lib/features/evacuation_centers/data/models/center_facility_model.dart), [center_status_display.dart](lib/features/evacuation_centers/presentation/widgets/center_status_display.dart), [facility_type_display.dart](lib/features/evacuation_centers/presentation/widgets/facility_type_display.dart). `CenterPhotoCacheService`, `centerPhotoFile`, `CenterPhotoCard`, `CenterFacilitiesSection`, `CenterFacilityModel`; file cache, photo fallback, facility parsing, status/type display.
- **[E09] Connectivity and GPS:** [connectivity_service.dart](lib/core/connectivity/connectivity_service.dart), [location_service.dart](lib/core/location/location_service.dart), [home_provider.dart](lib/features/home/presentation/providers/home_provider.dart), [distance_calculator.dart](lib/core/utils/distance_calculator.dart). `ConnectivityService`, `LocationService`, `connectivityStatus`; reachability probe, debouncing/replay, permission branches, position and distance calculation.
- **[E10] External map handoff:** [map_launcher.dart](lib/core/utils/map_launcher.dart). `openDirections`; `geo:` location URI followed by Google Maps search fallback.
- **[E11] Map presentation:** [evacuation_map_page.dart](lib/features/map/presentation/pages/evacuation_map_page.dart), [map_base_layer.dart](lib/features/map/presentation/widgets/map_base_layer.dart), [hazard_polygon_layer.dart](lib/features/map/presentation/widgets/hazard_polygon_layer.dart), [ligao_city_location.dart](lib/core/constants/ligao_city_location.dart). `EvacuationMapPage`, `_MapViewState._locateMe/_selectCenter/_fitToVisible/_showLayersSheet`, `mapBaseTileLayer`, `buildHazardPolygons`; markers, search, filters, base tiles and polygons.
- **[E12] GIS data path:** [map_remote_datasource.dart](lib/features/map/data/datasources/map_remote_datasource.dart), [map_local_datasource.dart](lib/features/map/data/datasources/map_local_datasource.dart), [map_repository_impl.dart](lib/features/map/data/repositories/map_repository_impl.dart), [map_provider.dart](lib/features/map/presentation/providers/map_provider.dart), [hazard_area_model.dart](lib/features/map/data/models/hazard_area_model.dart), [map_data.dart](lib/features/map/domain/entities/map_data.dart), [hazard_area.dart](lib/features/map/domain/entities/hazard_area.dart), [get_map_data.dart](lib/features/map/domain/usecases/get_map_data.dart). `MapRemoteDatasource.getMapData`, `MapRepositoryImpl.getMapData`, `mapData`, `HazardAreaModel.fromGeoJsonFeature`; expected feature collections, cache behavior and polygon interpretation.
- **[E13] Alert presentation and data fields:** [alerts_page.dart](lib/features/alerts/presentation/pages/alerts_page.dart), [alert_details_page.dart](lib/features/alerts/presentation/pages/alert_details_page.dart), [alert_type_display.dart](lib/features/alerts/presentation/widgets/alert_type_display.dart), [alert_model.dart](lib/features/alerts/data/models/alert_model.dart), [alert.dart](lib/features/alerts/domain/entities/alert.dart). `AlertsListPage`, `_visibleAlerts`, `_handleRefresh`, `AlertDetailsPage`, `_shareAlert`, `AlertModel`, `Alert`; search, severity, date groups, detail and sharing.
- **[E14] Alert fetching/cache:** [alerts_remote_datasource.dart](lib/features/alerts/data/datasources/alerts_remote_datasource.dart), [alerts_local_datasource.dart](lib/features/alerts/data/datasources/alerts_local_datasource.dart), [alerts_repository_impl.dart](lib/features/alerts/data/repositories/alerts_repository_impl.dart), [alerts_summary_provider.dart](lib/features/alerts/presentation/providers/alerts_summary_provider.dart), [get_alerts.dart](lib/features/alerts/domain/usecases/get_alerts.dart), [get_alert_by_id.dart](lib/features/alerts/domain/usecases/get_alert_by_id.dart). `AlertsRemoteDatasource.getAlerts/_parseAlertsPage`, `AlertsRepositoryImpl.getAlerts/getAlertById`, `alertsSummary`, `alertsList`, `alertById`; envelope handling, page sizes, cache-first detail and fallback.
- **[E15] Disconnected notification settings/realtime scaffold:** [notification_preference_provider.dart](lib/features/settings/presentation/providers/notification_preference_provider.dart), [reverb_client.dart](lib/core/realtime/reverb_client.dart). `NotificationPreferenceNotifier`, `ReverbClient`; stored switch versus unreferenced WebSocket scaffold. Compare with [E02] for the actual polling/banner path.
- **[E16] Home and presentation preferences:** [home_page.dart](lib/features/home/presentation/pages/home_page.dart), [nearest_center_preview.dart](lib/features/home/presentation/widgets/nearest_center_preview.dart), [emergency_status_card.dart](lib/features/home/presentation/widgets/emergency_status_card.dart), [home_stats_section.dart](lib/features/home/presentation/widgets/home_stats_section.dart), [weather_unavailable_placeholder.dart](lib/features/home/presentation/widgets/weather_unavailable_placeholder.dart), [safety_tips_section.dart](lib/features/home/presentation/widgets/safety_tips_section.dart), [app_locale.dart](lib/core/localization/app_locale.dart), [app_theme_mode.dart](lib/core/localization/app_theme_mode.dart), [framework_localizations_fallback.dart](lib/core/localization/framework_localizations_fallback.dart), [app_theme.dart](lib/app/theme/app_theme.dart). `HomePage`, `_handleQuickRefresh`, `NearestCenterPreview._requestPosition`, `AppLocale`, `AppThemeModeNotifier`; Home data freshness, device actions, preference loading and framework fallback. Translation evidence: [English](lib/l10n/app_en.arb), [Filipino](lib/l10n/app_fil.arb), [Bikol](lib/l10n/app_bcl.arb).

### 13.2 Staff workflows

- **[E17] Staff sign-in state:** [staff_login_page.dart](lib/features/staff_auth/presentation/pages/staff_login_page.dart), [staff_auth_provider.dart](lib/features/staff_auth/presentation/providers/staff_auth_provider.dart), [staff_session.dart](lib/features/staff_auth/domain/entities/staff_session.dart). `StaffLoginPage._submit`, `StaffAuth.build/login/logout`, `StaffSession.fromJson/isBarangayOfficial`; form validation, state transitions, identity and role parsing.
- **[E18] Staff authentication persistence/API:** [staff_auth_repository_impl.dart](lib/features/staff_auth/data/repositories/staff_auth_repository_impl.dart), [staff_auth_remote_datasource.dart](lib/features/staff_auth/data/datasources/staff_auth_remote_datasource.dart). `StaffAuthRepositoryImpl.login/restoreSession/_cachedSessionOr/logout`, `StaffAuthRemoteDataSource`; login, `/auth/me`, logout, cached restoration, token handling.
- **[E19] Staff entry/access checks:** [staff_auth_guard.dart](lib/features/staff_auth/presentation/widgets/staff_auth_guard.dart), [staff_workspace_page.dart](lib/features/staff_workspace/presentation/pages/staff_workspace_page.dart), [staff_identity_card.dart](lib/features/staff_auth/presentation/widgets/staff_identity_card.dart), [settings_page.dart](lib/features/settings/presentation/pages/settings_page.dart). `StaffAuthGuard.build`, `StaffWorkspacePage`, `_StaffWorkspaceBody._confirmLogout`, `StaffIdentityCard`, `SettingsPage`; session gate, available actions and logout confirmation.
- **[E20] Full family registration UI:** [family_registration_form_page.dart](lib/features/family_registration/presentation/pages/family_registration_form_page.dart), [family_member_card.dart](lib/features/family_registration/presentation/widgets/family_member_card.dart). `FamilyRegistrationFormPage`, `_FamilyRegistrationFormBodyState._submit/_contactNumberErrors/_scheduleDuplicateCheck/_setHeadOfFamily`, `FamilyMemberCard`; required fields, lookup selectors, member editing, duplicate warnings and save branches.
- **[E21] Family payload/validation:** [family_registration_draft.dart](lib/features/family_registration/domain/entities/family_registration_draft.dart), [family_member_draft.dart](lib/features/family_registration/domain/entities/family_member_draft.dart), [contact_number_validator.dart](lib/features/family_registration/domain/validators/contact_number_validator.dart), [duplicate_name_matcher.dart](lib/features/family_registration/domain/duplicate_match/duplicate_name_matcher.dart), [lookup_entities.dart](lib/features/family_registration/domain/entities/lookup_entities.dart). `FamilyRegistrationDraft.isSubmittable/toJson`, `FamilyMemberDraft.toJson`, `isValidPhMobileNumber`; field rules, JSON and local matching.
- **[E22] Family queue and lookup persistence:** [pending_queue_repository_impl.dart](lib/features/family_registration/data/repositories/pending_queue_repository_impl.dart), [pending_queue_local_datasource.dart](lib/features/family_registration/data/datasources/pending_queue_local_datasource.dart), [pending_family_registration_model.dart](lib/features/family_registration/data/models/pending_family_registration_model.dart), [lookup_repository_impl.dart](lib/features/family_registration/data/repositories/lookup_repository_impl.dart), [lookup_remote_datasource.dart](lib/features/family_registration/data/datasources/lookup_remote_datasource.dart), [lookup_local_datasource.dart](lib/features/family_registration/data/datasources/lookup_local_datasource.dart). `PendingQueueRepositoryImpl`, `PendingQueueLocalDataSource`, `LookupRepositoryImpl`; owner scoping, legacy owner claim, serialized drafts, lookup replacement/cache fallback.
- **[E23] Registration submission and queue screens:** [family_registration_repository_impl.dart](lib/features/family_registration/data/repositories/family_registration_repository_impl.dart), [family_registration_remote_datasource.dart](lib/features/family_registration/data/datasources/family_registration_remote_datasource.dart), [registration_submit_provider.dart](lib/features/family_registration/presentation/providers/registration_submit_provider.dart), [pending_queue_provider.dart](lib/features/family_registration/presentation/providers/pending_queue_provider.dart), [lookup_providers.dart](lib/features/family_registration/presentation/providers/lookup_providers.dart), [pending_registrations_page.dart](lib/features/family_registration/presentation/pages/pending_registrations_page.dart), [pending_registration_detail_page.dart](lib/features/family_registration/presentation/pages/pending_registration_detail_page.dart), [pending_registration_status.dart](lib/features/family_registration/domain/entities/pending_registration_status.dart). `FamilyRegistrationRepositoryImpl.submit`, `pendingRegistrations`, `pendingQueueCounts`, `pendingRegistrationDetail`, `staffSyncNow`, `staffSyncFamilyRegistrationsOnly`, `staffSyncEcBoardEntriesOnly`; submission, manual sync entry points, edit/delete and queue-state presentation.
- **[E24] Manual upload orchestration:** [staff_sync_service.dart](lib/features/family_registration/data/services/staff_sync_service.dart). `StaffSyncService.run/_runFamilyQueue/_runEcBoardQueue`, `StaffSyncRunResult`; order, connectivity checks, status changes, stop/continue decisions and dependent household promotion.
- **[E25] EC Board selection and dashboard:** [ec_board_centers_list_page.dart](lib/features/ec_board/presentation/pages/ec_board_centers_list_page.dart), [ec_board_page.dart](lib/features/ec_board/presentation/pages/ec_board_page.dart), [pin_own_barangay_first.dart](lib/features/evacuation_centers/presentation/widgets/pin_own_barangay_first.dart). `EcBoardCentersListPage._visibleCenters`, `EcBoardPage._ensureEventSelected/_runSync`, `_EcBoardBody.build/_openAddEvacuee`, `_PendingSection.build`, `pinOwnBarangayFirst`; own-barangay ordering, event selection, totals, age/sectoral rows, last-known data, separate pending contributions.
- **[E26] Rapid arrivals and pending detail:** [add_evacuee_form_page.dart](lib/features/ec_board/presentation/pages/add_evacuee_form_page.dart), [pending_ec_entry_detail_page.dart](lib/features/ec_board/presentation/pages/pending_ec_entry_detail_page.dart). `AddEvacueeFormPage._submit/_pickExistingHousehold`, `PendingEcEntryDetailPage`; new/existing household, home barangay, head answers, person flags, offline save, review/edit/delete, immediate submit.
- **[E27] EC Board storage and API:** [ec_board_repository_impl.dart](lib/features/ec_board/data/repositories/ec_board_repository_impl.dart), [ec_board_local_datasource.dart](lib/features/ec_board/data/datasources/ec_board_local_datasource.dart), [ec_board_remote_datasource.dart](lib/features/ec_board/data/datasources/ec_board_remote_datasource.dart), [ec_board_provider.dart](lib/features/ec_board/presentation/providers/ec_board_provider.dart), [pending_ec_board_entry_model.dart](lib/features/ec_board/data/models/pending_ec_board_entry_model.dart), [cached_quick_count_codec.dart](lib/features/ec_board/data/models/cached_quick_count_codec.dart). `EcBoardRepositoryImpl`, `EcBoardLocalDataSource`, `EcBoardRemoteDataSource`, `ecBoardQuickCount`, `ecBoardFamiliesHere`, `ecBoardEntriesForCenter`, `ecBoardPendingNewHouseholds`, `ecBoardCountsForCenter`, `CachedQuickCountCodec`; remote count/intake calls, fallback, local dependencies and cached timestamps.
- **[E28] EC Board entities and wire values:** [ec_board_entry_draft.dart](lib/features/ec_board/domain/entities/ec_board_entry_draft.dart), [pending_ec_board_entry.dart](lib/features/ec_board/domain/entities/pending_ec_board_entry.dart), [family_here.dart](lib/features/ec_board/domain/entities/family_here.dart), [ec_board_quick_count.dart](lib/features/ec_board/domain/entities/ec_board_quick_count.dart), [age_bracket.dart](lib/features/ec_board/domain/entities/age_bracket.dart), [sectoral_group.dart](lib/features/ec_board/domain/entities/sectoral_group.dart), [per_person_sectoral_flag.dart](lib/features/ec_board/domain/entities/per_person_sectoral_flag.dart). `EcBoardEntryDraft.isSubmittable/isReadyToSync/toJson`, `FamilyHere`, `EcBoardQuickCount`, `countPendingSectoral`; individual intake, generic household labels, count buckets and overlap.
- **[E29] Registered-family data and checkout:** [registered_families_repository_impl.dart](lib/features/registered_families/data/repositories/registered_families_repository_impl.dart), [registered_families_remote_datasource.dart](lib/features/registered_families/data/datasources/registered_families_remote_datasource.dart), [registered_families_local_datasource.dart](lib/features/registered_families/data/datasources/registered_families_local_datasource.dart), [cached_family_model.dart](lib/features/registered_families/data/models/cached_family_model.dart), [registered_families_provider.dart](lib/features/registered_families/presentation/providers/registered_families_provider.dart), [family_record.dart](lib/features/registered_families/domain/entities/family_record.dart), [registered_family.dart](lib/features/registered_families/domain/entities/registered_family.dart). `RegisteredFamiliesRemoteDataSource.fetchAll/fetchOne/checkOut`, `RegisteredFamiliesRepositoryImpl.getAll/getRecord/checkOut/_toRecordMember`, `registeredFamiliesGrouped`, `familyRecord`, `CheckOutReason`; pagination, owner cache, record parsing and per-evacuee departure API.
- **[E30] Family list/detail/departure UI:** [registered_families_page.dart](lib/features/registered_families/presentation/pages/registered_families_page.dart), [registered_families_overview_page.dart](lib/features/registered_families/presentation/pages/registered_families_overview_page.dart), [registered_family_detail_sheet.dart](lib/features/registered_families/presentation/widgets/registered_family_detail_sheet.dart). `RegisteredFamiliesPage`, `RegisteredFamiliesOverviewPage`, `showRegisteredFamilyDetailSheet`, `_MemberRow._checkOut`, `_RegisteredFamilyDetailSheet._markFamilyDeparted`, `_MarkFamilyDepartedConfirmDialogState._run`; partial cached view, confirmations, selected-member loop and partial failures.
- **[E31] Center management UI:** [staff_evacuation_centers_list_page.dart](lib/features/staff_evacuation_centers/presentation/pages/staff_evacuation_centers_list_page.dart), [staff_evacuation_center_detail_page.dart](lib/features/staff_evacuation_centers/presentation/pages/staff_evacuation_center_detail_page.dart), [evacuation_center_form_page.dart](lib/features/staff_evacuation_centers/presentation/pages/evacuation_center_form_page.dart), [center_location_picker_page.dart](lib/features/staff_evacuation_centers/presentation/pages/center_location_picker_page.dart), [coordinate_parser.dart](lib/features/staff_evacuation_centers/presentation/widgets/coordinate_parser.dart), [staff_evacuation_centers_provider.dart](lib/features/staff_evacuation_centers/presentation/providers/staff_evacuation_centers_provider.dart). `StaffEvacuationCentersListPage._visibleCenters/_refresh`, `StaffEvacuationCenterDetailPage`, `_EvacuationCenterFormBodyState._submit/_chooseLocation/_pickPhoto`, `CenterLocationPickerPage`, `parseCoordinates`; own-barangay list, form and location/photo branches.
- **[E32] Center writes and client permission:** [evacuation_center_draft.dart](lib/features/staff_evacuation_centers/domain/entities/evacuation_center_draft.dart), [center_edit_permission.dart](lib/features/staff_evacuation_centers/domain/center_edit_permission.dart), [staff_evacuation_centers_repository_impl.dart](lib/features/staff_evacuation_centers/data/repositories/staff_evacuation_centers_repository_impl.dart), [staff_evacuation_centers_remote_datasource.dart](lib/features/staff_evacuation_centers/data/datasources/staff_evacuation_centers_remote_datasource.dart). `EvacuationCenterDraft`, `canEditCenter`, `StaffEvacuationCentersRepositoryImpl`, `_cacheAuthoritative`, `StaffEvacuationCentersRemoteDataSource`; create/update payloads, JSON versus multipart null semantics and resident-cache writes.

### 13.3 Storage, tests, platform, and dependency behavior

- **[E33] Resident cache management/freshness:** [offline_cache_service.dart](lib/core/cache/offline_cache_service.dart), [sync_timestamps.dart](lib/core/sync/sync_timestamps.dart), [offline_data_provider.dart](lib/features/settings/presentation/providers/offline_data_provider.dart), [offline_data_management_page.dart](lib/features/settings/presentation/pages/offline_data_management_page.dart), [offline_banner.dart](lib/core/widgets/offline_banner.dart), [data_freshness_formatter.dart](lib/core/utils/data_freshness_formatter.dart). `OfflineCacheService._rowSizeBytes`, `OfflineDataOverview.syncAll/clearCachedData`, `OfflineDataManagementPage`, `OfflineBanner`; record-count estimate, timestamps, refresh/clear scope and displayed freshness.
- **[E34] Resident DB/native connections:** [resident_database.dart](lib/core/database/resident_database.dart), [resident_tables.dart](lib/core/database/tables/resident_tables.dart), [db_connection.dart](lib/core/database/db_connection.dart). `ResidentDatabase`, `EvacuationCenters`, `Alerts`, `HazardAreas`, `openSqlCipherDatabase`; unencrypted cache schema and native connection setup.
- **[E35] Staff schema and upgrades:** [staff_database.dart](lib/core/database/staff_database.dart), [staff_tables.dart](lib/core/database/tables/staff_tables.dart). `StaffDatabase`, `LookupBarangays`, `LookupEvacuationEvents`, `LookupEvacuationCenters`, `CachedFamilies`, `PendingFamilyRegistrations`, `PendingEcBoardEntries`, `CachedQuickCounts`; version 6 upgrades, owner fields, JSON payloads, old quick-count table removal.
- **[E36] Secret storage:** [secure_token_storage.dart](lib/core/security/secure_token_storage.dart). `SecureTokenStorage`; token/session read/write/delete, random database key creation and persistence.
- **[E37] Staff database recovery:** [staff_database_recovery.dart](lib/core/database/migration/staff_database_recovery.dart), [drift_migration_flags.dart](lib/core/database/migration/drift_migration_flags.dart). `StaffDatabaseRecoveryService`, `DriftMigrationFlags`, `DriftDataset`; classification, plaintext copy, backup/rename, unreadable-file handling and migration flags.
- **[E38] Hotlines:** [emergency_hotlines_data.dart](lib/features/emergency_hotlines/domain/emergency_hotlines_data.dart), [hotline.dart](lib/features/emergency_hotlines/domain/hotline.dart), [emergency_hotlines_page.dart](lib/features/emergency_hotlines/presentation/pages/emergency_hotlines_page.dart), [hotline_favorites_provider.dart](lib/features/emergency_hotlines/presentation/providers/hotline_favorites_provider.dart), [hotline_card.dart](lib/features/emergency_hotlines/presentation/widgets/hotline_card.dart), [priority_hotline_card.dart](lib/features/emergency_hotlines/presentation/widgets/priority_hotline_card.dart). `emergencyHotlines`, `Hotline.dialableNumber`, `HotlineFavorites.build/toggle`, `HotlineCard._handleCall/_handleCopy`, `PriorityHotlineCard`; bundled entries, preferences and dialer/clipboard actions.
- **[E39] Existing tests, inspected but not run:** [connectivity_service_test.dart](test/core/connectivity/connectivity_service_test.dart), [my_evacuation_centers_test.dart](test/features/staff_evacuation_centers/my_evacuation_centers_test.dart), [ec_board_board_test.dart](test/features/ec_board/ec_board_board_test.dart), [add_evacuee_form_test.dart](test/features/ec_board/add_evacuee_form_test.dart), [already_here_test.dart](test/features/ec_board/already_here_test.dart), [closed_event_test.dart](test/features/ec_board/closed_event_test.dart), [home_barangay_test.dart](test/features/ec_board/home_barangay_test.dart), [household_head_test.dart](test/features/ec_board/household_head_test.dart), [other_barangay_note_test.dart](test/features/ec_board/other_barangay_note_test.dart), [per_person_sectoral_flags_test.dart](test/features/ec_board/per_person_sectoral_flags_test.dart), [mark_family_departed_test.dart](test/features/registered_families/mark_family_departed_test.dart).
- **[E40] Build/dependency/platform declarations:** [pubspec.yaml](pubspec.yaml), [pubspec.lock](pubspec.lock), [Android main manifest](android/app/src/main/AndroidManifest.xml), [Android debug manifest](android/app/src/debug/AndroidManifest.xml), [Android profile manifest](android/app/src/profile/AndroidManifest.xml), [Android app Gradle](android/app/build.gradle.kts), [.gitignore](.gitignore), [l10n.yaml](l10n.yaml); package versions, permissions, URL visibility, signing fallback and generated-file rules. Map user-agent evidence is in [E11].
- **[E41] Failure/result handling:** [failure.dart](lib/core/error/failure.dart), [result.dart](lib/core/error/result.dart), [staff_api_error_mapper.dart](lib/core/network/staff_api_error_mapper.dart), [error_state.dart](lib/core/widgets/error_state.dart), [loading_skeleton.dart](lib/core/widgets/loading_skeleton.dart), [empty_state.dart](lib/core/widgets/empty_state.dart), [sync_now_action.dart](lib/core/widgets/sync_now_action.dart). `Failure` subclasses, `Result`, `Success`, `Failed`, `mapStaffDioError`, `ErrorState`, `LoadingSkeleton`, `EmptyState`, `SyncNowAction`; mapped and unmapped error paths and reusable state UI.
- **[E42] Installed dependency behavior:** Read from `C:/Users/micro/AppData/Local/Pub/Cache/hosted/pub.dev/`, outside the application source tree: `dio-5.10.0/lib/src/options.dart` (`RequestOptions.uri`); `flutter_map-8.3.1/lib/src/layer/tile_layer/tile_layer.dart`; `flutter_map-8.3.1/lib/src/layer/tile_layer/tile_provider/network/tile_provider.dart`; `flutter_map-8.3.1/lib/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart`; and `flutter_map-8.3.1/lib/src/layer/tile_layer/tile_provider/network/caching/built_in/built_in_caching_provider.dart`. These establish default URL joining and native built-in tile caching for the installed/locked versions, not an application-managed offline-region workflow or a device-tested cache guarantee.

### 13.4 Coverage inventory

| Source area | First-party Dart files, excluding generated files | Coverage in this report |
|---|---:|---|
| Entry point and `app` | 5 | Startup, shell routes, themes, polling |
| `core` | 54 | Networking, errors, connectivity, GPS, DBs, security, preferences, reusable states |
| `features/alerts` | 13 | Public alert list/detail, caching, sorting/filtering, sharing |
| `features/ec_board` | 18 | Center/event board, intake, pending entries, totals and dependencies |
| `features/emergency_hotlines` | 7 | Static directory, favorites, call/copy |
| `features/evacuation_centers` | 23 | Public center list/detail/nearest, facilities and photo cache |
| `features/family_registration` | 30 | Full family form, lookups, queue, manual synchronization |
| `features/home` | 12 | Resident dashboard, nearest preview, safety tips, placeholders |
| `features/map` | 12 | GIS feed, map controls, hazard polygons, tile sources |
| `features/registered_families` | 13 | Owner cache, records, individual/batch checkout |
| `features/settings` | 5 | Preferences, offline-data management, developer override |
| `features/staff_auth` | 8 | Login, restore, logout, guard and identity |
| `features/staff_evacuation_centers` | 11 | Staff center reads/writes, permission, coordinates, photos |
| `features/staff_workspace` | 1 | Staff entry dashboard/actions |
| **Total** | **212** | **12 feature directories plus app/core** |

Historical project documents are supplementary intent/history evidence only. Their claims about planned or previously supported features must be reconciled with Sections 4, 9, and 10 before they are used in Chapter 3. The diagrams and workflows in this report describe the inspected mobile source revision; backend internals and runtime guarantees require the additional evidence listed in Section 12.
