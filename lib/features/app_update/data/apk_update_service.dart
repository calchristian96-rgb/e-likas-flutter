import 'dart:io';

import '../domain/apk_hash.dart';
import '../domain/app_update_manifest.dart';
import 'apk_downloader.dart';

/// The download failed (network, truncation, size or SHA-256 mismatch)
/// on every attempt.
class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.cause);
  final Object cause;

  @override
  String toString() => 'UpdateDownloadException: $cause';
}

class ApkVerificationException implements Exception {
  const ApkVerificationException(this.message);
  final String message;

  @override
  String toString() => 'ApkVerificationException: $message';
}

/// Downloads the APK, verifies it, and retries once on any failure.
/// Nothing here installs anything — the caller hands the returned file
/// to an `ApkInstaller`.
class ApkUpdateService {
  ApkUpdateService({
    required this.downloader,
    required this.workDirectory,
    this.maxAttempts = 2,
    this.retryDelay = const Duration(seconds: 2),
  });

  static const _folderName = 'app_update';

  final ApkDownloader downloader;
  final Future<Directory> Function() workDirectory;
  final int maxAttempts;
  final Duration retryDelay;

  Future<Directory> _updateDirectory() async {
    final root = await workDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}$_folderName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Downloads [manifest]'s APK and returns the verified file. Throws
  /// [DownloadCancelledException] if cancelled, otherwise
  /// [UpdateDownloadException] after the last failed attempt. A partial
  /// or failed file is always deleted.
  Future<File> downloadVerified(
    AppUpdateManifest manifest, {
    required void Function(int received, int total) onProgress,
    required void Function() onVerifying,
    required DownloadCancellation cancellation,
  }) async {
    final dir = await _updateDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}E-LIKAS-${manifest.latestBuild}.apk',
    );

    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _deleteQuietly(file);
      try {
        await downloader.download(
          manifest.apkUrl,
          file,
          onProgress: onProgress,
          cancellation: cancellation,
        );
        if (cancellation.isCancelled) {
          throw const DownloadCancelledException();
        }
        onVerifying();
        await _verify(file, manifest);
        return file;
      } on DownloadCancelledException {
        _deleteQuietly(file);
        rethrow;
      } catch (e) {
        _deleteQuietly(file);
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay);
          if (cancellation.isCancelled) {
            throw const DownloadCancelledException();
          }
        }
      }
    }
    throw UpdateDownloadException(lastError ?? 'unknown error');
  }

  Future<void> _verify(File file, AppUpdateManifest manifest) async {
    if (!file.existsSync()) {
      throw const ApkVerificationException('file missing after download');
    }
    final expectedSize = manifest.sizeBytes;
    if (expectedSize != null && file.lengthSync() != expectedSize) {
      throw ApkVerificationException(
        'size ${file.lengthSync()} != expected $expectedSize',
      );
    }
    final expectedSha = manifest.sha256;
    if (expectedSha != null) {
      final actual = await sha256OfFile(file);
      if (!sha256Matches(actual, expectedSha)) {
        throw const ApkVerificationException('SHA-256 mismatch');
      }
    }
  }

  /// Deletes every APK a previous run left in the cache. Called on
  /// cold start.
  Future<void> deleteLeftovers() async {
    try {
      final root = await workDirectory();
      final dir = Directory(
        '${root.path}${Platform.pathSeparator}$_folderName',
      );
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {
      // Housekeeping only.
    }
  }

  void _deleteQuietly(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
