import 'package:shared_preferences/shared_preferences.dart';

import '../domain/update_decision.dart';

const _snoozedBuildKey = 'elikas.update.snoozedBuild';
const _snoozedAtKey = 'elikas.update.snoozedAtMs';

/// Remembers which build the resident last tapped "Later" on, and when.
class UpdateSnoozeStore {
  UpdateSnoozeStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  Future<bool> isSnoozed(int latestBuild) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = prefs.getInt(_snoozedAtKey);
      return isUpdateSnoozed(
        latestBuild: latestBuild,
        snoozedBuild: prefs.getInt(_snoozedBuildKey),
        snoozedAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
        now: _clock(),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> snooze(int latestBuild) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_snoozedBuildKey, latestBuild);
      await prefs.setInt(_snoozedAtKey, _clock().millisecondsSinceEpoch);
    } catch (_) {
      // Failing to remember the snooze only means a re-prompt.
    }
  }
}
