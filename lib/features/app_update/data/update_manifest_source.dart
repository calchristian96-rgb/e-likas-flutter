import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/env/env.dart';
import '../domain/app_update_manifest.dart';

const _manifestUrlOverride = String.fromEnvironment('UPDATE_MANIFEST_URL');

const updateCheckTimeout = Duration(seconds: 8);

/// `<origin of the API base URL>/downloads/version.json`, unless
/// `--dart-define=UPDATE_MANIFEST_URL=...` says otherwise. Reuses
/// [Env.apiBaseUrl] so the domain is configured in exactly one place.
Uri resolveManifestUri({
  String override = _manifestUrlOverride,
  String? apiBaseUrl,
}) {
  final explicit = Uri.tryParse(override.trim());
  if (override.trim().isNotEmpty && explicit != null) return explicit;
  final base = Uri.parse(apiBaseUrl ?? Env.apiBaseUrl);
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: '/downloads/version.json',
  );
}

/// Fetches and parses the version manifest. Uses its own plain [Dio] —
/// deliberately NOT the app's API client — so no auth interceptor can
/// ever attach the API token to a request for a static file.
class UpdateManifestSource {
  UpdateManifestSource({Dio? dio, Uri? manifestUri, DateTime Function()? clock})
    : _dio = dio ?? Dio(),
      _manifestUri = manifestUri ?? resolveManifestUri(),
      _clock = clock ?? DateTime.now;

  final Dio _dio;
  final Uri _manifestUri;
  final DateTime Function() _clock;

  /// The manifest, or null for every failure (offline, 404, bad JSON,
  /// invalid contents). Never throws.
  Future<AppUpdateManifest?> fetch() async {
    try {
      final response = await _dio
          .getUri<String>(
            // Cache-buster: a CDN or proxy must never serve a stale
            // manifest.
            _manifestUri.replace(
              queryParameters: {
                ..._manifestUri.queryParameters,
                't': _clock().millisecondsSinceEpoch.toString(),
              },
            ),
            options: Options(
              responseType: ResponseType.plain,
              sendTimeout: updateCheckTimeout,
              connectTimeout: updateCheckTimeout,
              receiveTimeout: updateCheckTimeout,
              headers: const {
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(updateCheckTimeout);
      final body = response.data;
      if (body == null) return null;
      return AppUpdateManifest.tryParse(
        jsonDecode(body),
        manifestUri: _manifestUri,
      );
    } catch (_) {
      return null;
    }
  }
}
