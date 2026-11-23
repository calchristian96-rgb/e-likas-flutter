import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications this app shows itself: a push that arrives while the
/// app is open (Android shows none then), and Staff Mode's "registration
/// is open". The channel ids are fixed: `elikas_alerts` is the one the
/// server's pushes name (docs/backend/push-notifications.md section 3).
abstract final class LocalNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Called with the payload when the person taps a notification this
  /// app showed (set by the app once the router exists).
  static void Function(String? payload)? onTap;

  static const alertsChannelId = 'elikas_alerts';
  static const staffChannelId = 'elikas_staff';

  /// High importance: sound and heads-up, for Emergency alerts and
  /// Preemptive or Forced evacuation orders.
  static const alertsChannel = AndroidNotificationChannel(
    alertsChannelId,
    'Emergency alerts and evacuation orders',
    description:
        'Emergency alerts and evacuation orders for Ligao City and your barangay.',
    importance: Importance.high,
  );

  static const staffChannel = AndroidNotificationChannel(
    staffChannelId,
    'Staff Mode',
    description: 'Event updates for barangay officials and CSWD.',
    importance: Importance.defaultImportance,
  );

  /// Creates the channels. Safe to call more than once; never throws (a
  /// phone without notification support simply shows nothing).
  static Future<void> init() async {
    if (_ready || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (r) => onTap?.call(r.payload),
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(alertsChannel);
      await android?.createNotificationChannel(staffChannel);
      _ready = true;
    } catch (e) {
      debugPrint('Local notifications unavailable: $e');
    }
  }

  /// Android 13+: asks for POST_NOTIFICATIONS. True when allowed.
  static Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// The payload of the notification that opened the app, if any.
  static Future<String?> launchPayload() async {
    if (!_ready) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.didNotificationLaunchApp == true
          ? details?.notificationResponse?.payload
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String channelId = alertsChannelId,
    String? payload,
  }) async {
    if (!_ready) return;
    final channel = channelId == staffChannelId ? staffChannel : alertsChannel;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: channel.importance == Importance.high
                ? Priority.high
                : Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Could not show a notification: $e');
    }
  }
}
