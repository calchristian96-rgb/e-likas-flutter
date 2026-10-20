import 'app_update_manifest.dart';

enum UpdateKind { none, optional, required }

/// What the installed [currentBuild] should do about [manifest].
/// `min_build` only matters when a newer build actually exists.
UpdateKind decideUpdate(AppUpdateManifest manifest, int currentBuild) {
  if (manifest.latestBuild <= currentBuild) return UpdateKind.none;
  final minBuild = manifest.minBuild;
  if (minBuild != null && minBuild > currentBuild) return UpdateKind.required;
  return UpdateKind.optional;
}

/// How long "Later" hides an optional update.
const updateSnoozeDuration = Duration(hours: 24);

/// Minimum gap between automatic checks on app resume.
const updateResumeCheckInterval = Duration(hours: 6);

/// A snooze covers exactly one build for [updateSnoozeDuration]; a
/// higher build than the snoozed one prompts again immediately.
bool isUpdateSnoozed({
  required int latestBuild,
  required int? snoozedBuild,
  required DateTime? snoozedAt,
  required DateTime now,
}) {
  if (snoozedBuild != latestBuild || snoozedAt == null) return false;
  final elapsed = now.difference(snoozedAt);
  // A negative elapsed time means the clock moved backwards; treat the
  // snooze as expired rather than hiding the update indefinitely.
  return !elapsed.isNegative && elapsed < updateSnoozeDuration;
}
