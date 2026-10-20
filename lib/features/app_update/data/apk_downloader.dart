import 'dart:io';

import 'package:dio/dio.dart';

/// Cancels a running [ApkDownloader.download]. Dio-free so the
/// interface (and its test fakes) don't depend on the HTTP client.
class DownloadCancellation {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }
}

class DownloadCancelledException implements Exception {
  const DownloadCancelledException();
}

abstract class ApkDownloader {
  /// Downloads [url] to [destination] over a single connection. Throws
  /// [DownloadCancelledException] when [cancellation] fires; any other
  /// exception means the download failed or was truncated.
  Future<void> download(
    Uri url,
    File destination, {
    required void Function(int received, int total) onProgress,
    required DownloadCancellation cancellation,
  });
}

class DioApkDownloader implements ApkDownloader {
  DioApkDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<void> download(
    Uri url,
    File destination, {
    required void Function(int received, int total) onProgress,
    required DownloadCancellation cancellation,
  }) async {
    final token = CancelToken();
    cancellation._onCancel = () => token.cancel();
    if (cancellation.isCancelled) token.cancel();
    try {
      // A single streamed GET: one connection, no parallel segments, and
      // Dio writes straight to disk. `identity` stops any intermediary
      // from compressing the APK, which would make the received byte
      // count disagree with Content-Length.
      await _dio.downloadUri(
        url,
        destination.path,
        cancelToken: token,
        deleteOnError: true,
        onReceiveProgress: onProgress,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          connectTimeout: const Duration(seconds: 15),
          headers: const {'Accept-Encoding': 'identity'},
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) throw const DownloadCancelledException();
      rethrow;
    } finally {
      cancellation._onCancel = null;
    }
  }
}
