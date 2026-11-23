import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../../core/security/secure_token_storage.dart';
import '../../data/datasources/staff_auth_remote_datasource.dart';
import '../../data/repositories/staff_auth_repository_impl.dart';
import '../../domain/entities/staff_session.dart';
import '../../domain/repositories/staff_auth_repository.dart';

part 'staff_auth_provider.g.dart';

@riverpod
StaffAuthRepository staffAuthRepository(Ref ref) {
  final client = ref.watch(staffApiClientProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  return StaffAuthRepositoryImpl(
    StaffAuthRemoteDataSource(client),
    tokenStorage,
  );
}

/// The single source of truth for "is staff signed in, and as whom."
///
/// [build] restores from a stored token on first watch — this never
/// runs at app startup by itself (nothing on the resident path
/// watches this provider), so it can never delay or block the
/// resident Home screen. A `Failed` restore (including "never signed
/// in") resolves to `null` rather than an [AsyncError], so screens can
/// just check `.value == null` to mean "show the login screen."
@riverpod
class StaffAuth extends _$StaffAuth {
  @override
  Future<StaffSession?> build() async {
    StaffApiClient.onPasswordChangeRequired = requirePasswordChange;
    final repo = ref.watch(staffAuthRepositoryProvider);
    final result = await repo.restoreSession();
    return switch (result) {
      Success(:final value) => value,
      Failed() => null,
    };
  }

  Future<Result<StaffSession>> login({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(staffAuthRepositoryProvider);
    final result = await repo.login(email: email, password: password);
    if (result case Success(:final value)) {
      state = AsyncData(value);
    }
    return result;
  }

  /// Any answer said a password change is required (an administrator
  /// reset while signed in): show the change-password screen.
  void requirePasswordChange() {
    final s = state.value;
    if (s == null || s.mustChangePassword) return;
    state = AsyncData(s.copyWith(mustChangePassword: true));
  }

  /// `POST /auth/password` worked: the server's user (with
  /// `must_change_password: false`), or the same session without the flag.
  Future<void> passwordChanged(Map<String, dynamic>? user) async {
    final current = state.value;
    if (current == null) return;
    final next = user == null || user['id'] == null
        ? current.copyWith(mustChangePassword: false)
        : StaffSession.fromJson(user).copyWith(mustChangePassword: false);
    state = AsyncData(next);
    // Saved for an offline restart; the next /auth/me saves it anyway.
    unawaited(
      ref
          .read(secureTokenStorageProvider)
          .writeCachedSession(next.toJson())
          .catchError((Object _) {}),
    );
  }

  Future<void> logout() async {
    final repo = ref.read(staffAuthRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }
}
