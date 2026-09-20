import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent, runtime backend-URL override — for testing this app on a
/// physical device that isn't actively tethered to a laptop's `flutter
/// run` session.
///
/// **What this actually fixes.** `Env`'s `--dart-define` is a genuine
/// Dart compile-time constant: once a build picks it up, it's baked
/// into that APK and survives being run standalone, disconnected,
/// rebooted — that part was never the real risk. The real risk is every
/// OTHER way this app can end up freshly installed *without* that
/// flag — a plain `flutter install`, an IDE "Run" button with no
/// launch args configured, a teammate's own build, a CI artifact — each
/// of which silently falls back to `Env`'s compiled-in default
/// (production), with nothing on screen to say so. This service exists
/// so a deliberate local/staging override can persist across exactly
/// that kind of reinstall, independent of the dart-define mechanism
/// entirely, and so it's never silently invisible (see
/// `DevModeBanner`).
///
/// **Never active in a release build — enforced here, not just by
/// hiding the UI that writes it.** `android/app/build.gradle.kts` gives
/// debug and release the same `applicationId` (no `.debug` suffix), so
/// a device that's had both installed shares one SharedPreferences file
/// between them. A value a debug build wrote must never be read back by
/// a release one just because the file still has it — every read here
/// checks [kReleaseMode] itself, unconditionally, before ever touching
/// [_cachedOverride] or storage.
class BackendOverrideService {
  BackendOverrideService._();

  static const _prefsKey = 'elikas.dev.backendBaseUrlOverride';

  static String? _cachedOverride;
  static bool _initialized = false;

  /// Loads any persisted override into memory. Must be awaited once, in
  /// `main()` before `runApp()`, so [overrideUrl] — and therefore
  /// `Env.apiBaseUrl` — is already correct by the time the first Dio
  /// client is constructed. A genuine no-op in a release build: never
  /// touches [SharedPreferences] at all in that case.
  static Future<void> initialize() async {
    if (kReleaseMode) {
      _initialized = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedOverride = prefs.getString(_prefsKey);
    _initialized = true;
  }

  /// The persisted override, or null when none is set — always null in
  /// a release build, regardless of what's actually stored on disk.
  static String? get overrideUrl {
    if (kReleaseMode) return null;
    assert(
      _initialized,
      'BackendOverrideService.initialize() must be awaited before this '
      'is read (call it in main(), before runApp()).',
    );
    return _cachedOverride;
  }

  static bool get isOverrideActive => overrideUrl != null;

  /// Persists [url] as the active override. Takes effect the next time
  /// the app is fully closed and reopened — an already-running Dio
  /// client keeps whatever base URL it was constructed with, so this
  /// deliberately does not try to hot-swap it.
  static Future<void> setOverride(String url) async {
    if (kReleaseMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
    _cachedOverride = url;
  }

  static Future<void> clearOverride() async {
    if (kReleaseMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cachedOverride = null;
  }
}
