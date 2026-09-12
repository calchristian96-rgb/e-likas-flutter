import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dio_factory.dart';

part 'api_client.g.dart';

/// Thin Dio wrapper around the E-LIKAS public API.
///
/// Every call is an unauthenticated GET — no Authorization header is
/// ever attached here, matching the handoff document's contract that
/// the Flutter app never authenticates. This client's [Dio] instance
/// is never shared with `StaffApiClient` (core/network/staff_api_client.dart),
/// so that client's auth-token interceptor can never leak onto a
/// resident request.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? buildDio();

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    // An explicit outer bound in addition to Dio's own connect/receive
    // timeouts above — a deliberate belt-and-suspenders safety net.
    // Every quick action that fetches data goes through this one
    // shared client, so this guarantees none of them can hang
    // indefinitely regardless of how a specific device or network
    // condition interacts with Dio's own timeout handling.
    return _dio
        .get(path, queryParameters: queryParameters)
        .timeout(const Duration(seconds: 12));
  }
}

/// Single shared ApiClient for the whole app — every feature's remote
/// datasource watches this instead of constructing its own.
@riverpod
ApiClient apiClient(Ref ref) => ApiClient();
