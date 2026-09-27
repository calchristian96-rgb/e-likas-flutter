import '../../../family_registration/domain/entities/pending_registration_status.dart';
import 'age_bracket.dart';
import 'ec_board_entry_draft.dart';
import 'per_person_sectoral_flag.dart';
import 'sectoral_group.dart';

/// What the EC Board page's pending-entries list shows — mirrors
/// `PendingRegistrationSummary`'s role exactly, one level smaller.
class PendingEcBoardEntrySummary {
  const PendingEcBoardEntrySummary({
    required this.localId,
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.status,
    required this.sex,
    required this.ageBracket,
    required this.householdLabel,
    required this.createdAt,
    required this.updatedAt,
    this.attemptCount = 0,
    this.lastErrorCategory,
    this.lastErrorMessage,
    this.sectoralFlags = const {},
    this.headIsSelf = false,
    this.createsChildHeadedHousehold = false,
    this.createsSingleHeadedHousehold = false,
    this.newHouseholdHeadSex,
  });

  final String localId;
  final int evacuationCenterId;

  /// Which evacuation event this entry belongs to — the pending
  /// breakdown on `EcBoardPage` filters to whichever event is
  /// currently selected, matching the live "last known" breakdown's
  /// own (center, event) scope exactly.
  final int evacuationEventId;
  final PendingRegistrationStatus status;
  final String sex;

  /// Null only for a locally-stored wire value that couldn't be parsed
  /// against the current [AgeBracket] vocabulary (corrupted/legacy
  /// data) — shown as "unclassified", same convention as
  /// `EcBoardAgeGroupCount.ageBracket` on the live/synced side, never
  /// silently reassigned to a real bracket.
  final AgeBracket? ageBracket;

  /// Display-only: the chosen household's name (existing family's
  /// head-of-family name, or the new household's head name) — never
  /// re-derived from a live lookup on this row, so the list stays
  /// cheap to render.
  final String householdLabel;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int attemptCount;
  final PendingErrorCategory? lastErrorCategory;
  final String? lastErrorMessage;

  /// Sectoral flags ticked for this one person — what the EC Board's
  /// pending sectoral table counts, additive per person exactly the way
  /// the pending age/sex breakdown counts [sex]/[ageBracket].
  final Set<PerPersonSectoralFlag> sectoralFlags;

  /// See [EcBoardEntryDraft.headIsSelf] — for a pending new household,
  /// whether it already has its head (so "Already here" doesn't offer
  /// linking one).
  final bool headIsSelf;

  /// This entry's household answers by the server's own rule — see the
  /// same-named [EcBoardEntryDraft] getters. Counted once per pending
  /// new household on the EC Board's "added on this device" sectoral
  /// figures, by [newHouseholdHeadSex].
  final bool createsChildHeadedHousehold;
  final bool createsSingleHeadedHousehold;
  final String? newHouseholdHeadSex;
}

/// The full record for the Review/Edit screen.
class PendingEcBoardEntryDetail {
  const PendingEcBoardEntryDetail({required this.summary, required this.draft});

  final PendingEcBoardEntrySummary summary;
  final EcBoardEntryDraft draft;
}

/// This device's not-yet-synced contribution to the EC Board's sectoral
/// figures, counted by the server's own rule so it lines up row-for-row
/// with the live board: each ticked per-person flag once, by that
/// person's sex, and child-/single-headed family once per pending NEW
/// household, by its head's sex. An unknown sex is counted in neither
/// column, and "not yet known" answers never count — same as the server.
/// Always all 8 groups, zero-filled.
Map<SectoralGroup, ({int male, int female})> countPendingSectoral(
  Iterable<PendingEcBoardEntrySummary> entries,
) {
  final counts = {
    for (final group in SectoralGroup.values) group: (male: 0, female: 0),
  };
  void add(SectoralGroup group, String? sex) {
    final c = counts[group]!;
    counts[group] = switch (sex) {
      'male' => (male: c.male + 1, female: c.female),
      'female' => (male: c.male, female: c.female + 1),
      _ => c,
    };
  }

  for (final entry in entries) {
    for (final flag in entry.sectoralFlags) {
      add(flag.sectoralGroup, entry.sex);
    }
    if (entry.createsChildHeadedHousehold) {
      add(SectoralGroup.childHeadedFamily, entry.newHouseholdHeadSex);
    }
    if (entry.createsSingleHeadedHousehold) {
      add(SectoralGroup.singleHeadedFamily, entry.newHouseholdHeadSex);
    }
  }
  return counts;
}
