import 'package:flutter/foundation.dart';

/// TEMPORARY diagnostic logging for tracing a real-device bug where the
/// Staff Workspace page shows "Could not load pending counts." with no
/// visible underlying cause — added to find exactly which checkpoint
/// in the UI → provider → repository → datasource → Drift chain the
/// real exception occurs at. Debug-only (`kDebugMode`), and never logs
/// PII, tokens, registration payloads, names, phone numbers,
/// addresses, or authentication credentials — only checkpoint names,
/// counts, ids, and exception type/message/stack trace.
///
/// Remove this file and every `pendingCountDebugLog(...)` call site
/// once the real-device bug is confirmed diagnosed and fixed.
void pendingCountDebugLog(String message) {
  if (kDebugMode) {
    debugPrint('PENDING COUNT DEBUG: $message');
  }
}
