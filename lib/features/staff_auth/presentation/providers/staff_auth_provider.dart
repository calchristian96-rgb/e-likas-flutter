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

  Future<void> logout() async {
    final repo = ref.read(staffAuthRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }
}
