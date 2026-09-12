/// The three states a queued registration can be in, matching the
/// task spec's own vocabulary exactly. `syncing` is transient — it
/// only exists while `StaffSyncService` has an active request in
/// flight for that record; nothing user-facing should linger in it.
enum PendingRegistrationStatus {
  pending,
  syncing,
  needsAttention;

  String get wireValue => switch (this) {
    PendingRegistrationStatus.pending => 'pending',
    PendingRegistrationStatus.syncing => 'syncing',
    PendingRegistrationStatus.needsAttention => 'needsAttention',
  };

  static PendingRegistrationStatus fromWire(String value) => switch (value) {
    'pending' => PendingRegistrationStatus.pending,
    'syncing' => PendingRegistrationStatus.syncing,
    _ => PendingRegistrationStatus.needsAttention,
  };
}

/// Why a record landed in [PendingRegistrationStatus.needsAttention] —
/// each maps to a distinct instruction from the sync spec, so the
/// Pending Registrations screen can show a specific, honest reason
/// instead of a generic "failed."
enum PendingErrorCategory {
  /// Backend 422 — the record stays editable, field errors are in
  /// `PendingFamilyRegistrationModel.fieldErrorsJson`.
  validation,

  /// Backend 403 — this staff member (or their barangay scope) isn't
  /// allowed to register this family. Not retried automatically.
  forbidden,

  /// A timeout or dropped connection *after* the POST was already
  /// sent — the backend may or may not have committed it. Retrying
  /// automatically could create a duplicate family, since the backend
  /// has no idempotency protection (confirmed by the backend audit),
  /// so this requires an explicit, informed manual retry.
  ambiguous,

  /// Backend 5xx surfaced after retries stopped making sense, or any
  /// other unclassified failure.
  server;

  String get wireValue => switch (this) {
    PendingErrorCategory.validation => 'validation',
    PendingErrorCategory.forbidden => 'forbidden',
    PendingErrorCategory.ambiguous => 'ambiguous',
    PendingErrorCategory.server => 'server',
  };

  static PendingErrorCategory fromWire(String value) => switch (value) {
    'validation' => PendingErrorCategory.validation,
    'forbidden' => PendingErrorCategory.forbidden,
    'ambiguous' => PendingErrorCategory.ambiguous,
    _ => PendingErrorCategory.server,
  };
}
