/// One barangay's status in the current event, as the public sees it:
/// words only, no note, who, when or counts (backend map-api.md,
/// `GET /public/gis/barangay-status`).
class BarangayStatus {
  const BarangayStatus({
    required this.id,
    required this.name,
    required this.status,
    required this.label,
    this.psgcCode,
    this.slug,
    this.pushTopic,
  });

  /// e.g. `tula-tula-pequeno`, and its push topic as the API names it
  /// (`elikas-brgy-tula-tula-pequeno`): the app never builds topics.
  final String? slug;
  final String? pushTopic;

  final int id;
  final String name;

  /// Matches the barangay outline in the static boundaries file.
  final String? psgcCode;

  /// normal | watch | flooding_reported | preemptive_evacuation |
  /// forced_evacuation
  final String status;

  /// The backend's own wording, e.g. "Flooding reported".
  final String label;

  bool get isNormal => status == BarangayStatusKey.normal;

  /// 0 (normal) to 4 (forced evacuation), the backend's `rank`.
  int get rank => BarangayStatusKey.rank(status);

  factory BarangayStatus.fromJson(Map<String, dynamic> json) => BarangayStatus(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    psgcCode: json['psgc_code'] as String?,
    status: json['status'] as String? ?? BarangayStatusKey.normal,
    label: json['label'] as String? ?? 'Normal',
    slug: json['slug'] as String?,
    pushTopic: json['push_topic'] as String?,
  );
}

abstract final class BarangayStatusKey {
  static const normal = 'normal';
  static const watch = 'watch';
  static const floodingReported = 'flooding_reported';
  static const preemptiveEvacuation = 'preemptive_evacuation';
  static const forcedEvacuation = 'forced_evacuation';

  static const ordered = [
    normal,
    watch,
    floodingReported,
    preemptiveEvacuation,
    forcedEvacuation,
  ];

  static int rank(String status) {
    final i = ordered.indexOf(status);
    return i < 0 ? 0 : i;
  }
}

/// The whole public board: the current real event (or a drill, when the
/// backend shows a demo event publicly) and every barangay's status.
class BarangayStatusBoard {
  const BarangayStatusBoard({
    required this.barangays,
    this.eventName,
    this.eventStatus,
    this.isDrill = false,
    this.isFromCache = false,
    this.lastSyncedAt,
    this.eventType,
    this.cityPushTopic,
  });

  /// `city_push_topic` (`elikas-city`); null on a saved copy.
  final String? cityPushTopic;

  /// e.g. `typhoon`, `volcanic_eruption` (the public board's event).
  final String? eventType;

  /// A volcanic event: centers within 7 km of Mayon's summit are inside
  /// the danger zone too.
  bool get isVolcanic => eventType == 'volcanic_eruption';

  final List<BarangayStatus> barangays;

  /// Null when no event is open: every barangay is then normal.
  final String? eventName;
  final String? eventStatus;

  /// The open event is a drill with made-up data (`is_drill`).
  final bool isDrill;
  final bool isFromCache;
  final DateTime? lastSyncedAt;

  bool get hasOpenEvent => eventName != null;

  BarangayStatus? byId(int? id) {
    if (id == null) return null;
    for (final b in barangays) {
      if (b.id == id) return b;
    }
    return null;
  }
}
