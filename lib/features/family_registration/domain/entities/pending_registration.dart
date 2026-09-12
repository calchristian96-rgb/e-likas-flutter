import 'family_registration_draft.dart';
import 'pending_registration_status.dart';

/// What the Pending Registrations *list* screen shows — deliberately
/// only the privacy-conscious summary fields the task spec allows
/// (head-of-family name, member count, barangay, created time,
/// status), never the full member list/DOB/PWD/etc.
class PendingRegistrationSummary {
  const PendingRegistrationSummary({
    required this.localId,
    required this.status,
    required this.headOfFamilyName,
    required this.memberCount,
    required this.barangayName,
    required this.createdAt,
    required this.updatedAt,
    this.attemptCount = 0,
    this.lastErrorCategory,
    this.lastErrorMessage,
  });

  final String localId;
  final PendingRegistrationStatus status;
  final String headOfFamilyName;
  final int memberCount;
  final String barangayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attemptCount;
  final PendingErrorCategory? lastErrorCategory;
  final String? lastErrorMessage;
}

/// The full record for the Review/Edit screen — includes the actual
/// draft (so it can be resubmitted or corrected) and any field-level
/// 422 errors from the last attempt.
class PendingRegistrationDetail {
  const PendingRegistrationDetail({
    required this.summary,
    required this.draft,
    this.fieldErrors = const {},
  });

  final PendingRegistrationSummary summary;
  final FamilyRegistrationDraft draft;
  final Map<String, List<String>> fieldErrors;
}
