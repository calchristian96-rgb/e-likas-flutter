import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_preference_provider.g.dart';

const _notificationsEnabledPrefsKey = 'elikas.notificationsEnabled';

/// Whether the resident has opted in to push notifications — a LOCAL
/// PREFERENCE ONLY, same persistence pattern as [AppThemeModeNotifier]/
/// `AppLocale` (a dedicated [SharedPreferences] key, loaded once during
/// splash). The backend does not currently expose a real push-
/// notification service, so this controls nothing server-side today —
/// see the Settings row's own honest subtitle. It still needs to be a
/// real, persisted preference (not a decorative switch that forgets
/// itself) so a future real notification feature has an existing
/// opt-in signal to read, and so toggling it off/on actually means
/// something rather than nothing at all.
///
/// Defaults to enabled: for a disaster-alerting app specifically, most
/// residents would want emergency notifications on by default once a
/// real service exists, rather than needing to discover and opt in.
@riverpod
class NotificationPreferenceNotifier extends _$NotificationPreferenceNotifier {
  @override
  bool build() => true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notificationsEnabledPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledPrefsKey, enabled);
  }
}
