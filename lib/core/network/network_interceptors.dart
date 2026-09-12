import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs requests/responses in debug builds only — a no-op in release,
/// so nothing about the (already public, unauthenticated) API traffic
/// gets logged in a shipped build.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      // err.type distinguishes connectionTimeout/receiveTimeout/sendTimeout,
      // connectionError (covers DNS failure), badCertificate (SSL/TLS), and
      // badResponse (HTTP error status, in err.response?.statusCode) from
      // one another — err.message alone doesn't reliably tell these apart.
      final status = err.response?.statusCode;
      debugPrint(
        '✕ ${err.requestOptions.uri}: ${err.type}'
        '${status != null ? ' (HTTP $status)' : ''} — ${err.message}',
      );
      // Laravel's own error envelope (`{"message": "...", "exception":
      // "..."}` — the "exception" key only appears with APP_DEBUG=true
      // server-side) is our own backend's diagnostic text, not request
      // credentials or PII — safe to log the two fields specifically,
      // never the raw body wholesale (which could be an HTML error page
      // instead of JSON, or carry a full stack trace under "trace").
      final body = err.response?.data;
      if (body is Map) {
        final message = body['message'];
        final exception = body['exception'];
        if (message != null || exception != null) {
          debugPrint(
            '✕ server error body: message=$message exception=$exception',
          );
        }
      }
    }
    handler.next(err);
  }
}
