import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/apk_downloader.dart';
import '../../data/apk_installer.dart';
import '../../data/apk_update_service.dart';
import '../../data/app_update_repository.dart';
import '../../data/update_manifest_source.dart';
import '../../data/update_snooze_store.dart';
import '../../domain/app_update_manifest.dart';

/// The in-app updater only exists on Android; everywhere else it is a
/// no-op and its Settings row is hidden. Overridable in tests.
final updateSupportedProvider = Provider<bool>(
  (ref) => !kIsWeb && Platform.isAndroid,
);

/// Installed version/build via package_info_plus, or null when it can't
/// be read (the update check is then skipped).
final installedAppInfoProvider = FutureProvider<InstalledAppInfo?>(
  (ref) => readInstalledAppInfo(),
);

Future<InstalledAppInfo?> readInstalledAppInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber);
    if (build == null) return null;
    return InstalledAppInfo(version: info.version, build: build);
  } catch (_) {
    return null;
  }
}

final apkDownloaderProvider = Provider<ApkDownloader>(
  (ref) => DioApkDownloader(),
);

final apkInstallerProvider = Provider<ApkInstaller>(
  (ref) => const OpenFilexApkInstaller(),
);

/// Opens a URL in the external browser. A provider so tests don't hit
/// the platform channel.
final externalUrlOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

final apkUpdateServiceProvider = Provider<ApkUpdateService>(
  (ref) => ApkUpdateService(
    downloader: ref.watch(apkDownloaderProvider),
    workDirectory: getTemporaryDirectory,
  ),
);

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(
    // Plain Dio inside the source: never the app's authenticated client.
    source: UpdateManifestSource(),
    snoozeStore: UpdateSnoozeStore(),
    service: ref.watch(apkUpdateServiceProvider),
    installedInfo: readInstalledAppInfo,
    isSupported: ref.watch(updateSupportedProvider),
  ),
);

enum UpdateDownloadPhase { idle, downloading, verifying, ready, failed }

class UpdateDownloadState {
  const UpdateDownloadState({
    this.phase = UpdateDownloadPhase.idle,
    this.progress,
    this.installerLaunched = false,
  });

  final UpdateDownloadPhase phase;

  /// 0..1 while downloading, null when the total size is unknown.
  final double? progress;

  /// Whether the system installer was opened for the verified file.
  final bool installerLaunched;
}

/// Runs one download-verify-install attempt for the dialog to render.
class UpdateDownloadController extends Notifier<UpdateDownloadState> {
  DownloadCancellation? _cancellation;
  File? _verifiedApk;

  @override
  UpdateDownloadState build() => const UpdateDownloadState();

  Future<void> start(AppUpdateManifest manifest) async {
    final cancellation = DownloadCancellation();
    _cancellation = cancellation;
    _verifiedApk = null;
    state = const UpdateDownloadState(phase: UpdateDownloadPhase.downloading);
    try {
      final file = await ref
          .read(apkUpdateServiceProvider)
          .downloadVerified(
            manifest,
            cancellation: cancellation,
            onProgress: (received, total) {
              if (cancellation.isCancelled) return;
              final progress = total > 0 ? received / total : null;
              // Only rebuild when the whole-percent value moves.
              final previous = state.progress;
              if (progress != null &&
                  previous != null &&
                  (progress * 100).floor() == (previous * 100).floor()) {
                return;
              }
              state = UpdateDownloadState(
                phase: UpdateDownloadPhase.downloading,
                progress: progress,
              );
            },
            onVerifying: () {
              state = const UpdateDownloadState(
                phase: UpdateDownloadPhase.verifying,
              );
            },
          );
      _verifiedApk = file;
      final launched = await ref.read(apkInstallerProvider).install(file);
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.ready,
        installerLaunched: launched,
      );
    } on DownloadCancelledException {
      state = const UpdateDownloadState();
    } catch (_) {
      state = const UpdateDownloadState(phase: UpdateDownloadPhase.failed);
    }
  }

  void cancel() => _cancellation?.cancel();

  /// Re-opens the Android installer for the already verified file, e.g.
  /// after the resident granted "install unknown apps" and came back.
  Future<void> installAgain() async {
    final file = _verifiedApk;
    if (file == null) return;
    final launched = await ref.read(apkInstallerProvider).install(file);
    state = UpdateDownloadState(
      phase: UpdateDownloadPhase.ready,
      installerLaunched: launched,
    );
  }

  void reset() {
    _cancellation?.cancel();
    state = const UpdateDownloadState();
  }
}

final updateDownloadControllerProvider =
    NotifierProvider<UpdateDownloadController, UpdateDownloadState>(
      UpdateDownloadController.new,
    );
