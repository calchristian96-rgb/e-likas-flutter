import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../security/secure_token_storage.dart';
import 'dio_factory.dart';

part 'staff_api_client.g.dart';

/// Authenticated Dio wrapper for the staff module — everything
/// [ApiClient] (core/network/api_client.dart) never needed: `POST`,
/// `PATCH`, `PUT`, and a Bearer token attached from
/// [SecureTokenStorage].
///
/// Deliberately its own [Dio] instance (via the same [buildDio]
/// factory the public client uses) rather than a shared one: the
/// public client's whole contract is "never sends an Authorization
/// header," and giving it a code path that sometimes attaches one
/// would put that invariant one refactor away from silently breaking.
class StaffApiClient {
  StaffApiClient({SecureTokenStorage? tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
      _dio = dio ?? buildDio() {
    if (dio == null) {
      _dio.interceptors.insert(0, _authInterceptor());
    }
  }

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio
        .get(path, queryParameters: queryParameters)
        .timeout(const Duration(seconds: 12));
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _dio.post(path, data: data).timeout(timeout);
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _dio.patch(path, data: data).timeout(timeout);
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _dio.put(path, data: data).timeout(timeout);
  }
}

/// Single shared StaffApiClient — every staff feature's remote
/// datasource watches this instead of constructing its own, same
/// convention as [ApiClient]'s provider.
@riverpod
StaffApiClient staffApiClient(Ref ref) => StaffApiClient();
