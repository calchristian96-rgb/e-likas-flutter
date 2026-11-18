import 'dart:async';

/// How long a screen waits for the server when a saved copy exists.
const savedCopyBudget = Duration(seconds: 5);

/// Runs [fetch] (which also saves what it gets). With a saved copy
/// ([hasSaved]) and a slow server, gives up waiting after [budget] and
/// returns null, so the caller shows the saved copy at once, while
/// [fetch] keeps running and refreshes the saved copy for next time.
/// Without a saved copy it waits as long as the request takes. Errors
/// propagate as before (the caller falls back to the saved copy).
Future<T?> fetchWithinBudget<T>(
  Future<T> Function() fetch, {
  required bool hasSaved,
  Duration budget = savedCopyBudget,
}) async {
  final future = fetch();
  if (!hasSaved) return future;
  try {
    return await future.timeout(budget);
  } on TimeoutException {
    // Still running: let it finish and save, quietly.
    unawaited(future.then<void>((_) {}, onError: (_) {}));
    return null;
  }
}
