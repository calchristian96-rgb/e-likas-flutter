import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_push_backend.dart';
import 'push_service.dart';

/// One push service for the app (Firebase in the app, a fake in tests).
final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(FirebasePushBackend()),
);
