/// The current moment, expressed in Philippine Standard Time
/// (Asia/Manila, UTC+08:00) regardless of the device's own configured
/// timezone.
///
/// Deliberately doesn't rely on the device's local timezone at all —
/// starts from UTC (a fixed, unambiguous reference point) and applies
/// the fixed +8 offset PST is defined as. PST has no daylight-saving
/// rules to account for, so this fixed offset is exact and permanent,
/// not an approximation.
///
/// The returned [DateTime] has `isUtc == true` but its fields (hour,
/// day, etc.) hold Manila's wall-clock time, not UTC's — this is
/// intentional: `DateFormat.format()` and `.hour`/`.day` etc. all read
/// a DateTime's fields directly without re-converting based on that
/// flag, so this is the standard, correct way to display "wall clock
/// time in a specific fixed-offset zone" without a full timezone
/// database package. Only use this value for *display* — never feed
/// it back into further timezone-sensitive arithmetic expecting a
/// true UTC instant.
DateTime philippineNow() {
  return DateTime.now().toUtc().add(const Duration(hours: 8));
}
