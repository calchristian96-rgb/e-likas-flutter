/// The same FNV-1a-based hash the wider Isar community uses to derive
/// a stable `int` id from a `String` key. Originally added on
/// `PendingFamilyRegistrationModel` (Isar rejects a nullable `Id`
/// field and has no working auto-increment in this version) and reused
/// by [CachedFamilyModel]'s id and [CenterPhotoCacheService]'s cache
/// filenames. Lives here, independent of any one Isar model, so it
/// keeps working for callers like the photo cache regardless of what
/// happens to the Isar collections during the Drift migration.
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFF;
    hash ^= codeUnit & 0xFF;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFF;
  }

  return hash;
}
