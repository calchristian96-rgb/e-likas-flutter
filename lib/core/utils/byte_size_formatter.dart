/// Formats a real byte count (from `IsarCollection.getSize()`) as a
/// short human-readable size — never a placeholder or estimated value,
/// only ever called with a number actually measured from the local
/// cache.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}
