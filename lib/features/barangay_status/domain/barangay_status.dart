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
  });

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
  });

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
