import 'package:dio/dio.dart';

import '../env/env.dart';
import 'network_interceptors.dart';

/// Shared Dio construction for both the public [ApiClient] and the
/// staff-only `StaffApiClient` — same base URL, same timeouts, same
/// [LoggingInterceptor] (which only ever logs method/URI/status, never
/// request/response bodies, so it's safe for staff traffic too).
///
/// Each caller gets its own [Dio] instance rather than sharing one, so
/// an interceptor added to one (e.g. the staff auth-token interceptor)
/// can never affect the other's requests.
Dio buildDio({List<Interceptor> extraInterceptors = const []}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.addAll(extraInterceptors);
  dio.interceptors.add(LoggingInterceptor());
  return dio;
}
