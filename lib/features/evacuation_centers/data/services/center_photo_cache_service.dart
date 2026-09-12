import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/debug/center_photo_debug_log.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/utils/fast_hash.dart';

part 'center_photo_cache_service.g.dart';

/// A small on-disk cache of evacuation-center photos — reusing this
/// app's existing `dio` (for the download) and `path_provider` (for
/// where to put the file) rather than adding a new image-caching
/// package, since neither Flutter's own `Image.network` nor any
/// in-memory cache survives an app restart, and the task requires
/// *actual* offline availability.
///
/// Every file lives under `<app documents>/evacuation_center_photos/`,
/// named `center_<centerId>_<hash of the photo URL>` — namespacing by
/// [centerId] in the filename itself means center A can never show
/// center B's cached image even if two URLs happened to hash the same
/// way, and hashing the URL means a changed photo URL naturally maps
/// to a different filename rather than silently reusing stale bytes.
/// [downloadAndCache] deletes any other cached file for the same
/// [centerId] before writing the new one, so a changed URL replaces
/// the old cache entry instead of accumulating duplicates forever.
///
/// Paths are joined with plain [Platform.pathSeparator] string
/// interpolation rather than the `path` package — avoids adding it as
/// a new direct dependency for something this simple (a two-segment
/// join and a basename split, both doable with `dart:io` alone).
class CenterPhotoCacheService {
  CenterPhotoCacheService(this._dio);

  final Dio _dio;

  Future<Directory> _photosDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documentsDir.path}${Platform.pathSeparator}evacuation_center_photos',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileNameFor(int centerId, String url) =>
      'center_${centerId}_${fastHash(url)}';

  String _pathIn(Directory dir, String fileName) =>
      '${dir.path}${Platform.pathSeparator}$fileName';

  /// The cached file for this exact (center, URL) pair, or null if
  /// nothing's usable is cached for it (never cached, cache was
  /// cleared, the URL changed since the last successful cache, or the
  /// file that's there turns out to be invalid).
  ///
  /// Self-healing: a zero-byte file can never be a real photo, so one
  /// found here is treated as not cached at all — evicted immediately
  /// rather than ever being handed to `Image.file` (which would just
  /// show a broken-image icon) — so the next successful online
  /// download can take its place. [downloadAndCache] itself already
  /// refuses to write a file unless the HTTP response was a real 200
  /// with bytes on disk, so this mainly guards against a file left
  /// over from before that safeguard existed (e.g. the historical
  /// production HTTP 403 period) rather than anything the current
  /// download path can produce going forward.
  Future<File?> getCachedFile(int centerId, String url) async {
    final dir = await _photosDirectory();
    final file = File(_pathIn(dir, _fileNameFor(centerId, url)));
    if (!await file.exists()) return null;

    final length = await file.length();
    if (length == 0) {
      centerPhotoDebugLog(
        'cached file for centerId=$centerId is zero-byte — evicting',
      );
      await _safeDelete(file);
      return null;
    }
    return file;
  }

  /// Downloads [url] and caches it for [centerId], replacing any
  /// previously-cached file for this center. Returns the cached
  /// [File] on success, or null on any failure (bad URL, network
  /// error, non-200 response, disk error) — callers fall back to
  /// [getCachedFile] or a placeholder, never crash.
  Future<File?> downloadAndCache(int centerId, String url) async {
    try {
      final dir = await _photosDirectory();
      final fileName = _fileNameFor(centerId, url);
      final tempFile = File(_pathIn(dir, '$fileName.tmp'));

      final response = await _dio.download(
        url,
        tempFile.path,
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      final tempExists = await tempFile.exists();
      centerPhotoDebugLog(
        'image url http status=${response.statusCode} '
        'file written=$tempExists',
      );
      if (response.statusCode != 200 || !tempExists) {
        await _safeDelete(tempFile);
        return null;
      }

      await _evictOtherFilesForCenter(dir, centerId, keepFileName: fileName);

      final finalFile = File(_pathIn(dir, fileName));
      await _safeDelete(finalFile);
      final saved = await tempFile.rename(finalFile.path);
      centerPhotoDebugLog(
        'image cached at path=${saved.path} exists after write='
        '${await saved.exists()}',
      );
      return saved;
    } catch (e) {
      centerPhotoDebugLog('image download failed error=${e.runtimeType}');
      return null;
    }
  }

  /// Removes every cached file for [centerId] other than
  /// [keepFileName] — the mechanism that makes a changed photo URL
  /// replace the old one instead of leaving it to accumulate on disk
  /// forever.
  Future<void> _evictOtherFilesForCenter(
    Directory dir,
    int centerId, {
    required String keepFileName,
  }) async {
    final prefix = 'center_${centerId}_';
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final separator = Platform.pathSeparator;
      final name = entity.path.split(separator).last;
      if (name.startsWith(prefix) && name != keepFileName) {
        await _safeDelete(entity);
      }
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup — a leftover temp/stale file costs a few
      // KB and is harmless; failing the whole cache operation over it
      // would not be.
    }
  }
}

@riverpod
CenterPhotoCacheService centerPhotoCacheService(Ref ref) =>
    CenterPhotoCacheService(buildDio());
