/// A public alert, as returned by `/public/alerts`.
///
/// The original five fields (id, title, message, alertType, status,
/// dateSent) are exactly as the Home Dashboard's minimal slice defined
/// them and are unchanged — [LatestAlertCard] and [AlertListTile] keep
/// working against them without edits.
///
/// The full Alerts phase adds the three fields that slice deliberately
/// deferred, all **optional**: `evacuationEventName`, `senderName`, and
/// `recipientSummary`. Optional both because they're only shown on the
/// details screen, and because their exact JSON key names aren't
/// confirmed against a real response yet (see
/// [AlertModel.fromJson] for the defensive parsing and the specific
/// keys it tries). A missing one hides its row in the UI rather than
/// failing the parse.
///
/// Sender is a *display name* only. Contact details are excluded from
/// the public API by design, so there is deliberately no phone/email
/// field here to accidentally surface one.
class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    required this.status,
    required this.dateSent,
    this.evacuationEventName,
    this.senderName,
    this.recipientSummary,
    this.severity,
  });

  final int id;
  final String title;
  final String message;
  final String alertType;
  final String status;

  /// One of `mandatory`, `advisory`, `info`, `all_clear`, straight from
  /// the backend's `severity` field. Nullable — see [AlertModel].
  final String? severity;

  /// Nullable defensively — every alert this endpoint returns should
  /// have one (the API only returns `status=sent` alerts), but a
  /// missing or unparsable date shouldn't crash the dashboard over a
  /// display field.
  final DateTime? dateSent;

  /// The evacuation event this alert was raised under, if any. Plain
  /// name only — the full event is its own resource and isn't fetched
  /// here.
  final String? evacuationEventName;

  /// Display name of whoever sent the alert (an office or officer
  /// name). Never contact details — see the class doc comment.
  final String? senderName;

  /// Human-readable "who this went to" line, e.g. a barangay list or a
  /// recipient count. Free-form text straight from the API; not parsed
  /// into structure because nothing in the UI needs it structured.
  final String? recipientSummary;
}
