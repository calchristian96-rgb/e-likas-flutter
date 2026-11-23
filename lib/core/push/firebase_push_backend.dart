import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../notifications/local_notifications.dart';
import 'push_service.dart';

PushMessage _message(RemoteMessage m) => PushMessage(
  title: m.notification?.title,
  body: m.notification?.body,
  data: {for (final e in m.data.entries) e.key: '${e.value}'},
);

/// Firebase Cloud Messaging (project e-likas-40a9e, configured by
/// android/app/google-services.json, which is never committed).
class FirebasePushBackend implements PushBackend {
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  Future<void> init() async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  }

  @override
  Future<bool> requestPermission() async {
    // Android 13+ POST_NOTIFICATIONS; older Android needs none.
    final local = await LocalNotifications.requestPermission();
    final settings = await _fm.requestPermission();
    return local ||
        settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<void> subscribe(String topic) => _fm.subscribeToTopic(topic);

  @override
  Future<void> unsubscribe(String topic) => _fm.unsubscribeFromTopic(topic);

  @override
  Stream<PushMessage> get onForeground =>
      FirebaseMessaging.onMessage.map(_message);

  @override
  Stream<PushMessage> get onOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_message);

  @override
  Future<PushMessage?> initialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _message(m);
  }
}
