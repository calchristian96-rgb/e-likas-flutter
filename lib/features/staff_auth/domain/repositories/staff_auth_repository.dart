import '../../../../core/error/result.dart';
import '../entities/staff_session.dart';

abstract class StaffAuthRepository {
  Future<Result<StaffSession>> login({
    required String email,
    required String password,
  });

  /// Best-effort server-side logout (revokes just this device's
  /// token, per `AuthController::logout` — other sessions stay
  /// logged in). Always clears the local token/cached session
  /// afterward even if the network call fails, per the task's
  /// "handle gracefully" instruction; never touches the pending
  /// registration queue.
  Future<void> logout();

  Future<bool> hasStoredToken();

  /// Restores a session from a previously stored token: validates
  /// against `GET /auth/me` when reachable, and falls back to the
  /// locally cached copy of the last successful validation when
  /// offline — never fabricates a session with no prior successful
  /// login. A confirmed-invalid token (401) is cleared.
  Future<Result<StaffSession>> restoreSession();
}
