import 'package:flutter/foundation.dart';

/// TEMPORARY diagnostic logging for the evacuation-center photo
/// upload/display pipeline — added to trace a real-device bug where
/// Center Details kept showing "No photo available" after a
/// successful staff photo upload/edit. Debug-only (`kDebugMode`), and
/// never logs anything sensitive: no Sanctum token, no image bytes,
/// no camp-manager contact, no PII. A `photo_url` itself is safe to
/// print — it's meant to be a publicly reachable HTTPS URL, not a
/// secret.
///
/// Remove this file and every `centerPhotoDebugLog(...)` call site
/// once the real-device bug is confirmed fixed.
void centerPhotoDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('CENTER PHOTO DEBUG: $message');
  }
}

/// Logs the shape of [url] (never its bytes, and the URL itself is
/// safe to print — see the class doc comment) against the checks the
/// real-device bug report specifically asked for: absolute/HTTPS,
/// no doubled `/storage/storage/` (a classic `Storage::url()` +
/// manual-prefix double-up), and not pointing at localhost/a private
/// LAN address (which would mean a resident's phone, on a different
/// network than the dev server, could never actually reach it).
void centerPhotoDebugLogUrlShape(String? url) {
  if (!kDebugMode || url == null) return;
  final uri = Uri.tryParse(url);
  final isAbsolute = uri?.isAbsolute ?? false;
  final isHttps = uri?.scheme == 'https';
  final hasDoubledStorage = url.contains('/storage/storage/');
  final host = uri?.host ?? '';
  final isLocalOrPrivate =
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host.startsWith('192.168.') ||
      host.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host);
  centerPhotoDebugLog(
    'photo url shape: absolute=$isAbsolute https=$isHttps '
    'doubledStoragePath=$hasDoubledStorage host=$host '
    'localOrPrivateHost=$isLocalOrPrivate',
  );
}
