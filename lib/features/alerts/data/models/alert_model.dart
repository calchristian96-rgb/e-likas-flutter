import '../../domain/entities/alert.dart';

/// JSON model for a public alert from `/public/alerts`, and the
/// in-memory shape `AlertsLocalDatasource` reads/writes to Drift.
///
/// **One decision specific to this model:** `dateSent` is
/// stored as [dateSentUtcMs], an `int?` of epoch milliseconds, rather
/// than as an Isar `DateTime` field. Isar does support `DateTime`
/// natively, but it normalizes on write and hands values back in
/// *local* time — a round-trip that silently shifts a displayed
/// timestamp rather than failing loudly. Every alert timestamp in this
/// app is a display value shown next to the word "sent," so a silent
/// shift is exactly the wrong failure mode. An epoch int is also the
/// same plain-primitive surface the other two models deliberately
/// stick to, and it makes newest-first sorting a plain integer compare.
class AlertModel {
  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    required this.status,
    this.dateSentUtcMs,
    this.evacuationEventName,
    this.senderName,
    this.recipientSummary,
    this.severity,
  });

  /// The backend's own numeric id, doubling as the Drift primary key.
  final int id;

  final String title;
  final String message;
  final String alertType;
  final String status;

  /// One of `mandatory`, `advisory`, `info`, `all_clear` — from
  /// `AlertResource::toArray()`'s `severity` key. Nullable rather than
  /// defaulted: unlike [alertType]/[status], there's no single severity
  /// value that's safe to assume when the field is missing.
  final String? severity;

  /// `dateSent` as epoch milliseconds **in UTC**, or null when the API
  /// sent no parsable date. See the class doc comment for why this
  /// isn't a `DateTime` field.
  final int? dateSentUtcMs;

  final String? evacuationEventName;
  final String? senderName;
  final String? recipientSummary;

  /// The one place alert JSON is parsed — moved here from
  /// [AlertsRemoteDatasource] so the cache and the network path can't
  /// drift into two different interpretations of the same payload.
  ///
  /// The five original fields use the key names the Home Dashboard
  /// slice already confirmed. The three added fields do **not** have
  /// confirmed key names yet, so each tries the two shapes a Laravel
  /// API most plausibly returns — a nested relation object
  /// (`evacuation_event: {name: ...}`) or a flattened sibling key
  /// (`evacuation_event_name: ...`) — and falls back to null rather
  /// than throwing. Worth replacing with the single real key for each
  /// once a live response is available.
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      alertType: (json['alert_type'] as String?) ?? 'advisory',
      status: (json['status'] as String?) ?? 'sent',
      severity: json['severity'] as String?,
      dateSentUtcMs: _parseDateToUtcMs(json['date_sent'] ?? json['created_at']),
      evacuationEventName: _nestedOrFlat(
        json,
        nestedKey: 'evacuation_event',
        nestedField: 'name',
        flatKey: 'evacuation_event_name',
      ),
      senderName: _nestedOrFlat(
        json,
        nestedKey: 'sender',
        nestedField: 'name',
        flatKey: 'sender_name',
      ),
      recipientSummary: _recipientSummary(json),
    );
  }

  Alert toEntity() {
    return Alert(
      id: id,
      title: title,
      message: message,
      alertType: alertType,
      status: status,
      severity: severity,
      dateSent: dateSentUtcMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              dateSentUtcMs!,
              isUtc: true,
            ).toLocal(),
      evacuationEventName: evacuationEventName,
      senderName: senderName,
      recipientSummary: recipientSummary,
    );
  }

  /// Converted to UTC before storing so the value written is
  /// unambiguous regardless of the device's timezone at write time;
  /// [toEntity] converts back to local for display.
  static int? _parseDateToUtcMs(dynamic value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed?.toUtc().millisecondsSinceEpoch;
  }

  static String? _nestedOrFlat(
    Map<String, dynamic> json, {
    required String nestedKey,
    required String nestedField,
    required String flatKey,
  }) {
    final nested = json[nestedKey];
    if (nested is Map && nested[nestedField] is String) {
      return nested[nestedField] as String;
    }
    final flat = json[flatKey];
    return flat is String ? flat : null;
  }

  /// Same defensive idea as [_nestedOrFlat], with one extra shape: a
  /// plain recipient *count* is a plausible response too, and reads
  /// perfectly well as a summary line once labelled.
  static String? _recipientSummary(Map<String, dynamic> json) {
    final summary = json['recipient_summary'];
    if (summary is String && summary.isNotEmpty) return summary;

    final count = json['recipients_count'] ?? json['recipient_count'];
    if (count is num) {
      final n = count.toInt();
      return n == 1 ? '1 recipient' : '$n recipients';
    }
    return null;
  }
}
