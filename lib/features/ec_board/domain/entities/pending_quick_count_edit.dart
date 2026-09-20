import '../../../family_registration/domain/entities/pending_registration_status.dart';
import 'sectoral_group_draft.dart';

/// This device's own not-yet-synced sectoral/4Ps edit for one
/// center+event — at most one exists at a time per (center, event),
/// unlike the Add Evacuee queue's many discrete entries: this is a
/// single mutable aggregate, not a list of records, so a second save
/// before the first syncs simply replaces it rather than queuing
/// alongside it (see `EcBoardRepository.saveQuickCountEdit`'s doc
/// comment).
class PendingQuickCountEditSummary {
  const PendingQuickCountEditSummary({
    required this.evacuationCenterId,
    required this.evacuationEventId,
    required this.status,
    required this.beneficiaries4ps,
    required this.createdAt,
    required this.updatedAt,
    this.attemptCount = 0,
    this.lastErrorCategory,
    this.lastErrorMessage,
  });

  final int evacuationCenterId;
  final int evacuationEventId;
  final PendingRegistrationStatus status;
  final int beneficiaries4ps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attemptCount;
  final PendingErrorCategory? lastErrorCategory;
  final String? lastErrorMessage;
}

/// The full record, including the draft itself — what the sectoral/4Ps
/// edit form re-opens to let staff keep adjusting an unsynced save.
class PendingQuickCountEditDetail {
  const PendingQuickCountEditDetail({
    required this.summary,
    required this.draft,
  });

  final PendingQuickCountEditSummary summary;
  final SectoralGroupDraft draft;
}
