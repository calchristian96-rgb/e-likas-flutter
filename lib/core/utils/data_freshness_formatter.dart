/// Buckets [since] into a short "how long ago" phrase: minutes under
/// an hour, hours under a day, then "yesterday"/"N days ago" for
/// anything older — the shared building block behind every "Offline •
/// Last updated …" style message in the app, so the wording can't
/// drift between the offline banner and the dashboard's own footer.
String formatElapsedSince(DateTime since, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final elapsed = reference.difference(since);

  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays <= 1) return 'yesterday';
  return '${elapsed.inDays} days ago';
}

/// True once data is old enough (24h+) that showing it without a clear
/// caution risks being misleading for emergency information — swaps
/// in a warning icon/wording at the call site rather than relying on
/// color alone to communicate that.
bool isDataStale(DateTime? lastUpdated, {DateTime? now}) {
  if (lastUpdated == null) return false;
  final reference = now ?? DateTime.now();
  return reference.difference(lastUpdated).inHours >= 24;
}
