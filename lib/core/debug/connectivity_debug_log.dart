import 'package:flutter/foundation.dart';

/// TEMPORARY diagnostic logging for tracing a real-device bug where the
/// app kept showing "Online" with all networks disabled — added to
/// confirm [ConnectivityService]'s interface-detection and backend-
/// reachability-probe steps are actually running and returning the
/// expected result on a real device. Debug-only (`kDebugMode`), and
/// never logs tokens, request bodies, or PII — only interface-state
/// summaries, probe outcomes, and state transitions.
///
/// Remove this file and every `connectivityDebugLog(...)` call site
/// once the real-device fix is confirmed.
void connectivityDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('CONNECTIVITY DEBUG: $message');
  }
}
