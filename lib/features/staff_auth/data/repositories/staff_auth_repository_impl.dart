import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../../core/security/secure_token_storage.dart';
import '../../domain/entities/staff_session.dart';
import '../../domain/repositories/staff_auth_repository.dart';
import '../datasources/staff_auth_remote_datasource.dart';

class StaffAuthRepositoryImpl implements StaffAuthRepository {
  StaffAuthRepositoryImpl(this._remote, this._tokenStorage);

  final StaffAuthRemoteDataSource _remote;
  final SecureTokenStorage _tokenStorage;

  @override
  Future<Result<StaffSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.login(email: email, password: password);
      final token = data['token'] as String;
      final session = StaffSession.fromJson(
        data['user'] as Map<String, dynamic>,
      );
      // Order matters: only persist the token once the response has
      // been fully parsed, so a malformed response can't leave a
      // token stored with no usable session to go with it.
      await _tokenStorage.writeToken(token);
      await _tokenStorage.writeCachedSession(session.toJson());
      return Success(session);
    } on DioException catch (e) {
      return Failed(mapStaffDioError(e));
    } catch (_) {
      return const Failed(
        NetworkFailure('Could not sign in. Please try again.'),
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Best-effort: an unreachable server or an already-revoked
      // token must not block clearing the local session — see the
      // repository interface doc comment.
    }
    await _tokenStorage.clearSession();
  }

  @override
  Future<bool> hasStoredToken() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<Result<StaffSession>> restoreSession() async {
    if (!await hasStoredToken()) {
      return const Failed(AuthFailure('Not signed in.'));
    }

    try {
      final data = await _remote.me();
      final session = StaffSession.fromJson(data);
      await _tokenStorage.writeCachedSession(session.toJson());
      return Success(session);
    } on DioException catch (e) {
      final failure = mapStaffDioError(e);
      if (failure is AuthFailure) {
        // The token itself was rejected — nothing left to restore.
        await _tokenStorage.clearSession();
        return Failed(failure);
      }
      // Anything else (offline, timeout, 5xx) — the token might
      // still be perfectly valid, so fall back to the last confirmed
      // session rather than forcing a sign-out the connectivity
      // alone doesn't justify.
      return _cachedSessionOr(failure);
    } catch (_) {
      return _cachedSessionOr(
        const NetworkFailure('Could not restore your session.'),
      );
    }
  }

  Future<Result<StaffSession>> _cachedSessionOr(Failure failure) async {
    final cached = await _tokenStorage.readCachedSession();
    if (cached == null) return Failed(failure);
    return Success(StaffSession.fromJson(cached, isFromCache: true));
  }
}
