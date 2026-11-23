import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Turns a [DioException] from [StaffApiClient] into the app's shared
/// [Failure] hierarchy.
///
/// The backend audit found the API returns error bodies in two
/// distinct shapes depending on whether a controller/middleware threw
/// the error by hand or Laravel's own exception handler rendered it:
///   - hand-thrown 401/403/404: `{success:false, message, errors:null}`
///   - framework-level 422/401(unauthenticated)/404(model-not-found)/500:
///     Laravel's default `{message, errors?}`
/// Both shapes happen to share the same `message`/`errors` key names
/// at the top level, so a single parser handles both without needing
/// to know which one it's looking at.
Failure mapStaffDioError(DioException err) {
  final status = err.response?.statusCode;
  final body = err.response?.data;
  final message = _extractMessage(body) ?? _fallbackMessageFor(err);

  switch (status) {
    case 401:
      return AuthFailure(message);
    case 403:
      if (_errorCode(body) == 'password_change_required') {
        return PasswordChangeRequiredFailure(message);
      }
      return ForbiddenFailure(message);
    case 423:
      return AccountLockedFailure(message);
    case 404:
      return ServerFailure(
        message.isNotEmpty ? message : 'The requested resource was not found.',
      );
    case 422:
      final fields = _extractFieldErrors(body);
      final lock = eventLockKindOf(message, fields);
      if (lock != null) return EventLockFailure(fields, message, kind: lock);
      return ValidationFailure(fields, message);
    case 429:
      return RateLimitFailure(message);
  }

  if (status == 503 && _errorCode(body) == 'maintenance') {
    return MaintenanceFailure(message);
  }
  if (status != null && status >= 500) {
    return const ServerFailure(
      'The server is having trouble right now. Please try again later.',
    );
  }

  switch (err.type) {
    // The request body was fully sent and the client was waiting on a
    // response when this fired — the server may well have processed
    // it. See [AmbiguousWriteFailure]'s doc comment.
    case DioExceptionType.receiveTimeout:
      return const AmbiguousWriteFailure();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.transformTimeout:
      return const NetworkFailure('The request timed out.');
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'Could not reach the server. Check your connection.',
      );
    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'A secure connection could not be established.',
      );
    case DioExceptionType.cancel:
      return const NetworkFailure('The request was cancelled.');
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return NetworkFailure(message);
  }
}

String? _extractMessage(Object? body) {
  if (body is Map) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return null;
}

String _fallbackMessageFor(DioException err) => switch (err.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout => 'The request timed out.',
  DioExceptionType.connectionError =>
    'Could not reach the server. Check your connection.',
  _ => 'Something went wrong. Please try again.',
};

Map<String, List<String>> _extractFieldErrors(Object? body) {
  if (body is! Map) return const {};
  final errors = body['errors'];
  if (errors is! Map) return const {};

  final result = <String, List<String>>{};
  for (final entry in errors.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is List) {
      result[key] = value.map((e) => e.toString()).toList();
    } else if (value != null) {
      result[key] = [value.toString()];
    }
  }
  return result;
}

/// Whether a 422 is one of the event locks (apps-api-2026-11-22.md
/// section 1): the server puts the message under
/// `errors.evacuation_event_id` too. Null for any other refusal.
EventLockKind? eventLockKindOf(
  String message,
  Map<String, List<String>> fieldErrors,
) {
  final m = message.toLowerCase();
  final kind = m.contains('is being monitored')
      ? EventLockKind.monitored
      : m.contains('is closed') && m.contains('read-only')
      ? EventLockKind.closed
      : m.startsWith('no open event')
      ? EventLockKind.noEvent
      : null;
  if (kind != null) return kind;
  return fieldErrors.containsKey('evacuation_event_id')
      ? EventLockKind.other
      : null;
}

String? _errorCode(Object? body) {
  if (body is! Map) return null;
  final errors = body['errors'];
  if (errors is Map && errors['code'] is String) {
    return errors['code'] as String;
  }
  return body['code'] as String?;
}
