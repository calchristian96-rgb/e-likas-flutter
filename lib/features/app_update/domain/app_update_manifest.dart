/// The static `version.json` the release process uploads next to the
/// APK. Only [latestBuild] and [apkUrl] are mandatory; everything else
/// is optional and a bad optional value is dropped rather than
/// failing the whole manifest — except [sha256], which is the download's
/// integrity check, so a malformed one invalidates the manifest instead
/// of silently turning verification off.
class AppUpdateManifest {
  const AppUpdateManifest({
    required this.latestBuild,
    required this.apkUrl,
    this.latestVersion,
    this.minBuild,
    this.sha256,
    this.sizeBytes,
    this.notes = const {},
  });

  final int latestBuild;
  final Uri apkUrl;
  final String? latestVersion;
  final int? minBuild;

  /// Lower-case 64-char hex digest of the APK, when the manifest has one.
  final String? sha256;
  final int? sizeBytes;

  /// Release notes by language code. A plain-string `notes` is stored
  /// under `en`.
  final Map<String, String> notes;

  /// Notes in [languageCode], falling back to English, else null.
  String? notesFor(String languageCode) {
    final text = notes[languageCode] ?? notes['en'];
    return (text == null || text.trim().isEmpty) ? null : text.trim();
  }

  /// Size in whole megabytes for display, or null when unknown.
  double? get sizeMegabytes =>
      sizeBytes == null ? null : sizeBytes! / (1024 * 1024);

  /// Parses decoded JSON. Returns null for anything unusable — wrong
  /// shape, missing/invalid mandatory fields, an `apk_url` that is not
  /// https or not on the same host as [manifestUri], or a malformed
  /// `sha256`. Never throws.
  static AppUpdateManifest? tryParse(Object? json, {required Uri manifestUri}) {
    try {
      if (json is! Map) return null;

      final latestBuild = _asInt(json['latest_build']);
      if (latestBuild == null || latestBuild <= 0) return null;

      final urlText = json['apk_url'];
      if (urlText is! String) return null;
      final apkUrl = Uri.tryParse(urlText.trim());
      if (apkUrl == null ||
          apkUrl.scheme != 'https' ||
          apkUrl.host.isEmpty ||
          apkUrl.host.toLowerCase() != manifestUri.host.toLowerCase()) {
        return null;
      }

      String? sha256;
      final rawSha = json['sha256'];
      if (rawSha != null) {
        if (rawSha is! String ||
            !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(rawSha.trim())) {
          return null;
        }
        sha256 = rawSha.trim().toLowerCase();
      }

      final minBuild = _asInt(json['min_build']);
      final sizeBytes = _asInt(json['size_bytes']);
      final version = json['latest_version'];

      return AppUpdateManifest(
        latestBuild: latestBuild,
        apkUrl: apkUrl,
        latestVersion: version is String && version.trim().isNotEmpty
            ? version.trim()
            : null,
        minBuild: minBuild != null && minBuild > 0 ? minBuild : null,
        sha256: sha256,
        sizeBytes: sizeBytes != null && sizeBytes > 0 ? sizeBytes : null,
        notes: _parseNotes(json['notes']),
      );
    } catch (_) {
      return null;
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Map<String, String> _parseNotes(Object? raw) {
    if (raw is String) {
      return raw.trim().isEmpty ? const {} : {'en': raw};
    }
    if (raw is Map) {
      return {
        for (final entry in raw.entries)
          if (entry.key is String &&
              entry.value is String &&
              (entry.value as String).trim().isNotEmpty)
            entry.key as String: entry.value as String,
      };
    }
    return const {};
  }
}
