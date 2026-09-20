import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/env/backend_override_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must complete before runApp(): Env.apiBaseUrl (read the moment any
  // Dio client is first constructed) needs the persisted override
  // already loaded into memory, not still mid-flight.
  await BackendOverrideService.initialize();
  runApp(const ProviderScope(child: ElikasApp()));
}
