/// Lowercase, trim, collapse internal whitespace — comparison-only
/// normalization. Never mutates what staff actually typed or what's
/// stored; used purely to decide whether two names are "the same" for
/// warning purposes.
String normalizeNameForMatch(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Whether an in-progress member entry might already be a registered
/// family member — local, offline, precision-first. Two tiers only,
/// deliberately: (1) an exact normalized full-name match, and (2) both
/// the first *and* last name appearing as separate tokens in the
/// candidate's name (catches a differently-formatted middle name/
/// suffix without loosening past that). A third, fuzzy/edit-distance
/// tier was considered and left out — first+last token matching
/// already satisfies "don't warn on a common first name alone," and
/// adding fuzzy matching would mean pulling in a dependency this
/// feature doesn't otherwise need (see the task's own "avoid a large
/// fuzzy-search dependency unless genuinely necessary").
///
/// Requires both a first name and a last name of at least 2 characters
/// — an empty/near-empty field can't meaningfully match anything, and
/// matching on a single short token is exactly the "common first name"
/// false-positive this is designed to avoid.
bool isPossibleDuplicateMember({
  required String firstName,
  required String middleName,
  required String lastName,
  required String candidateFullName,
}) {
  final first = normalizeNameForMatch(firstName);
  final last = normalizeNameForMatch(lastName);
  if (first.length < 2 || last.length < 2) return false;

  final candidate = normalizeNameForMatch(candidateFullName);
  if (candidate.isEmpty) return false;

  final middle = normalizeNameForMatch(middleName);
  final enteredFull = [first, if (middle.isNotEmpty) middle, last].join(' ');
  if (enteredFull == candidate) return true;

  final candidateTokens = candidate.split(' ');
  return candidateTokens.contains(first) && candidateTokens.contains(last);
}
