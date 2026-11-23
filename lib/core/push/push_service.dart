import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/local_notifications.dart';

/// A push as the app needs it: the notification's title and body, and
/// the data payload (all strings; docs/backend/push-notifications.md 3).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, String> data;
}

/// Where a tapped push opens (section 4.8). Unknown types open nothing,
/// so a future type never breaks an older app.
sealed class PushTarget {
  const PushTarget();
}

class AlertTarget extends PushTarget {
  const AlertTarget(this.alertId);
  final int? alertId;
}

class EvacuationOrderTarget extends PushTarget {
  const EvacuationOrderTarget();
}

class HomeTarget extends PushTarget {
  const HomeTarget();
}

PushTarget? pushTargetOf(Map<String, String> data) => switch (data['type']) {
  'alert' => AlertTarget(int.tryParse(data['alert_id'] ?? '')),
  'evacuation_order' => const EvacuationOrderTarget(),
  'test' => const HomeTarget(),
  _ => null,
};

/// The parts of Firebase Messaging the app uses; a fake in tests.
abstract class PushBackend {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
  Stream<PushMessage> get onForeground;
  Stream<PushMessage> get onOpened;
  Future<PushMessage?> initialMessage();
}

/// Push notifications for residents (Firebase Cloud Messaging, by
/// topic). Topic names always come from the API (`city_push_topic`,
/// `barangays[].push_topic`); the app never builds one.
class PushService {
  PushService(this._backend);

  final PushBackend _backend;

  static const cityTopicFallbackKey = 'push_city_topic_v1';
  static const barangayTopicKey = 'push_barangay_topic_v1';
  static const testTopicKey = 'push_test_topic_on_v1';
  static const testTopic = 'elikas-test';

  /// Taps (and the push that opened the app) go here, once the router
  /// exists.
  void Function(PushTarget target)? onOpen;

  /// A push arrived while the app is open: refresh alerts and statuses.
  VoidCallback? onForegroundRefresh;

  bool _started = false;
  final _subs = <StreamSubscription<PushMessage>>[];

  /// On every start: Firebase, the city topic (safe to repeat; a
  /// reinstall loses subscriptions), the saved barangay topic, the test
  /// topic when it is on, and the listeners. Never throws.
  Future<void> start({String cityTopic = 'elikas-city'}) async {
    if (_started) return;
    _started = true;
    try {
      await _backend.init();
      final prefs = await SharedPreferences.getInstance();
      await _backend.subscribe(
        prefs.getString(cityTopicFallbackKey) ?? cityTopic,
      );
      final barangay = prefs.getString(barangayTopicKey);
      if (barangay != null) await _backend.subscribe(barangay);
      if (prefs.getBool(testTopicKey) ?? false) {
        await _backend.subscribe(testTopic);
      }
      _subs
        ..add(_backend.onForeground.listen(_showInApp))
        ..add(_backend.onOpened.listen(_open));
      final initial = await _backend.initialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('Push unavailable: $e');
    }
  }

  /// Android 13+: the notification permission (after the app's reason).
  Future<bool> requestPermission() async {
    try {
      return await _backend.requestPermission();
    } catch (_) {
      return false;
    }
  }

  /// The city topic as the API names it (`city_push_topic`).
  Future<void> setCityTopic(String topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(cityTopicFallbackKey);
      if (old == topic) return;
      if (old != null) await _backend.unsubscribe(old);
      await _backend.subscribe(topic);
      await prefs.setString(cityTopicFallbackKey, topic);
    } catch (e) {
      debugPrint('City topic not changed: $e');
    }
  }

  /// The resident's barangay changed: unsubscribe from the old topic,
  /// subscribe to the new one, then save it. Null keeps only the city.
  Future<void> setBarangayTopic(String? topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(barangayTopicKey);
      if (old == topic) return;
      if (old != null) await _backend.unsubscribe(old);
      if (topic != null) {
        await _backend.subscribe(topic);
        await prefs.setString(barangayTopicKey, topic);
      } else {
        await prefs.remove(barangayTopicKey);
      }
    } catch (e) {
      debugPrint('Barangay topic not changed: $e');
    }
  }

  /// The hidden "Receive test notifications" switch.
  Future<void> setTestTopic(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(testTopicKey, on);
    try {
      on
          ? await _backend.subscribe(testTopic)
          : await _backend.unsubscribe(testTopic);
    } catch (e) {
      debugPrint('Test topic not changed: $e');
    }
  }

  static Future<bool> testTopicOn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(testTopicKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  void _open(PushMessage m) {
    final target = pushTargetOf(m.data);
    if (target != null) onOpen?.call(target);
  }

  /// Android shows nothing while the app is in the foreground: show it on
  /// the elikas_alerts channel, and refresh.
  void _showInApp(PushMessage m) {
    if (pushTargetOf(m.data) == null && m.title == null) return;
    onForegroundRefresh?.call();
    LocalNotifications.show(
      id:
          (m.data['alert_id'] ?? m.data['order_id'] ?? '${m.hashCode}')
              .hashCode &
          0x7fffffff,
      title: m.title ?? 'E-LIKAS',
      body: m.body ?? '',
      payload: jsonEncode(m.data),
    );
  }

  /// A local notification this app showed was tapped.
  void openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final map = (jsonDecode(payload) as Map).map(
        (k, v) => MapEntry('$k', '$v'),
      );
      _open(PushMessage(data: map));
    } catch (_) {
      // Not a push payload.
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }
}
