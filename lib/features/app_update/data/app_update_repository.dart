import '../domain/app_update_manifest.dart';
import '../domain/update_decision.dart';
import 'apk_update_service.dart';
import 'update_manifest_source.dart';
import 'update_snooze_store.dart';

/// The installed app's `version` (pubspec name) and `build` (number
/// after the `+`, i.e. the Android versionCode).
class InstalledAppInfo {
  const InstalledAppInfo({required this.version, required this.build});

  final String version;
  final int build;
}

class UpdateOffer {
  const UpdateOffer({required this.manifest, required this.kind});

  final AppUpdateManifest manifest;
  final UpdateKind kind;
}

enum ManualCheckOutcome { upToDate, offer, failed }

class ManualCheckResult {
  const ManualCheckResult(this.outcome, [this.offer]);

  final ManualCheckOutcome outcome;
  final UpdateOffer? offer;
}

/// Decides whether the resident should be offered an update. Every
/// failure path resolves to "no update" — nothing here throws.
class AppUpdateRepository {
  AppUpdateRepository({
    required this.source,
    required this.snoozeStore,
    required this.service,
    required this.installedInfo,
    required this.isSupported,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final UpdateManifestSource source;
  final UpdateSnoozeStore snoozeStore;
  final ApkUpdateService service;
  final Future<InstalledAppInfo?> Function() installedInfo;

  /// False off Android: every check becomes a no-op.
  final bool isSupported;
  final DateTime Function() _clock;

  DateTime? _lastSuccessfulCheck;
  bool _checking = false;

  /// The automatic check: once per cold start ([coldStart]) and, on app
  /// resume, only when more than [updateResumeCheckInterval] has passed
  /// since the last successful one. Honors the 24 h snooze for optional
  /// updates; a required update is offered every time.
  Future<UpdateOffer?> checkAutomatically({required bool coldStart}) async {
    if (!isSupported || _checking) return null;
    _checking = true;
    try {
      if (coldStart) {
        await service.deleteLeftovers();
      } else {
        final last = _lastSuccessfulCheck;
        if (last != null &&
            _clock().difference(last) < updateResumeCheckInterval) {
          return null;
        }
      }
      final info = await installedInfo();
      if (info == null) return null;
      final manifest = await source.fetch();
      if (manifest == null) return null;
      _lastSuccessfulCheck = _clock();

      final kind = decideUpdate(manifest, info.build);
      if (kind == UpdateKind.none) return null;
      if (kind == UpdateKind.optional &&
          await snoozeStore.isSnoozed(manifest.latestBuild)) {
        return null;
      }
      return UpdateOffer(manifest: manifest, kind: kind);
    } catch (_) {
      return null;
    } finally {
      _checking = false;
    }
  }

  /// The Settings "Check for updates" tap: ignores the snooze and the
  /// resume interval, and reports failure instead of staying silent.
  Future<ManualCheckResult> checkManually() async {
    if (!isSupported) {
      return const ManualCheckResult(ManualCheckOutcome.upToDate);
    }
    try {
      final info = await installedInfo();
      if (info == null) {
        return const ManualCheckResult(ManualCheckOutcome.failed);
      }
      final manifest = await source.fetch();
      if (manifest == null) {
        return const ManualCheckResult(ManualCheckOutcome.failed);
      }
      _lastSuccessfulCheck = _clock();
      final kind = decideUpdate(manifest, info.build);
      if (kind == UpdateKind.none) {
        return const ManualCheckResult(ManualCheckOutcome.upToDate);
      }
      return ManualCheckResult(
        ManualCheckOutcome.offer,
        UpdateOffer(manifest: manifest, kind: kind),
      );
    } catch (_) {
      return const ManualCheckResult(ManualCheckOutcome.failed);
    }
  }

  Future<void> snooze(int latestBuild) => snoozeStore.snooze(latestBuild);
}
