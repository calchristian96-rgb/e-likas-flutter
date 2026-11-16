/// Thin domain entities for the three offline lookup caches — each
/// mirrors its Isar model 1:1 field-for-field (see
/// `data/models/lookup_*_model.dart`), kept separate only so the
/// presentation layer never imports an Isar-annotated class directly,
/// matching every other feature's data/domain split in this app.
class Barangay {
  const Barangay({required this.id, required this.name});

  final int id;
  final String name;
}

class EvacuationEventLookup {
  const EvacuationEventLookup({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
    this.isDemo = false,
  });

  final int id;
  final String name;
  final String status;
  final String? startDate;
  final String? endDate;
  final bool isDemo;

  bool get isOpen => status != 'closed';
}

class EvacuationCenterLookup {
  const EvacuationCenterLookup({
    required this.id,
    required this.name,
    required this.barangayId,
    required this.status,
    this.approvalStatus = 'approved',
    this.hasPendingChange = false,
    this.rejectionReason,
  });

  final int id;
  final String name;
  final int barangayId;
  final String status;

  /// approved | pending (shown as "Unverified") | rejected.
  final String approvalStatus;

  /// An edit (for example a new location) waits for CSWD.
  final bool hasPendingChange;
  final String? rejectionReason;

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';

  /// The EC Board, check-ins and relief refuse a rejected center (422).
  bool get isUsable => !isRejected;
}
