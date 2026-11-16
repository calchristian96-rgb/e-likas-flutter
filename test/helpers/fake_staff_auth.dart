import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:elikas_mobile/features/staff_auth/domain/repositories/staff_auth_repository.dart';
import 'package:elikas_mobile/features/staff_auth/presentation/providers/staff_auth_provider.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Signed in as [session] (or signed out when null), no network.
class FakeStaffAuthRepository implements StaffAuthRepository {
  FakeStaffAuthRepository(this.session);

  StaffSession? session;

  @override
  Future<Result<StaffSession>> login({
    required String email,
    required String password,
  }) async =>
      session == null ? const Failed(AuthFailure('no')) : Success(session!);

  @override
  Future<void> logout() async => session = null;

  @override
  Future<bool> hasStoredToken() async => session != null;

  @override
  Future<Result<StaffSession>> restoreSession() async => session == null
      ? const Failed(AuthFailure('Not signed in.'))
      : Success(session!);
}

const official = StaffSession(
  id: 4,
  name: 'Ana Official',
  email: 'ana@example.test',
  role: 'barangay_official',
  roleDisplayName: 'Barangay Official',
  barangayId: 13,
  barangayName: 'Binatagan',
  permissions: {
    'operations.access',
    'page.monitoring',
    'centers.edit',
    'centers.set_status',
    'facility_requests.create',
    'count_submissions.submit',
    'families.re_enroll',
    'box_relief.distribute',
    'situation.update',
    'puroks.view',
  },
);

const cswd = StaffSession(
  id: 10,
  name: 'Carlo CSWD',
  email: 'carlo@example.test',
  role: 'cswd_personnel',
  roleDisplayName: 'CSWD Personnel',
  permissions: {'operations.access', 'scope.all_barangays', 'page.monitoring'},
);

const administrator = StaffSession(
  id: 1,
  name: 'Ada Admin',
  email: 'ada@example.test',
  role: 'administrator',
  roleDisplayName: 'Administrator',
  permissions: {
    'users.manage',
    'logs.view',
    'backups.manage',
    'barangays.view',
  },
);

List<Override> signedInAs(StaffSession? session) => [
  staffAuthRepositoryProvider.overrideWithValue(
    FakeStaffAuthRepository(session),
  ),
];

Widget testApp(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
