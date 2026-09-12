import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/debug/center_photo_debug_log.dart';
import '../../data/services/center_photo_cache_service.dart';

part 'center_photo_provider.g.dart';

/// Resolves a center's photo to a local [File] the UI can render with
/// `Image.file`, following exactly the network-first-with-cache-
/// fallback behavior the task specifies:
///
/// - online: download, cache it, return the freshly-downloaded file
///   (this *is* "the network photo" — its bytes are literally the
///   just-received response, simply read back from where they were
///   just written rather than re-streamed from memory).
/// - online but the download fails: fall back to whatever's already
///   cached for this exact URL, if anything.
/// - offline: whatever's already cached for this exact URL, if
///   anything.
/// - no cache either way: null, which the UI renders as the neutral
///   placeholder — never a broken-image icon or raw error.
@riverpod
Future<File?> centerPhotoFile(Ref ref, int centerId, String? photoUrl) async {
  if (photoUrl == null || photoUrl.isEmpty) {
    centerPhotoDebugLog(
      'centerPhotoFile centerId=$centerId photoUrl is null/empty',
    );
    return null;
  }

  final cache = ref.watch(centerPhotoCacheServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final online = await connectivity.hasConnection;
  centerPhotoDebugLog(
    'centerPhotoFile centerId=$centerId url=$photoUrl online=$online',
  );

  if (online) {
    final downloaded = await cache.downloadAndCache(centerId, photoUrl);
    centerPhotoDebugLog(
      'centerPhotoFile download result=${downloaded != null ? 'success path=${downloaded.path}' : 'failed'}',
    );
    if (downloaded != null) return downloaded;
  }
  final cached = await cache.getCachedFile(centerId, photoUrl);
  centerPhotoDebugLog(
    'centerPhotoFile fallback cached file=${cached != null ? 'found path=${cached.path}' : 'none'}',
  );
  return cached;
}
