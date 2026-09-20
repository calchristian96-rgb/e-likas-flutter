import '../../../family_registration/domain/entities/pending_registration_status.dart';
import 'age_bracket.dart';
import 'ec_board_entry_draft.dart';

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
}

/// The full record for the Review/Edit screen.
class PendingEcBoardEntryDetail {
  const PendingEcBoardEntryDetail({required this.summary, required this.draft});

  final PendingEcBoardEntrySummary summary;
  final EcBoardEntryDraft draft;
}
