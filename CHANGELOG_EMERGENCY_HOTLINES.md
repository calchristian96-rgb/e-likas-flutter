# Changelog — Emergency Hotlines Feature

Fully static, fully offline feature — no API request, no Isar storage,
no repository/datasource layer, since there's nothing to fetch or
cache. The data *is* the code: a `const List<Hotline>` compiled
directly into the app.

## Files created (4)

| File | Purpose |
|---|---|
| `features/emergency_hotlines/domain/hotline.dart` | `Hotline` entity + `HotlineCategory` enum. Pure Dart — no `IconData` in the domain layer; category-to-icon/color mapping lives in the presentation widget, matching the pattern the Map feature already uses for hazard-type colors. |
| `features/emergency_hotlines/domain/emergency_hotlines_data.dart` | The actual static data — Ligao City's 7 official numbers, exactly as given. |
| `features/emergency_hotlines/presentation/pages/emergency_hotlines_page.dart` | The page: an offline-availability banner, then one card per hotline. |
| `features/emergency_hotlines/presentation/widgets/hotline_card.dart` | Reusable card — icon, name, number, description, Call + Copy actions. |

## Files modified (2)

**`app_router.dart`** — one new route added, same pattern as `/centers`
(a plain route outside the tab shell, since this is a Home quick
action, not a bottom-nav destination):
```dart
GoRoute(
  path: '/emergency-hotlines',
  builder: (context, state) => const EmergencyHotlinesPage(),
),
```

**`home_page.dart`** — one new `QuickActionCard` appended to the
existing grid (now 6 tiles instead of 5; the fixed-height grid
delegate from the UI Polish phase needs no changes to accommodate
this). Nothing else in the file touched.

## The Call button, honestly

This project has no `url_launcher` (or any call-launching mechanism)
and `pubspec.yaml` is explicitly off-limits this phase. Rather than
either silently do nothing or fake success, "Call" shows a clear
SnackBar explaining that direct dialing isn't wired up yet and points
at "Copy Number" as the immediate alternative. "Copy Number" itself is
fully functional — `Clipboard.setData`, part of the Flutter SDK
itself, not a new package.

`hotline_card.dart`'s `_handleCall` has a comment with the exact
one-line change needed to connect it for real once `url_launcher` is
added: `launchUrl(Uri(scheme: 'tel', path: hotline.number.replaceAll(' ', '')))`.

## Assumptions
- The 7 numbers and category groupings are used exactly as given.
- Each hotline's "short description" was written based on the service
  name/category (none were provided in the request) — worth a quick
  read-through to confirm the wording matches how CSWDO/CDRRMO would
  actually describe each service.
- "EQRT" is expanded as "Emergency Quick Response Team" in its
  description — a standard term in Philippine LGU disaster response,
  not confirmed against an official source.

## Manual verification
- [ ] Confirm all 7 numbers display exactly as given (easy to
      mis-transcribe a digit by hand — worth a direct visual check
      against the original list).
- [ ] Tap "Copy Number" and paste somewhere to confirm the clipboard
      actually received the right number.
- [ ] Confirm "Emergency Hotlines" appears as the 6th quick action on
      Home and navigates correctly, with the back button returning to
      Home afterward.
- [ ] On a narrow device, confirm the long names ("Philippine National
      Police – Ligao", "Bureau of Fire Protection – Ligao") wrap
      cleanly rather than overflow.
